output "server_public_ip" {
  description = "Public IP address of the Taiga server"
  value       = aws_eip.taiga.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh ubuntu@${aws_eip.taiga.public_ip}"
}

output "ssh_allowed_cidr" {
  description = "CIDR that is allowed to SSH into the instance"
  value       = local.ssh_cidr
}
