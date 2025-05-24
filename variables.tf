variable "proxmox_api_url" {
  description = "The URL of the Proxmox API"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "The API token ID for Proxmox authentication"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "The API token secret for Proxmox authentication"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "The name of the Proxmox node"
  type        = string
  default     = "pve"
}
