variable "vm_id" {
  description = "Unique VM ID for the Splunk VM"
  type        = number

  validation {
    condition     = var.vm_id > 0 && var.vm_id < 10000
    error_message = "VM ID must be between 1 and 9999."
  }
}

variable "name" {
  description = "Name of the Splunk VM"
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
  description = "Resource pool ID for the Splunk VM (optional, empty string means no pool)"
  type        = string
  default     = ""
}

variable "ip_address" {
  description = "IPv4 address with CIDR notation for the Splunk VM (e.g., 192.168.1.100/24)"
  type        = string

  validation {
    condition     = can(cidrhost(var.ip_address, 0))
    error_message = "IP address must be a valid IPv4 address in CIDR notation (e.g., 192.168.1.100/24)."
  }
}

variable "gateway" {
  description = "IPv4 gateway address for the Splunk VM"
  type        = string

  validation {
    condition     = can(regex("^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$", var.gateway))
    error_message = "Gateway must be a valid IPv4 address (e.g., 192.168.1.1)."
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

variable "vm_password" {
  description = "Password for the VM user account"
  type        = string
  default     = "packer123"
  sensitive   = true
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "homelab"
}

variable "protection" {
  description = "Enable resource protection for the VM"
  type        = bool
  default     = false
}

variable "on_boot" {
  description = "Start the VM automatically on boot"
  type        = bool
  default     = true
}

variable "cpu_cores" {
  description = "Number of CPU cores for the Splunk VM"
  type        = number
  default     = 6

  validation {
    condition     = var.cpu_cores >= 1 && var.cpu_cores <= 32
    error_message = "CPU cores must be between 1 and 32."
  }
}

variable "cpu_type" {
  description = "CPU type for the VM (e.g., 'host', 'x86-64-v2-AES')"
  type        = string
  default     = "host"
}

variable "memory_dedicated" {
  description = "Dedicated memory in MB for the Splunk VM"
  type        = number
  default     = 6144

  validation {
    condition     = var.memory_dedicated >= 256 && var.memory_dedicated <= 65536
    error_message = "Memory must be between 256 MB and 64 GB."
  }
}

variable "memory_floating" {
  description = "Floating memory in MB for the Splunk VM"
  type        = number
  default     = 6144

  validation {
    condition     = var.memory_floating >= 256 && var.memory_floating <= 65536
    error_message = "Floating memory must be between 256 MB and 64 GB."
  }
}

variable "disk_interface" {
  description = "Disk interface type (e.g., 'virtio0', 'scsi0')"
  type        = string
  default     = "virtio0"
}

variable "disk_size" {
  description = "Disk size in GB for the Splunk VM"
  type        = number
  default     = 200

  validation {
    condition     = var.disk_size >= 20 && var.disk_size <= 2000
    error_message = "Disk size must be between 20 GB and 2000 GB."
  }
}

variable "disk_file_format" {
  description = "Disk file format (e.g., 'raw', 'qcow2')"
  type        = string
  default     = "raw"
}

variable "disk_iothread" {
  description = "Enable IO threading for better disk performance"
  type        = bool
  default     = true
}

variable "disk_ssd" {
  description = "Mark disk as SSD for optimization"
  type        = bool
  default     = false
}

variable "disk_discard" {
  description = "Discard strategy for the disk"
  type        = string
  default     = "ignore"
}

variable "os_type" {
  description = "Operating system type for the VM"
  type        = string
  default     = "l26"
}

variable "agent_enabled" {
  description = "Enable QEMU agent for the VM"
  type        = bool
  default     = true
}

variable "agent_timeout" {
  description = "Agent timeout duration"
  type        = string
  default     = "15m"
}

variable "agent_trim" {
  description = "Enable agent trim functionality"
  type        = bool
  default     = true
}

variable "agent_type" {
  description = "Agent type (e.g., 'virtio')"
  type        = string
  default     = "virtio"
}
