terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["mar13-vpc"]
  }
}

data "aws_subnet" "public" {
  filter {
    name   = "tag:Name"
    values = ["mar13-public-subnet"]
  }
}

data "aws_subnet" "private" {
  filter {
    name   = "tag:Name"
    values = ["mar13-private-subnet"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }
}

# Skapa en nyckelpar i AWS baserat på en existerande nyckel (för SSH)
resource "aws_key_pair" "deployer_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "public_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnet.public.id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.public_ec2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "mar13-opentofu-public-server"
  }
}

resource "aws_instance" "private_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnet.private.id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.private_ec2_sg.id]

  tags = {
    Name = "mar13-opentofu-private-server"
  }
}

resource "aws_security_group" "public_ec2_sg" {
  name        = "public_ec2_sg"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.trusted_ip_for_ssh]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Tillåter all trafik ut från EC2-instansen
  }
}

resource "aws_security_group" "private_ec2_sg" {
  name   = "private-ec2-sg"
  vpc_id = data.aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.public_ec2_sg.id]
  }
}
