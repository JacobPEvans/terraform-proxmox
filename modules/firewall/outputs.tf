output "vm_firewall_enabled" {
  description = "Map of VM IDs with firewall enabled"
  value       = { for k, v in proxmox_virtual_environment_firewall_options.splunk_vm : k => v.enabled }
}

output "container_firewall_enabled" {
  description = "Map of container IDs with firewall enabled"
  value       = { for k, v in proxmox_virtual_environment_firewall_options.splunk_container : k => v.enabled }
}
