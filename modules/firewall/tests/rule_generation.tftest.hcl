# Tests for firewall module rule generation
#
# Verifies the DRY source-joining approach: one rule per protocol/port combo,
# using comma-joined CIDRs as source, instead of one rule per network.
# Rule count must be independent of internal_networks list length.

mock_provider "proxmox" {}

variables {
  node_name          = "pve"
  management_network = "192.168.0.0/24"
  splunk_network     = "192.168.0.200"
}

# --- internal_src joining ---

run "single_network_no_comma_in_src" {
  command = plan

  variables {
    internal_networks = ["10.0.0.0/8"]
  }

  assert {
    condition     = local.internal_src == "10.0.0.0/8"
    error_message = "Single network should be the source as-is, got '${local.internal_src}'"
  }
}

run "three_networks_comma_joined_src" {
  command = plan

  variables {
    internal_networks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  assert {
    condition     = local.internal_src == "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
    error_message = "Three networks must be comma-joined, got '${local.internal_src}'"
  }
}

# --- Rule counts independent of network count ---

run "syslog_rules_always_four" {
  command = plan

  variables {
    internal_networks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  # UDP 514, TCP 514, UDP 1514:1518, TCP 1514:1518
  assert {
    condition     = length(local.syslog_rules) == 4
    error_message = "syslog_rules must be exactly 4 (2 protocols × 2 port groups), got ${length(local.syslog_rules)}"
  }
}

run "pipeline_services_rules_always_two" {
  command = plan

  variables {
    internal_networks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  # HAProxy stats (8404) + Cribl Edge API (9000)
  assert {
    condition     = length(local.pipeline_services_rules) == 2
    error_message = "pipeline_services_rules must be exactly 2, got ${length(local.pipeline_services_rules)}"
  }
}

run "netflow_rules_always_one" {
  command = plan

  variables {
    internal_networks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  assert {
    condition     = length(local.netflow_rules) == 1
    error_message = "netflow_rules must be exactly 1 (UDP 2055), got ${length(local.netflow_rules)}"
  }
}

run "outbound_rules_always_three" {
  command = plan

  variables {
    internal_networks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  # TCP + UDP + ICMP outbound
  assert {
    condition     = length(local.outbound_internal_rules) == 3
    error_message = "outbound_internal_rules must be exactly 3 (TCP, UDP, ICMP), got ${length(local.outbound_internal_rules)}"
  }
}

run "cribl_stream_rules_always_one" {
  command = plan

  variables {
    internal_networks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  assert {
    condition     = length(local.cribl_stream_services_rules) == 1
    error_message = "cribl_stream_services_rules must be exactly 1 (TCP 9100), got ${length(local.cribl_stream_services_rules)}"
  }
}

run "syslog_rules_source_matches_joined_networks" {
  command = plan

  variables {
    internal_networks = ["10.0.0.0/8", "192.168.0.0/16"]
  }

  assert {
    condition     = local.syslog_rules[0].source == "10.0.0.0/8,192.168.0.0/16"
    error_message = "syslog_rules source must be comma-joined networks, got '${local.syslog_rules[0].source}'"
  }
}
