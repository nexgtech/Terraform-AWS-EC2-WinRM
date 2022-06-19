output "public_fqdn" {
  value = aws_instance.windows_server.public_dns
}

output "public_ip" {
  value = aws_instance.windows_server.public_ip
}