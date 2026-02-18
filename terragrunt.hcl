# Terragrunt configuration for Proxmox infrastructure

locals {
  # SOPS integration: decrypt terraform.sops.json if it exists, fall back to empty map
  # This allows using either SOPS or Doppler (env vars) for secrets.
  # - SOPS active: place terraform.sops.json (encrypted) in repo root
  # - Doppler active: run with `doppler run -- aws-vault exec terraform -- terragrunt plan`
  sops_secrets = try(jsondecode(sops_decrypt_file("${get_terragrunt_dir()}/terraform.sops.json")), {})

  # Provider auth extracted from SOPS (empty strings if SOPS not active)
  sops_endpoint  = lookup(local.sops_secrets, "proxmox_ve_endpoint", "")
  sops_api_token = lookup(local.sops_secrets, "proxmox_ve_api_token", "")
  sops_insecure  = lookup(local.sops_secrets, "proxmox_ve_insecure", "")

  # SSH configuration for BPG provider
  proxmox_ssh_user        = "root"
  proxmox_ssh_private_key = lookup(local.sops_secrets, "proxmox_ssh_private_key", get_env("PROXMOX_SSH_PRIVATE_KEY", ""))

  # Pre-compute provider auth block:
  # - SOPS active: explicit endpoint, api_token, insecure attributes
  # - SOPS absent: comment directing to PROXMOX_VE_* environment variables
  provider_auth_block = local.sops_endpoint != "" ? join("\n", [
    "  endpoint  = \"${local.sops_endpoint}\"",
    "  api_token = \"${local.sops_api_token}\"",
    "  insecure  = ${local.sops_insecure != "" ? local.sops_insecure : "false"}",
  ]) : "  # Authentication from PROXMOX_VE_* environment variables (Doppler or manual export)"

  # Keys that are provider-level and must be excluded from Terraform variable inputs
  provider_keys = toset(["proxmox_ve_endpoint", "proxmox_ve_api_token", "proxmox_ve_insecure", "_comment"])

  # SOPS inputs: all keys except provider-level ones pass through as Terraform inputs
  sops_inputs = {
    for k, v in local.sops_secrets : k => v
    if !contains(local.provider_keys, k)
  }

  # Default inputs from environment variables (Doppler compatibility)
  env_var_defaults = {
    proxmox_node     = get_env("PROXMOX_VE_NODE", "pve")
    proxmox_username = get_env("PROXMOX_VE_USERNAME", "terraform@pve")
    proxmox_insecure = get_env("PROXMOX_VE_INSECURE", "true") == "true" ? true : false

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
