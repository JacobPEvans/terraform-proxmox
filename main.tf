
resource "proxmox_vm_qemu" "splunk" {
  name        = "splunk"
  target_node = var.proxmox_node

  # VM hardware
  cores       = 4
  sockets     = 1
  memory      = 4096
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"
  vmid        = 1

  disk {
    slot     = 0
    size     = "2G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = true
  }

  disk {
    slot     = 1
    size     = "100G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = true

  disks {
    ide {
      ide2 {
        cdrom {
          iso = "ISO file"
        }
      }
    }
  }
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Attach the ISO for installation
  cdrom {
    file = "local:iso/ubuntu-24.04.1-live-server-amd64.iso"
  }

  # Optional: set boot order to boot from CD first
  boot = "cd"
}
