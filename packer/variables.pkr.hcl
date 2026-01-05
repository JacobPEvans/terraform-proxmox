# Packer variables for Splunk template build
# Uses PROXMOX_VE_* environment variables (same as BPG Terraform provider)

variable "proxmox_url" {
  type        = string
  description = "Proxmox API URL (without /api2/json)"
  default     = env("PROXMOX_VE_ENDPOINT")
}

variable "proxmox_username" {
  type        = string
  description = "Proxmox API username (e.g., terraform@pve)"
  default     = env("PROXMOX_VE_USERNAME")
}

variable "proxmox_token" {
  type        = string
  description = "Proxmox API token (format: user@realm!tokenid=secret)"
  sensitive   = true
  default     = env("PROXMOX_VE_API_TOKEN")
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name"
  default     = env("PROXMOX_VE_NODE")
}

variable "proxmox_insecure_skip_tls_verify" {
  type        = bool
  description = "Skip TLS verification for Proxmox API"
  default     = true # Most homelab setups use self-signed certs
}

# Packer-specific secrets (add to Doppler)
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

variable "splunk_download_sha512" {
  type        = string
  description = "SHA512 checksum for the Splunk Enterprise .deb package"
  default     = env("SPLUNK_DOWNLOAD_SHA512")
}
