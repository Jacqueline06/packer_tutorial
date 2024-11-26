packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
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

  # access_key = "TU_AWS_ACCESS_KEY"
  # secret_key = "TU_AWS_SECRET_KEY"

  instance_type = "t2.micro"
  region        = "us-east-1"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
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
}

# build {
#   name = "hello-packer"
#   sources = [
#     "source.amazon-ebs.ubuntu",
#   ]

#   provisioner "shell" {
#     inline = [
#       "echo updating and upgrading the system",
#       "sleep 30",
#       "sudo apt update",
#       "sudo apt upgrade -y",
#     ]
#   }

#   provisioner "shell" {
#     inline = [
#       "echo Installing Nginx",
#       "sleep 30",
#       "sudo apt install nginx -y",
#       "sudo nginx -version",
#       "sudo systemctl enable nginx",
#       "sudo systemctl start nginx",
#       "sudo systemctl status nginx",
#     ]
#   }

#   provisioner "shell" {
#     inline = [
#       "echo Installing Node.js",
#       "cd ~",
#       "sudo apt update",
#       "curl -fsSL https://fnm.vercel.app/install | bash",
#       "source ~/.bashrc",
#       "fnm use --install-if-missing 22",
#       "node -v",
#       "npm -v",
#     ]
#   }

#   provisioner "file" {
#     source      = "./hello.js"
#     destination = "/home/ubuntu/hello.js"
#   }

#   provisioner "shell" {
#     inline = [
#       "echo Creating a simple Node.js app",
#       "cd ~",
#       "mkdir -p app",
#       "mv /home/ubuntu/hello.js app/hello.js",
#       "cd app",
#       "node hello.js",
#     ]
#   }

#   provisioner "shell" {
#     inline = [
#       "echo 'Serving the app with Nginx'",
#       "sudo nano /etc/nginx/sites-available/app.example.com.conf",
#     ]
#   }

#   post-processor "shell-local" {
#     inline = [
#       "echo 'AMI created successfully'",
#     ]
#   }
# }
