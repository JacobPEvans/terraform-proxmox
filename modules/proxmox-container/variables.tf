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
    os_type          = optional(string, "ubuntu")

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

    user_account = object({
      password = string
      keys     = list(string)
    })

    # Features
    protection = optional(bool, false)
  }))
  default = {}
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "homelab"
}

variable "default_datastore" {
  description = "Default datastore for container storage"
  type        = string
  default     = "local-lvm"
}
