# resource "proxmox_virtual_environment_container" "container" {
#   vm_id       = 100
#   node_name   = var.proxmox_node
#   description = "TF CT container"
#   tags        = ["terraform", "ubuntu", "container"]

#   protection = false

#   initialization {
#     hostname = "tf-pve-ubuntu-ct-container"

#     ip_config {
#       ipv4 {
#         address = "10.0.1.100/32"
#       }
#     }

#     user_account {
#       keys = [
#         trimspace(tls_private_key.ubuntu_vm_key.public_key_openssh)
#       ]
#       password = random_password.ubuntu_vm_password.result
#     }
#   }

#   cpu {
#     cores = 2
#   }

#   memory {
#     dedicated = 512
#     swap      = 512
#   }

#   disk {
#     datastore_id = "local-lvm"
#     size         = 16
#   }

#   mount_point {
#     # volume mount, a new volume will be created by PVE
#     volume = "local-lvm"
#     size   = "8G"
#     path   = "/mnt/volume"
#   }

#   network_interface {
#     name   = "eth0"
#     bridge = "vmbr0"
#   }

#   operating_system {
#     template_file_id = "local:vztmpl/${var.proxmox_ct_template_ubuntu}"
#     type             = "ubuntu"
#   }
# }
