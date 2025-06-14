output "container_ids" {
  description = "Map of container names to their IDs"
  value       = { for k, v in proxmox_virtual_environment_container.containers : k => v.vm_id }
}

output "container_details" {
  description = "Complete container information"
  value = { for k, v in proxmox_virtual_environment_container.containers : k => {
    id          = v.vm_id
    node_name   = v.node_name
    description = v.description
    tags        = v.tags
    pool_id     = v.pool_id
  } }
}

output "container_network_interfaces" {
  description = "Container network interface information"
  value = { for k, v in proxmox_virtual_environment_container.containers : k => {
    ipv4_addresses          = v.ipv4_addresses
    ipv6_addresses          = v.ipv6_addresses
    mac_addresses           = v.mac_addresses
    network_interface_names = v.network_interface_names
  } }
}
