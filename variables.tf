# För att sätta dina egna värden och slippa skriva in dem varje körning
# skapa en fil som heter terraform.tfvars
#  referens: https://developer.hashicorp.com/terraform/tutorials/configuration-language/variables#assign-values-with-a-file

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "Amazon Machine Image (AMI) ID"
  type        = string
  default     = "ami-05b10e08d247fb927" # Amazon Linux 2023
}

variable "instance_type" {
  description = "Typ av EC2-instans"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "SSH Key Pair för EC2-instansen"
  type        = string
  default     = "tofu-key"
}

variable "public_key_path" {
  description = "Sökväg till den publika (<filnamn>.pub) SSH-nyckeln"
  type        = string
  default     = "~/.ssh/tofu-key.pub"
}

variable "trusted_ip_for_ssh" {
  description = "IP-adresser som släpps in till SSH (glöm inte /32)"
  type        = string
}
