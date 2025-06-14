# Security outputs
output "vm_password" {
  description = "Generated password for VMs and containers"
  value       = module.security.vm_password
  sensitive   = true
}

output "vm_private_key" {
  description = "Private SSH key for VMs and containers"
  value       = module.security.vm_private_key
  sensitive   = true
}

output "vm_public_key" {
  description = "Public SSH key for VMs and containers"
  value       = module.security.vm_public_key
}

# Pool outputs
output "pools" {
  description = "Created resource pools"
  value       = module.pools.pools
}

# Storage outputs
output "datastores" {
  description = "Created datastores"
  value       = module.storage.datastores
}

output "cloud_init_file_id" {
  description = "Cloud-init configuration file ID"
  value       = module.storage.cloud_init_file_id
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
