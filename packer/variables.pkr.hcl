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

variable "proxmox_insecure_skip_tls_verify" {
  type        = bool
  description = "Skip TLS verification for Proxmox API. Set to true only for development/testing with self-signed certificates."
  default     = false
}

variable "splunk_version" {
  type        = string
  description = "Splunk Enterprise version to download and install"
  default     = "10.0.2"
}

variable "splunk_build" {
  type        = string
  description = "Splunk Enterprise build number"
  default     = "e2d18b4767e9"
}

variable "splunk_download_sha256" {
  type        = string
  description = "SHA256 checksum for the Splunk Enterprise .deb package"
  default     = env("SPLUNK_DOWNLOAD_SHA256")
}
