terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.90.0"
    }
  }
}

resource "proxmox_virtual_environment_vm" "splunk_vm" {
  vm_id       = var.vm_id
  node_name   = var.node_name
  name        = var.name
  description = "Splunk Enterprise All-in-One - ${var.name}"

  tags = [
    "terraform",
    "splunk",
    "enterprise"
  ]

  pool_id    = var.pool_id
  protection = false

  agent {
    enabled = true
    timeout = "15m"
    trim    = true
    type    = "virtio"
  }

  cpu {
    cores      = 6
    type       = "host"
    hotplugged = 0
  }

  vga {
    type = "std"
  }

  memory {
    dedicated = 6144
    floating  = 6144
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "virtio0"
    size         = 200
    file_format  = "raw"
    iothread     = true
    ssd          = false
    discard      = "ignore"
  }

  network_device {
    bridge   = var.bridge
    model    = "virtio"
    firewall = true
  }

  clone {
    vm_id = var.template_id
  }

  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    user_account {
      username = "debian"
      password = var.vm_password
      keys     = var.ssh_public_key != "" ? [var.ssh_public_key] : []
    }
  }

  operating_system {
    type = "l26"
  }

  # Timeout configurations - 30 min for clone/create, 15 min standard for others
  # These are operation-level timeouts, not HTTP client timeouts
  timeout_clone       = 1800  # 30 min - disk copy can be slow
  timeout_create      = 1800  # 30 min - cloud-init execution
  timeout_migrate     = 900   # 15 min - standard
  timeout_reboot      = 900   # 15 min - standard
  timeout_shutdown_vm = 900   # 15 min - standard
  timeout_start_vm    = 900   # 15 min - standard
  timeout_stop_vm     = 900   # 15 min - standard

  lifecycle {
    create_before_destroy = false
  }
}
