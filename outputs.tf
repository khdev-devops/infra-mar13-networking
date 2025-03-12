output "ec2_public_ip" {
  description = "Den publika IP-adressen för EC2-instansen"
  value       = aws_instance.public_instance.public_ip
}

output "ec2_private_ip" {
  description = "Den private IP-adressen för EC2-instansen"
  value       = aws_instance.private_instance.private_ip
}

