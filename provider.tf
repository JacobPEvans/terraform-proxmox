terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.78.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
  ssh {
    agent       = false
    username    = var.proxmox_ssh_username
    private_key = (var.proxmox_ssh_private_key)
  }
}
