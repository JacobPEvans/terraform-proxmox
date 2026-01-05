# Local values for common computed expressions
locals {
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

  # Splunk network gateway (from variable)
  splunk_network_gateway = var.splunk_network_gateway
}
