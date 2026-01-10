# ==============================================================================
# SECRET VARIABLES - Injected from Doppler as PKR_VAR_* environment variables
# ==============================================================================
# All Doppler secrets are exported as PKR_VAR_* environment variables.
# Packer automatically reads PKR_VAR_<name> and maps to variable <name>.
#
# Required Doppler secrets:
#   PROXMOX_VE_ENDPOINT       - API endpoint URL
#   PKR_PVE_USERNAME          - Composed as: ${PROXMOX_VE_USERNAME}@pve!${PROXMOX_VE_USERNAME}
#   PROXMOX_TOKEN             - Just the secret UUID
#   PROXMOX_VE_NODE           - Node name
#   PROXMOX_VE_HOSTNAME       - Hostname for SSH
# ==============================================================================

variable "PROXMOX_VE_ENDPOINT" {
  type        = string
  description = "Proxmox API endpoint"
  sensitive   = false
}

variable "PKR_PVE_USERNAME" {
  type        = string
  description = "Proxmox username with token ID in format user@realm!tokenid"
  sensitive   = false
}

variable "PROXMOX_TOKEN" {
  type        = string
  description = "Proxmox API token secret"
  sensitive   = true
}

variable "PROXMOX_VE_NODE" {
  type        = string
  description = "Proxmox node name"
  sensitive   = false
}

variable "PROXMOX_VE_INSECURE" {
  type        = string
  description = "Skip TLS verification"
  default     = "false"
  sensitive   = false
}

variable "SPLUNK_ADMIN_PASSWORD" {
  type        = string
  description = "Splunk admin password"
  sensitive   = true
}

variable "SPLUNK_DOWNLOAD_SHA512" {
  type        = string
  description = "SHA512 checksum for Splunk package"
  sensitive   = false
}

variable "PROXMOX_VE_HOSTNAME" {
  type        = string
  description = "Hostname for Packer SSH connection"
  sensitive   = false
}

variable "PROXMOX_VM_SSH_PASSWORD" {
  type        = string
  description = "SSH password for Packer connection"
  sensitive   = true
}

# URL construction (concatenation is OK)
locals {
  proxmox_url = "${var.PROXMOX_VE_ENDPOINT}/api2/json"
}

# ==============================================================================
# NON-SECRET VARIABLES - Defined in variables.pkrvars.hcl (committed to git)
# ==============================================================================

variable "SPLUNK_VERSION" {
  type        = string
  description = "Splunk Enterprise version (e.g., 10.0.2)"
}

variable "SPLUNK_BUILD" {
  type        = string
  description = "Splunk build hash (e.g., e2d18b4767e9)"
}

variable "SPLUNK_ARCHITECTURE" {
  type        = string
  description = "CPU architecture for Splunk package (amd64, arm64)"
}

variable "SPLUNK_USER" {
  type        = string
  description = "User account that owns Splunk files and runs Splunk service"
}

variable "SPLUNK_GROUP" {
  type        = string
  description = "Group that owns Splunk files"
}

variable "SPLUNK_HOME" {
  type        = string
  description = "Splunk installation directory (SPLUNK_HOME)"
}
