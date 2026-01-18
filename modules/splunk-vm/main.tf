terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.90.0"
    }
  }
}

# Render cloud-init configuration with secrets and config files
# Firewall is managed by Proxmox firewall module, not guest-level iptables
locals {
  cloud_init_config = templatefile("${path.module}/templates/cloud-init.yml.tpl", {
    hostname     = var.name
    indexes_conf = file("${path.module}/files/indexes.conf")
    inputs_conf  = file("${path.module}/files/inputs.conf")
    docker_compose = templatefile("${path.module}/files/docker-compose.yml.tpl", {
      splunk_password  = var.splunk_password
      splunk_hec_token = var.splunk_hec_token
    })
  })
}

resource "proxmox_virtual_environment_vm" "splunk_vm" {
  vm_id       = var.vm_id
  node_name   = var.node_name
  name        = var.name
  description = "Splunk Enterprise Docker - ${var.name}"

  tags = [
    "terraform",
    "splunk",
    "docker",
    "enterprise"
  ]

  pool_id    = var.pool_id
  protection = false

  # Startup configuration
  on_boot = true

  agent {
    enabled = true
    timeout = "15m"
    trim    = true
    type    = "virtio"
  }

  # CPU configuration: "host" exposes all host CPU features directly
  # to the VM with zero emulation overhead
  cpu {
    cores      = var.cpu_cores
    type       = "host"
    hotplugged = 0
  }

  memory {
    dedicated = var.memory
    floating  = var.memory
  }

  # Boot disk: virtio0 interface uses VirtIO SCSI controller
  disk {
    datastore_id = var.datastore_id
    interface    = "virtio0"
    size         = var.boot_disk_size
    file_format  = "raw"
    iothread     = true
    ssd          = false
    discard      = "ignore"
  }

  # Data disk for Splunk index storage (mounted at /opt/splunk)
  dynamic "disk" {
    for_each = var.data_disk_size > 0 ? [1] : []
    content {
      datastore_id = var.datastore_id
      interface    = "virtio1"
      size         = var.data_disk_size
      file_format  = "raw"
      iothread     = true
      ssd          = false
      discard      = "ignore"
    }
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

    # Cloud-init user data with Splunk Docker configuration
    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
  }

  operating_system {
    type = "l26"
  }

  # Timeout configurations - 30 min for clone/create, 15 min standard for others
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

# Cloud-init configuration file stored in Proxmox
resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = var.datastore_id
  node_name    = var.node_name

  source_raw {
    data      = local.cloud_init_config
    file_name = "${var.name}-cloud-init.yml"
  }
}
