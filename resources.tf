locals {
  config_files_path = "~/foundry_files"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "foundry_vtt" {
  name        = "FoundryVTT"
  description = "Allow necessary port openings for FoundryVTT"
  # vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 30000
    to_port          = 30000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "SSH from current public IP address"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.local_public_ip]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "FoundryVTT"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "foundry-deployment-key"
  public_key = file(var.ssh_key_public)
}

resource "aws_instance" "foundry" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t3.micro"
  key_name        = "foundry-deployment-key"
  security_groups = ["FoundryVTT"]
  tags = {
    Name = "FoundryVTT"
  }
}

resource "null_resource" "foundry_install" {
  depends_on = [
    aws_instance.foundry
  ]

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ubuntu"
      host = aws_instance.foundry.public_ip
      port = 22
    }
    inline = [
      # Install nodejs, unzip
      "sudo apt update",
      "curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -",
      "sudo apt install libssl-dev unzip nodejs -y",
      # Install FoundryVTT
      "mkdir foundryvtt foundrydata ${local.config_files_path}",
      "cd foundryvtt",
      "wget -O foundryvtt.zip \"${var.fvtt_download_link}\"",
      "unzip foundryvtt.zip"
    ]
  }

  provisioner "file" {
    connection {
      type = "ssh"
      user = "ubuntu"
      host = aws_instance.foundry.public_ip
      port = 22
    }
    source      = "./files/foundry.service"
    destination = "${local.config_files_path}/foundry.service"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ubuntu"
      host = aws_instance.foundry.public_ip
      port = 22
    }
    inline = [
      "sudo cp ${local.config_files_path}/foundry.service /lib/systemd/system/foundry.service",
      "sudo systemctl enable foundry.service",
      "sudo systemctl start foundry.service"
    ]
  }
}
