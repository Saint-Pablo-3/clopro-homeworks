provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.100"
    }
  }
}
# -------------------------
# VPC
# -------------------------
resource "yandex_vpc_network" "network" {
  name = "hw-network"
}

# PUBLIC SUBNET
resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}


# -------------------------
# NAT INSTANCE
# -------------------------
resource "yandex_compute_instance" "nat" {
  name        = "nat-instance"
  zone        = var.zone
  platform_id = "standard-v1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.public.id
    nat        = true
    ip_address = "192.168.10.254"
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/yandex-key.pub")}"
  }
}

# -------------------------
# PUBLIC VM (internet check)
# -------------------------
resource "yandex_compute_instance" "public_vm" {
  name        = "public-vm"
  zone        = var.zone
  platform_id = "standard-v1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd827b91d99psvq5fjit"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/yandex-key.pub")}"
  }
}

# -------------------------
# ROUTE TABLE (PRIVATE -> NAT)
# -------------------------
resource "yandex_vpc_route_table" "private_rt" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
  }
}

# Attach route table to private subnet
resource "yandex_vpc_subnet" "private" {
  name           = "private"
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.20.0/24"]

  route_table_id = yandex_vpc_route_table.private_rt.id
}

# -------------------------
# PRIVATE VM
# -------------------------
resource "yandex_compute_instance" "private_vm" {
  name        = "private-vm"
  zone        = var.zone
  platform_id = "standard-v1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd827b91d99psvq5fjit"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private.id
    nat       = false
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/yandex-key.pub")}"
  }
}
