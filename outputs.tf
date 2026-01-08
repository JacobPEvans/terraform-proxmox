# SSH key outputs
output "vm_ssh_public_key" {
  description = "SSH public key used for VMs and containers"
  value       = trimspace(data.local_file.vm_ssh_public_key.content)
}

output "vm_ssh_key_file" {
  description = "Path to the SSH public key file"
  value       = data.local_file.vm_ssh_public_key.filename
}

# Pool outputs
output "pools" {
  description = "Created resource pools"
  value       = module.pools.pools
}

# Storage outputs
output "cloud_init_file_id" {
  description = "Cloud-init configuration file ID"
  value       = module.storage.cloud_init_file_id
}

output "storage_validated" {
  description = "Confirms storage data sources are loaded"
  value       = module.storage.storage_validated
}

# VM outputs
output "vms" {
  description = "Created VMs information"
  value       = module.vms.vm_details
}

output "vm_network_info" {
  description = "VM network interface information"
  value       = module.vms.vm_network_interfaces
}

# Container outputs (when enabled)
output "containers" {
  description = "Created containers information"
  value       = length(var.containers) > 0 ? module.containers[0].container_details : {}
}

output "container_network_info" {
  description = "Container network interface information"
  value       = length(var.containers) > 0 ? module.containers[0].container_network_interfaces : {}
}
