variable "vms" {
  description = "Map of VMs to create"
  type = map(object({
    vm_id       = number
    name        = string
    description = optional(string)
    tags        = optional(list(string), ["terraform"])
    pool_id     = optional(string)

    # Node configuration
    node_name = string

    # Resource configuration
    cpu_cores        = optional(number, 2)
    cpu_type         = optional(string, "x86-64-v2-AES")
    memory_dedicated = optional(number, 1024)
    memory_floating  = optional(number)

    # Storage configuration
    boot_disk = optional(object({
      datastore_id = optional(string, "local-lvm")
      interface    = optional(string, "scsi0")
      size         = optional(number, 32)
      file_format  = optional(string, "raw")
      iothread     = optional(bool, true)
      ssd          = optional(bool, false)
      discard      = optional(string, "ignore")
    }), {})

    # Additional disks
    additional_disks = optional(list(object({
      datastore_id = string
      interface    = string
      size         = number
      file_format  = optional(string, "raw")
      iothread     = optional(bool, true)
      ssd          = optional(bool, false)
      discard      = optional(string, "ignore")
    })), [])

    # Network configuration
    network_interfaces = optional(list(object({
      bridge      = optional(string, "vmbr0")
      model       = optional(string, "virtio")
      vlan_id     = optional(number)
      firewall    = optional(bool, false)
      mac_address = optional(string)
    })), [{ bridge = "vmbr0" }])

    # Initialization
    ip_config = optional(object({
      ipv4_address = optional(string)
      ipv4_gateway = optional(string)
      ipv6_address = optional(string)
      ipv6_gateway = optional(string)
    }), {})

    # Cloud-init / OS configuration
    cdrom_file_id = optional(string)
    user_account = object({
      username = string
      password = string
      keys     = list(string)
    })
    # Agent and features
    agent_enabled = optional(bool, true)
    protection    = optional(bool, false)

    # Operating system
    os_type = optional(string, "l26")
  }))
  default = {}
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "homelab"
}

variable "default_datastore" {
  description = "Default datastore for VM storage"
  type        = string
  default     = "local-lvm"
}

variable "proxmox_api_endpoint" {
  description = "The URL of the Proxmox API (e.g. https://proxmox.example.com:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token" {
  description = "The API token for Proxmox authentication (format: 'user@realm!tokenid=secret')"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Allow insecure HTTPS connections to the Proxmox API (true/false)"
  type        = bool
  default     = false
}

variable "proxmox_ssh_username" {
  description = "The SSH username for connecting to the Proxmox node"
  type        = string
}

variable "proxmox_ssh_private_key" {
  description = "The path to the SSH private key for connecting to the Proxmox node"
  type        = string
}
