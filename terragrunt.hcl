# Terragrunt configuration for Proxmox infrastructure

locals {
  # SOPS integration: decrypt terraform.sops.json if it exists, fall back to empty map
  # This allows using either SOPS or Doppler (env vars) for secrets.
  # - SOPS active: place terraform.sops.json (encrypted) in repo root
  # - Doppler active: run with `aws-vault exec terraform -- doppler run -- terragrunt plan`
  #
  # fileexists() gate ensures decrypt/parse errors fail loudly instead of silently
  # falling back to Doppler when terraform.sops.json exists but can't be decrypted.
  sops_secrets = fileexists("${get_terragrunt_dir()}/terraform.sops.json") ? jsondecode(sops_decrypt_file("${get_terragrunt_dir()}/terraform.sops.json")) : {}

  # Provider auth extracted from SOPS (empty string/null if SOPS not active)
  sops_endpoint  = lookup(local.sops_secrets, "proxmox_ve_endpoint", "")
  sops_api_token = lookup(local.sops_secrets, "proxmox_ve_api_token", "")
  sops_insecure  = lookup(local.sops_secrets, "proxmox_ve_insecure", null)

  # SSH configuration for BPG provider (reads from SOPS or environment variable)
  proxmox_ssh_user        = lookup(local.sops_secrets, "proxmox_ssh_username", get_env("PROXMOX_SSH_USERNAME", "root"))
  proxmox_ssh_private_key = lookup(local.sops_secrets, "proxmox_ssh_private_key", get_env("PROXMOX_SSH_PRIVATE_KEY", ""))

  # Pre-compute provider auth block:
  # - SOPS active: explicit endpoint, api_token, insecure attributes
  # - SOPS absent: comment directing to PROXMOX_VE_* environment variables
  provider_auth_block = (local.sops_endpoint != "" && local.sops_api_token != "") ? join("\n", [
    "  endpoint  = \"${local.sops_endpoint}\"",
    "  api_token = \"${local.sops_api_token}\"",
    "  insecure  = ${local.sops_insecure != null ? local.sops_insecure : false}",
  ]) : "  # Authentication from PROXMOX_VE_* environment variables (Doppler or manual export)"

  # Keys that are provider-level or unused and must be excluded from Terraform variable inputs.
  # proxmox_username and proxmox_insecure are declared in variables.tf but not referenced by
  # any resource module - exclude them to avoid passing noise through inputs.
  provider_keys = toset([
    "proxmox_ve_endpoint", "proxmox_ve_api_token", "proxmox_ve_insecure",
    "proxmox_username", "proxmox_insecure",
    "_comment",
  ])

  # SOPS inputs: all keys except provider-level/unused ones pass through as Terraform inputs
  sops_inputs = {
    for k, v in local.sops_secrets : k => v
    if !contains(local.provider_keys, k)
  }

  # Default inputs from environment variables (Doppler compatibility).
  # Only includes variables actually referenced by resource modules.
  env_var_defaults = {
    proxmox_node = get_env("PROXMOX_VE_NODE", "pve")

    proxmox_ssh_username    = get_env("PROXMOX_SSH_USERNAME", "root")
    proxmox_ssh_private_key = get_env("PROXMOX_SSH_PRIVATE_KEY", "~/.ssh/id_rsa")

    splunk_password  = get_env("SPLUNK_PASSWORD", "")
    splunk_hec_token = get_env("SPLUNK_HEC_TOKEN", "")

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
    # key            = "terraform-proxmox/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    use_lockfile   = true
    dynamodb_table = "terraform-proxmox-locks-useast2"

    # Retry configuration for transient S3/DynamoDB failures
    max_retries = 5
  }
}

# Merge env var defaults with SOPS values (SOPS takes precedence when active)
inputs = merge(local.env_var_defaults, local.sops_inputs)

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

# BPG provider - auth from SOPS (terraform.sops.json) when present, or PROXMOX_VE_* env vars
# See: https://registry.terraform.io/providers/bpg/proxmox/latest/docs
provider "proxmox" {
${local.provider_auth_block}
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
