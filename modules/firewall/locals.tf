# =============================================================================
# Rule Data & Firewall Defaults
# =============================================================================

# Firewall defaults shared across all VM/container options resources
locals {
  firewall_defaults = {
    enabled       = true
    input_policy  = "DROP"
    output_policy = "DROP"
    log_level_in  = "warning"
    log_level_out = "warning"
  }
}

# Security group rule definitions - use comma-joined source/dest for multi-network rules
# Proxmox natively supports comma-separated CIDRs in source/dest fields,
# so we generate one rule per protocol/port rather than one per network.
locals {
  # Comma-separated internal networks for use in source/dest fields
  internal_src = join(",", var.internal_networks)

  internal_access_rules = [
    { proto = "tcp", dport = "22", source = local.internal_src, comment = "SSH from internal networks" },
    { proto = "icmp", dport = null, source = local.internal_src, comment = "ICMP from internal networks" },
  ]

  splunk_services_rules = [
    { proto = "tcp", dport = "8000", source = local.internal_src, comment = "Splunk Web UI from internal" },
    { proto = "tcp", dport = "8088", source = local.internal_src, comment = "Splunk HEC from internal" },
    { proto = "tcp", dport = "9997", source = local.internal_src, comment = "Splunk Forwarding from internal" },
  ]

  syslog_rules = [
    { proto = "udp", dport = "514", source = local.internal_src, comment = "Syslog UDP from internal" },
    { proto = "tcp", dport = "514", source = local.internal_src, comment = "Syslog TCP from internal" },
    { proto = "udp", dport = "1514:1518", source = local.internal_src, comment = "Pipeline syslog UDP from internal" },
    { proto = "tcp", dport = "1514:1518", source = local.internal_src, comment = "Pipeline syslog TCP from internal" },
  ]

  pipeline_services_rules = [
    { proto = "tcp", dport = "8404", source = local.internal_src, comment = "HAProxy stats from internal" },
    { proto = "tcp", dport = "9000", source = local.internal_src, comment = "Cribl Edge API from internal" },
  ]

  netflow_rules = [
    { proto = "udp", dport = "2055", source = local.internal_src, comment = "NetFlow/IPFIX UDP from internal" },
  ]

  notification_services_rules = [
    { proto = "tcp", dport = "1025", source = local.internal_src, comment = "Mailpit SMTP from internal" },
    { proto = "tcp", dport = "8025", source = local.internal_src, comment = "Mailpit Web UI from internal" },
    { proto = "tcp", dport = "8080", source = local.internal_src, comment = "ntfy HTTP from internal" },
  ]

  vectordb_services_rules = [
    { proto = "tcp", dport = "6333", source = local.internal_src, comment = "Qdrant HTTP API from internal" },
    { proto = "tcp", dport = "6334", source = local.internal_src, comment = "Qdrant gRPC from internal" },
  ]

  apt_cacher_ng_services_rules = [
    { proto = "tcp", dport = "3142", source = local.internal_src, comment = "apt-cacher-ng from internal" },
  ]

  cribl_stream_services_rules = [
    { proto = "tcp", dport = "9100", source = local.internal_src, comment = "Cribl Stream API from internal" },
  ]

  # Outbound to internal RFC1918 only (blocks internet egress)
  outbound_internal_rules = [
    { proto = "tcp", dest = local.internal_src, comment = "Outbound TCP to internal" },
    { proto = "udp", dest = local.internal_src, comment = "Outbound UDP to internal" },
    { proto = "icmp", dest = local.internal_src, comment = "Outbound ICMP to internal" },
  ]
}
