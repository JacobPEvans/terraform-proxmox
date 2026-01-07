
# Environment and general configuration
variable "environment" {
  description = "Environment name for resource tagging and organization"
  type        = string
  default     = "homelab"
}

# Proxmox connection variables
# The BPG provider reads authentication directly from PROXMOX_VE_* environment variables:
#   - PROXMOX_VE_ENDPOINT   → API URL (without /api2/json)
#   - PROXMOX_VE_API_TOKEN  → API token (user@realm!tokenid=secret)
#   - PROXMOX_VE_USERNAME   → Username for token
#   - PROXMOX_VE_INSECURE   → Skip TLS verification
#
# These variables are kept for backward compatibility and module usage,
# but the provider itself reads from environment variables.

variable "proxmox_insecure" {
  description = "Allow insecure HTTPS connections to the Proxmox API (read from PROXMOX_VE_INSECURE)"
  type        = bool
  default     = false
}

variable "proxmox_node" {
  description = "The name of the Proxmox node to deploy resources on"
  type        = string
  default     = "pve"
}

variable "template_id" {
  description = "VM ID of the Packer-built Splunk template to clone from"
  type        = number
  default     = 9200
  validation {
    condition     = var.template_id > 0 && var.template_id < 10000
    error_message = "Template ID must be between 1 and 9999."
  }
}

variable "datastore_id" {
  description = "Datastore ID for Splunk VM disk storage"
  type        = string
  default     = "local-zfs"
  validation {
    condition     = length(var.datastore_id) > 0
    error_message = "Datastore ID cannot be empty."
  }
}

variable "bridge" {
  description = "Network bridge for Splunk VM network interface"
  type        = string
  default     = "vmbr0"
  validation {
    condition     = length(var.bridge) > 0
    error_message = "Bridge name cannot be empty."
  }
}

variable "ssh_public_key" {
  description = "SSH public key content for Splunk VM access (optional)"
  type        = string
  default     = ""
  sensitive   = true
  validation {
    condition     = can(regex("^(ssh-rsa |ssh-ed25519 |ecdsa-sha2-|$)", var.ssh_public_key))
    error_message = "SSH public key must be empty or start with a valid SSH key type prefix."
  }
}

variable "proxmox_ssh_username" {
  description = "The SSH username for connecting to the Proxmox node (for cloud-init, etc.)"
  type        = string
  default     = "root@pam"
}

variable "proxmox_ssh_private_key" {
  description = "The SSH private key content for connecting to the Proxmox node (use secure parameter store or environment variable)"
  type        = string
  sensitive   = true
  default     = "~/.ssh/id_rsa"
  validation {
    condition     = can(regex("^(~/.ssh/|/.*|-----BEGIN)", var.proxmox_ssh_private_key))
    error_message = "SSH private key must be either a file path starting with ~/ or /, or the actual key content starting with -----BEGIN."
  }
}

variable "proxmox_username" {
  description = "The Proxmox username for authentication"
  type        = string
  default     = "proxmox"
}

# Storage configuration
variable "datastore_default" {
  description = "Default datastore for VM disks and container volumes"
  type        = string
  default     = "local-zfs"
}

variable "datastore_iso" {
  description = "Datastore for ISO images and container templates"
  type        = string
  default     = "local"
}

variable "datastore_backup" {
  description = "Datastore for backups"
  type        = string
  default     = "local"
}

# Template and ISO configuration
variable "proxmox_ct_template_debian" {
  description = "The name of the Debian container template to use for containers"
  type        = string
  default     = "debian-13-standard_13.1-2_amd64.tar.zst"
}

variable "proxmox_iso_debian" {
  description = "The name of the Debian ISO file to use for VMs"
  type        = string
  default     = "debian-13.2.0-amd64-netinst.iso"
}

# Resource pools configuration
variable "pools" {
  description = "Map of resource pools to create"
  type = map(object({
    comment = optional(string)
  }))
  default = {}
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

    # Template cloning
    cdrom_file_id = optional(string)
    clone_template = optional(object({
      template_id = number
    }))

    # User account configuration
    user_account = optional(object({
      username = string
      password = string
      keys     = list(string)
      }), {
      username = "debian"
      password = "" # Must be set in terraform.tfvars - do not use default passwords
      keys     = []
    })

    # Features
    agent_enabled = optional(bool, true)
    protection    = optional(bool, false)
    os_type       = optional(string, "l26")

    # Cloud-init configuration
    cloud_init_user_data = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.vms : v.vm_id >= 100 && v.vm_id <= 999999999
    ])
    error_message = "VM IDs must be between 100 and 999999999."
  }

  validation {
    condition = alltrue([
      for k, v in var.vms : v.cpu_cores >= 1 && v.cpu_cores <= 32
    ])
    error_message = "CPU cores must be between 1 and 32."
  }

  validation {
    condition = alltrue([
      for k, v in var.vms : v.memory_dedicated >= 256 && v.memory_dedicated <= 65536
    ])
    error_message = "Memory must be between 256 MB and 64 GB."
  }
}

