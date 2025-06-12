resource "proxmox_virtual_environment_vm" "syslog" {
  vm_id       = 100
  node_name   = var.proxmox_node
  name        = "syslog"
  description = "TF VM Syslog"
  tags        = ["terraform", "ubuntu", "syslog"]

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = "10.0.1.100/32"
      }
    }

    user_account {
      keys = [
        trimspace(tls_private_key.ubuntu_vm_key.public_key_openssh)
      ]
      username = var.proxmox_username
      password = random_password.ubuntu_vm_password.result
    }
  }

  agent {
    enabled = true
  }

  cdrom {
    file_id = "local:iso/${var.proxmox_iso_ubuntu}"
  }

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 2048
    floating  = 2048 # set equal to dedicated to enable ballooning
    #hugepages = "disable"
  }

  disk {
    datastore_id      = "local-lvm"
    #path_in_datastore = "vm-100-disk-0"
    interface         = "scsi0"
    size              = 16
    file_format       = "raw"
    iothread          = true
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }
}
