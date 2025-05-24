resource "proxmox_virtual_environment_pool" "logging" {
  comment = "TF Logging Pool"
  pool_id = "logging"
}

resource "proxmox_virtual_environment_vm" "splunk" {
  vm_id       = 102
  node_name   = var.proxmox_node
  name        = "splunk"
  description = "TF VM Splunk"
  tags        = ["terraform", "ubuntu", "splunk"]

  agent {
    # read 'Qemu guest agent' section, change to true only when ready
    enabled = false
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
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 64
    file_format  = "raw"
    iothread     = true
  }

  initialization {
    ip_config {
      ipv4 {
        address = "10.0.1.102/32"
      }
    }
  }

  network_device {
    bridge = "vmbr0"
  }

  cdrom {
    file_id = "local:iso/ubuntu-24.04.1-live-server-amd64.iso"
  }

  operating_system {
    type = "l26"
  }

  #boot_order = ["cdrom", "scsi0"]
}
