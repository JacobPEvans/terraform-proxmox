terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.89.0"
    }
  }
}

resource "proxmox_virtual_environment_container" "containers" {
  for_each = var.containers

  vm_id       = each.value.vm_id
  node_name   = each.value.node_name
  description = each.value.description != null ? each.value.description : "TF CT ${each.value.hostname} - ${var.environment}"

  # Tags with environment
  tags = concat(
    each.value.tags,
    [var.environment]
  )

  # Pool assignment
  pool_id = each.value.pool_id

  # Protection
  protection = each.value.protection

  # Container initialization
  initialization {
    hostname = each.value.hostname

    # IP configuration
    dynamic "ip_config" {
      for_each = each.value.ip_config.ipv4_address != null ? [1] : []
      content {
        ipv4 {
          address = each.value.ip_config.ipv4_address
          gateway = each.value.ip_config.ipv4_gateway
        }
      }
    }

    # User account configuration
    user_account {
      password = each.value.user_account.password
      keys     = each.value.user_account.keys
    }
  }

  # CPU configuration
  cpu {
    cores = each.value.cpu_cores
  }

  # Memory configuration
  memory {
    dedicated = each.value.memory_dedicated
    swap      = each.value.memory_swap
  }

  # Root disk
  disk {
    datastore_id = each.value.root_disk.datastore_id != null ? each.value.root_disk.datastore_id : var.default_datastore
    size         = each.value.root_disk.size != null ? each.value.root_disk.size : 8
  }

  # Additional mount points
  dynamic "mount_point" {
    for_each = each.value.mount_points
    content {
      volume = mount_point.value.volume
      size   = mount_point.value.size
      path   = mount_point.value.path
    }
  }

  # Network interfaces
  dynamic "network_interface" {
    for_each = each.value.network_interfaces
    content {
      name     = network_interface.value.name
      bridge   = network_interface.value.bridge
      firewall = network_interface.value.firewall
      vlan_id  = network_interface.value.vlan_id
    }
  }

  # Operating system
  operating_system {
    template_file_id = each.value.template_file_id
    type             = each.value.os_type
  }

  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      # Ignore changes to password after first boot
      initialization[0].user_account[0].password,
    ]
  }
}
