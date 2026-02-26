# Tests for variables.tf - input validation rules
#
# Uses expect_failures to verify validation blocks reject bad input.
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

# Shared valid defaults for all runs
variables {
  network_prefix    = "192.168.0"
  network_cidr_mask = "/24"
  splunk_vm_id      = 200
}

# --- Positive test: valid inputs pass ---

run "valid_inputs_pass" {
  command = plan
}

# --- Negative tests: invalid inputs rejected ---

run "invalid_network_prefix_rejected" {
  command = plan

  variables {
    network_prefix = "999.999.999"
  }

  expect_failures = [
    var.network_prefix,
  ]
}

run "splunk_vm_id_out_of_range_rejected" {
  command = plan

  variables {
    splunk_vm_id = 99999
  }

  expect_failures = [
    var.splunk_vm_id,
  ]
}

run "invalid_internal_networks_cidr_rejected" {
  command = plan

  variables {
    internal_networks = ["not-a-cidr"]
  }

  expect_failures = [
    var.internal_networks,
  ]
}

run "vm_with_invalid_vga_type_rejected" {
  command = plan

  variables {
    vms = {
      test = {
        vm_id    = 100
        name     = "test-vm"
        vga_type = "invalid-vga"
      }
    }
  }

  expect_failures = [
    var.vms,
  ]
}

run "vm_with_id_below_minimum_rejected" {
  command = plan

  variables {
    vms = {
      test = {
        vm_id = 1
        name  = "test-vm"
      }
    }
  }

  expect_failures = [
    var.vms,
  ]
}

run "container_with_id_below_minimum_rejected" {
  command = plan

  variables {
    containers = {
      test = {
        vm_id    = 1
        hostname = "test"
      }
    }
  }

  expect_failures = [
    var.containers,
  ]
}

run "container_with_excessive_cpu_rejected" {
  command = plan

  variables {
    containers = {
      test = {
        vm_id     = 100
        hostname  = "test"
        cpu_cores = 64
      }
    }
  }

  expect_failures = [
    var.containers,
  ]
}
