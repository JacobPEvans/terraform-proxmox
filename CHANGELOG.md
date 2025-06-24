# Changelog

<!-- markdownlint-disable-file MD024 -->

All notable changes to the terraform-proxmox infrastructure project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Calendar Versioning](https://calver.org/).

## 2025-06-24

### Fixed

- Fixed markdown formatting issues across all documentation files for better readability
- Resolved Terraform provider checksum validation error by upgrading provider dependencies
- Fixed line length violations in CHANGELOG.md, CLAUDE.md, PLANNING.md, README.md, DESTROY_ANALYSIS.md, and
  modules/security/README.md
- Corrected ordered list numbering in PLANNING.md for proper markdown compliance

### Changed

- Enhanced GitHub Actions workflow with 20-minute timeout for better CI/CD reliability
- Updated infrastructure timeout configurations from 4-minute to 5-10 minute maximums
- Improved agent timeout from 4 minutes to 15 minutes for better VM provisioning reliability

## 2025-06-22

### Changed

- **Documentation Structure**: Consolidated all duplicate documentation files into comprehensive README.md
- **SSH Key Strategy**: Migrated from security module generated keys to static cloud-init approach using `~/.ssh/id_rsa_vm.pub`
- **Provider Versions**: Updated all providers to latest stable versions (proxmox ~> 0.78, tls ~> 4.0, random ~> 3.7,
  local ~> 2.5)
- **Terraform Version**: Updated minimum requirement to >= 1.12.2
- **Terragrunt Version**: Updated to latest stable v0.81.10
- **Disk Interface**: Changed all VM boot disks from scsi0 to virtio0 for optimal performance
- **Resource Allocation**: Adjusted Splunk VM memory from 8192MB to 6144MB to fit hardware constraints
- **Timeout Configuration**: Limited all timeouts to maximum 3 minutes for faster failure detection
- **Secrets Sanitization**: Replaced all sensitive tokens and usernames with example values in public documentation

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
