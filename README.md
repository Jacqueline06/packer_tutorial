# Packer Tutorial
Despliegue de Nginx y Nodejs mediante una imagen generada por Packer.

## Tabla de Contenido

- [Requisitos Previos](#requisitos-previos)
- [Comandos Básicos de Packer](#comandos-básicos-de-packer)
- [Template de packer](#template-de-packer)
- [Despliegue sin invtervención manual](#despliegue)
- [Despliegue multinube](#despliegue-multinube)
- [Conclusión](#conclusión)


## Requisitos Previos

Antes de comenzar, asegúrate de tener las siguientes herramientas instaladas con los siguientes comandos:

- **Packer**: Puedes descargarlo desde [la página oficial de Packer](https://www.packer.io/downloads).
```bash
packer version
```
- **AWS CLI**
```bash
aws --version
```
- **Azure CLI** 
```bash
az version
```

## Comandos Básicos de Packer

Packer ofrece varios comandos que te permiten gestionar las plantillas, inicializar la configuración, formatear y validar archivos, y construir imágenes. Aquí te explicamos algunos de los más importantes:

### 1. Inicializar la Configuración de Packer

El primer paso al trabajar con Packer es inicializar la configuración. Este comando descarga los plugins necesarios según lo definido en tu plantilla.

```bash
packer init <archivo>.pkr.hcl
```

**¿Qué hace este comando?**

- Descarga e instala los plugins definidos en tu plantilla. Por ejemplo, si estás trabajando con Amazon, descargará el plugin de Amazon.
- Si los plugins ya están instalados, Packer no hará nada.

### 2. Formatear la Plantilla de Packer

El comando `packer fmt` ajusta el formato de las plantillas para mejorar su legibilidad y consistencia.

```bash
packer fmt <archivo>.pkr.hcl
```

**¿Qué hace este comando?**

- Este comando organiza y da formato a tus archivos `.pkr.hcl` para asegurarse de que sean más legibles y consistentes. Si el archivo ya está bien formateado, no hará cambios.

### 3. Validar la Plantilla de Packer

Es importante asegurarse de que la plantilla de Packer esté libre de errores sintácticos y sea válida antes de usarla. El comando `packer validate` realiza esta validación.

```bash
packer validate <archivo>.pkr.hcl
```

**¿Qué hace este comando?**

- Este comando verifica que la plantilla no tenga errores en su sintaxis y que todos los valores y parámetros estén correctamente configurados.
- Si la plantilla es válida, no se mostrará ningún mensaje; si hay errores, Packer te indicará qué líneas y qué tipo de error existe.

### 4. Construir la Imagen

Una vez que tu plantilla esté lista, el comando `packer build` es el que crea la imagen según la configuración especificada.

```bash
packer build <archivo>.pkr.hcl
```

**¿Qué hace este comando?**

- Packer comienza a construir la imagen, utilizando la plantilla que has definido. Dependiendo de los _builders_ y _provisioners_ que hayas especificado, Packer descargará imágenes base, configurará máquinas virtuales o contenedores, y aplicará los cambios definidos.
- El archivo resultante es una imagen de máquina que se puede usar en entornos de producción.


## Template de packer
Para crear la imagen en packer se ha utilizado como referencia [Build an image - AWS](https://developer.hashicorp.com/packer/tutorials/aws-get-started/aws-get-started-build-image)

## Explicación de la Plantilla Packer (Ejemplo General)

Aquí te presentamos un ejemplo general de cómo se estructura una plantilla de **Packer** en HCL (HashiCorp Configuration Language).

### Ejemplo de Plantilla Packer en HCL

```hcl
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "packer-linux-nginx-nodejs"
  instance_type = "t2.micro"
  region        = "us-west-2"
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
    "source.amazon-ebs.ubuntu"
  ]
}

```

### Descripción de las Secciones de una Plantilla Packer

1. **`packer { required_plugins { ... } }`**:
   - Esta sección es utilizada para definir los plugins que Packer necesita para trabajar. En este caso, se está solicitando el plugin de Amazon (aunque si trabajas con AWS, usarías el plugin `amazon`).
   - Especificas la versión mínima del plugin que necesitas y la fuente del plugin (en este caso, desde el repositorio de HashiCorp en GitHub).
2. **`source "amazon-ebs" "ubuntu" { ... }`**:

   - En esta sección se define un _builder_ (constructor) que indica el tipo de recurso que deseas crear. En este caso, estamos utilizando el _builder_ de Amazon para crear una imagen basada en Ubuntu.
   - **`image`**: Especifica la imagen base que se utilizará (en este caso, `ubuntu:jammy`).
   - **`commit`**: Este parámetro indica que una vez que se hayan realizado los cambios en el contenedor, Packer debe hacer un `commit` para guardar el estado final de la imagen.

3. **`build { ... }`**:
   - El bloque `build` es donde se configuran los pasos de construcción de la imagen. En este caso, estamos construyendo una imagen Amazon basada en la fuente de Amazon que definimos antes (`source.amazon-ebs.ubuntu`).
   - **`name`**: Define un nombre para el proceso de construcción. No es obligatorio, pero es útil para identificar el proceso en los registros.
   - **`sources`**: Aquí defines las fuentes de los _builders_ que utilizarás. En este caso, estamos usando `source.amazon-ebs.ubuntu`, que corresponde al _builder_ que definimos previamente.



## Despliegue

Utilizando el archivo de **template.pkr.hcl** antes de realizar la contrucción de la imagen, se debe realizar la autenticación de AWS.

### Autenticacion con AWS
Si no se desean ingresar las variables directamente el codigo se puede realizar en el ambiente de la consola.

```bash
$env:AWS_ACCESS_KEY_ID="TU_AWS_ACCESS_KEY"
$env:AWS_SECRET_ACCESS_KEY="TU_AWS_SECRET_KEY"
```

En caso contrario debe se contener la siguiente estructura, pero no es recomendable ya que las credenciales de acceso quedan de forma publica.
```bash
source "amazon-ebs" "ubuntu" {
  ami_name        = "${var.ami_prefix}-${local.timestamp}"
  ami_description = "Learn Packer Linux AWS with Redis installed"
  instance_type   = "t2.micro"
  region          = "us-east-1"

  access_key          = "TU_AWS_ACCESS_KEY"
  secret_key          = "TU_AWS_SECRET_KEY"

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
```

## Despliegue multinube

En proceso...

## Conclusión

Packer es una herramienta poderosa y flexible para automatizar la creación de imágenes de infraestructura para múltiples plataformas. Ya sea que se esté trabajando con AWS o cualquier otra plataforma, Packer te permite definir tu infraestructura como código y crear imágenes de manera repetible y consistente.

Este repositorio contiene ejemplos tanto para AWS como para Azure, y puedes extenderlo para experimentar con otras plataformas soportadas por Packer.
