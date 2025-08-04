# Changelog

<!-- markdownlint-disable-file MD024 -->

All notable changes to the terraform-proxmox infrastructure project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Calendar Versioning](https://calver.org/).

## 2025-08-04

### Added

- **Containers VM**: Added new VM (ID: 140) for Kubernetes k3s and Docker container orchestration
- **Comprehensive Documentation Review**: Fixed critical inconsistencies between documentation and actual terraform.tfvars configuration
- **Enhanced VM Configuration Documentation**: Updated all documentation to reflect 5-VM infrastructure  
  (ansible=100, claude=110, syslog=120, splunk=130, containers=140)

### Changed

- **Provider Version Documentation**: Updated all module READMEs from bpg/proxmox ~> 0.78 to ~> 0.79 to match actual code
- **Architecture Documentation**: Corrected README.md file structure to show actual files (locals.tf, container.tf, security module)
- **Infrastructure State References**: Updated all troubleshooting guides to reflect current 5-VM configuration
- **Storage Configuration**: Updated default datastore documentation from local-lvm to local-zfs for accuracy
- **Variable Documentation**: Fixed proxmox_ssh_username default value in proxmox-vm module to match documentation

### Fixed

- **Documentation-Code Mismatch**: Resolved critical discrepancies between terraform.tfvars and documentation
- **IP Address Placeholders**: Verified all documentation uses proper 192.168.x.x placeholders while keeping real IPs in gitignored files
- **Module Documentation Consistency**: Fixed provider version mismatches across all module documentation

## 2025-07-13

### Added

- **Comprehensive State Troubleshooting**: Created TERRAGRUNT_STATE_TROUBLESHOOTING.md with 400+ lines of detailed analysis  
  for DynamoDB lock abandonment and state drift issues
- **Provider Version Updates**: Successfully updated hashicorp/tls provider from ~> 4.0 to ~> 4.1
- **Enhanced Force Unlock Procedures**: Documented multiple successful DynamoDB lock cleanup operations  
  with exact command patterns
- **Import Operation Analysis**: Detailed technical analysis of why VM imports consistently hang during refresh phase

### Changed

- **Terraform Provider Constraints**: Updated TLS provider version constraints in both main.tf and terragrunt.hcl
- **Backend Configuration**: Resolved terragrunt.hcl generate block conflicts with successful `init -reconfigure` operations
- **Troubleshooting Documentation**: Enhanced TROUBLESHOOTING.md with references to new comprehensive state guide

### Fixed

- **Backend Configuration Drift**: Successfully resolved backend configuration changes requiring reconfiguration
- **Configuration Validation**: All Terraform configurations pass validation after provider updates
- **Lock Table Cleanup**: Successfully cleaned up 3 abandoned DynamoDB locks from failed import operations

### Identified Issues (Unresolved)

- **State Synchronization Failure**: VM imports consistently hang during Proxmox provider refresh phase
- **Infrastructure State Mismatch**: Terraform state shows no managed VMs while 5 VMs exist in Proxmox (IDs: 100, 110, 120, 130, 140)
- **Provider Communication**: bpg/proxmox provider appears unable to reconcile existing VM configurations with Terraform expectations

## 2025-06-29

### Added

- **Targeted VM Troubleshooting**: Added comprehensive TROUBLESHOOTING.md section for single VM operations to avoid 30+ minute full cycles
- **Cloud-init Debugging Workflow**: Added 2-5 minute iteration cycles for cloud-init troubleshooting using targeted VM destroy/apply operations
- **DynamoDB Lock Management**: Enhanced lock cleanup procedures for targeted operations and bulk lock removal
- **Provider Timeout Troubleshooting**: Added detailed timeout handling for Proxmox API, network connectivity, and resource contention issues
- **Pre-flight Check Scripts**: Added comprehensive health check procedures before major infrastructure operations
- **Gradual Operations Strategy**: Added phased deployment approach for large infrastructure changes

### Fixed

- **Documentation Organization**: Updated PLANNING.md to accurately reflect current cloud-init external file integration issue
- **Troubleshooting Efficiency**: Reduced cloud-init troubleshooting cycles from 30+ minutes to 2-5 minutes using targeted operations
- **Infrastructure Status Tracking**: Enhanced project status tracking with accurate completion indicators and blocking issue identification

### Changed

- **Troubleshooting Approach**: Shifted from full infrastructure cycles to targeted VM operations for faster iteration
- **Documentation Accuracy**: Updated status tracking to reflect actual infrastructure state and known issues
- **Operational Procedures**: Enhanced emergency cleanup procedures and provider-specific timeout handling

## 2025-06-26

### Fixed

- **DynamoDB Lock Abandonment**: Resolved critical timeout issue causing abandoned state locks during long-running VM operations
- **Terraform Timeout Configuration**: Increased VM creation and clone timeouts from 900s to 1800s (30 minutes) to prevent premature operation abandonment
- **Infrastructure Deployment Reliability**: Enhanced timeout settings now allow operations to complete naturally without lock conflicts
- **Cloud-init File Reference**: Fixed hardcoded file path in main.tf that was causing Terraform failures, replaced with variable-based configuration

### Added

- **External Cloud-init Files**: Moved cloud-init configuration from inline strings to dedicated external files for better maintainability
- **Enhanced Ansible Installation**: Improved cloud-init script with complete package updates, both ansible and ansible-core packages,  
  and installation verification logging
- **Cloud-init Directory Structure**: Added organized cloud-init/ directory with ansible-server.local.yml for comprehensive Ansible server setup
- **Variable-based Cloud-init Management**: Added `ansible_cloud_init_file` variable with validation to allow flexible cloud-init file configuration

### Changed

- **Repository Security**: Enhanced .gitignore protection with explicit terraform.tfvars exclusion and additional local file patterns
- **Documentation Examples**: Updated terraform.tfvars.example with more realistic example values and external cloud-init file references
- **Cloud-init Management**: Transitioned from embedded cloud-init strings to external file-based configuration using locals and variables
- **Configuration Security**: Implemented variable-based approach ensuring sensitive local file paths never get committed to public repository

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

- **Comprehensive Troubleshooting Guide**: Consolidated destroy operation procedures, state consistency checks, and operational best practices into TROUBLESHOOTING.md

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
- **Comprehensive Troubleshooting Guide**: Created detailed troubleshooting documentation for state locks, timeouts, and connectivity issues
- **Hardware Optimization Documentation**: Added hardware constraints analysis and resource allocation guidance

### Changed

- **Infrastructure Modernization**: Updated all software to latest stable versions
- **SSH Key Strategy**: Migrated from security module generated keys to static cloud-init approach
- **Provider Versions**: Updated all providers to latest stable versions (proxmox ~> 0.78, tls ~> 4.0, random ~> 3.7, local ~> 2.5)
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
