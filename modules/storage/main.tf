terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.90.0"
    }
  }
}

# TODO: Re-enable this resource once the datastore issues are resolved.
# This is currently disabled to allow for the initial deployment of the environment.
# See the following for more details:
# https://github.com/JevonM/int_homelab/pull/1
# Cloud-init configuration file for VMs
resource "proxmox_virtual_environment_file" "cloud_init_config" {
  count = var.enable_cloud_init_config ? 1 : 0

  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.node_name

  source_raw {
    data = yamlencode({
      "#cloud-config" = true
      package_update  = true
      package_upgrade = true
      packages = [
        "qemu-guest-agent",
        "cloud-init",
        "curl",
        "wget"
      ]
      write_files = [
        {
          path    = "/etc/environment"
          content = "ENVIRONMENT=${var.environment}\n"
          append  = true
        }
      ]
      runcmd = [
        "systemctl enable qemu-guest-agent",
        "systemctl start qemu-guest-agent"
      ]
    })
    file_name = "${var.environment}-cloud-init.yml"
  }
}

# Note: Proxmox datastore creation is typically done manually or via Proxmox API
# The bpg/proxmox provider doesn't support datastore creation through Terraform
# This is documented in Proxmox best practices to manage storage at the hypervisor level
# Additional datastores should be configured directly in Proxmox VE before running Terraform
