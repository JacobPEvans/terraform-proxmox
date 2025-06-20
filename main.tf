terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.78.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }
  }
}

# Security module - generates passwords and SSH keys
module "security" {
  source = "./modules/security"

  environment      = var.environment
  password_length  = 16
  password_special = true
  rsa_bits         = 2048
}

# Storage module - manages datastores and storage configuration
module "storage" {
  source = "./modules/storage"

  node_name   = var.proxmox_node
  datastores  = var.datastores
  environment = var.environment
}

# Pool module - manages resource pools
module "pools" {
  source = "./modules/proxmox-pool"

  pools       = var.pools
  environment = var.environment
}

# VM module - creates and manages virtual machines
module "vms" {
  source = "./modules/proxmox-vm"

  vms = {
    for k, v in var.vms : k => merge(v, {
      node_name     = var.proxmox_node
      cdrom_file_id = "local:iso/${var.proxmox_iso_ubuntu}"
      user_account = {
        username = var.proxmox_username
        password = module.security.vm_password
        keys     = [module.security.vm_public_key_trimmed]
      }
    })
  }

  environment       = var.environment
  default_datastore = "local-zfs"

  proxmox_api_token       = var.proxmox_api_token
  proxmox_api_endpoint    = var.proxmox_api_endpoint
  proxmox_ssh_username    = var.proxmox_ssh_username
  proxmox_ssh_private_key = var.proxmox_ssh_private_key
}

# Container module - creates and manages containers (optional)
module "containers" {
  count  = length(var.containers) > 0 ? 1 : 0
  source = "./modules/proxmox-container"

  containers = {
    for k, v in var.containers : k => merge(v, {
      node_name        = var.proxmox_node
      template_file_id = "local:vztmpl/${var.proxmox_ct_template_ubuntu}"
      user_account = {
        password = module.security.vm_password
        keys     = [module.security.vm_public_key_trimmed]
      }
    })
  }

  environment       = var.environment
  default_datastore = "local-zfs"

  depends_on = [module.pools, module.storage]
}
