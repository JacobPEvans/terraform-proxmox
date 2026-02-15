terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.90.0"
    }
  }
}

# =============================================================================
# Cluster-Level Firewall (must be enabled for VM/container rules to work)
# =============================================================================

# Enable the datacenter/cluster-level firewall
# Without this, VM-level firewall rules are NOT applied
resource "proxmox_virtual_environment_cluster_firewall" "main" {
  enabled = true

  # Ebtables for layer 2 filtering (disabled - not needed for basic firewall)
  ebtables = false

  # Default policies at cluster level
  # IMPORTANT: Use ACCEPT here - VM-level policies (DROP) handle the actual filtering
  # The cluster firewall is only for enabling the firewall subsystem, not for filtering VM traffic
  input_policy  = "ACCEPT"
  output_policy = "ACCEPT"

  # Log rate limiting to prevent log flooding
  log_ratelimit {
    enabled = true
    burst   = 10
    rate    = "5/second"
  }
}

# =============================================================================
# Cluster-Level Security Groups (defined once, used by all Splunk VMs/containers)
# =============================================================================

# Security group for common internal access (SSH, ICMP)
resource "proxmox_virtual_environment_cluster_firewall_security_group" "internal_access" {
  name    = "internal-access"
  comment = "Allow SSH and ICMP from internal RFC1918 networks"

  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "tcp"
      dport   = "22"
      source  = rule.value
      comment = "SSH from ${rule.value}"
    }
  }

  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "icmp"
      source  = rule.value
      comment = "ICMP from ${rule.value}"
    }
  }
}

# Security group for Splunk services accessible from internal networks
resource "proxmox_virtual_environment_cluster_firewall_security_group" "splunk_services" {
  name    = "splunk-services"
  comment = "Splunk ports accessible from internal RFC1918 networks"

  # Web UI, HEC, Forwarding - all TCP from internal networks
  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "tcp"
      dport   = "8000"
      source  = rule.value
      comment = "Splunk Web UI from ${rule.value}"
    }
  }

  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "tcp"
      dport   = "8088"
      source  = rule.value
      comment = "Splunk HEC from ${rule.value}"
    }
  }

  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "tcp"
      dport   = "9997"
      source  = rule.value
      comment = "Splunk Forwarding from ${rule.value}"
    }
  }
}

# Security group for syslog ingestion
# Includes standard syslog (514) and per-source pipeline ports (1514-1518)
resource "proxmox_virtual_environment_cluster_firewall_security_group" "syslog" {
  name    = "syslog"
  comment = "Syslog ports: 514 (standard) and 1514-1518 (pipeline per-source) from internal networks"

  # Standard syslog port 514
  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "udp"
      dport   = "514"
      source  = rule.value
      comment = "Syslog UDP from ${rule.value}"
    }
  }

  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "tcp"
      dport   = "514"
      source  = rule.value
      comment = "Syslog TCP from ${rule.value}"
    }
  }

  # Pipeline per-source syslog ports 1514-1518
  # 1514=UniFi, 1515=Palo Alto, 1516=Cisco ASA, 1517=Linux, 1518=Windows
  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "udp"
      dport   = "1514:1518"
      source  = rule.value
      comment = "Pipeline syslog UDP from ${rule.value}"
    }
  }

  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "tcp"
      dport   = "1514:1518"
      source  = rule.value
      comment = "Pipeline syslog TCP from ${rule.value}"
    }
  }
}

# Security group for NetFlow/IPFIX ingestion
resource "proxmox_virtual_environment_cluster_firewall_security_group" "netflow" {
  name    = "netflow"
  comment = "NetFlow/IPFIX UDP port 2055 from internal networks"

  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "in"
      action  = "ACCEPT"
      proto   = "udp"
      dport   = "2055"
      source  = rule.value
      comment = "NetFlow UDP from ${rule.value}"
    }
  }
}

# Security group for Splunk cluster communication (internal only)
resource "proxmox_virtual_environment_cluster_firewall_security_group" "splunk_cluster" {
  name    = "splunk-cluster"
  comment = "Splunk cluster ports (management, replication, clustering)"

  # Management port 8089
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "8089"
    source  = var.splunk_network
    comment = "Splunk management from cluster"
  }

  # Replication port 8080
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "8080"
    source  = var.splunk_network
    comment = "Splunk replication from cluster"
  }

  # Clustering port 9887
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "9887"
    source  = var.splunk_network
    comment = "Splunk clustering from cluster"
  }
}

