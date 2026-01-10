terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.90.0"
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

  node_name     = var.node_name
  container_id  = each.value
  enabled       = true
  input_policy  = "DROP"
  output_policy = "DROP"
  log_level_in  = "warning"
  log_level_out = "warning"
}

# Splunk VM Firewall Rules
resource "proxmox_virtual_environment_firewall_rules" "splunk_vm" {
  for_each = var.splunk_vm_ids

  node_name = var.node_name
  vm_id     = each.value

  # Allow SSH from all internal networks (RFC1918)
  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "tcp"
      dport   = "22"
      source  = rule.value
      comment = "Allow SSH from ${rule.value}"
      enabled = true
    }
  }

  # Allow Splunk Web UI (8000) from all internal networks
  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "tcp"
      dport   = "8000"
      source  = rule.value
      comment = "Allow Splunk Web UI from ${rule.value}"
      enabled = true
    }
  }

  # Allow Splunk Management Port (8089) from cluster nodes only
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "8089"
    source  = var.splunk_network
    comment = "Allow Splunk management from cluster"
    enabled = true
  }

  # Allow Splunk Forwarding Port (9997) from all internal networks
  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "tcp"
      dport   = "9997"
      source  = rule.value
      comment = "Allow Splunk forwarding from ${rule.value}"
      enabled = true
    }
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

  # OUTBOUND: Allow Splunk Management (8089) to cluster network
  rule {
    type    = "out"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "8089"
    dest    = var.splunk_network
    comment = "Allow outbound Splunk management to cluster"
    enabled = true
  }

  # OUTBOUND: Allow Splunk Replication (8080) to cluster network
  rule {
    type    = "out"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "8080"
    dest    = var.splunk_network
    comment = "Allow outbound Splunk replication to cluster"
    enabled = true
  }

  # OUTBOUND: Allow Splunk Clustering (9887) to cluster network
  rule {
    type    = "out"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "9887"
    dest    = var.splunk_network
    comment = "Allow outbound Splunk clustering to cluster"
    enabled = true
  }

  # OUTBOUND: Allow outbound TCP to internal networks for SSH, Web UI responses
  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "out"
      action  = "ACCEPT"
      proto   = "tcp"
      dest    = rule.value
      comment = "Allow outbound TCP to ${rule.value}"
      enabled = true
    }
  }

  # OUTBOUND: Allow outbound ICMP to internal networks for diagnostics (ping, traceroute)
  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "out"
      action  = "ACCEPT"
      proto   = "icmp"
      dest    = rule.value
      comment = "Allow outbound ICMP to ${rule.value} for diagnostics"
      enabled = true
    }
  }

  # INBOUND: Allow ICMP from internal networks (for ping)
  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "icmp"
      source  = rule.value
      comment = "Allow ICMP from ${rule.value}"
      enabled = true
    }
  }

  depends_on = [proxmox_virtual_environment_firewall_options.splunk_vm]
}

# Splunk Container Firewall Rules
resource "proxmox_virtual_environment_firewall_rules" "splunk_container" {
  for_each = var.splunk_container_ids

  node_name    = var.node_name
  container_id = each.value

  # Allow SSH from all internal networks (RFC1918)
  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "tcp"
      dport   = "22"
      source  = rule.value
      comment = "Allow SSH from ${rule.value}"
      enabled = true
    }
  }

  # Allow Splunk Web UI (8000) from all internal networks
  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "tcp"
      dport   = "8000"
      source  = rule.value
      comment = "Allow Splunk Web UI from ${rule.value}"
      enabled = true
    }
  }

  # Allow Splunk Management (8089) from cluster nodes only
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "8089"
    source  = var.splunk_network
    comment = "Allow Splunk management"
    enabled = true
  }

  # Allow Splunk Forwarding Port (9997) from all internal networks
  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "tcp"
      dport   = "9997"
      source  = rule.value
      comment = "Allow Splunk forwarding from ${rule.value}"
      enabled = true
    }
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

  # OUTBOUND: Allow Splunk Management (8089) to Splunk network
  rule {
    type    = "out"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "8089"
    dest    = var.splunk_network
    comment = "Allow outbound Splunk management to Splunk network"
    enabled = true
  }

  # OUTBOUND: Allow Splunk Replication (8080) to Splunk network
  rule {
    type    = "out"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "8080"
    dest    = var.splunk_network
    comment = "Allow outbound Splunk replication to Splunk network"
    enabled = true
  }

  # OUTBOUND: Allow Splunk Clustering (9887) to Splunk network
  rule {
    type    = "out"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "9887"
    dest    = var.splunk_network
    comment = "Allow outbound Splunk clustering to Splunk network"
    enabled = true
  }

  # OUTBOUND: Allow outbound TCP to internal networks for SSH, Web UI responses
  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "out"
      action  = "ACCEPT"
      proto   = "tcp"
      dest    = rule.value
      comment = "Allow outbound TCP to ${rule.value}"
      enabled = true
    }
  }

  # OUTBOUND: Allow outbound ICMP to internal networks for diagnostics (ping, traceroute)
  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "out"
      action  = "ACCEPT"
      proto   = "icmp"
      dest    = rule.value
      comment = "Allow outbound ICMP to ${rule.value} for diagnostics"
      enabled = true
    }
  }

  # INBOUND: Allow ICMP from internal networks (for ping)
  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "icmp"
      source  = rule.value
      comment = "Allow ICMP from ${rule.value}"
      enabled = true
    }
  }

  depends_on = [proxmox_virtual_environment_firewall_options.splunk_container]
}
