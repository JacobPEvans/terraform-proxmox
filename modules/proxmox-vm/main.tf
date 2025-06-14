terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.78.0"
    }
  }
}

resource "proxmox_virtual_environment_vm" "vms" {
  for_each = var.vms

  vm_id       = each.value.vm_id
  node_name   = each.value.node_name
  name        = each.value.name
  description = each.value.description != null ? each.value.description : "TF VM ${each.value.name} - ${var.environment}"

  tags = concat(
    each.value.tags,
    [var.environment]
  )

  pool_id    = each.value.pool_id
  protection = each.value.protection

  agent {
    enabled = each.value.agent_enabled
    trim    = true
    type    = "virtio"
  }

  cpu {
    cores      = each.value.cpu_cores
    type       = each.value.cpu_type
    hotplugged = 0
  }

  memory {
    dedicated = each.value.memory_dedicated
    floating  = each.value.memory_floating != null ? each.value.memory_floating : each.value.memory_dedicated
  }

  disk {
    datastore_id = each.value.boot_disk.datastore_id != null ? each.value.boot_disk.datastore_id : var.default_datastore
    interface    = each.value.boot_disk.interface != null ? each.value.boot_disk.interface : "scsi0"
    size         = each.value.boot_disk.size != null ? each.value.boot_disk.size : 32
    file_format  = each.value.boot_disk.file_format != null ? each.value.boot_disk.file_format : "raw"
    iothread     = each.value.boot_disk.iothread != null ? each.value.boot_disk.iothread : true
    ssd          = each.value.boot_disk.ssd != null ? each.value.boot_disk.ssd : false
    discard      = each.value.boot_disk.discard != null ? each.value.boot_disk.discard : "ignore"
  }

  dynamic "disk" {
    for_each = each.value.additional_disks
    content {
      datastore_id = disk.value.datastore_id
      interface    = disk.value.interface
      size         = disk.value.size
      file_format  = disk.value.file_format != null ? disk.value.file_format : "raw"
      iothread     = disk.value.iothread != null ? disk.value.iothread : true
      ssd          = disk.value.ssd != null ? disk.value.ssd : false
      discard      = disk.value.discard != null ? disk.value.discard : "ignore"
    }
  }

  dynamic "network_device" {
    for_each = each.value.network_interfaces
    content {
      bridge      = network_device.value.bridge
      model       = network_device.value.model != null ? network_device.value.model : "virtio"
      vlan_id     = network_device.value.vlan_id
      firewall    = network_device.value.firewall != null ? network_device.value.firewall : false
      mac_address = network_device.value.mac_address
    }
  }

  dynamic "cdrom" {
    for_each = each.value.cdrom_file_id != null ? [each.value.cdrom_file_id] : []
    content {
      file_id = cdrom.value
    }
  }

  initialization {
    datastore_id = var.default_datastore

    dynamic "ip_config" {
      for_each = each.value.ip_config.ipv4_address != null || each.value.ip_config.ipv6_address != null ? [1] : []
      content {
        ipv4 {
          address = each.value.ip_config.ipv4_address
          gateway = each.value.ip_config.ipv4_gateway
        }

        dynamic "ipv6" {
          for_each = each.value.ip_config.ipv6_address != null ? [1] : []
          content {
            address = each.value.ip_config.ipv6_address
            gateway = each.value.ip_config.ipv6_gateway
          }
        }
      }
    }

    user_account {
      username = each.value.user_account.username
      password = each.value.user_account.password
      keys     = each.value.user_account.keys
    }
  }

  operating_system {
    type = each.value.os_type
  }

  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      initialization[0].user_account[0].password,
    ]
  }
}
