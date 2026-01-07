# Proxmox connection (from Doppler PROXMOX_VE_* env vars)
variable "proxmox_endpoint" {
  type    = string
  default = env("PROXMOX_VE_ENDPOINT")
}

variable "proxmox_api_token_raw" {
  type      = string
  sensitive = true
  default   = env("PROXMOX_VE_API_TOKEN")
}

variable "proxmox_node" {
  type    = string
  default = env("PROXMOX_VE_NODE")
}

# Parse BPG token format (user@realm!tokenid=secret) for Packer
locals {
  proxmox_url        = "${var.proxmox_endpoint}/api2/json"
  token_parts        = split("!", var.proxmox_api_token_raw)
  token_id_parts     = split("=", local.token_parts[1])
  proxmox_username   = local.token_parts[0]
  proxmox_token      = local.token_id_parts[1]
  proxmox_insecure   = env("PROXMOX_VE_INSECURE") == "true" ? true : false
}

# Splunk install (from Doppler)
variable "splunk_admin_password" {
  type      = string
  sensitive = true
  default   = env("SPLUNK_ADMIN_PASSWORD")
}

variable "splunk_version" {
  type    = string
  default = "10.0.2"
}

variable "splunk_build" {
  type    = string
  default = "e2d18b4767e9"
}

variable "splunk_download_sha512" {
  type    = string
  default = env("SPLUNK_DOWNLOAD_SHA512")
}

# Network configuration for Packer builder
# Read from environment to avoid committing real IPs to the repository
variable "packer_ssh_host" {
  type        = string
  default     = env("PACKER_SSH_HOST")
  description = "IP address for Packer SSH connection during build"
}

variable "packer_ip_address" {
  type        = string
  default     = env("PACKER_IP_ADDRESS")
  description = "IP address for VM with CIDR (e.g., 192.168.1.250/24)"
}

variable "packer_gateway" {
  type        = string
  default     = env("PACKER_GATEWAY")
  description = "Network gateway (e.g., 192.168.1.1)"
}
