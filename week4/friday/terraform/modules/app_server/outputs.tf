output "public_ip" {
  description = "Public IP address of the instance."
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance."
  value       = aws_instance.this.private_ip
}

output "instance_id" {
  description = "EC2 instance id."
  value       = aws_instance.this.id
}

output "security_group_id" {
  description = "Security group id attached to the instance."
  value       = aws_security_group.this.id
}
