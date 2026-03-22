# Storage variables: datastores, templates, ISOs, and host-level services

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

variable "datastore_id" {
  description = "Datastore ID for Splunk VM disk storage"
  type        = string
  default     = "local-zfs"
  validation {
    condition     = length(var.datastore_id) > 0
    error_message = "Datastore ID cannot be empty."
  }
}

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

variable "template_id" {
  description = "VM ID of the Packer-built Splunk Docker template to clone from (default: splunk-docker-template ID 9201)"
  type        = number
  default     = 9201
  validation {
    condition     = var.template_id > 0 && var.template_id < 10000
    error_message = "Template ID must be between 1 and 9999."
  }
}

# Host-level services (ZFS datasets, Samba, etc.) — not managed by Terraform directly,
# but documented here so ansible-proxmox can consume them via ansible_inventory output.
variable "host_services" {
  description = "Host-level services config (ZFS datasets, Samba shares) for ansible-proxmox consumption"
  type = object({
    nas = optional(object({
      zfs_dataset    = string
      zfs_quota      = string
      mount_point    = string
      smb_share_name = string
      directories    = list(string)
      description    = optional(string)
    }))
  })
  default = {}
}
