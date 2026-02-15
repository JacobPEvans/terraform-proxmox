# Tests for locals.tf - IP derivation and pipeline constants
#
# All runs use mock providers (no real infrastructure needed).
# command = plan is sufficient since locals are evaluated at plan time.

mock_provider "proxmox" {
  mock_data "proxmox_virtual_environment_datastores" {
    defaults = {
      datastores = [
        { id = "local", type = "dir", content_types = ["iso", "vztmpl", "backup"] },
        { id = "local-zfs", type = "zfspool", content_types = ["images", "rootdir"] },
      ]
    }
  }
}
mock_provider "tls" {}
mock_provider "random" {}
mock_provider "local" {}
mock_provider "null" {}

# Override data sources and modules that require real provider connections
override_data {
  target = data.local_file.vm_ssh_public_key
  values = {
    content = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyData test@test"
  }
}

override_module {
  target = module.storage
  outputs = {
    cloud_init_file_id   = null
    datastores_available = {}
    storage_validated    = true
  }
}

override_module {
  target = module.splunk_vm
  outputs = {
    vm_id       = 200
    name        = "splunk-vm"
    ip_address  = null
    mac_address = null
  }
}

override_module {
  target = module.firewall
  outputs = {
    cluster_firewall_enabled            = true
    vm_firewall_enabled                 = true
    container_firewall_enabled          = true
    pipeline_container_firewall_enabled = true
  }
}

override_module {
  target = module.acme_certificates
  outputs = {
    acme_accounts = {}
    dns_plugins   = {}
    certificates  = {}
  }
}

variables {
  network_prefix     = "192.168.0"
  network_cidr_mask  = "/24"
  splunk_vm_id       = 200
  management_network = "192.168.0.0/24"
  splunk_network     = ["192.168.0.200"]
  splunk_password    = "test-password-12345"
  splunk_hec_token   = "12345678-abcd-ef01-2345-678901234567"
}

# --- derive_ip tests ---

run "derive_ip_200" {
  command = plan

  assert {
    condition     = local.derive_ip[200] == "192.168.0.200/24"
    error_message = "derive_ip[200] should be 192.168.0.200/24, got ${local.derive_ip[200]}"
  }
}

run "derive_ip_boundary_low" {
  command = plan

  assert {
    condition     = local.derive_ip[1] == "192.168.0.1/24"
    error_message = "derive_ip[1] should be 192.168.0.1/24, got ${local.derive_ip[1]}"
  }
}

run "derive_ip_boundary_high" {
  command = plan

  assert {
    condition     = local.derive_ip[999] == "192.168.0.999/24"
    error_message = "derive_ip[999] should be 192.168.0.999/24, got ${local.derive_ip[999]}"
  }
}

# --- network_gateway test ---

run "network_gateway_derivation" {
  command = plan

  assert {
    condition     = local.network_gateway == "192.168.0.1"
    error_message = "network_gateway should be 192.168.0.1, got ${local.network_gateway}"
  }
}

# --- splunk_derived_ip test ---

run "splunk_derived_ip_uses_vm_id" {
  command = plan

  assert {
    condition     = local.splunk_derived_ip == "192.168.0.200/24"
    error_message = "splunk_derived_ip should use splunk_vm_id (200), got ${local.splunk_derived_ip}"
  }
}

run "splunk_derived_ip_different_id" {
  command = plan

  variables {
    splunk_vm_id = 100
  }

  assert {
    condition     = local.splunk_derived_ip == "192.168.0.100/24"
    error_message = "splunk_derived_ip should be 192.168.0.100/24, got ${local.splunk_derived_ip}"
  }
}

# --- pipeline_constants tests ---

run "pipeline_constants_service_ports" {
  command = plan

  assert {
    condition     = local.pipeline_constants.service_ports.splunk_hec == 8088
    error_message = "splunk_hec port should be 8088"
  }

  assert {
    condition     = local.pipeline_constants.service_ports.splunk_web == 8000
    error_message = "splunk_web port should be 8000"
  }

  assert {
    condition     = local.pipeline_constants.service_ports.haproxy_stats == 8404
    error_message = "haproxy_stats port should be 8404"
  }
}

run "pipeline_constants_syslog_ports" {
  command = plan

  assert {
    condition     = local.pipeline_constants.syslog_ports.unifi == 1514
    error_message = "unifi syslog port should be 1514"
  }

  assert {
    condition     = local.pipeline_constants.syslog_ports.palo_alto == 1515
    error_message = "palo_alto syslog port should be 1515"
  }
}

# --- derive_ip with different prefix ---

run "derive_ip_custom_prefix" {
  command = plan

  variables {
    network_prefix = "10.0.1"
  }

  assert {
    condition     = local.derive_ip[100] == "10.0.1.100/24"
    error_message = "derive_ip with custom prefix should work, got ${local.derive_ip[100]}"
  }

  assert {
    condition     = local.network_gateway == "10.0.1.1"
    error_message = "network_gateway should use custom prefix, got ${local.network_gateway}"
  }
}
