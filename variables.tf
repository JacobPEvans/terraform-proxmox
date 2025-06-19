
# Environment and general configuration
variable "environment" {
  description = "Environment name for resource tagging and organization"
  type        = string
  default     = "homelab"
}

# Proxmox connection variables
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

variable "proxmox_node" {
  description = "The name of the Proxmox node to deploy resources on"
  type        = string
  default     = "pve"
}

variable "proxmox_ssh_username" {
  description = "The SSH username for connecting to the Proxmox node (for cloud-init, etc.)"
  type        = string
  default     = "root@pam"
}

variable "proxmox_ssh_private_key" {
  description = "The path to the SSH private key for connecting to the Proxmox node"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "proxmox_username" {
  description = "The Proxmox username for authentication"
  type        = string
  default     = "proxmox"
}

# Template and ISO configuration
variable "proxmox_ct_template_ubuntu" {
  description = "The name of the Ubuntu container template to use for containers"
  type        = string
  default     = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}

variable "proxmox_iso_ubuntu" {
  description = "The name of the Ubuntu ISO file to use for VMs"
  type        = string
  default     = "ubuntu-24.04.1-live-server-amd64.iso"
}

# Resource pools configuration
variable "pools" {
  description = "Map of resource pools to create"
  type = map(object({
    comment = optional(string)
  }))
  default = {
    logging = {
      comment = "Logging infrastructure pool"
    }
    compute = {
      comment = "General compute resources pool"
    }
  }
}

# Storage datastores configuration
variable "datastores" {
  description = "Map of additional datastores to create beyond default local storage"
  type = map(object({
    type    = string # "dir", "nfs", etc.
    path    = optional(string)
    content = optional(list(string), ["images", "vztmpl", "iso", "backup"])
    shared  = optional(bool, false)
    nodes   = optional(list(string))
    # NFS specific
    server  = optional(string)
    export  = optional(string)
    options = optional(string)
  }))
  default = {}
}

# VMs configuration
variable "vms" {
  description = "Map of VMs to create"
  type = map(object({
    vm_id       = number
    name        = string
    description = optional(string)
    tags        = optional(list(string), ["terraform"])
    pool_id     = optional(string)

    # Resource configuration
    cpu_cores        = optional(number, 4)
    cpu_type         = optional(string, "x86-64-v2-AES")
    memory_dedicated = optional(number, 2048)
    memory_floating  = optional(number)

    # Storage configuration
    boot_disk = optional(object({
      datastore_id = optional(string, "local-lvm")
      interface    = optional(string, "scsi0")
      size         = optional(number, 64)
      file_format  = optional(string, "raw")
      iothread     = optional(bool, true)
      ssd          = optional(bool, false)
      discard      = optional(string, "ignore")
    }), {})

    # Network configuration
    network_interfaces = optional(list(object({
      bridge   = optional(string, "vmbr0")
      model    = optional(string, "virtio")
      vlan_id  = optional(number)
      firewall = optional(bool, false)
    })), [{ bridge = "vmbr0" }])

    # Initialization
    ip_config = optional(object({
      ipv4_address = optional(string)
      ipv4_gateway = optional(string)
    }), {})

    # Features
    agent_enabled = optional(bool, true)
    protection    = optional(bool, false)
    os_type       = optional(string, "l26")
  }))
  default = {}
}

# Containers configuration
variable "containers" {
  description = "Map of containers to create"
  type = map(object({
    vm_id       = number
    hostname    = string
    description = optional(string)
    tags        = optional(list(string), ["terraform", "container"])
    pool_id     = optional(string)

    # Resource configuration
    cpu_cores        = optional(number, 2)
    memory_dedicated = optional(number, 512)
    memory_swap      = optional(number, 512)

    # Storage
    root_disk = optional(object({
      datastore_id = optional(string, "local-lvm")
      size         = optional(number, 16)
    }), {})

    # Network
    network_interfaces = optional(list(object({
      name     = optional(string, "eth0")
      bridge   = optional(string, "vmbr0")
      firewall = optional(bool, false)
    })), [{ name = "eth0", bridge = "vmbr0" }])

    # Initialization
    ip_config = optional(object({
      ipv4_address = optional(string)
      ipv4_gateway = optional(string)
    }), {})

    protection = optional(bool, false)
    os_type    = optional(string, "ubuntu")
  }))
  default = {}
}
