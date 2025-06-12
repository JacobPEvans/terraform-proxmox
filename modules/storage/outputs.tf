output "datastores" {
  description = "Information about datastores (managed outside Terraform)"
  value = {
    note = "Datastores are managed directly in Proxmox VE. Common datastores: local, local-lvm, local-zfs"
    default_datastores = [
      "local",      # For ISO images, snippets, backups
      "local-lvm",  # For VM disks
    ]
  }
}

output "cloud_init_file_id" {
  description = "Cloud-init configuration file ID"
  value       = length(proxmox_virtual_environment_file.cloud_init_config) > 0 ? proxmox_virtual_environment_file.cloud_init_config[0].id : null
}