# SSH Key Configuration for VMs
variable "vm_ssh_public_key_path" {
  description = "Path to the SSH public key for VM authentication (e.g., ~/.ssh/id_rsa_vm.pub)"
  type        = string
  default     = "~/.ssh/id_rsa_vm.pub"
  validation {
    condition     = can(regex("^(~/.ssh/|/).*\\.pub$", var.vm_ssh_public_key_path))
    error_message = "SSH public key path must be a valid file path ending with .pub"
  }
}

variable "vm_ssh_private_key_path" {
  description = "Path to the SSH private key for VM authentication (e.g., ~/.ssh/id_rsa_vm)"
  type        = string
  default     = "~/.ssh/id_rsa_vm"
  sensitive   = true
  validation {
    condition     = can(regex("^(~/.ssh/|/)", var.vm_ssh_private_key_path))
    error_message = "SSH private key path must be a valid file path starting with ~/ or /"
  }
}

# Cloud-init configuration
variable "ansible_cloud_init_file" {
  description = "Path to the cloud-init configuration file for Ansible server"
  type        = string
  default     = "cloud-init/ansible-server-example.yml"
  validation {
    condition     = can(regex("^cloud-init/.*\\.ya?ml$", var.ansible_cloud_init_file))
    error_message = "Cloud-init file must be in cloud-init/ directory and have .yml or .yaml extension."
  }
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

    # User account configuration
    user_account = optional(object({
      username = string
      password = string
      keys     = list(string)
    }))

    protection = optional(bool, false)
    os_type    = optional(string, "debian")
  }))
  default = {}
}

# Network configuration - single source of truth
variable "network_prefix" {
  description = "Network prefix for IP address derivation (e.g., '10.0.1' - IPs derived as prefix.vm_id)"
  type        = string
  default     = "10.0.1"
  validation {
    condition     = can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.network_prefix))
    error_message = "Network prefix must be in format 'x.x.x' where each octet is 0-255 (e.g., '10.0.1')."
  }
}

variable "network_cidr_mask" {
  description = "CIDR mask for individual IPs (typically /32 for static IPs)"
  type        = string
  default     = "/32"
}

# Firewall configuration
variable "management_network" {
  description = "CIDR of management network for SSH/Web access"
  type        = string
  default     = "192.168.1.0/24"
}

variable "splunk_network" {
  description = "List of Splunk VM IP addresses for firewall rules"
  type        = list(string)
  default     = ["192.168.1.100"]
}

variable "splunk_vm_id" {
  description = "VM ID for the Splunk VM"
  type        = number
  default     = 100
  validation {
    condition     = var.splunk_vm_id > 0 && var.splunk_vm_id < 10000
    error_message = "Splunk VM ID must be between 1 and 9999."
  }
}

variable "splunk_vm_name" {
  description = "Name of the Splunk VM"
  type        = string
  default     = "splunk-vm"
  validation {
    condition     = length(var.splunk_vm_name) > 0 && length(var.splunk_vm_name) <= 63
    error_message = "Splunk VM name must be between 1 and 63 characters."
  }
}

variable "splunk_vm_ip_address" {
  description = "IPv4 address with CIDR notation for the Splunk VM"
  type        = string
  default     = "192.168.1.100/32"
  validation {
    condition     = can(cidrhost(var.splunk_vm_ip_address, 0))
    error_message = "Splunk VM IP address must be a valid IPv4 address in CIDR notation."
  }
}

variable "splunk_vm_pool_id" {
  description = "Resource pool ID for the Splunk VM (optional)"
  type        = string
  default     = ""
}

variable "splunk_network_gateway" {
  description = "Gateway IP address for the Splunk network"
  type        = string
  default     = "192.168.1.1"
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.splunk_network_gateway))
    error_message = "Gateway must be a valid IPv4 address."
  }
}
