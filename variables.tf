
# Environment and general configuration
variable "environment" {
  description = "Environment name for resource tagging and organization"
  type        = string
  default     = "homelab"
}

# Proxmox connection variables
# SECURITY: These are provided via environment variables (TF_VAR_*) from secret manager
# Provider credentials are always stored in Terraform state, but our state file is:
#   - Encrypted at rest in S3 (AES-256 server-side encryption)
#   - Encrypted in transit (TLS)
#   - Access-controlled via IAM policies
#   - Locked via DynamoDB to prevent concurrent modifications
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
  default     = "debian-13-standard_13.2-1_amd64.tar.zst"
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

# Firewall configuration
variable "management_network" {
  description = "CIDR of management network for SSH/Web access"
  type        = string
  default     = "192.168.1.0/24"
}

variable "splunk_network" {
  description = "Comma-separated list of Splunk node IPs for cluster communication"
  type        = string
  default     = "192.168.1.100,192.168.1.101,192.168.1.205"
}
