terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "v0.7.1"
    }
    ignition = {
      source = "community-terraform-providers/ignition"
    }
  }
}
variable "ssh_authorized_keys" {
  type = list(string)
}

variable "domain_name" {
  type    = string
  default = "flatcar"
}

variable "memory_mb" {
  type    = string
  default = "16384"
}

variable "vcpu" {
  type    = number
  default = 8
}

variable "pool_name" {
  type = string
}

variable "base_volume_id" {
  type = string
}

variable "network_interface" {
  type    = string
  default = "br0"
}

resource "libvirt_volume" "volume" {
  name           = "${var.domain_name}.qcow2"
  pool           = var.pool_name
  base_volume_id = var.base_volume_id
  format         = "qcow2"
}

resource "libvirt_ignition" "ignition" {
  name    = "${var.domain_name}-ignition"
  pool    = var.pool_name
  content = data.ignition_config.ignition.rendered
}

resource "libvirt_domain" "domain" {
  name   = var.domain_name
  memory = var.memory_mb
  vcpu   = var.vcpu

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_name = var.network_interface
  }

  coreos_ignition = libvirt_ignition.ignition.id
  fw_cfg_name     = "opt/org.flatcar-linux/config"

  disk {
    volume_id = libvirt_volume.volume.id
  }
}

output "hostname" {
  value = var.domain_name
}
