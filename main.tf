
resource "proxmox_vm_qemu" "splunk" {
  name        = "splunk"
  target_node = var.proxmox_node

  # VM hardware
  cores       = 4
  sockets     = 1
  memory      = 8192
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  disk {
    slot     = 0
    size     = "50G"
    type     = "scsi"
    storage  = "local-lvm" # Change if your storage is different
    iothread = true
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
