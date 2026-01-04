output "vm_id" {
  description = "The VM ID of the Splunk VM"
  value       = proxmox_virtual_environment_vm.splunk_vm.vm_id
}

output "name" {
  description = "The name of the Splunk VM"
  value       = proxmox_virtual_environment_vm.splunk_vm.name
}

output "ip_address" {
  description = "The IPv4 address of the Splunk VM"
  value       = length(proxmox_virtual_environment_vm.splunk_vm.ipv4_addresses) > 0 ? proxmox_virtual_environment_vm.splunk_vm.ipv4_addresses[0] : null
}

output "mac_address" {
  description = "The MAC address of the Splunk VM network interface"
  value       = length(proxmox_virtual_environment_vm.splunk_vm.mac_addresses) > 0 ? proxmox_virtual_environment_vm.splunk_vm.mac_addresses[0] : null
}
