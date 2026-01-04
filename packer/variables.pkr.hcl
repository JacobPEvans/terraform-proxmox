variable "proxmox_url" {
  type        = string
  description = "Proxmox API URL"
  default     = env("PROXMOX_VE_ENDPOINT")
}

variable "proxmox_username" {
  type        = string
  description = "Proxmox API username"
  default     = env("PROXMOX_VE_USERNAME")
}

variable "proxmox_password" {
  type        = string
  description = "Proxmox API password"
  sensitive   = true
  default     = env("PROXMOX_VE_PASSWORD")
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name"
  default     = "pve"
}

variable "packer_ssh_password" {
  type        = string
  description = "SSH password for Packer provisioning (matches base template cloud-init)"
  sensitive   = true
  default     = env("PACKER_SSH_PASSWORD")
}

variable "splunk_admin_password" {
  type        = string
  description = "Splunk admin user password"
  sensitive   = true
  default     = env("SPLUNK_ADMIN_PASSWORD")
}
