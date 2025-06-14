# Terraform Proxmox Infrastructure

Infrastructure as Code (IaC) for managing Proxmox Virtual Environment resources using Terraform and Terragrunt.

## 🏗️ Overview

This repository provides Terraform configurations to provision and manage:
- Virtual machines and containers on Proxmox VE
- Logging infrastructure (Splunk, Syslog)
- Resource pools and networking
- SSH keys and authentication

## 🚀 Quick Start

### Prerequisites
- Terraform >= 1.0
- Terragrunt >= 0.45.0
- AWS CLI configured
- Proxmox API token

### Setup
```bash
# Initialize the environment
terragrunt init

# Plan your changes
terragrunt plan

# Apply the infrastructure
terragrunt apply
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

## 📖 Documentation

- **[CLAUDE.md](./CLAUDE.md)** - Comprehensive setup guide and best practices
- **[PLANNING.md](./PLANNING.md)** - Current project status and planning

## 🛡️ Security

- API tokens and SSH keys are managed securely
- State files are encrypted in S3
- Least-privilege access principles applied

## 🤝 Contributing

1. Plan changes with `terragrunt plan`
2. Review infrastructure changes carefully
3. Test in isolated environments
4. Follow conventional commit messages

## 📄 License

This project is for internal infrastructure management.