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
    key            = "terraform-proxmox/terraform.tfstate"
    # key            = "terraform-proxmox/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    use_lockfile   = true
    dynamodb_table = "terraform-proxmox-locks-useast2"
  }
}

# Define common variables that can be used across modules
inputs = {
  # Default Proxmox configuration
  # These can be overridden via terraform.tfvars or environment variables
  # IMPORTANT: Terragrunt inputs can read from environment variables using get_env()
  proxmox_api_endpoint = get_env("TF_VAR_proxmox_api_endpoint", "")
  proxmox_api_token    = get_env("TF_VAR_proxmox_api_token", "")
  proxmox_node         = get_env("TF_VAR_proxmox_node", "pve")
  proxmox_username     = get_env("TF_VAR_proxmox_username", "proxmox")
  proxmox_insecure     = get_env("TF_VAR_proxmox_insecure", "false")
}

# Terragrunt will generate provider.tf with these settings
generate "provider" {
  path      = "provider_override.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = ">= 1.10"
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.90"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}
EOF
}
