variable "region" {
  type = string
  default = "ap-southeast-1"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "gitlab_url" {
  type = string
}

variable "gitlab_reg_token" {
  type = string
}

locals {
  ami_name = format("gitlab-runner-%s", formatdate("DD-MM-YY", timestamp()))
}

source "amazon-ebs" "gitlab-runner" {
  ami_name = local.ami_name
  region = var.region
  instance_type = var.instance_type
  vpc_id = var.vpc_id
  subnet_id = var.subnet_id

  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name = "amzn2-ami-hvm-2.0.20200406.0-x86_64-ebs"
      root-device-type = "ebs"
    }
    owners = ["137112412989"]
    most_recent = true
  }

  associate_public_ip_address = true
  communicator = "ssh"
  ssh_username = "ec2-user"
}

build {
  sources = [
    "source.amazon-ebs.gitlab-runner"
  ]

  provisioner "shell" {
    script = "scripts/provision.sh"
    environment_vars = [
      "GITLAB_URL=${var.gitlab_url}",
      "GITLAB_REG_TOKEN=${var.gitlab_reg_token}",
    ]
  }
}
