variable "containers" {
  description = "Map of containers to create"
  type = map(object({
    vm_id       = number
    node_name   = string
    description = optional(string)
    tags        = optional(list(string), ["terraform", "container"])
    pool_id     = optional(string)

    # Container specific
    hostname         = string
    template_file_id = string
    os_type          = optional(string, "debian")

    # Resource configuration
    cpu_cores        = optional(number, 1)
    memory_dedicated = optional(number, 512)
    memory_swap      = optional(number, 512)

    # Storage
    root_disk = optional(object({
      datastore_id = optional(string, "local-lvm")
      size         = optional(number, 8)
    }), {})

    # Mount points
    mount_points = optional(list(object({
      volume = string
      size   = string
      path   = string
    })), [])

    # Network
    network_interfaces = optional(list(object({
      name     = optional(string, "eth0")
      bridge   = optional(string, "vmbr0")
      firewall = optional(bool, false)
      vlan_id  = optional(number)
    })), [{ name = "eth0", bridge = "vmbr0" }])

    # Initialization
    ip_config = optional(object({
      ipv4_address = optional(string)
      ipv4_gateway = optional(string)
    }), {})

    user_account = optional(object({
      password = optional(string, "")
      keys     = optional(list(string), [])
    }), {})

    # Features
    protection    = optional(bool, false)
    start_on_boot = optional(bool, true)

    # LXC features (nesting required for Docker-in-LXC)
    features = optional(object({
      nesting = optional(bool, true)
      keyctl  = optional(bool, false)
      fuse    = optional(bool, false)
      mount   = optional(list(string), [])
    }), { nesting = true, keyctl = false, fuse = false, mount = [] })
  }))
  default = {}
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "homelab"
}

variable "default_datastore" {
  description = "Default datastore for container storage (passed from root module)"
  type        = string
  default     = "local-zfs"
}

variable "startup_delay" {
  description = "Global startup delay in seconds between container starts"
  type        = number
  default     = 30
}
