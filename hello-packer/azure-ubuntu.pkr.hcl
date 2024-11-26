# Variables para la configuración
variable "azure_subscription_id" {}
variable "azure_client_id" {}
variable "azure_client_secret" {}
variable "azure_tenant_id" {}
variable "azure_location" {
  default = "East US"
}
variable "node_nginx_image_name" {
  default = "node-nginx-image-{{timestamp}}"
}

# Builder: Azure Resource Manager (ARM)
source "azure-arm" "ubuntu" {
  subscription_id            = var.azure_subscription_id
  client_id                  = var.azure_client_id
  client_secret              = var.azure_client_secret
  tenant_id                  = var.azure_tenant_id
  managed_image_resource_group_name = "packer-images"
  managed_image_name         = var.node_nginx_image_name
  location                   = var.azure_location

  # AMI base: Ubuntu LTS
  os_type                    = "Linux"
  image_publisher            = "Canonical"
  image_offer                = "UbuntuServer"
  image_sku                  = "20_04-lts"
  azure_tags = {
    environment = "Dev"
    created_by  = "Packer"
  }
}

# Build: Configuración de instalación y provisión
build {
  sources = ["source.azure-arm.ubuntu"]

  # Instalación de Node.js y Nginx
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y curl unzip nginx",
      "curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -",
      "sudo apt-get install -y nodejs",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx"
    ]
  }

  # Subir configuración de Nginx personalizada
  provisioner "file" {
    source      = "nginx.conf"
    destination = "/tmp/nginx.conf"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/nginx.conf /etc/nginx/sites-available/default",
      "sudo systemctl restart nginx"
    ]
  }

  # Archivo de estado para validación
  provisioner "shell" {
    inline = [
      "echo 'Node.js y Nginx configurados correctamente' > /home/packer/status.txt"
    ]
  }
}
