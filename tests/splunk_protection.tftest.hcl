# Tests for splunk VM protection guarantees
#
# Verifies that the splunk VM module:
#   1. Plans successfully without splunk credentials (moved to Ansible/Doppler)
#   2. Produces the expected outputs used by downstream Ansible repos
#   3. Handles non-default splunk_vm_id correctly in derived IPs

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
  network_prefix     = "192.168.0"
  network_cidr_mask  = "/24"
  splunk_vm_id       = 200
  management_network = "192.168.0.0/24"
  splunk_network     = ["192.168.0.200"]
}

# --- Test: no Splunk credentials required at Terraform level ---
# splunk_password and splunk_hec_token are consumed by Ansible directly from
# Doppler. Terraform no longer needs them. This run verifies the plan succeeds
# without any credential variables.

run "plan_succeeds_without_splunk_credentials" {
  command = plan
}

# --- Test: ansible_inventory output contains splunk_vm at root level ---
# Downstream Ansible repos load this output and access terraform_data.splunk_vm.
# Any nesting change here breaks ansible-splunk inventory loading.

run "ansible_inventory_splunk_vm_at_root" {
  command = plan

  assert {
    condition     = output.ansible_inventory.splunk_vm != null
    error_message = "ansible_inventory must contain splunk_vm at root level (not nested under another key)"
  }
}

# --- Test: splunk IP is derived from vm_id, not hardcoded ---
# Changing splunk_vm_id must produce a different IP and be reflected in
# ansible_inventory. This prevents silent misconfiguration if the VM is
# renumbered.

run "splunk_ip_derived_from_vm_id" {
  command = plan

  variables {
    splunk_vm_id   = 205
    splunk_network = ["192.168.0.205"]
  }

  assert {
    condition     = local.splunk_derived_ip == "192.168.0.205/24"
    error_message = "splunk_derived_ip must track splunk_vm_id (205), got ${local.splunk_derived_ip}"
  }
}
