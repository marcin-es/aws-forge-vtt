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

resource "aws_key_pair" "deployer" {
  key_name   = "foundry-deployment-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "foundry" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name = "foundry-deployment-key"
  tags = {
    Name = "FoundryVTT"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = self.public_ip
      port        = 22
      # private_key = file("~/.ssh/id_rsa")
    }
    inline = [
      # Get nodeJS
      "sudo apt install -y libssl-dev",
      "curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -",
      "sudo apt install -y nodejs",
      # Get Foundry zip file with wget
      "sudo apt install -y wget"
    ]

  }
}