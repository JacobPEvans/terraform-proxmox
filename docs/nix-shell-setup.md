# Using Nix Shells with Terraform Proxmox Repository

This guide provides step-by-step instructions for Claude Code (and developers) to use Nix shells for local Terraform/Terragrunt development and testing in this repository.

## Overview

This repository leverages a pre-configured Nix development shell located at `~/git/nix-config/main/shells/terraform` that provides all necessary tools for infrastructure-as-code development, including:

- **Infrastructure Tools**: Terraform, Terragrunt, OpenTofu
- **Security Scanners**: checkov, terrascan, tfsec, trivy
- **Configuration Management**: Ansible, ansible-lint, molecule
- **Cloud Tools**: AWS CLI, Docker
- **Utilities**: terraform-docs, tflint, jq, yq, git

## Prerequisites

Before starting, ensure you have:

1. **Nix Package Manager** installed on your system
   - Check: `nix --version`
   - If not installed, visit: https://nixos.org/download.html

2. **direnv** (optional, but recommended for automatic shell activation)
   - Check: `direnv --version`
   - Install via Nix: `nix profile install nixpkgs#direnv`

3. **Docker** running (required for Ansible molecule testing)
   - Check: `docker --version && docker ps`

4. **AWS CLI configured** (for Terraform state backend)
   - Check: `aws sts get-caller-identity`
   - Configure: `aws configure` (or use aws-vault)

## Quick Start (3 Steps)

### Step 1: Navigate to Repository

```bash
cd ~/git/terraform-proxmox/feat/initial-splunk
```

### Step 2: Enter Nix Shell

**Option A - Using direnv (Recommended)**

If you have direnv installed:

```bash
# Create .envrc file
echo "use flake ~/git/nix-config/main/shells/terraform" > .envrc

# Allow direnv to load the shell
direnv allow

# The shell will auto-activate whenever you cd into this directory
```

**Option B - Manual Activation**

```bash
# Enter the Nix shell manually
nix develop ~/git/nix-config/main/shells/terraform

# You'll see a welcome message showing all available tools
```

### Step 3: Verify Installation

The shell hook will display installed tools. Verify manually:

```bash
# Check Terraform tools
terraform version
terragrunt --version
opentofu version

# Check Ansible tools
ansible --version
ansible-lint --version
molecule --version

# Check security scanners
tfsec --version
checkov --version
trivy --version

# Check cloud tools
aws --version
docker --version
```

## Development Workflow

### 1. Initialize Terraform/Terragrunt

```bash
# Initialize Terragrunt (also runs terraform init)
terragrunt init

# This will:
# - Download required providers (bpg/proxmox)
# - Configure S3 backend for state storage
# - Set up DynamoDB table for state locking
```

### 2. Validate Configuration

```bash
# Validate Terraform syntax
terragrunt validate

# Run Terraform linting
tflint

# Security scanning
tfsec .
checkov --directory .
trivy config .
```

### 3. Plan Infrastructure Changes

```bash
# Generate execution plan
terragrunt plan

# Save plan to file for review
terragrunt plan -out=tfplan

# View saved plan
terragrunt show tfplan
```

### 4. Run Security Checks

```bash
# Quick security scan
tfsec --concise-output .

# Comprehensive compliance check
checkov --directory . --framework terraform

# Vulnerability scanning
trivy config --severity HIGH,CRITICAL .

# Cost estimation (requires API key)
infracost breakdown --path .
```

### 5. Test Ansible Roles (if applicable)

```bash
# Navigate to role directory
cd ansible/roles/common

# Install molecule dependencies
pip install molecule molecule-docker

# Run molecule tests
molecule test

# Or run individual steps
molecule create    # Create test container
molecule converge  # Run playbook
molecule verify    # Run tests
molecule destroy   # Clean up
```

### 6. Apply Changes

```bash
# Apply with auto-approval (use with caution)
terragrunt apply -auto-approve

# Or apply interactively
terragrunt apply
```

### 7. Manage State

