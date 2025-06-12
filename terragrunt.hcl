# Terragrunt configuration for Proxmox infrastructure

terraform {
  source = "."
}

# Remote state backend configuration using S3 + DynamoDB
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "terraform-proxmox-state-useast2-${get_aws_account_id()}"
    key            = "terraform-proxmox/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "terraform-proxmox-locks-useast2"
  }
}

# Define common variables that can be used across modules
inputs = {
  # Default Proxmox configuration
  # These can be overridden via terraform.tfvars or environment variables
  proxmox_node     = "pve"
  proxmox_username = "proxmox"
  proxmox_insecure = false
}

# Terragrunt will generate provider.tf with these settings
generate "provider" {
  path      = "provider_override.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }
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
    private_key = file(var.proxmox_ssh_private_key)
  }
}
EOF
}

# Generate a terraform.tfvars file with required variables
generate "terraform_vars" {
  path      = "terraform.tfvars"
  if_exists = "skip"
  contents  = <<EOF
# Proxmox API Configuration
# You need to set these values for your environment

# Example: "https://pve.mgmt:8006/api2/json"
proxmox_api_endpoint = ""

# Example: "root@pam!terraform=your-secret-token-here"
proxmox_api_token = ""

# SSH Configuration
proxmox_ssh_username = "root@pam"
proxmox_ssh_private_key = "~/.ssh/id_rsa"

# VM Configuration
proxmox_node = "pve"
proxmox_username = "proxmox"
proxmox_insecure = false

# ISO and Template Configuration
proxmox_iso_ubuntu = "ubuntu-24.04.1-live-server-amd64.iso"
proxmox_ct_template_ubuntu = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
EOF
}
