# Terraform Proxmox Infrastructure

This project contains Terraform/Terragrunt configurations for managing Proxmox VE infrastructure with virtual machines
for automation, development, logging, and service management.

## 🏗️ Overview

This repository provides Terraform configurations to provision and manage:

- Virtual machines and containers on Proxmox VE
- Automation infrastructure to manage all VMs and containers
- Logging infrastructure and centralized syslog
- Resource pools and networking
- SSH keys and authentication

## Architecture

The project uses a modular structure for better maintainability and reusability:

```text
terraform-proxmox/
├── main.tf                    # Root module orchestrating all components
├── variables.tf               # Root-level variable definitions
├── outputs.tf                 # Root-level outputs
├── provider.tf                # Provider configuration
├── terraform.tfvars          # Variable values
├── terragrunt.hcl            # Terragrunt configuration
└── modules/
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
- **Security**: Static SSH key management via cloud-init
- **Resource Pools**: Organized resource management
- **Virtual Machines**: Configurable VM deployments with virtio disk interface
- **Containers**: LXC container support (configurable)
- **Storage**: Cloud-init configuration management
- **Terragrunt Integration**: Backend configuration and state management
- **Latest Versions**: All tools and providers updated to latest stable versions

### Benefits of the Modular Structure

1. **Eliminated Duplication**: All VMs use the same module
2. **Improved Reusability**: Modules can be used across different environments
3. **Enhanced Maintainability**: Clear separation of concerns
4. **Better Security**: Static SSH key management with cloud-init
5. **Consistent Configuration**: Standardized VM settings with virtio interfaces
6. **Performance Optimized**: Virtio disk interfaces eliminate Proxmox warnings

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.12.2
- Terragrunt >= 0.81.10
- AWS CLI configured
- Proxmox API token
- SSH key pair

### Essential Commands

```bash
# Plan changes
terragrunt plan

# Deploy infrastructure
terragrunt apply -auto-approve

# Destroy infrastructure
terragrunt destroy --terragrunt-parallelism=1

# Check state
terragrunt state list

# View infrastructure
terragrunt show
```

### Configuration

1. Update `terraform.tfvars` with your infrastructure configuration:

   ```hcl
   proxmox_api_endpoint = "https://infrastructure.example.com:8006/api2/json"
   proxmox_api_token    = "user@pam!token=example-token-here"
   # ... other variables
   ```

2. Configure your VMs in the `vms` variable:

   ```hcl
   vms = {
     "example-vm" = {
       vm_id = 100
       name  = "example-vm"
       # ... configuration
     }
   }
   ```

## 📁 Repository Structure

| File | Purpose |
|------|---------|
| `main.tf` | Core resource definitions |
| `provider.tf` | Terraform provider configurations |
| `variables.tf` | Input variable definitions |
| `terragrunt.hcl` | Remote state management |
| `container.tf` | Container resources |

## 🔧 Configuration

### Required Variables

- `proxmox_api_endpoint` - Proxmox API URL
- `proxmox_api_token` - API authentication token
- `proxmox_ssh_private_key` - SSH key for Proxmox host access

### State Management

- **Backend**: AWS S3 + DynamoDB
- **Encryption**: Enabled
- **Locking**: DynamoDB table for state locking

## Storage Configuration

**Note**: Proxmox datastore creation is typically done manually or via Proxmox API.
The bpg/proxmox provider doesn't support datastore creation through Terraform.
This follows Proxmox best practices to manage storage at the hypervisor level.

Default datastores used:

- `local`: For ISO images, snippets, backups
- `local-lvm`: For VM disks

Additional datastores should be configured directly in Proxmox VE before running Terraform.

## VM Configuration

All VMs are configured with:

- Hardware-constrained resource allocation
- Virtio disk interfaces for optimal performance
- Ubuntu 24.04.2 LTS
- Cloud-init integration with static SSH keys
- SSH key authentication from configured SSH key

Example allocations:

- **Service VM 1**: 4 cores, 6144MB RAM, 64GB disk
- **Service VM 2**: 2 cores, 2048MB RAM, 32GB disk
- **Service VM 3**: 2 cores, 4096MB RAM, 32GB disk
- **Service VM 4**: 2 cores, 2048MB RAM, 32GB disk

## 📖 Documentation

- **[CLAUDE.md](./CLAUDE.md)** - AI-specific instructions for this repository
- **[PLANNING.md](./PLANNING.md)** - Current project status and remaining tasks
- **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Detailed troubleshooting procedures and operational guidance
- **[CHANGELOG.md](./CHANGELOG.md)** - History of completed changes and improvements

## 🛡️ Security

- Passwords configured per VM via cloud-init user accounts
- All sensitive outputs are marked as sensitive
- State files are encrypted in S3
- Least-privilege access principles applied
- Virtio interfaces provide secure disk access

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