# Security group for outbound to internal networks only
resource "proxmox_virtual_environment_cluster_firewall_security_group" "outbound_internal" {
  name    = "outbound-internal"
  comment = "Allow outbound to RFC1918 only (blocks internet)"

  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "out"
      action  = "ACCEPT"
      proto   = "tcp"
      dest    = rule.value
      comment = "Outbound TCP to ${rule.value}"
    }
  }

  dynamic "rule" {
    for_each = var.internal_networks
    content {
      type    = "out"
      action  = "ACCEPT"
      proto   = "icmp"
      dest    = rule.value
      comment = "Outbound ICMP to ${rule.value}"
    }
  }

  # Splunk cluster outbound
  rule {
    type    = "out"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "8089"
    dest    = var.splunk_network
    comment = "Outbound Splunk management"
  }

  rule {
    type    = "out"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "8080"
    dest    = var.splunk_network
    comment = "Outbound Splunk replication"
  }

  rule {
    type    = "out"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "9887"
    dest    = var.splunk_network
    comment = "Outbound Splunk clustering"
  }
}

# =============================================================================
# VM Firewall Configuration
# =============================================================================

resource "proxmox_virtual_environment_firewall_options" "splunk_vm" {
  for_each = var.splunk_vm_ids

  node_name     = var.node_name
  vm_id         = each.value
  enabled       = true
  input_policy  = "DROP"
  output_policy = "DROP"
  log_level_in  = "warning"
  log_level_out = "warning"

  depends_on = [proxmox_virtual_environment_cluster_firewall.main]
}

resource "proxmox_virtual_environment_firewall_rules" "splunk_vm" {
  for_each = var.splunk_vm_ids

  node_name = var.node_name
  vm_id     = each.value

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.internal_access.name
    comment        = "Internal access (SSH, ICMP)"
  }

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.splunk_services.name
    comment        = "Splunk services (Web, HEC, Forwarding)"
  }

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.syslog.name
    comment        = "Syslog ingestion"
  }

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.splunk_cluster.name
    comment        = "Splunk cluster communication"
  }

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.outbound_internal.name
    comment        = "Outbound to internal only"
  }

  depends_on = [proxmox_virtual_environment_firewall_options.splunk_vm]
}

# =============================================================================
# Container Firewall Configuration
# =============================================================================

resource "proxmox_virtual_environment_firewall_options" "splunk_container" {
  for_each = var.splunk_container_ids

  node_name     = var.node_name
  container_id  = each.value
  enabled       = true
  input_policy  = "DROP"
  output_policy = "DROP"
  log_level_in  = "warning"
  log_level_out = "warning"

  depends_on = [proxmox_virtual_environment_cluster_firewall.main]
}

resource "proxmox_virtual_environment_firewall_rules" "splunk_container" {
  for_each = var.splunk_container_ids

  node_name    = var.node_name
  container_id = each.value

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.internal_access.name
    comment        = "Internal access (SSH, ICMP)"
  }

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.splunk_services.name
    comment        = "Splunk services (Web, HEC, Forwarding)"
  }

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.syslog.name
    comment        = "Syslog ingestion"
  }

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.splunk_cluster.name
    comment        = "Splunk cluster communication"
  }

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.outbound_internal.name
    comment        = "Outbound to internal only"
  }

  depends_on = [proxmox_virtual_environment_firewall_options.splunk_container]
}

# =============================================================================
# Pipeline Container Firewall Configuration (HAProxy, Cribl Edge)
# These containers receive syslog and NetFlow data from network devices
# =============================================================================

resource "proxmox_virtual_environment_firewall_options" "pipeline_container" {
  for_each = var.pipeline_container_ids

  node_name     = var.node_name
  container_id  = each.value
  enabled       = true
  input_policy  = "DROP"
  output_policy = "DROP"
  log_level_in  = "warning"
  log_level_out = "warning"

  depends_on = [proxmox_virtual_environment_cluster_firewall.main]
}

resource "proxmox_virtual_environment_firewall_rules" "pipeline_container" {
  for_each = var.pipeline_container_ids

  node_name    = var.node_name
  container_id = each.value

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.internal_access.name
    comment        = "Internal access (SSH, ICMP)"
  }

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.syslog.name
    comment        = "Syslog ingestion"
  }

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.netflow.name
    comment        = "NetFlow/IPFIX ingestion"
  }

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.outbound_internal.name
    comment        = "Outbound to internal only"
  }

  depends_on = [proxmox_virtual_environment_firewall_options.pipeline_container]
}
