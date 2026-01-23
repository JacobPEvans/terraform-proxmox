output "cluster_firewall_enabled" {
  description = "Whether the cluster-level firewall is enabled"
  value       = proxmox_virtual_environment_cluster_firewall.main.enabled
}

output "vm_firewall_enabled" {
  description = "Map of VM IDs with firewall enabled"
  value       = { for k, v in proxmox_virtual_environment_firewall_options.splunk_vm : k => v.enabled }
}

output "container_firewall_enabled" {
  description = "Map of container IDs with firewall enabled"
  value       = { for k, v in proxmox_virtual_environment_firewall_options.splunk_container : k => v.enabled }
}

output "pipeline_container_firewall_enabled" {
  description = "Map of pipeline container IDs with firewall enabled (HAProxy, Cribl Edge)"
  value       = { for k, v in proxmox_virtual_environment_firewall_options.pipeline_container : k => v.enabled }
}
