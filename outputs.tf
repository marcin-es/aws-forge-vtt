output "your_aws_foundry_url" {
  value = aws_instance.foundry.public_dns
}
