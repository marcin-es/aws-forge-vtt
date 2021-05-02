variable "ssh_key_public" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "local_public_ip" {
  type = string
}

variable "fvtt_download_link" {
  type = string
}
