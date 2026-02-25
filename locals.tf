# Local values for common computed expressions
locals {
  # DRY Network Configuration - Single Source of Truth
  # IPs are derived from VM IDs: network_prefix.vm_id (e.g., 192.168.0.200 for VM ID 200)
  network_gateway = "${var.network_prefix}.1"

  # Helper function to derive IP from VM ID
  # Usage: local.derive_ip[100] => "192.168.0.100/24"
  derive_ip = { for id in range(1, 1000) : id => "${var.network_prefix}.${id}${var.network_cidr_mask}" }

  # Derived Splunk IP from VM ID (eliminates redundant splunk_vm_ip_address variable)
  splunk_derived_ip = "${var.network_prefix}.${var.splunk_vm_id}${var.network_cidr_mask}"

  # Common tags for all resources
  common_tags = [
    "terraform",
    "proxmox",
    var.environment
  ]

  # Default network configuration
  default_network = {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = false
  }

  # VM defaults computed from variables
  vm_defaults = {
    cpu_cores  = 2
    memory     = 2048
    disk_size  = 20
    os_type    = "l26"
    agent      = true
    protection = false
  }

  # Container defaults
  container_defaults = {
    cpu_cores = 1
    memory    = 1024
    disk_size = 8
    os_type   = "debian"
    features = {
      nesting = true
    }
  }

  # ISO and template configurations
  default_iso         = var.proxmox_iso_debian
  default_ct_template = var.proxmox_ct_template_debian

  # Validation helpers
  valid_vm_ids = {
    for k, v in var.vms : k => v.vm_id
    if v.vm_id >= 100 && v.vm_id <= 999999999
  }

  # Network configurations for different environments
  network_configs = {
    development = {
      bridge = "vmbr0"
      vlan   = 100
    }
    staging = {
      bridge = "vmbr0"
      vlan   = 200
    }
    production = {
      bridge = "vmbr0"
      vlan   = 300
    }
  }

  # Storage configurations
  storage_defaults = {
    datastore_id = "local-zfs"
    file_format  = "raw"
    iothread     = true
    ssd          = false
    discard      = "ignore"
  }

  # Splunk network gateway - derived from network_prefix (DRY)
  # This replaces the explicit splunk_network_gateway variable
  splunk_network_gateway = local.network_gateway

  # VGA type validation helper
  valid_vga_types = ["std", "cirrus", "vmware", "qxl"]

  # DRY: Derive management_network from network_prefix (eliminates redundant variable)
  management_network = "${var.network_prefix}.0${var.network_cidr_mask}"

  # DRY: Derive splunk_network_ips from VM IDs (eliminates redundant variable)
  # Combines splunk VM IP + any containers tagged "splunk"
  splunk_network_ips = concat(
    ["${var.network_prefix}.${var.splunk_vm_id}"],
    [for k, v in var.containers : "${var.network_prefix}.${v.vm_id}" if contains(coalesce(v.tags, []), "splunk")]
  )

  # Pipeline containers: HAProxy (haproxy tag) and Cribl Edge (cribl + edge tags)
  # These receive syslog and NetFlow data from network devices
  pipeline_container_ids = {
    for k, v in var.containers : k => v.vm_id
    if contains(try(v.tags, []), "haproxy") || (
      contains(try(v.tags, []), "cribl") && contains(try(v.tags, []), "edge")
    )
  }

  # Notification containers: Mailpit and ntfy (notifications tag)
  notification_container_ids = {
    for k, v in var.containers : k => v.vm_id
    if contains(try(v.tags, []), "notifications")
  }
}

# Pipeline constants - single source of truth for service, syslog, and NetFlow ports
# Referenced by ansible_inventory output for downstream consumption
locals {
  pipeline_constants = {
    service_ports = {
      haproxy_stats    = 8404
      splunk_web       = 8000
      splunk_hec       = 8088
      splunk_mgmt      = 8089
      cribl_edge_api   = 9000
      cribl_stream_api = 9100
    }
    syslog_ports = {
      unifi     = 1514
      palo_alto = 1515
      cisco_asa = 1516
      linux     = 1517
      windows   = 1518
    }
    netflow_ports = {
      unifi = 2055
    }
    notification_ports = {
      mailpit_smtp = 1025
      mailpit_web  = 8025
      ntfy_http    = 8080
    }
  }
}
