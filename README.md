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
├── packer/                    # Packer templates for VM images
│   ├── splunk.pkr.hcl        # Splunk Enterprise template build
│   └── variables.pkr.hcl     # Packer variables (Doppler integration)
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
    ├── splunk-vm/             # Splunk Enterprise all-in-one VM
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── security/              # Security resources (SSH keys, passwords)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── firewall/              # Proxmox firewall rules for clusters
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
- **Splunk Infrastructure**: Packer-built Splunk Enterprise template with dedicated splunk-vm module
- **Firewall Management**: Integrated Proxmox firewall module for network isolation and security
- **Terragrunt Integration**: Backend configuration and state management
- **Latest Versions**: Terraform 1.12.2, bpg/proxmox 0.90.0, hashicorp/tls ~> 4.1 (updated 2026-01-01)

### Benefits of the Modular Structure

1. **Eliminated Duplication**: All VMs use the same module
2. **Improved Reusability**: Modules can be used across different environments
3. **Enhanced Maintainability**: Clear separation of concerns
4. **Better Security**: Static SSH key management with cloud-init
5. **Consistent Configuration**: Standardized VM settings with virtio interfaces
6. **Performance Optimized**: Virtio disk interfaces eliminate Proxmox warnings

## 🚀 Quick Start

### Prerequisites

#### Option A: Using Nix Shell (Recommended)

All tools are provided via a pre-configured Nix development shell:

```bash
# Enter the Nix shell (provides all tools below)
nix develop ~/git/nix-config/main/shells/terraform
```

See **[Nix Shell Setup Guide](./docs/nix-shell-setup.md)** for detailed instructions.

#### Option B: Manual Installation

Install the following tools manually:

- Terraform >= 1.12.2
- Terragrunt >= 0.81.10
- AWS CLI configured
- Proxmox API token
- SSH key pair
- Security scanners (tfsec, checkov, trivy)
- Ansible and molecule (for configuration management)

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

**⚠️ Security Notice**: This repository uses placeholder values (192.168.1.x) in all committed files. Never commit your real infrastructure values.

1. **Copy the example file** and replace with your real values:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your REAL IPs, hostnames, etc.
   # This file is gitignored - your real values never touch git
   ```

2. **Verify protection** before making changes:

   ```bash
   # Ensure terraform.tfvars is gitignored
   git status | grep terraform.tfvars  # Should show nothing
   ```

3. **See the complete guide**: [Managing Real Infrastructure Values](./docs/MANAGING_REAL_VALUES.md)

   This document explains:
   - How to safely maintain real vs. example values
   - Pre-commit safety checks
   - Multi-environment configurations
   - Doppler integration for secrets

## 📁 Repository Structure

| File | Purpose |
| ---- | ------- |
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
- Debian 13.2.0 (Trixie)
- Cloud-init integration with static SSH keys
- SSH key authentication from configured SSH key

**Infrastructure Summary**:
- 1 VM (Splunk Enterprise all-in-one): ID 100
- 5 LXC Containers: IDs 200, 205, 210-211, 220
- See [INFRASTRUCTURE_NUMBERING.md](./docs/INFRASTRUCTURE_NUMBERING.md) for complete details

## 📖 Documentation

### Setup & Configuration

- **[DEPLOYMENT_GUIDE.md](./docs/DEPLOYMENT_GUIDE.md)** - **START HERE**: Complete deployment walkthrough
- **[Managing Real Infrastructure Values](./docs/MANAGING_REAL_VALUES.md)** - **CRITICAL**: How to safely maintain real IPs/hostnames separate from committed code
- **[Nix Shell Setup Guide](./docs/nix-shell-setup.md)** - Comprehensive guide to using Nix shells for development
- **[OpenHands Integration](./docs/openhands-integration.md)** - Guide for integrating OpenHands autonomous AI software engineer with Nix, OrbStack, Terraform, and Kubernetes

### Infrastructure Reference

- **[INFRASTRUCTURE_NUMBERING.md](./docs/INFRASTRUCTURE_NUMBERING.md)** - Complete infrastructure map and numbering scheme
- **[Splunk Cluster Specification](./docs/splunk-cluster-spec.md)** - Detailed Splunk configuration

### Troubleshooting

- **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Operational guidance and common issues
- **[TERRAGRUNT_STATE_TROUBLESHOOTING.md](./TERRAGRUNT_STATE_TROUBLESHOOTING.md)** - Historical state management issues (resolved)

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

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
