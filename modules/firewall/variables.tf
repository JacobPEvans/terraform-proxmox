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
  default     = "192.168.1.199,192.168.1.200"
}

variable "internal_networks" {
  description = "RFC1918 networks allowed to access Splunk (SSH, Web UI, forwarding port 9997)"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}
