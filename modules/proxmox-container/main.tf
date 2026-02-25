terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.90.0"
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

  # Startup configuration
  start_on_boot = each.value.start_on_boot

  # Startup order: 256 - vm_id (higher IDs start first)
  # Delay: global startup_delay between each start
  startup {
    order    = 256 - each.value.vm_id
    up_delay = var.startup_delay
  }

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

    # User account configuration (only if keys are provided)
    dynamic "user_account" {
      for_each = length(lookup(each.value.user_account, "keys", [])) > 0 || lookup(each.value.user_account, "password", "") != "" ? [1] : []
      content {
        password = lookup(each.value.user_account, "password", "")
        keys     = lookup(each.value.user_account, "keys", [])
      }
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
    datastore_id = each.value.root_disk.datastore_id
    size         = coalesce(each.value.root_disk.size, 8)
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

  # Container features (nesting for Docker, keyctl for overlay fs)
  features {
    nesting = each.value.features.nesting
    keyctl  = each.value.features.keyctl
    fuse    = each.value.features.fuse
    mount   = each.value.features.mount
  }

  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      # Ignore changes to immutable attributes after import
      # These can only be changed by replacing the container
      initialization[0].user_account[0].password,
      initialization[0].user_account[0].keys,
      operating_system[0].template_file_id,
      pool_id,
      # Ignore the runtime started status - this is a computed field that reflects
      # whether the container is currently running. We manage boot behavior via
      # start_on_boot, not runtime state.
      started,
    ]
  }
}
