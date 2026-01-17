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

  # VM Disk defaults - single source of truth for all disk configurations
  vm_disk_defaults = {
    datastore_id = "local-zfs"
    interface    = "virtio0"
    file_format  = "raw"
    iothread     = true
    ssd          = false
    discard      = "ignore"
  }

  # Container root disk defaults
  container_disk_defaults = {
    datastore_id = "local-zfs"
    size         = 8
  }

  # Additional disk defaults (shared between VMs and containers)
  additional_disk_defaults = {
    file_format = "raw"
    iothread    = true
    ssd         = false
    discard     = "ignore"
  }

  # Agent configuration defaults - used by VMs
  agent_defaults = {
    timeout = "15m"
    trim    = true
    type    = "virtio"
  }

  # Operation timeout configuration - single source of truth
  # These are operation-level timeouts, not HTTP client timeouts
  operation_timeouts = {
    clone       = 1800  # 30 min - disk copy can be slow
    create      = 1800  # 30 min - cloud-init execution
    migrate     = 900   # 15 min - standard
    reboot      = 900   # 15 min - standard
    shutdown_vm = 900   # 15 min - standard
    start_vm    = 900   # 15 min - standard
    stop_vm     = 900   # 15 min - standard
  }

  # VGA type validation helper
  valid_vga_types = ["std", "cirrus", "vmware", "qxl"]

  # Splunk VM defaults
  splunk_vm_defaults = {
    cpu_cores       = 6
    cpu_type        = "host"
    memory_dedicated = 6144
    memory_floating = 6144
    disk_size       = 200
    os_type         = "l26"
    on_boot         = true
    protection      = false
    agent_enabled   = true
    vga_type        = "std"
  }
}
