packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.3"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ami_prefix" {
  type    = string
  default = "packer-linux-nginx-nodejs"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {
  ami_name        = "${var.ami_prefix}-${local.timestamp}"
  ami_description = "AMI with Nginx and Node.js installed on Ubuntu"

  #   associate_public_ip_address = true
  instance_type = "t2.micro"
  region        = "us-east-1"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  ssh_username = "ubuntu"
}

build {
  name = "hello-packer"
  sources = [
    "source.amazon-ebs.ubuntu",
  ]

  provisioner "file" {
    source      = "./hello.js"
    destination = "/home/ubuntu/hello.js"
  }

  provisioner "file" {
    source      = "./nginx.conf"
    destination = "/home/ubuntu/nginx.conf"
  }

  provisioner "shell" {
    inline = [
      "echo Updating and upgrading the system",
      "sleep 10",
      "sudo apt update",
      "sudo apt upgrade -y",
      "echo Installing Nginx",
      "sleep 10",
      "sudo apt install nginx -y",
      "sudo nginx -version",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "echo 'Installing Node.js with fnm'",
      "sleep 10",
      "cd ~",
      "curl -sL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh",
      "sudo bash nodesource_setup.sh",
      "sudo apt install nodejs -y",
      "node -v",
      "npm -v",
      "sudo apt install build-essential -y",
      "echo 'Installing PM2 process manager'",
      "sudo npm install pm2@latest -g",
      "echo 'Creating a simple Node.js app and running it with PM2'",
      "cd ~",
      "mkdir -p app",
      "mv /home/ubuntu/hello.js app/hello.js",
      "cd app",
      "pm2 start hello.js",
      "pm2 startup systemd",
      "echo 'Serving the app with Nginx'",
      "sudo mv /home/ubuntu/nginx.conf /etc/nginx/nginx.conf",
      "sudo nginx -t",
      "sudo systemctl restart nginx",
    ]
  }

  post-processor "shell-local" {
    inline = [
      "echo 'AMI created successfully'",
    ]
  }
}
