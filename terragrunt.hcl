# Terragrunt configuration for Proxmox infrastructure

locals {
  # SOPS: deployment-specific config (node name, IPs, network topology, container/VM definitions).
  # This is the encrypted equivalent of .env/terraform.tfvars — repo config, not secrets.
  # Doppler continues to provide all credentials (API tokens, passwords, SSH keys) via env vars.
  #
  # Usage: aws-vault exec terraform -- doppler run -- terragrunt plan
  #   - Doppler injects PROXMOX_VE_* (provider auth) and secret vars (SPLUNK_PASSWORD, etc.)
  #   - Terragrunt decrypts terraform.sops.json for deployment config if it exists
  sops_config = fileexists("${get_terragrunt_dir()}/terraform.sops.json") ? jsondecode(sops_decrypt_file("${get_terragrunt_dir()}/terraform.sops.json")) : {}

  # SSH credentials for BPG provider file operations (from Doppler via env vars)
  proxmox_ssh_user        = get_env("PROXMOX_SSH_USERNAME", "root")
  proxmox_ssh_private_key = get_env("PROXMOX_SSH_PRIVATE_KEY", "")

  # Exclude SOPS metadata key from Terraform inputs
  sops_inputs = {
    for k, v in local.sops_config : k => v
    if k != "_comment"
  }

  # Fallback defaults from Doppler env vars for values not provided by SOPS.
  # When SOPS is present, its values override these via merge().
  env_var_defaults = {
    proxmox_node = get_env("PROXMOX_VE_NODE", "pve")

    proxmox_ssh_username    = get_env("PROXMOX_SSH_USERNAME", "root")
    proxmox_ssh_private_key = get_env("PROXMOX_SSH_PRIVATE_KEY", "")

    management_network = get_env("MANAGEMENT_NETWORK", "192.168.0.0/24")
    splunk_network     = jsondecode(get_env("SPLUNK_NETWORK", "[\"192.168.0.200\"]"))
  }
}

terraform {
  source = "."

  # Load environment-specific tfvars (gitignored, contains real values)
  extra_arguments "env_vars" {
    commands = get_terraform_commands_that_need_vars()
    optional_var_files = [
      "${get_terragrunt_dir()}/.env/terraform.tfvars"
    ]
  }
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
    region         = "us-east-2"
    encrypt        = true
    use_lockfile   = true
    dynamodb_table = "terraform-proxmox-locks-useast2"

    # Retry configuration for transient S3/DynamoDB failures
    max_retries = 5
  }
}

# SOPS config overrides env var defaults (SOPS takes precedence when present)
inputs = merge(local.env_var_defaults, local.sops_inputs)

# Generate provider.tf — required_providers block + SSH credentials from Doppler env vars.
# BPG provider reads API auth (endpoint, token) from PROXMOX_VE_* env vars set by Doppler.
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

# BPG provider reads API auth from PROXMOX_VE_* env vars (set by Doppler).
# See: https://registry.terraform.io/providers/bpg/proxmox/latest/docs
provider "proxmox" {
  ssh {
    agent       = false
    username    = "${local.proxmox_ssh_user}"
    private_key = <<-SSHKEY
${local.proxmox_ssh_private_key}
SSHKEY
  }
}
EOF
}
