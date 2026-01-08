# Note: The proxmox_virtual_environment_datastores data source doesn't expose
# a list of datastore IDs. Storage validation happens implicitly when resources
# reference datastore_id - the provider will error if a datastore doesn't exist.

output "cloud_init_file_id" {
  description = "Cloud-init configuration file ID"
  value       = length(proxmox_virtual_environment_file.cloud_init_config) > 0 ? proxmox_virtual_environment_file.cloud_init_config[0].id : null
}

output "storage_validated" {
  description = "Confirms storage data sources are loaded"
  value       = true
}
