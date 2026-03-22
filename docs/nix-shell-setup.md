# Using Nix Shells with Terraform Proxmox Repository

This guide covers setting up and using Nix development shells for Terraform/Terragrunt work in this repository.

**Related guides:**

- [AWS Vault + Terraform](aws-vault-terraform.md) -- credential management for the S3 state backend
- [Nix Shell Troubleshooting](nix-shell-troubleshooting.md) -- common issues and advanced usage

## Prerequisites

1. **Nix Package Manager** -- `nix --version`
2. **direnv** (recommended) -- `direnv --version`
3. **Docker** (for Ansible molecule testing) -- `docker --version && docker ps`
4. **AWS CLI configured** -- `aws sts get-caller-identity`

## Quick Start

### 1. Navigate to Repository

```bash
cd ~/git/terraform-proxmox/main
```

### 2. Enter Nix Shell

**direnv (recommended):**

```bash
cp .envrc.example .envrc
direnv allow
# Shell auto-activates whenever you cd into the directory
```

**Manual activation:**

```bash
nix develop ~/git/terraform-proxmox/main
```

### 3. Verify Installation

```bash
tofu version
terragrunt --version
ansible --version
tfsec --version
```

## Development Workflow

### Initialize and Validate

```bash
terragrunt init
terragrunt validate
tflint
tfsec .
```

### Plan and Apply

```bash
# With aws-vault (see aws-vault-terraform.md)
aws-vault exec default -- doppler run -- terragrunt plan
aws-vault exec default -- doppler run -- terragrunt apply

# Security scans (no AWS credentials needed)
tfsec --concise-output .
checkov --directory . --quiet
trivy config --severity HIGH,CRITICAL .
```

### State Management

```bash
terragrunt state list
terragrunt state show 'module.pool.proxmox_virtual_environment_pool.this["automation"]'
```

### Generate Module Documentation

```bash
cd modules/proxmox-vm
terraform-docs markdown table --output-file README.md .
```

### Pre-commit Hooks

```bash
pre-commit install
pre-commit run --all-files
```

## Environment Variables

### Proxmox API Access

```bash
export TF_VAR_proxmox_api_endpoint="https://your-proxmox.example.com:8006/api2/json"
export TF_VAR_proxmox_api_token="user@pam!token=your-token-here"
```

### SSH Keys

```bash
export TF_VAR_proxmox_ssh_private_key="$(cat ~/.ssh/id_rsa)"
```

## Summary Checklist

- [ ] Verify Nix is installed (`nix --version`)
- [ ] Navigate to repository and allow direnv (`direnv allow`)
- [ ] Use `aws-vault` for any command that accesses the S3 state backend
- [ ] Security validation and linting do not need AWS credentials
- [ ] Review plan before applying changes
