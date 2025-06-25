# Changelog

<!-- markdownlint-disable-file MD024 -->

All notable changes to the terraform-proxmox infrastructure project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Calendar Versioning](https://calver.org/).

## 2025-06-25

### Added

- **Cloud-init Support**: Extended VM module to support custom cloud-init user_data configuration
- **Secure SSH Key Provisioning**: Implemented null_resource approach for securely copying SSH private keys to Ansible VMs
- **Comprehensive Ansible Configuration**: Created complete cloud-init script for Ansible VM with all required packages
- **Ansible Infrastructure**: Added Ansible control node configuration with inventory, playbooks, and configuration files
- **Null Provider Integration**: Added hashicorp/null provider (~> 3.2) to main Terraform configuration

### Changed

- **Ansible VM Disk Size**: Increased from 32GB to 64GB to accommodate additional packages and tools
- **VM Module Variables**: Extended variables.tf to support optional cloud_init_user_data parameter
- **Infrastructure as Code**: All VM configuration now managed through Terraform/cloud-init instead of manual setup

### Fixed

- **SSH Key Security**: Removed any potential exposure of private keys in configuration files
- **Terraform Syntax**: Corrected provisioner implementation using null_resource instead of dynamic blocks

### Planned

- **Ansible VM Deployment**: Resolve Proxmox VM 100 config conflict and complete deployment
- **Service Configuration**: Deploy rsyslog and Splunk services via Ansible automation
- **Centralized Logging**: Implement complete log forwarding and analysis infrastructure

## 2025-06-24

### Added

- **Comprehensive Troubleshooting Guide**: Consolidated destroy operation procedures, state consistency checks,
  and operational best practices into TROUBLESHOOTING.md

### Changed

- **Documentation Consolidation**: Applied DRY principles across all documentation files
- **Infrastructure Sanitization**: Removed all infrastructure-specific details from public documentation
- **CLAUDE.md Restructure**: Focused exclusively on AI-specific instructions for repository
- **PLANNING.md Cleanup**: Restructured to contain only unfinished tasks, moved completed tasks to CHANGELOG.md
- **README.md Optimization**: Eliminated duplication with TROUBLESHOOTING.md, created clean project overview
- Enhanced GitHub Actions workflow with 20-minute timeout for better CI/CD reliability
- Updated infrastructure timeout configurations from 4-minute to 5-10 minute maximums
- Improved agent timeout from 4 minutes to 15 minutes for better VM provisioning reliability

### Fixed

- Fixed markdown formatting issues across all documentation files for better readability
- Resolved Terraform provider checksum validation error by upgrading provider dependencies
- Fixed line length violations across all documentation files
- Corrected ordered list numbering in PLANNING.md for proper markdown compliance

### Removed

- **DESTROY_ANALYSIS.md**: Content consolidated into TROUBLESHOOTING.md
- **modules/security/README.md**: Deprecated module documentation removed
- **Infrastructure-specific details**: All specific IPs, hostnames, and configuration details sanitized

## 2025-06-22

### Added

- **Control VM Configuration**: Added new control VM for automation management
- **Comprehensive Troubleshooting Guide**: Created detailed troubleshooting documentation for state locks, timeouts,
  and connectivity issues
- **Hardware Optimization Documentation**: Added hardware constraints analysis and resource allocation guidance

### Changed

- **Infrastructure Modernization**: Updated all software to latest stable versions
- **SSH Key Strategy**: Migrated from security module generated keys to static cloud-init approach
- **Provider Versions**: Updated all providers to latest stable versions (proxmox ~> 0.78, tls ~> 4.0, random ~> 3.7,
  local ~> 2.5)
- **Terraform Version**: Updated minimum requirement to >= 1.12.2
- **Terragrunt Version**: Updated to latest stable v0.81.10
- **Disk Interface**: Changed all VM boot disks from scsi0 to virtio0 for optimal performance and warning elimination
- **Resource Allocation**: Optimized memory and CPU allocations within hardware constraints
- **Timeout Configuration**: Enhanced timeout configurations for faster failure detection
- **Documentation Structure**: Consolidated all duplicate documentation files into comprehensive README.md
- **Secrets Sanitization**: Replaced all sensitive tokens and usernames with example values in public documentation

### Fixed

- **Infrastructure State Management**: Performed complete infrastructure cleanup and state file optimization
- **State Lock Issues**: Resolved state locking problems and timeout conflicts
- **Proxmox Warnings**: Eliminated infrastructure warnings through virtio interface adoption

### Added

- **Ansible VM**: New VM configuration
- **VERSION_UPDATE.md**: Comprehensive documentation of version updates and configuration fixes
- **TROUBLESHOOTING.md**: Detailed troubleshooting guide for state locks, timeouts, and connectivity issues
- **Hardware Documentation**: Detailed hardware constraints analysis (8 core AMD CPU, 16GB RAM)

### Fixed

- **Proxmox Warnings**: Eliminated "iothread is only valid with virtio disk" warnings by switching to virtio0 interface
- **Cloud-init Warnings**: Resolved perl warnings in Proxmox cloud-init configuration
- **State Management**: Cleaned up orphaned state entries and resolved state drift issues
- **Provider Configuration**: Fixed invalid timeout configuration in proxmox provider

### Removed

- **Security Module**: Completely removed dynamic SSH key generation module from configuration
- **Module Dependencies**: Cleaned up references to removed security module in outputs and main configuration
- **Duplicate Documentation**: Removed DOCS.md, SYNC_SUMMARY.md, and VERSION_UPDATE.md files to eliminate redundancy

### Security

- **Static SSH Keys**: Improved security by using static SSH keys outside Terraform state management
- **Cloud-init Integration**: Secure SSH key distribution via Proxmox cloud-init functionality
- **Provider Validation**: Updated to latest provider versions with security fixes

## 2025-06-21

### Added

- Comprehensive variable validation for VM configurations
- Pre-commit hooks for automated security scanning (terrascan, tflint, checkov)
- Enhanced secrets management with secure parameter store support
- locals.tf file for computed values and common expressions
- Module-level README documentation with usage examples
- terraform.tfvars.example file with security guidance
- Version constraints for all providers and Terraform
- Documentation cleanup and standardization
- PLANNING.md preservation guidance in standardized CLAUDE.md
- SSH key infrastructure analysis and validation framework

### Changed

- Enhanced SSH private key variable to support both file paths and key content
- Removed provider duplication between terragrunt.hcl and provider.tf
- Improved SSH key handling in terragrunt configuration with conditional logic
- Simplified Git workflow documentation to reference standardized guidelines
- Repository documentation cleanup and standardization
- SSH key configuration standardized to use id_rsa instead of id_rsa_pve

### Fixed

- Updated Git Workflow Standards to remove references to non-existent .claude/ directory

### Security

- Added comprehensive validation rules for VM IDs, CPU cores, and memory
- Enhanced SSH private key security with multiple input methods
- Implemented automated security scanning in development workflow
- Added guidance for using AWS Systems Manager Parameter Store

### Planned

- SSH key infrastructure validation (verify paths and permissions)
- Ansible VM deployment using existing proxmox-vm module
- Infrastructure validation with terragrunt plan/apply
- VM provisioning testing with SSH key distribution
- Operational improvements (automated inventory, monitoring)
- Configure Ansible for VM management (Syslog, Splunk)

## 2025-06-20

### Added

- Initial Terraform/Terragrunt infrastructure for Proxmox VE
- Modular architecture with VM, container, pool, security, and storage modules
- Remote state management with S3 backend and DynamoDB locking
- Comprehensive module structure for proxmox-vm, proxmox-container, proxmox-pool, security, and storage
- Cloud-init support for automated VM provisioning
- Resource pool management for organization
- Automated SSH key and password generation
- Network configuration with bridge and VLAN support
- Storage management with multiple datastore support

### Changed

- Refactored VM creation to use dedicated module instead of inline resources
- Eliminated code duplication through modular design
- Improved variable organization and validation

### Fixed

- SSH key trimming for cloud-init compatibility
- Network interface configuration consistency
- Storage allocation and disk management

### Security

- Sensitive variable marking for passwords and SSH keys
- Lifecycle management to prevent credential regeneration
- Proper separation of public and private repository configurations