```bash
# List all resources in state
terragrunt state list

# Show specific resource
terragrunt state show 'module.pool.proxmox_virtual_environment_pool.this["automation"]'

# View current infrastructure
terragrunt show
```

### 8. Clean Up

```bash
# Destroy infrastructure (sequential to avoid dependency issues)
terragrunt destroy --terragrunt-parallelism=1

# Remove .terraform directory
rm -rf .terraform

# Remove generated files
rm -f .terraform.lock.hcl tfplan
```

## Environment Variables

The Nix shell automatically provides these tools, but you may need to configure:

### Proxmox API Access

```bash
# Set Proxmox credentials (alternative to terraform.tfvars)
export TF_VAR_proxmox_api_endpoint="https://your-proxmox.example.com:8006/api2/json"
export TF_VAR_proxmox_api_token="user@pam!token=your-token-here"
```

### AWS Credentials (for state backend)

```bash
# Option 1: AWS CLI default profile
aws configure

# Option 2: Use aws-vault
aws-vault exec your-profile -- terragrunt plan

# Option 3: Set explicit credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"
```

### SSH Keys

```bash
# Set SSH private key for Proxmox host access
export TF_VAR_proxmox_ssh_private_key="$(cat ~/.ssh/id_rsa)"

# Or use a specific key file
export TF_VAR_proxmox_ssh_private_key="$(cat ~/.ssh/proxmox_key)"
```

## Common Tasks for Claude Code

### Task: Validate Terraform Configuration

```bash
# Step 1: Enter Nix shell
nix develop ~/git/nix-config/main/shells/terraform

# Step 2: Run validation
terragrunt validate

# Step 3: Check formatting
terraform fmt -check -recursive

# Step 4: Run linting
tflint --recursive
```

### Task: Test Infrastructure Changes Locally

```bash
# Step 1: Enter Nix shell
nix develop ~/git/nix-config/main/shells/terraform

# Step 2: Initialize if needed
terragrunt init

# Step 3: Create execution plan
terragrunt plan -out=tfplan

# Step 4: Review plan output
terragrunt show -json tfplan | jq '.'

# Step 5: Run security scans on plan
tfsec --concise-output .
checkov --directory . --quiet
```

### Task: Generate Module Documentation

```bash
# Step 1: Enter Nix shell
nix develop ~/git/nix-config/main/shells/terraform

# Step 2: Generate docs for a module
cd modules/proxmox-vm
terraform-docs markdown table --output-file README.md .

# Step 3: Generate docs for all modules
for dir in modules/*/; do
  cd "$dir"
  terraform-docs markdown table --output-file README.md .
  cd ../..
done
```

### Task: Run Pre-commit Hooks

```bash
# Step 1: Enter Nix shell
nix develop ~/git/nix-config/main/shells/terraform

# Step 2: Install pre-commit hooks
pre-commit install

# Step 3: Run hooks on all files
pre-commit run --all-files

# Step 4: Run specific hook
pre-commit run terraform_validate --all-files
```

### Task: Test Ansible Playbook Syntax

```bash
# Step 1: Enter Nix shell
nix develop ~/git/nix-config/main/shells/terraform

# Step 2: Run ansible-lint
ansible-lint ansible/playbooks/site.yml

# Step 3: Check playbook syntax
ansible-playbook --syntax-check ansible/playbooks/site.yml

# Step 4: Run molecule test for role
cd ansible/roles/common && molecule test
```

## Troubleshooting

### Issue: Nix shell not found

**Symptom**: `error: getting status of '/nix/store/...': No such file or directory`

**Solution**:
```bash
# Update nix flake inputs
nix flake update ~/git/nix-config/main/shells/terraform

# Rebuild the shell
nix develop ~/git/nix-config/main/shells/terraform --rebuild
```

### Issue: Docker not available in Nix shell

**Symptom**: `Cannot connect to the Docker daemon`

**Solution**:
```bash
# Docker must be running on the host system
# The Nix shell provides the Docker CLI client only

# macOS: Ensure Docker Desktop is running
open -a Docker

# Linux: Start Docker service
sudo systemctl start docker
```

### Issue: AWS credentials not found

