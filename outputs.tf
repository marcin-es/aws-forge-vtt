output "public_ip" {
  value = aws_instance.foundry.public_ip
}

output "public_dns" {
  value = aws_instance.foundry.public_dns
}
