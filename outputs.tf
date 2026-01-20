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

# NOTE: Route53 DNS outputs are now in aws-infra/outputs.tf

# ACME Certificate outputs
output "acme_certificates" {
  description = "ACME certificates information"
  value       = try(module.acme_certificates[0].certificates, {})
}

output "acme_accounts" {
  description = "ACME accounts information"
  value       = try(module.acme_certificates[0].acme_accounts, {})
}

output "acme_dns_plugins" {
  description = "DNS plugins for ACME validation"
  value       = try(module.acme_certificates[0].dns_plugins, {})
  sensitive   = true
}

# Ansible Inventory Output - Single Source of Truth
# This output structures all infrastructure data for dynamic Ansible inventory
# generation, eliminating hardcoded VM IDs and IPs from Ansible configuration.
output "ansible_inventory" {
  description = "Structured inventory for Ansible consumption - includes all VMs, containers, and Splunk infrastructure"
  value = {
    # LXC Containers - using proxmox_pct_remote connection
    containers = {
      for k, v in (length(var.containers) > 0 ? module.containers[0].container_details : {}) : k => {
        vmid     = v.id
        hostname = var.containers[k].hostname
        ip       = split("/", local.derive_ip[v.id])[0] # IP derived from vm_id: network_prefix.vm_id/mask; strip CIDR for Ansible
        node     = v.node_name
        # Connection settings for proxmox_pct_remote (community.general)
        ansible_connection = "community.general.proxmox_pct_remote"
        ansible_pct_vmid  = v.id
        tags              = v.tags
        pool_id           = v.pool_id
      }
    }
    # Regular VMs - using SSH connection
    vms = {
      for k, v in module.vms.vm_details : k => {
        vmid     = v.id
        hostname = v.name
        # Extract first IPv4 address from vm_network_interfaces (skip loopback at index 0)
        ip = length(module.vms.vm_network_interfaces[k].ipv4_addresses) > 1 ? (
          length(module.vms.vm_network_interfaces[k].ipv4_addresses[1]) > 0 ?
          split("/", module.vms.vm_network_interfaces[k].ipv4_addresses[1][0])[0] : null
        ) : null
        node                = v.node_name
        ansible_connection  = "ssh"
        tags                = v.tags
        pool_id             = v.pool_id
      }
    }
    # Splunk VM - dedicated Docker host with SSH connection
    splunk_vm = {
      splunk = {
        vmid     = module.splunk_vm.vm_id
        hostname = module.splunk_vm.name
        ip       = module.splunk_vm.ip_address
        node     = var.proxmox_node
        ansible_connection = "ssh"
      }
    }
  }
}
