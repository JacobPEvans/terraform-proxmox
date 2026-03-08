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

# Security group rule definitions - each expands across internal_networks
# flatten() iterates rules-then-networks, preserving existing rule ordering
locals {
  internal_access_rules = flatten([
    for rule in [
      { proto = "tcp", dport = "22", label = "SSH" },
      { proto = "icmp", dport = null, label = "ICMP" },
      ] : [
      for net in var.internal_networks : {
        proto   = rule.proto
        dport   = rule.dport
        source  = net
        comment = "${rule.label} from ${net}"
      }
    ]
  ])

  splunk_services_rules = flatten([
    for rule in [
      { proto = "tcp", dport = "8000", label = "Splunk Web UI" },
      { proto = "tcp", dport = "8088", label = "Splunk HEC" },
      { proto = "tcp", dport = "9997", label = "Splunk Forwarding" },
      ] : [
      for net in var.internal_networks : {
        proto   = rule.proto
        dport   = rule.dport
        source  = net
        comment = "${rule.label} from ${net}"
      }
    ]
  ])

  syslog_rules = flatten([
    for rule in [
      { proto = "udp", dport = "514", label = "Syslog UDP" },
      { proto = "tcp", dport = "514", label = "Syslog TCP" },
      { proto = "udp", dport = "1514:1518", label = "Pipeline syslog UDP" },
      { proto = "tcp", dport = "1514:1518", label = "Pipeline syslog TCP" },
      ] : [
      for net in var.internal_networks : {
        proto   = rule.proto
        dport   = rule.dport
        source  = net
        comment = "${rule.label} from ${net}"
      }
    ]
  ])

  pipeline_services_rules = flatten([
    for rule in [
      { proto = "tcp", dport = "8404", label = "HAProxy stats" },
      { proto = "tcp", dport = "9000", label = "Cribl Edge API" },
      ] : [
      for net in var.internal_networks : {
        proto   = rule.proto
        dport   = rule.dport
        source  = net
        comment = "${rule.label} from ${net}"
      }
    ]
  ])

  netflow_rules = flatten([
    for rule in [
      { proto = "udp", dport = "2055", label = "NetFlow UDP" },
      ] : [
      for net in var.internal_networks : {
        proto   = rule.proto
        dport   = rule.dport
        source  = net
        comment = "${rule.label} from ${net}"
      }
    ]
  ])

  notification_services_rules = flatten([
    for rule in [
      { proto = "tcp", dport = "1025", label = "Mailpit SMTP" },
      { proto = "tcp", dport = "8025", label = "Mailpit Web UI" },
      { proto = "tcp", dport = "8080", label = "ntfy HTTP" },
      ] : [
      for net in var.internal_networks : {
        proto   = rule.proto
        dport   = rule.dport
        source  = net
        comment = "${rule.label} from ${net}"
      }
    ]
  ])

  vectordb_services_rules = flatten([
    for rule in [
      { proto = "tcp", dport = "6333", label = "Qdrant HTTP API" },
      { proto = "tcp", dport = "6334", label = "Qdrant gRPC" },
      ] : [
      for net in var.internal_networks : {
        proto   = rule.proto
        dport   = rule.dport
        source  = net
        comment = "${rule.label} from ${net}"
      }
    ]
  ])

  # Outbound rules - dynamic portion only (static Splunk rules stay inline)
  outbound_internal_rules = flatten([
    for rule in [
      { proto = "tcp", label = "Outbound TCP" },
      { proto = "udp", label = "Outbound UDP" },
      { proto = "icmp", label = "Outbound ICMP" },
      ] : [
      for net in var.internal_networks : {
        proto   = rule.proto
        dest    = net
        comment = "${rule.label} to ${net}"
      }
    ]
  ])
}
