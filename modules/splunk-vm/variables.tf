variable "vm_id" {
  description = "Unique VM ID for the Splunk VM"
  type        = number

  validation {
    condition     = var.vm_id > 0 && var.vm_id < 10000
    error_message = "VM ID must be between 1 and 9999."
  }
}

variable "name" {
  description = "Name of the Splunk VM VM"
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 63
    error_message = "VM name must be between 1 and 63 characters."
  }
}

variable "node_name" {
  description = "Proxmox node name where the VM will be created"
  type        = string

  validation {
    condition     = length(var.node_name) > 0
    error_message = "Node name cannot be empty."
  }
}

variable "pool_id" {
  description = "Resource pool ID for the Splunk VM"
  type        = string
  default     = ""

  validation {
    condition     = length(var.pool_id) >= 0
    error_message = "Pool ID must be a valid string."
  }
}

variable "ip_address" {
  description = "IPv4 address with CIDR notation for the Splunk VM (e.g., 192.168.1.100/32)"
  type        = string

  validation {
    condition     = can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}/\\d{1,2}$", var.ip_address))
    error_message = "IP address must be in CIDR notation (e.g., 192.168.1.100/32)."
  }
}

variable "gateway" {
  description = "IPv4 gateway address for the Splunk VM"
  type        = string

  validation {
    condition     = can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", var.gateway))
    error_message = "Gateway must be a valid IPv4 address."
  }
}

variable "template_id" {
  description = "VM ID of the template to clone from"
  type        = number
  default     = 9001

  validation {
    condition     = var.template_id > 0 && var.template_id < 10000
    error_message = "Template ID must be between 1 and 9999."
  }
}

variable "datastore_id" {
  description = "Datastore ID for VM disk storage"
  type        = string
  default     = "local-zfs"

  validation {
    condition     = length(var.datastore_id) > 0
    error_message = "Datastore ID cannot be empty."
  }
}

variable "bridge" {
  description = "Network bridge for VM network interface"
  type        = string
  default     = "vmbr0"

  validation {
    condition     = length(var.bridge) > 0
    error_message = "Bridge name cannot be empty."
  }
}

variable "ssh_public_key" {
  description = "SSH public key content for VM access (optional)"
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = can(regex("^(ssh-rsa |ssh-ed25519 |ecdsa-sha2-|$)", var.ssh_public_key))
    error_message = "SSH public key must be empty or start with a valid SSH key type prefix."
  }
}
