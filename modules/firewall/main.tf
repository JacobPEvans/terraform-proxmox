terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.89.0"
    }
  }
}

# Splunk VM Firewall Options - Enable firewall and set default policies
resource "proxmox_virtual_environment_firewall_options" "splunk_vm" {
  for_each = var.splunk_vm_ids

  node_name     = var.node_name
  vm_id         = each.value
  enabled       = true
  input_policy  = "DROP"
  output_policy = "DROP"
  log_level_in  = "warning"
  log_level_out = "warning"
}

# Splunk Container Firewall Options
resource "proxmox_virtual_environment_firewall_options" "splunk_container" {
  for_each = var.splunk_container_ids

  node_name    = var.node_name
  container_id = each.value
  enabled      = true
  input_policy = "DROP"
  output_policy = "DROP"
  log_level_in  = "warning"
  log_level_out = "warning"
}

# Splunk VM Firewall Rules
resource "proxmox_virtual_environment_firewall_rules" "splunk_vm" {
  for_each = var.splunk_vm_ids

  node_name = var.node_name
  vm_id     = each.value

  # Allow SSH from management network
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "22"
    source  = var.management_network
    comment = "Allow SSH from management network"
    enabled = true
  }

  # Allow Splunk Web UI (8000)
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "8000"
    source  = var.management_network
    comment = "Allow Splunk Web UI"
    enabled = true
  }

  # Allow Splunk Management Port (8089)
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "8089"
    source  = var.splunk_network
    comment = "Allow Splunk management from cluster"
    enabled = true
  }

  # Allow Splunk Forwarding Port (9997)
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "9997"
    source  = var.splunk_network
    comment = "Allow Splunk forwarding from cluster"
    enabled = true
  }

  # Allow Splunk Replication (8080)
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "8080"
    source  = var.splunk_network
    comment = "Allow Splunk replication"
    enabled = true
  }

  # Allow Splunk Clustering (9887)
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "9887"
    source  = var.splunk_network
    comment = "Allow Splunk clustering"
    enabled = true
  }

  # OUTBOUND: Only allow to other Splunk nodes
  rule {
    type    = "out"
    action  = "ACCEPT"
    proto   = "tcp"
    dest    = var.splunk_network
    comment = "Allow outbound to Splunk cluster only"
    enabled = true
  }

  depends_on = [proxmox_virtual_environment_firewall_options.splunk_vm]
}

# Splunk Container Firewall Rules
resource "proxmox_virtual_environment_firewall_rules" "splunk_container" {
  for_each = var.splunk_container_ids

  node_name    = var.node_name
  container_id = each.value

  # Allow SSH
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "22"
    source  = var.management_network
    comment = "Allow SSH from management network"
    enabled = true
  }

  # Allow Splunk Web UI
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "8000"
    source  = var.management_network
    comment = "Allow Splunk Web UI"
    enabled = true
  }

  # Allow Splunk Management
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "8089"
    source  = var.splunk_network
    comment = "Allow Splunk management"
    enabled = true
  }

  # Allow Splunk Forwarding Port (9997) - for receiving logs
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "9997"
    source  = var.splunk_network
    comment = "Allow Splunk forwarding"
    enabled = true
  }

  # Allow Splunk Replication (8080)
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "8080"
    source  = var.splunk_network
    comment = "Allow Splunk replication"
    enabled = true
  }

  # Allow Splunk Clustering (9887)
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "9887"
    source  = var.splunk_network
    comment = "Allow Splunk clustering"
    enabled = true
  }

  # OUTBOUND: Only to Splunk nodes
  rule {
    type    = "out"
    action  = "ACCEPT"
    proto   = "tcp"
    dest    = var.splunk_network
    comment = "Allow outbound to Splunk cluster"
    enabled = true
  }

  depends_on = [proxmox_virtual_environment_firewall_options.splunk_container]
}
