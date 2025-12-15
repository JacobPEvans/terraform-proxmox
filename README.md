# Terraform Proxmox Infrastructure

This project contains Terraform/Terragrunt configurations for managing Proxmox VE infrastructure with virtual machines
for automation, development, logging, and service management.

## 🏗️ Overview

This repository provides Terraform configurations to provision and manage:

- Virtual machines and containers on Proxmox VE
- Automation infrastructure to manage all VMs and containers
- Logging infrastructure and centralized syslog
- Container orchestration with Kubernetes k3s and Docker
- Resource pools and networking
- SSH keys and authentication

## Architecture

The project uses a modular structure for better maintainability and reusability:

```text
terraform-proxmox/
├── main.tf                    # Root module orchestrating all components
├── variables.tf               # Root-level variable definitions
├── outputs.tf                 # Root-level outputs
├── locals.tf                  # Local value definitions
├── container.tf               # Container resource definitions
├── terraform.tfvars.example   # Variable values template
├── terragrunt.hcl            # Terragrunt configuration (generates provider.tf)
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
    ├── security/              # Security resources (SSH keys, passwords)
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
- **Latest Versions**: Terraform 1.12.2, bpg/proxmox 0.79.0, hashicorp/tls ~> 4.1 (updated 2025-07-13)

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

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and update with your infrastructure configuration:

   ```hcl
   proxmox_api_endpoint = "https://infrastructure.example.com:8006/api2/json"
   proxmox_api_token    = "user@pam!token=example-token-here"
   # ... other variables
   ```

2. Configure your VMs in the `vms` variable:

   ```hcl
   vms = {
     "ansible" = {
       vm_id            = 100
       name             = "ansible"
       description      = "Ansible control node for VM management"
       cpu_cores        = 2
       memory_dedicated = 2048
       # ... additional configuration
     }
   }
   ```

## 📁 Repository Structure

| File | Purpose |
|------|---------|
| `main.tf` | Core resource definitions and VM orchestration |
| `variables.tf` | Input variable definitions with validation |
| `locals.tf` | Local value computations and transformations |
| `container.tf` | Container resources and configurations |
| `outputs.tf` | Output value definitions |
| `terragrunt.hcl` | Remote state management (generates provider.tf) |
| `terraform.tfvars.example` | Variable values template |

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
- `local-zfs`: For VM disks (recommended for better performance)
- `local-lvm`: Alternative storage option

Additional datastores should be configured directly in Proxmox VE before running Terraform.

## VM Configuration

All VMs are configured with:

- Hardware-constrained resource allocation
- Virtio disk interfaces for optimal performance
- Ubuntu 24.04.2 LTS
- Cloud-init integration with static SSH keys
- SSH key authentication from configured SSH key

Example VM configurations:

- **ansible** (100): 2 cores, 2048MB RAM, 64GB disk - Automation control node
- **claude** (110): 2 cores, 2048MB RAM, 64GB disk - Development environment
- **syslog** (120): 2 cores, 2048MB RAM, 32GB disk - Centralized logging server
- **splunk** (130): 4 cores, 4096MB RAM, 100GB disk - Log analysis platform
- **containers** (140): 4 cores, 4096MB RAM, 100GB disk - Kubernetes k3s and Docker

## 📖 Documentation

- **[CLAUDE.md](./CLAUDE.md)** - AI-specific instructions for this repository
- **[PLANNING.md](./PLANNING.md)** - Current project status and remaining tasks
- **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - General troubleshooting procedures and operational guidance
- **[TERRAGRUNT_STATE_TROUBLESHOOTING.md](./TERRAGRUNT_STATE_TROUBLESHOOTING.md)** - 📚 **HISTORICAL**: Comprehensive analysis of resolved
  state synchronization issues
- **[CHANGELOG.md](./CHANGELOG.md)** - History of completed changes and improvements

## ✅ Current Status

**Infrastructure Ready**: Terraform state synchronization issues completely resolved. All state operations (plan, refresh, apply) work reliably
with proper S3 + DynamoDB backend connectivity. Ready for controlled infrastructure deployment and k3s/Docker container setup.

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

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
