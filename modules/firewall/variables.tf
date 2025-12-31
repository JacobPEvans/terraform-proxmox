variable "node_name" {
  description = "Proxmox node name"
  type        = string
}

variable "splunk_vm_ids" {
  description = "Map of Splunk VM names to their IDs"
  type        = map(number)
  default     = {}
}

variable "splunk_container_ids" {
  description = "Map of Splunk container names to their IDs"
  type        = map(number)
  default     = {}
}

variable "management_network" {
  description = "CIDR of management network for SSH/Web access"
  type        = string
  default     = "192.168.1.0/24"
}

variable "splunk_network" {
  description = "Comma-separated list of Splunk node IPs for cluster communication"
  type        = string
  default     = "192.168.1.100,192.168.1.101,192.168.1.205"
}
