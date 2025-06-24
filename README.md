# Terraform Proxmox Infrastructure

This project contains Terraform/Terragrunt configurations for managing Proxmox VE infrastructure with 4 VMs:
ansible, claude, splunk, and syslog.

## Current Infrastructure Status ✅

## Successfully deployed with 5-10 minute timeouts and clean state management

### Deployed VMs

- **ansible** (ID: 130): 2 cores, 4GB RAM, 10.0.1.130 - Automation control node
- **claude** (ID: 100): 4 cores, 4GB RAM, 10.0.1.100 - Development environment
- **splunk** (ID: 110): 4 cores, 6GB RAM, 10.0.1.110 - Log analysis platform
- **syslog** (ID: 120): 2 cores, 2GB RAM, 10.0.1.120 - Centralized logging

### Infrastructure Specifications

- **Total Resources**: 12 cores, 16GB RAM (optimized for AMD Ryzen)
- **Network**: 10.0.1.0/24 with static IP assignments
- **Storage**: ZFS datastore with virtio0 interfaces (eliminates Proxmox warnings)
- **SSH Access**: Static key management via ~/.ssh/id_rsa_vm.pub
- **State Management**: AWS S3 + DynamoDB

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

### Benefits of the New Structure

1. **Eliminated Duplication**: VMs (splunk, syslog, ansible, claude) now use the same module
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
- SSH key pair (~/.ssh/id_rsa_vm)

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

1. Update `terraform.tfvars` with your Proxmox configuration:

   ```hcl
   proxmox_api_endpoint = "https://pve.example.com:8006/api2/json"
   proxmox_api_token    = "root@pve!root=example-token-here"
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

## Troubleshooting Guide

### Common Issues

#### State Lock Problems

```bash
# Check active locks
aws dynamodb scan --table-name terraform-proxmox-locks-useast2 --region us-east-2

# Force unlock
terragrunt force-unlock -force <LOCK_ID>

# Manual cleanup
aws dynamodb delete-item --table-name terraform-proxmox-locks-useast2 --region us-east-2 --key '{"LockID": {"S": "<LOCK_ID>"}}'
```

#### Timeout Issues

- All operations limited to 300-600 seconds (5-10 minutes)
- VM creation can take up to 5 minutes
- Use longer command timeouts for complex operations

#### State Drift

```bash
# Verify state vs reality
terragrunt state list
curl -k GET "https://pve.example.com:8006/api2/json/cluster/resources?type=vm"

# Clean orphaned resources
terragrunt state rm <resource>
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
- `proxmox_ssh_private_key` - SSH key for Proxmox host access

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

All VMs (splunk, syslog, ansible, claude) are configured with:

- Hardware-constrained resource allocation (AMD Ryzen 7 1700, 16GB total RAM)
- Virtio disk interfaces for optimal performance
- Ubuntu 24.04.2 LTS
- Cloud-init integration with static SSH keys
- SSH key authentication from ~/.ssh/id_rsa_vm.pub

Example allocations:

- **Example VM 1**: 4 cores, 6144MB RAM, 64GB disk (ID: 110)
- **Example VM 2**: 2 cores, 2048MB RAM, 32GB disk (ID: 120)
- **Example VM 3**: 2 cores, 4096MB RAM, 32GB disk (ID: 130)
- **Example VM 4**: 2 cores, 2048MB RAM, 32GB disk (ID: 100)

## Emergency Procedures

### Complete State Reset

```bash
# Only use if all other methods fail
terragrunt state list | xargs -I {} terragrunt state rm {}
```

### Manual VM Cleanup

```bash
# Stop VM
curl -k -X POST "https://pve.example.com:8006/api2/json/nodes/pve/qemu/<VM_ID>/status/stop"

# Delete VM
curl -k -X DELETE "https://pve.example.com:8006/api2/json/nodes/pve/qemu/<VM_ID>"
```

## Version History & Changes

### 2025-06-22 - Major Update

- **Timeout Optimization**: Reduced to 5-10 minute maximum for all operations
- **SSH Key Migration**: Moved to static key management (improved security)
- **Provider Updates**: Latest stable versions (proxmox ~> 0.78, terraform 1.12.2)
- **Performance Fix**: Changed disk interfaces to virtio0 (eliminates warnings)
- **Resource Optimization**: Adjusted allocations for hardware constraints
- **State Management**: Clean deployment with consistent S3/DynamoDB state

### Key Improvements

- Faster failure detection with 5-10 minute timeouts
- Elimination of Proxmox iothread warnings
- Optimized resource allocation within hardware limits
- Enhanced security with static SSH key approach
- Comprehensive troubleshooting procedures

## 📖 Documentation

- **[CLAUDE.md](./CLAUDE.md)** - Project-specific context and standards
- **[PLANNING.md](./PLANNING.md)** - Current project status and planning
- **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Detailed troubleshooting procedures

## 🛡️ Security

- Static SSH keys managed via cloud-init (~/.ssh/id_rsa_vm)
- Passwords configured per VM via cloud-init user accounts
- All sensitive outputs are marked as sensitive
- API tokens managed securely via Proxmox API
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
