# =============================================================================
# Node-Level (Proxmox Host) Firewall Rules
# =============================================================================

# Apply host-level rules to the Proxmox node itself (no vm_id / container_id).
# Used for services running on the Proxmox host — e.g. chrony serving NTP to
# internal VMs/containers (paired with ansible-proxmox NTP server role).
resource "proxmox_virtual_environment_firewall_rules" "node" {
  node_name = var.node_name

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.ntp_server.name
    comment        = "NTP server (chrony on Proxmox host)"
  }

  depends_on = [proxmox_virtual_environment_cluster_firewall.main]
}
