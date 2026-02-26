# Tests for tag-based container filtering locals
#
# Verifies that pipeline_container_ids and notification_container_ids
# correctly include/exclude containers based on their tags.
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
  network_prefix    = "192.168.0"
  network_cidr_mask = "/24"
  splunk_vm_id      = 200
}

# --- pipeline_container_ids tests ---

run "haproxy_tagged_container_in_pipeline_ids" {
  command = plan

  variables {
    containers = {
      "haproxy" = {
        vm_id    = 190
        hostname = "haproxy"
        tags     = ["terraform", "haproxy", "container"]
      }
    }
  }

  assert {
    condition     = contains(keys(local.pipeline_container_ids), "haproxy")
    error_message = "Container with 'haproxy' tag must be in pipeline_container_ids"
  }

  assert {
    condition     = local.pipeline_container_ids["haproxy"] == 190
    error_message = "pipeline_container_ids['haproxy'] should be vm_id 190"
  }
}

run "cribl_edge_tagged_container_in_pipeline_ids" {
  command = plan

  variables {
    containers = {
      "cribl-edge" = {
        vm_id    = 181
        hostname = "cribl-edge"
        tags     = ["terraform", "cribl", "edge", "container"]
      }
    }
  }

  assert {
    condition     = contains(keys(local.pipeline_container_ids), "cribl-edge")
    error_message = "Container with 'cribl' + 'edge' tags must be in pipeline_container_ids"
  }

  assert {
    condition     = local.pipeline_container_ids["cribl-edge"] == 181
    error_message = "pipeline_container_ids['cribl-edge'] should be vm_id 181"
  }
}

run "notifications_tagged_container_in_notification_ids" {
  command = plan

  variables {
    containers = {
      "mailpit" = {
        vm_id    = 185
        hostname = "mailpit"
        tags     = ["terraform", "notifications", "container"]
      }
    }
  }

  assert {
    condition     = contains(keys(local.notification_container_ids), "mailpit")
    error_message = "Container with 'notifications' tag must be in notification_container_ids"
  }

  assert {
    condition     = local.notification_container_ids["mailpit"] == 185
    error_message = "notification_container_ids['mailpit'] should be vm_id 185"
  }

  assert {
    condition     = !contains(keys(local.pipeline_container_ids), "mailpit")
    error_message = "Container with only 'notifications' tag must NOT be in pipeline_container_ids"
  }
}

run "database_tagged_container_in_neither_set" {
  command = plan

  variables {
    containers = {
      "postgres" = {
        vm_id    = 170
        hostname = "postgres"
        tags     = ["terraform", "database", "container"]
      }
    }
  }

  assert {
    condition     = !contains(keys(local.pipeline_container_ids), "postgres")
    error_message = "Container with 'database' tag must NOT be in pipeline_container_ids"
  }

  assert {
    condition     = !contains(keys(local.notification_container_ids), "postgres")
    error_message = "Container with 'database' tag must NOT be in notification_container_ids"
  }
}

run "empty_containers_both_sets_empty" {
  command = plan

  variables {
    containers = {}
  }

  assert {
    condition     = length(local.pipeline_container_ids) == 0
    error_message = "pipeline_container_ids should be empty when containers is empty"
  }

  assert {
    condition     = length(local.notification_container_ids) == 0
    error_message = "notification_container_ids should be empty when containers is empty"
  }
}

run "cribl_without_edge_not_in_pipeline_ids" {
  command = plan

  variables {
    containers = {
      "cribl-stream" = {
        vm_id    = 182
        hostname = "cribl-stream"
        tags     = ["terraform", "cribl", "stream", "container"]
      }
    }
  }

  assert {
    condition     = !contains(keys(local.pipeline_container_ids), "cribl-stream")
    error_message = "Container with 'cribl' but NOT 'edge' tag must NOT be in pipeline_container_ids"
  }
}
