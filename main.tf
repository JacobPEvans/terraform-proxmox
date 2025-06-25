terraform {
  required_version = ">= 1.12.2"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.78"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Read VM SSH public key for cloud-init
data "local_file" "vm_ssh_public_key" {
  filename = pathexpand(var.vm_ssh_public_key_path)
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
      node_name      = var.proxmox_node
      cdrom_file_id  = v.cdrom_file_id != null ? "local:iso/${var.proxmox_iso_ubuntu}" : null
      clone_template = v.clone_template
      user_account = {
        username = v.user_account.username
        password = v.user_account.password
        keys     = [trimspace(data.local_file.vm_ssh_public_key.content)]
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
        password = "ubuntu"  # default password
        keys     = [trimspace(data.local_file.vm_ssh_public_key.content)]
      }
    })
  }

  environment       = var.environment
  default_datastore = "local-zfs"

  depends_on = [module.pools, module.storage]
}

# Secure SSH key provisioning for Ansible VM
resource "null_resource" "ansible_ssh_key_setup" {
  count = contains(keys(var.vms), "ansible") ? 1 : 0

  depends_on = [module.vms]

  connection {
    type        = "ssh"
    user        = var.vms["ansible"].user_account.username
    private_key = file(pathexpand(var.vm_ssh_private_key_path))
    host        = cidrhost(var.vms["ansible"].ip_config.ipv4_address, 0)
    timeout     = "2m"
  }

  provisioner "file" {
    source      = pathexpand(var.vm_ssh_private_key_path)
    destination = "/home/${var.vms["ansible"].user_account.username}/.ssh/id_rsa_vm"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/${var.vms["ansible"].user_account.username}/.ssh/id_rsa_vm",
      "chown ${var.vms["ansible"].user_account.username}:${var.vms["ansible"].user_account.username} /home/${var.vms["ansible"].user_account.username}/.ssh/id_rsa_vm"
    ]
  }

  triggers = {
    vm_id = module.vms.vm_ids["ansible"]
  }
}
