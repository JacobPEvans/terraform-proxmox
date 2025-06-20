# Changelog

All notable changes to the terraform-proxmox infrastructure project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive variable validation for VM configurations
- Pre-commit hooks for automated security scanning (terrascan, tflint, checkov)
- Enhanced secrets management with secure parameter store support
- locals.tf file for computed values and common expressions
- Module-level README documentation with usage examples
- terraform.tfvars.example file with security guidance
- Version constraints for all providers and Terraform

### Changed
- Enhanced SSH private key variable to support both file paths and key content
- Removed provider duplication between terragrunt.hcl and provider.tf
- Improved SSH key handling in terragrunt configuration with conditional logic

### Security
- Added comprehensive validation rules for VM IDs, CPU cores, and memory
- Enhanced SSH private key security with multiple input methods
- Implemented automated security scanning in development workflow
- Added guidance for using AWS Systems Manager Parameter Store

## [1.0.0] - 2025-06-20

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