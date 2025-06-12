
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

variable "proxmox_ct_template_ubuntu" {
  description = "The name of the Ubuntu container template to use for the VM"
  type        = string
  default     = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}

variable "proxmox_iso_ubuntu" {
  description = "The name of the Ubuntu ISO file to use for the VM"
  type        = string
  default     = "ubuntu-24.04.1-live-server-amd64.iso"
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
