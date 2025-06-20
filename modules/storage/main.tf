terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.78.0"
    }
  }
}

# Cloud-init configuration file for VMs
resource "proxmox_virtual_environment_file" "cloud_init_config" {
  count = 0 # Temporarily disabled due to datastore issues

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
