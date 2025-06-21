# Terraform Proxmox Infrastructure

This project manages Proxmox VE infrastructure using Terraform and Terragrunt with a modular architecture.

Infrastructure as Code (IaC) for managing Proxmox Virtual Environment resources using Terraform and Terragrunt.

## 🏗️ Overview

This repository provides Terraform configurations to provision and manage:

- Virtual machines and containers on Proxmox VE
- Ansible infrastructure to manage all VMs and containers
- Logging infrastructure (Splunk, Syslog)
- Resource pools and networking
- SSH keys and authentication

## Architecture

The project has been refactored into a modular structure for better maintainability and reusability:

```text
terraform-proxmox/
├── main.tf                    # Root module orchestrating all components
├── variables.tf               # Root-level variable definitions
├── outputs.tf                 # Root-level outputs
├── provider.tf                # Provider configuration
├── terraform.tfvars          # Variable values
├── terragrunt.hcl            # Terragrunt configuration
└── modules/
    ├── security/              # Password & SSH key generation
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── proxmox-pool/          # Resource pool management
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── proxmox-vm/            # Virtual machine creation
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── proxmox-container/     # Container management
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── storage/               # Storage and cloud-init configs
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Features

### Implemented

- **Modular Design**: Separate modules for different resource types
- **Security**: Centralized password and SSH key generation
- **Resource Pools**: Organized resource management
- **Virtual Machines**: Configurable VM deployments with consistent settings
- **Containers**: LXC container support (configurable)
- **Storage**: Cloud-init configuration management
- **Terragrunt Integration**: Backend configuration and state management

### Benefits of the New Structure

1. **Eliminated Duplication**: VMs (splunk, syslog) now use the same module
2. **Improved Reusability**: Modules can be used across different environments
3. **Enhanced Maintainability**: Clear separation of concerns
4. **Better Security**: Centralized credential management
5. **Consistent Configuration**: Standardized VM and container settings

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.0
- Terragrunt >= 0.45.0
- AWS CLI configured
- Proxmox API token

1. Proxmox VE server configured and accessible
2. Terraform and Terragrunt installed
3. AWS S3 bucket for state storage (configured in terragrunt.hcl)

### Setup

```bash
# Initialize the environment
terragrunt init

# Plan your changes
terragrunt plan

# Apply the infrastructure
terragrunt apply
```

### Configuration

1. Update `terraform.tfvars` with your Proxmox configuration:

   ```hcl
   proxmox_api_endpoint = "https://your-proxmox:8006/api2/json"
   proxmox_api_token    = "your-api-token"
   # ... other variables
   ```

2. Configure your VMs in the `vms` variable:

   ```hcl
   vms = {
     splunk = {
       vm_id = 110
       name  = "splunk"
       # ... configuration
     }
   }
   ```

## Usage

### Commands

```bash
# Initialize
terragrunt run-all init

# Validate configuration
terragrunt validate

# Plan changes
terragrunt plan

# Apply changes
terragrunt apply

# Format code
terragrunt fmt
```

## 📁 Repository Structure

| File | Purpose |
|------|---------|
| `main.tf` | Core resource definitions |
| `provider.tf` | Terraform provider configurations |
| `variables.tf` | Input variable definitions |
| `terragrunt.hcl` | Remote state management |
| `container.tf` | Container resources |
| `splunk.tf` | Splunk infrastructure |
| `syslog.tf` | Syslog server configuration |

## 🔧 Configuration

### Required Variables

- `proxmox_api_endpoint` - Proxmox API URL
- `proxmox_api_token` - API authentication token
- `proxmox_ssh_private_key` - SSH key for VM access

### State Management

- **Backend**: AWS S3 + DynamoDB
- **Region**: us-east-2
- **Encryption**: Enabled

## Storage Configuration

**Note**: Proxmox datastore creation is typically done manually or via Proxmox API.
The bpg/proxmox provider doesn't support datastore creation through Terraform.
This follows Proxmox best practices to manage storage at the hypervisor level.

Default datastores used:

- `local`: For ISO images, snippets, backups
- `local-lvm`: For VM disks

Additional datastores should be configured directly in Proxmox VE before running Terraform.

## VM Configuration

Both VMs (splunk and syslog) are now configured with:

- 4 CPU cores
- 2048 MB memory with ballooning
- 64 GB disk (standardized)
- Ubuntu 24.04.2 LTS
- Cloud-init integration
- SSH key authentication

## 📖 Documentation

- **[CLAUDE.md](./CLAUDE.md)** - Comprehensive setup guide and best practices
- **[PLANNING.md](./PLANNING.md)** - Current project status and planning

## 🛡️ Security

- Passwords are randomly generated and stored in Terraform state
- SSH keys are generated automatically
- All sensitive outputs are marked as sensitive
- Credentials are shared across all VMs and containers
- API tokens and SSH keys are managed securely
- State files are encrypted in S3
- Least-privilege access principles applied

## Best Practices Implemented

1. **Resource Tagging**: All resources tagged with environment and purpose
2. **Module Versioning**: Provider versions pinned for stability
3. **State Management**: Remote state with S3 backend and DynamoDB locking
4. **Variable Validation**: Input validation where appropriate
5. **Lifecycle Management**: Proper resource lifecycle configuration
6. **Error Handling**: Robust error handling and validation

## 🤝 Contributing

1. Plan changes with `terragrunt plan`
2. Review infrastructure changes carefully
3. Test in isolated environments
4. Follow conventional commit messages

## Future Enhancements

- Add support for additional VM types
- Implement backup automation
- Add monitoring and alerting configurations
- Integrate with configuration management tools

## 📄 License

This project is for internal infrastructure management.
