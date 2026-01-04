terraform {
  required_version = ">= 1.10"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.91"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1"
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

# Local variables for cloud-init files
locals {
  ansible_cloud_init = file(var.ansible_cloud_init_file)
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
      cdrom_file_id  = v.cdrom_file_id != null ? "${var.datastore_iso}:iso/${var.proxmox_iso_debian}" : null
      clone_template = v.clone_template
      user_account = {
        username = v.user_account.username
        password = v.user_account.password
        keys     = [trimspace(data.local_file.vm_ssh_public_key.content)]
      }
      # Override cloud-init for ansible VM to use external file
      cloud_init_user_data = k == "ansible" ? local.ansible_cloud_init : v.cloud_init_user_data
    })
  }

  environment       = var.environment
  default_datastore = var.datastore_default

  proxmox_api_token       = var.proxmox_api_token
  proxmox_api_endpoint    = var.proxmox_api_endpoint
  proxmox_ssh_username    = var.proxmox_ssh_username
  proxmox_ssh_private_key = var.proxmox_ssh_private_key

  depends_on = [module.pools]
}

# Container module - creates and manages containers (optional)
module "containers" {
  count  = length(var.containers) > 0 ? 1 : 0
  source = "./modules/proxmox-container"

  containers = {
    for k, v in var.containers : k => merge(v, {
      node_name        = var.proxmox_node
      template_file_id = "${var.datastore_iso}:vztmpl/${var.proxmox_ct_template_debian}"
      user_account = merge(
        lookup(v, "user_account", {}),
        {
          keys = [trimspace(data.local_file.vm_ssh_public_key.content)]
        }
      )
    })
  }

  environment       = var.environment
  default_datastore = var.datastore_default

  depends_on = [module.pools, module.storage]
}

# Splunk VM module - All-in-One Splunk Enterprise
module "splunk_vm" {
  source = "./modules/splunk-vm"

  vm_id          = var.splunk_vm_id
  name           = var.splunk_vm_name
  ip_address     = var.splunk_vm_ip_address
  gateway        = local.splunk_network_gateway
  node_name      = var.proxmox_node
  pool_id        = var.splunk_vm_pool_id
  template_id    = var.template_id
  datastore_id   = var.datastore_id
  bridge         = var.bridge
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : trimspace(data.local_file.vm_ssh_public_key.content)

  depends_on = [module.pools]
}

# Firewall module - manages Proxmox firewall rules for Splunk
module "firewall" {
  source = "./modules/firewall"

  node_name = var.proxmox_node

  splunk_vm_ids = merge(
    {
      for k, v in var.vms : k => v.vm_id
      if contains(try(v.tags, []), "splunk")
    },
    {
      "splunk-vm" = module.splunk_vm.vm_id
    }
  )

  splunk_container_ids = {
    for k, v in var.containers : k => v.vm_id
    if contains(try(v.tags, []), "splunk")
  }

  management_network = var.management_network
  splunk_network     = join(",", var.splunk_network)

  depends_on = [module.vms, module.containers, module.splunk_vm]
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
