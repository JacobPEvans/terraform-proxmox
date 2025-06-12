output "pool_ids" {
  description = "Map of created pool IDs"
  value       = { for k, v in proxmox_virtual_environment_pool.pools : k => v.pool_id }
}

output "pools" {
  description = "Created pools information"
  value = { for k, v in proxmox_virtual_environment_pool.pools : k => {
    id      = v.pool_id
    comment = v.comment
  } }
}
