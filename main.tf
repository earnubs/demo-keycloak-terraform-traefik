terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
  host = var.docker_host
}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "nginx" {
  image        = docker_image.nginx.image_id
  name         = "tutorial"
  network_mode = "bridge"
  ports {
    internal = 80
    external = 8000
  }
}

variable "docker_host" {
  description = "Docker host"
  type        = string
  default     = "unix:///var/run/docker.sock"
  nullable    = false
}
