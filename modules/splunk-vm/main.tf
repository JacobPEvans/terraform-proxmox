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

  tags = concat(
    ["terraform", "splunk", "enterprise"],
    [var.environment]
  )

  pool_id    = var.pool_id
  protection = var.protection

  # Startup configuration
  on_boot = var.on_boot

  agent {
    enabled = var.agent_enabled
    timeout = var.agent_timeout
    trim    = var.agent_trim
    type    = var.agent_type
  }

  # CPU configuration: "host" exposes all host CPU features directly
  # to the VM with zero emulation overhead. This provides maximum stability and
  # performance on a single-node homelab. VMs will only run on identical/similar
  # CPUs, but that's acceptable for homelab use.
  # CRITICAL: Must match Packer template's cpu_type setting.
  cpu {
    cores      = var.cpu_cores
    type       = var.cpu_type
    hotplugged = 0
  }

  memory {
    dedicated = var.memory_dedicated
    floating  = var.memory_floating
  }

  # Disk configuration: virtio0 interface uses VirtIO SCSI controller (virtio-scsi-pci)
  # which provides modern, high-performance storage with low CPU overhead.
  # This matches the Packer template's explicit scsi_controller="virtio-scsi-pci" setting.
  # DO NOT use IDE or LSI Logic controllers - they are legacy and cause performance issues.
  disk {
    datastore_id = var.datastore_id
    interface    = var.disk_interface
    size         = var.disk_size
    file_format  = var.disk_file_format
    iothread     = var.disk_iothread
    ssd          = var.disk_ssd
    discard      = var.disk_discard
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
      keys     = var.ssh_public_key != "" ? [var.ssh_public_key] : []
    }
  }

  operating_system {
    type = var.os_type
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
