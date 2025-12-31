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
  # IMPORTANT: Variables are sourced from TF_VAR_* environment variables
  #
  # Flow: Secret manager → --name-transformer tf-var → TF_VAR_* → Terragrunt inputs → Terraform
  #
  # Why get_env() instead of .tfvars files?
  # - Terraform variable precedence: .tfvars files > TF_VAR_* env vars > defaults
  # - Generating .tfvars files would override environment variables from secret manager
  # - Using get_env() directly reads from environment without precedence conflicts
  #
  # Usage with secret manager:
  #   doppler run --name-transformer tf-var -- aws-vault exec terraform -- \
  #     nix develop ~/git/nix-config/main/shells/terraform --command terragrunt plan
  #
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
