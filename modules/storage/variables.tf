variable "node_name" {
  description = "Proxmox node name"
  type        = string
}

variable "datastores" {
  description = "Map of datastores to create"
  type = map(object({
    type    = string # "dir", "lvm", "lvmthin", "zfs", "nfs", "cifs"
    path    = optional(string)
    content = optional(list(string), ["images", "vztmpl", "iso", "backup"])
    shared  = optional(bool, false)
    nodes   = optional(list(string))
    # LVM specific
    vgname = optional(string)
    # NFS specific
    server  = optional(string)
    export  = optional(string)
    options = optional(string)
    # ZFS specific
    pool      = optional(string)
    sparse    = optional(bool)
    blocksize = optional(string)
  }))
  default = {}
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "homelab"
}
