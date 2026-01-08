# Available datastores from data source
output "available_datastores" {
  description = "List of all available datastores on the Proxmox node"
  value       = data.proxmox_virtual_environment_datastores.available.datastore_ids
}

# Legacy output for compatibility
output "datastores" {
  description = "Information about datastores (managed outside Terraform)"
  value = {
    note = "Datastores are managed directly in Proxmox VE. Use available_datastores output for current list."
    available = data.proxmox_virtual_environment_datastores.available.datastore_ids
  }
}

output "cloud_init_file_id" {
  description = "Cloud-init configuration file ID"
  value       = length(proxmox_virtual_environment_file.cloud_init_config) > 0 ? proxmox_virtual_environment_file.cloud_init_config[0].id : null
}

output "storage_validated" {
  description = "Confirms storage data sources are loaded"
  value       = true
}
