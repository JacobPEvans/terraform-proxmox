terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.90.0"
    }
  }
}

# Reference existing storage pools as data sources for validation
# These are created at the Proxmox/ZFS level and managed outside Terraform
# Data sources provide type safety and ensure storage exists before use

data "proxmox_virtual_environment_datastores" "available" {
  node_name = var.node_name
}

# Validate that common datastores exist on the target node
# This provides faster feedback than waiting for a resource to fail during apply
check "datastore_local_exists" {
  condition = contains([
    for ds in data.proxmox_virtual_environment_datastores.available.datastores : ds.id
  ], "local")
  error_message = "The required 'local' datastore for ISOs and snippets does not exist on node ${var.node_name}."
}

check "datastore_local_zfs_exists" {
  condition = contains([
    for ds in data.proxmox_virtual_environment_datastores.available.datastores : ds.id
  ], "local-zfs")
  error_message = "The required 'local-zfs' datastore for VM disks does not exist on node ${var.node_name}."
}

# Common datastores in our environment:
#   - local       (dir, /var/lib/vz)          - ISOs, templates, backups
#   - local-zfs   (zfspool, rpool/data)       - VM disks, container rootfs
#   - ssd-pool    (zfspool, ssd-pool)         - High-performance VM disks

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
