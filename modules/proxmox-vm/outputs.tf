output "vm_ids" {
  description = "Map of VM names to their IDs"
  value       = { for k, v in proxmox_virtual_environment_vm.vms : k => v.vm_id }
}

output "vm_names" {
  description = "Map of VM keys to their names"
  value       = { for k, v in proxmox_virtual_environment_vm.vms : k => v.name }
}

output "vm_details" {
  description = "Complete VM information"
  value = { for k, v in proxmox_virtual_environment_vm.vms : k => {
    id          = v.vm_id
    name        = v.name
    node_name   = v.node_name
    description = v.description
    tags        = v.tags
    pool_id     = v.pool_id
  } }
}

output "vm_network_interfaces" {
  description = "VM network interface information"
  value = { for k, v in proxmox_virtual_environment_vm.vms : k => {
    ipv4_addresses          = v.ipv4_addresses
    ipv6_addresses          = v.ipv6_addresses
    mac_addresses           = v.mac_addresses
    network_interface_names = v.network_interface_names
  } }
}
