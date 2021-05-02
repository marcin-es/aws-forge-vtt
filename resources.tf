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

data "template_file" "nginx_conf" {
  template = file("${path.module}/templates/nginx.conf")
  vars = {
    public_dns = "${aws_instance.foundry.public_dns}"
  }
}

data "template_file" "foundry_options" {
  template = file("${path.module}/templates/options.json")
  vars = {
    public_dns = "${aws_instance.foundry.public_dns}"
  }
}


resource "aws_security_group" "foundry_vtt" {
  name        = "FoundryVTT"
  description = "Allow necessary port openings for FoundryVTT"

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

resource "aws_eip" "foundry_eip" {
  instance = aws_instance.foundry.id
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
      host = aws_eip.foundry_eip.public_ip
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
      host = aws_eip.foundry_eip.public_ip
      port = 22
    }
    source      = "./files/foundry.service"
    destination = "${local.config_files_path}/foundry.service"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ubuntu"
      host = aws_eip.foundry_eip.public_ip
      port = 22
    }
    inline = [
      "sudo cp ${local.config_files_path}/foundry.service /lib/systemd/system/foundry.service",
      "sudo systemctl enable foundry.service",
      "sudo systemctl start foundry.service"
    ]
  }
}

resource "null_resource" "foundry_nginx_proxy" {
  depends_on = [
    null_resource.foundry_install
  ]

  provisioner "file" {
    connection {
      type = "ssh"
      user = "ubuntu"
      host = aws_eip.foundry_eip.public_ip
      port = 22
    }
    content     = data.template_file.nginx_conf.rendered
    destination = "${local.config_files_path}/nginx.conf"
  }

  provisioner "file" {
    connection {
      type = "ssh"
      user = "ubuntu"
      host = aws_eip.foundry_eip.public_ip
      port = 22
    }
    content     = data.template_file.foundry_options.rendered
    destination = "${local.config_files_path}/options.json"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ubuntu"
      host = aws_eip.foundry_eip.public_ip
      port = 22
    }
    inline = [
      "sudo apt install nginx -y",
      "sudo cp ${local.config_files_path}/nginx.conf /etc/nginx/sites-available/default",
      "sudo systemctl reload nginx.service",
      "cp ${local.config_files_path}/options.json /home/ubuntu/foundrydata/Config/options.json",
      "sudo systemctl restart foundry.service"
    ]
  }
}
