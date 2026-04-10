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
# resource "yandex_compute_instance" "nat" {
#   name        = "nat-instance"
#   zone        = var.zone
#   platform_id = "standard-v1"

#   resources {
#     cores  = 2
#     memory = 2
#   }

#   boot_disk {
#     initialize_params {
#       image_id = "fd80mrhj8fl2oe87o4e1"
#     }
#   }

#   network_interface {
#     subnet_id = yandex_vpc_subnet.public.id
#     nat       = true
#     # ip_address = "192.168.10.254"
#   }

#   metadata = {
#     ssh-keys = "ubuntu:${file("~/.ssh/yandex-key.pub")}"
#   }
# }

# -------------------------
# PUBLIC VM (internet check)
# -------------------------
# resource "yandex_compute_instance" "public_vm" {
#   name        = "public-vm"
#   zone        = var.zone
#   platform_id = "standard-v1"

#   resources {
#     cores  = 2
#     memory = 2
#   }

#   boot_disk {
#     initialize_params {
#       image_id = "fd827b91d99psvq5fjit"
#     }
#   }

#   network_interface {
#     subnet_id = yandex_vpc_subnet.public.id
#     nat       = true
#   }

#   metadata = {
#     ssh-keys = "ubuntu:${file("~/.ssh/yandex-key.pub")}"
#   }
# }

# -------------------------
# ROUTE TABLE (PRIVATE -> NAT)
# -------------------------
# resource "yandex_vpc_route_table" "private_rt" {
#   name       = "private-route-table"
#   network_id = yandex_vpc_network.network.id

#   static_route {
#     destination_prefix = "0.0.0.0/0"
#     next_hop_address   = "192.168.10.254"
#   }
# }

# # Attach route table to private subnet
# resource "yandex_vpc_subnet" "private" {
#   name           = "private"
#   zone           = var.zone
#   network_id     = yandex_vpc_network.network.id
#   v4_cidr_blocks = ["192.168.20.0/24"]

#   route_table_id = yandex_vpc_route_table.private_rt.id
# }

# -------------------------
# PRIVATE VM
# -------------------------
# resource "yandex_compute_instance" "private_vm" {
#   name        = "private-vm"
#   zone        = var.zone
#   platform_id = "standard-v1"

#   resources {
#     cores  = 2
#     memory = 2
#   }

#   boot_disk {
#     initialize_params {
#       image_id = "fd827b91d99psvq5fjit"
#     }
#   }

#   network_interface {
#     subnet_id = yandex_vpc_subnet.private.id
#     nat       = false
#   }

#   metadata = {
#     ssh-keys = "ubuntu:${file("~/.ssh/yandex-key.pub")}"
#   }
# }

# resource "yandex_compute_instance_group" "lamp_group" {
#   name               = "lamp-instance-group"
#   folder_id          = var.folder_id
#   service_account_id = yandex_iam_service_account.sa.id

#   depends_on = [
#     yandex_resourcemanager_folder_iam_member.compute_admin,
#     yandex_resourcemanager_folder_iam_member.vpc_user,
#     yandex_resourcemanager_folder_iam_member.iam_user
#   ]

#   instance_template {
#     platform_id = "standard-v1"

#     resources {
#       cores  = 2
#       memory = 2
#     }

#     boot_disk {
#       initialize_params {
#         image_id = "fd827b91d99psvq5fjit"
#       }
#     }

#     network_interface {
#       subnet_ids = [yandex_vpc_subnet.public.id]
#       nat        = true
#     }

#     metadata = {
#       ssh-keys  = "ubuntu:${file("~/.ssh/yandex-key.pub")}"
#       user-data = <<-EOF
#                 #cloud-config
#                 runcmd:
#                   - apt update
#                   - apt install -y apache2 php
#                   - systemctl enable apache2
#                   - systemctl start apache2
#                   - echo "<h1>LAMP VM</h1><img src='https://storage.yandexcloud.net/student-bucket-71dzhinozfl/71dZHINOZFL.jpg' width='400'>" > /var/www/html/index.html
#               EOF
#     }
#   }

#   scale_policy {
#     fixed_scale {
#       size = 3
#     }
#   }

#   allocation_policy {
#     zones = ["ru-central1-a"]
#   }

#   deploy_policy {
#     max_unavailable = 1
#     max_creating    = 1
#     max_expansion   = 1
#     max_deleting    = 1
#   }

#   health_check {
#     http_options {
#       port = 80
#       path = "/"
#     }
#   }

#   load_balancer {
#     target_group_name = "lamp-target-group"
#   }
# }

resource "yandex_kms_symmetric_key" "bucket_key" {
  name              = "bucket-key"
  description       = "Key for bucket encryption"
  default_algorithm = "AES_128"
  rotation_period   = "8760h"
}

# resource "yandex_storage_bucket" "bucket" {
#   bucket = "student-bucket-71dzhinozfl"

#   access_key = var.access_key
#   secret_key = var.secret_key

#   depends_on = [
#     yandex_kms_symmetric_key.bucket_key
#   ]

#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         sse_algorithm     = "aws:kms"
#         kms_master_key_id = yandex_kms_symmetric_key.bucket_key.id
#       }
#     }
#   }
# }
resource "yandex_storage_object" "index" {
  bucket = yandex_storage_bucket.bucket.bucket
  key    = "index.html"
  source = "./index.html"
  acl    = "public-read"
}
