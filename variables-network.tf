# Network variables: bridge, addressing, and firewall network ranges

variable "bridge" {
  description = "Network bridge for Splunk VM network interface"
  type        = string
  default     = "vmbr0"
  validation {
    condition     = length(var.bridge) > 0
    error_message = "Bridge name cannot be empty."
  }
}

variable "network_prefix" {
  description = "Network prefix for IP address derivation (e.g., '192.168.0' - IPs derived as prefix.vm_id)"
  type        = string
  default     = "192.168.0"
  validation {
    condition     = can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.network_prefix))
    error_message = "Network prefix must be in format 'x.x.x' where each octet is 0-255 (e.g., '192.168.0')."
  }
}

variable "network_cidr_mask" {
  description = "CIDR mask for network IPs (use /24 for standard LAN, /32 only for point-to-point)"
  type        = string
  default     = "/24"
}

# Firewall configuration
variable "internal_networks" {
  description = "RFC1918 networks allowed to access Splunk (SSH, Web UI, forwarding port 9997). Configure in terraform.tfvars for your actual networks."
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

  validation {
    condition = alltrue([
      for net in var.internal_networks :
      can(cidrnetmask(net))
    ])
    error_message = "Each internal_networks entry must be a valid CIDR block, for example 10.0.0.0/8."
  }
}