**Symptom**: `Error: No valid credential sources found`

**Solution**:
```bash
# Configure AWS CLI
aws configure

# Or use aws-vault
aws-vault exec your-profile -- bash

# Then enter Nix shell
nix develop ~/git/nix-config/main/shells/terraform
```

### Issue: Terraform provider download fails

**Symptom**: `Failed to install provider from shared cache`

**Solution**:
```bash
# Clear provider cache
rm -rf ~/.terraform.d/plugin-cache
rm -rf .terraform

# Re-initialize
terragrunt init
```

### Issue: Terragrunt state locking errors

**Symptom**: `Error acquiring the state lock`

**Solution**:
```bash
# List active locks
aws dynamodb scan --table-name terraform-state-lock

# Force unlock (use with caution)
terragrunt force-unlock <lock-id>

# Or wait for lock to expire (typically 2 minutes)
```

## Advanced Usage

### Using Multiple Nix Shells Simultaneously

```bash
# Terminal 1: Main development
cd ~/git/terraform-proxmox/feat/initial-splunk
nix develop ~/git/nix-config/main/shells/terraform

# Terminal 2: Parallel testing
cd ~/git/terraform-proxmox/feat/initial-splunk
nix develop ~/git/nix-config/main/shells/terraform
```

### Customizing the Shell

Create a local `flake.nix` override:

```nix
{
  description = "Custom Terraform shell for this project";

  inputs = {
    terraform-shell.url = "path:/Users/jevans/git/nix-config/main/shells/terraform";
  };

  outputs = { terraform-shell, ... }: {
    devShells = terraform-shell.devShells // {
      default = terraform-shell.devShells.default.overrideAttrs (old: {
        shellHook = old.shellHook + ''
          echo "Custom setup for Splunk cluster development"
          export TF_LOG=DEBUG
        '';
      });
    };
  };
}
```

### Running Commands Outside the Shell

```bash
# Execute a single command in the Nix shell environment
nix develop ~/git/nix-config/main/shells/terraform --command terragrunt plan

# Run a script in the Nix shell
nix develop ~/git/nix-config/main/shells/terraform --command bash ./scripts/deploy.sh
```

## Integration with CI/CD

The same Nix shell can be used in CI/CD pipelines:

```yaml
# .github/workflows/terraform.yml
name: Terraform Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: cachix/install-nix-action@v27
        with:
          nix_path: nixpkgs=channel:nixos-unstable

      - name: Enter Nix shell and validate
        run: |
          nix develop ~/git/nix-config/main/shells/terraform --command bash -c "
            terragrunt init
            terragrunt validate
            tflint
            tfsec .
          "
```

## Additional Resources

- **Nix Shell Documentation**: `~/git/nix-config/main/shells/terraform/flake.nix`
- **Terraform Documentation**: https://developer.hashicorp.com/terraform/docs
- **Terragrunt Documentation**: https://terragrunt.gruntwork.io/docs/
- **Proxmox Provider**: https://registry.terraform.io/providers/bpg/proxmox/latest/docs
- **This Repository's README**: `~/git/terraform-proxmox/feat/initial-splunk/README.md`
- **Troubleshooting Guide**: `~/git/terraform-proxmox/feat/initial-splunk/TROUBLESHOOTING.md`

## Summary Checklist

When starting work on this repository, Claude should:

- [ ] Verify Nix is installed (`nix --version`)
- [ ] Navigate to repository (`cd ~/git/terraform-proxmox/feat/initial-splunk`)
- [ ] Enter Nix shell (`nix develop ~/git/nix-config/main/shells/terraform`)
- [ ] Verify all tools are available (terraform, terragrunt, ansible, etc.)
- [ ] Configure AWS credentials for state backend
- [ ] Initialize Terragrunt (`terragrunt init`)
- [ ] Validate configuration (`terragrunt validate`)
- [ ] Run security scans (`tfsec`, `checkov`, `trivy`)
- [ ] Create execution plan (`terragrunt plan`)
- [ ] Review plan before applying changes

This ensures a consistent, reproducible development environment across all sessions.
