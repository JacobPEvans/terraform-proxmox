# Terragrunt configuration for Proxmox infrastructure

locals {
  # SSH configuration for BPG provider (used in generated provider block)
  # Note: Use "root" for SSH, not "root@pam" (which is Proxmox auth format)
  proxmox_ssh_user        = "root"
  proxmox_ssh_private_key = get_env("PROXMOX_SSH_PRIVATE_KEY", "")
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
    # key            = "terraform-proxmox/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    use_lockfile   = true
    dynamodb_table = "terraform-proxmox-locks-useast2"

    # Retry configuration for transient S3/DynamoDB failures
    max_retries = 5
  }
}

# Define common variables that can be used across modules
inputs = {
  # BPG Provider Authentication
  # The BPG provider reads directly from PROXMOX_VE_* environment variables:
  #   - PROXMOX_VE_ENDPOINT   → API URL (without /api2/json)
  #   - PROXMOX_VE_API_TOKEN  → API token (user@realm!tokenid=secret)
  #   - PROXMOX_VE_USERNAME   → Username for token
  #   - PROXMOX_VE_INSECURE   → Skip TLS verification
  #
  # These are set by Doppler and passed through WITHOUT --name-transformer
  #
  # Usage:
  #   doppler run -- aws-vault exec terraform -- \
  #     nix develop ~/git/nix-config/main/shells/terraform --command terragrunt plan
  #
  # Note: No --name-transformer needed! BPG reads PROXMOX_VE_* directly.

  # Non-provider variables still passed as inputs
  proxmox_node     = get_env("PROXMOX_VE_NODE", "pve")
  proxmox_username = get_env("PROXMOX_VE_USERNAME", "terraform@pve")
  proxmox_insecure = get_env("PROXMOX_VE_INSECURE", "true")

  # SSH credentials for provisioners (not BPG provider vars)
  proxmox_ssh_username    = get_env("PROXMOX_SSH_USERNAME", "root")
  proxmox_ssh_private_key = get_env("PROXMOX_SSH_PRIVATE_KEY", "~/.ssh/id_rsa")

  # Splunk secrets (from Doppler)
  splunk_password  = get_env("SPLUNK_ADMIN_PASSWORD", "")
  splunk_hec_token = get_env("SPLUNK_HEC_TOKEN", "")
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

# BPG provider reads authentication from PROXMOX_VE_* environment variables:
#   - PROXMOX_VE_ENDPOINT   (required)
#   - PROXMOX_VE_API_TOKEN  (required, or use USERNAME+PASSWORD)
#   - PROXMOX_VE_INSECURE   (optional, default false)
# See: https://registry.terraform.io/providers/bpg/proxmox/latest/docs
provider "proxmox" {
  # Authentication is read from environment variables
  # SSH config needed for file uploads (snippets)
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
