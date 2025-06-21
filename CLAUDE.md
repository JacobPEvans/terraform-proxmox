# Terraform Proxmox Infrastructure Repository

## Repository Overview

This repository contains Terraform/Terragrunt configurations for managing Proxmox Virtual Environment (PVE)
infrastructure. It's designed to provision VMs, containers, and other resources on a Proxmox cluster using
Infrastructure as Code (IaC) principles.

## Architecture & Components

### Core Files

- `main.tf` - Core resource definitions using modular architecture
- `variables.tf` - Input variable definitions
- `outputs.tf` - Output definitions
- `locals.tf` - Local computed values
- `terragrunt.hcl` - Terragrunt configuration with remote state management
- `container.tf` - Container-specific resource definitions
- `modules/` - Modular components (security, proxmox-vm, proxmox-container, proxmox-pool, storage)

### State Management

- **Backend**: AWS S3 + DynamoDB for state locking
- **Bucket**: `terraform-proxmox-state-{region}-{account_id}`
- **State Key**: `terraform-proxmox/{path}/terraform.tfstate`
- **Region**: `us-east-2`
- **Lock Table**: `terraform-proxmox-locks-{region}`

### Proxmox Configuration

- **Default Node**: `pve`
- **API Endpoint**: Configured via `proxmox_api_endpoint` variable
- **Authentication**: API token based (`proxmox_api_token`)
- **SSH Access**: Uses private key authentication for VM provisioning
- **SSH VM Access**: SSH keys should be generated at Image or VM creation and known by Proxmox and Terraform

## Prerequisites

### Required Tools

- Terraform >= 1.0
- Terragrunt >= 0.45.0
- AWS CLI configured with appropriate permissions
- SSH key pair for Proxmox access

### Required Permissions

- **AWS**: S3 bucket read/write, DynamoDB table access
- **Proxmox**: API token with VM/container management permissions

## Environment Setup

### AWS CLI Configuration

```bash
aws configure
# Set AWS Access Key ID, Secret Access Key, and region (us-east-2)
```

### Terraform Variables

Create or update `terraform.tfvars` with your environment-specific values:

```hcl
proxmox_api_endpoint = "https://pve.example.com:8006/api2/json"
proxmox_api_token = "your-api-token-here"
proxmox_ssh_private_key = "~/.ssh/id_rsa"
```

## Development Workflow

### Planning Changes

1. **Always plan before applying**:

   ```bash
   terragrunt plan
   ```

2. **Review plan output carefully** - especially for:
   - Resource deletions
   - VM/container changes
   - Network modifications

3. **Use targeted operations when needed**:

   ```bash
   terragrunt plan -target=resource.name
   ```

### Applying Changes

1. **Apply in stages for complex changes**
2. **Monitor Proxmox console during application**
3. **Validate resources after deployment**

### Common Commands

```bash
# Initialize and download providers
terragrunt init

# Plan changes
terragrunt plan

# Apply changes
terragrunt apply

# Show current state
terragrunt show

# Destroy resources (use with caution)
terragrunt destroy
```

## Best Practices

**For generic Claude Code and development best practices, see**: [Standardized CLAUDE.md](../CLAUDE.md)

### Terraform-Specific Best Practices

- Keep resource definitions modular
- Use consistent naming conventions
- Document all variables with descriptions
- Use sensitive = true for secrets
- Always use remote state for production
- Regular state backups via S3 versioning
- Use consistent state key naming
- Never update VM or container configurations directly. Always use Terraform.

### Security Best Practices

- Never commit API tokens or passwords
- Use separate SSH keys for different environments
- Enable encryption for state files
- Implement least-privilege access

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Check API token validity
   - Verify SSH key permissions
   - Confirm Proxmox API endpoint

2. **State Lock Issues**
   - Force unlock if necessary: `terragrunt force-unlock -force LOCK_ID`

3. **Resource Conflicts**
   - Review existing resources in Proxmox
   - Check for naming conflicts
   - Validate resource dependencies

### Debugging

- Use `TF_LOG=DEBUG` for detailed logging
- Check Proxmox logs for API errors
- Verify network connectivity to Proxmox

## Testing Strategy

- Use separate environments (dev/staging/prod)
- Test in isolated resource pools
- Validate with `terragrunt validate`
- Use `terragrunt plan` before all applies

## Maintenance

- Regular provider updates
- State file cleanup
- Resource tagging consistency
- Documentation updates

## Repository Standards

**For generic Git workflow and repository standards, see**: [Standardized CLAUDE.md](../CLAUDE.md)

## Infrastructure Context

Real infrastructure details are maintained in a separate private repository for security.

This file contains placeholder/example values for public repository safety. Reference the private context for actual:

- Hostnames and IP addresses
- API endpoints and credentials
- Network configurations
- Development environment paths

## Git Workflow Standards

**For generic Git workflow and repository standards, see**: [Standardized CLAUDE.md](../CLAUDE.md)

### Repository-Specific Guidelines

- Always run `terragrunt plan` before commits
- Validate terraform syntax with `terragrunt validate`
- Test infrastructure changes in isolated environments
- Follow conventional commit messages
- Never commit sensitive information (API tokens, passwords)
- Use feature branches for all changes
