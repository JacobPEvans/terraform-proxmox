# Tests for ansible_inventory output contract
#
# Validates the structure of the ansible_inventory output that downstream
# Ansible repos (ansible-proxmox-apps, ansible-splunk) depend on.
# Any breaking change to this output structure will break downstream inventory loading.
#
# All runs use mock providers (no real infrastructure needed).

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
    name        = "splunk-aio"
    ip_address  = "192.168.0.200"
    mac_address = "BC:24:11:00:00:C8"
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
  network_prefix    = "192.168.0"
  network_cidr_mask = "/24"
  splunk_vm_id      = 200
}

# --- constants structure tests ---

run "ansible_inventory_constants_exists" {
  command = plan

  assert {
    condition     = output.ansible_inventory.constants != null
    error_message = "ansible_inventory must contain 'constants' key"
  }
}

run "ansible_inventory_constants_service_ports_exists" {
  command = plan

  assert {
    condition     = output.ansible_inventory.constants.service_ports != null
    error_message = "ansible_inventory.constants must contain 'service_ports' key"
  }
}

run "ansible_inventory_constants_syslog_ports_exists" {
  command = plan

  assert {
    condition     = output.ansible_inventory.constants.syslog_ports != null
    error_message = "ansible_inventory.constants must contain 'syslog_ports' key"
  }
}

run "ansible_inventory_constants_netflow_ports_exists" {
  command = plan

  assert {
    condition     = output.ansible_inventory.constants.netflow_ports != null
    error_message = "ansible_inventory.constants must contain 'netflow_ports' key"
  }
}

run "ansible_inventory_constants_notification_ports_exists" {
  command = plan

  assert {
    condition     = output.ansible_inventory.constants.notification_ports != null
    error_message = "ansible_inventory.constants must contain 'notification_ports' key"
  }
}

# --- key port value tests ---

run "ansible_inventory_splunk_hec_port_value" {
  command = plan

  assert {
    condition     = output.ansible_inventory.constants.service_ports.splunk_hec == 8088
    error_message = "splunk_hec port must be 8088, got ${output.ansible_inventory.constants.service_ports.splunk_hec}"
  }
}

run "ansible_inventory_unifi_syslog_port_value" {
  command = plan

  assert {
    condition     = output.ansible_inventory.constants.syslog_ports.unifi == 1514
    error_message = "unifi syslog port must be 1514, got ${output.ansible_inventory.constants.syslog_ports.unifi}"
  }
}

run "ansible_inventory_unifi_netflow_port_value" {
  command = plan

  assert {
    condition     = output.ansible_inventory.constants.netflow_ports.unifi == 2055
    error_message = "unifi netflow port must be 2055, got ${output.ansible_inventory.constants.netflow_ports.unifi}"
  }
}

# --- top-level structure tests ---

run "ansible_inventory_splunk_vm_exists" {
  command = plan

  assert {
    condition     = output.ansible_inventory.splunk_vm != null
    error_message = "ansible_inventory must contain 'splunk_vm' key at root level"
  }
}

run "ansible_inventory_containers_exists" {
  command = plan

  assert {
    condition     = output.ansible_inventory.containers != null
    error_message = "ansible_inventory must contain 'containers' key at root level"
  }
}

run "ansible_inventory_docker_vms_exists" {
  command = plan

  assert {
    condition     = output.ansible_inventory.docker_vms != null
    error_message = "ansible_inventory must contain 'docker_vms' key at root level"
  }
}
