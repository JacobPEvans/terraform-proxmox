# AI Instructions for Terraform Proxmox Repository

## Repository Context

This repository manages infrastructure as code using Terraform and Terragrunt. All infrastructure-specific details and general usage instructions  
are documented in README.md. This file contains AI-specific instructions for working with this repository.

## Infrastructure Context

Real infrastructure details are maintained in a separate private repository for security.

This repository contains placeholder/example values for public repository safety. Reference the private context for actual infrastructure details:

- Hostnames and IP addresses
- API endpoints and credentials
- Network configurations
- Development environment paths

## Repository-Specific AI Guidelines

### Development Workflow

- Always run `terragrunt plan` before commits
- Validate terraform syntax with `terragrunt validate`
- Test infrastructure changes in isolated environments
- Follow conventional commit messages
- Never commit sensitive information (API tokens, passwords)
- Use feature branches for all changes

### Terraform-Specific Best Practices

- Keep resource definitions modular
- Use consistent naming conventions
- Document all variables with descriptions
- Use `sensitive = true` for secrets
- Always use remote state for production
- Regular state backups via S3 versioning
- Use consistent state key naming
- Never update VM or container configurations directly. Always use Terragrunt or Ansible

### Security Best Practices

- Never commit API tokens or passwords
- Use separate SSH keys for different environments
- Enable encryption for state files
- Implement least-privilege access
- Reference private context for actual infrastructure details

### Testing Strategy

- Use separate environments (dev/staging/prod)
- Test in isolated resource pools
- Validate with `terragrunt validate`
- Use `terragrunt plan` before all applies

### Documentation Standards

- Keep infrastructure-specific details out of public documentation
- Use generic examples and placeholders in public repositories
- Reference README.md for general infrastructure documentation
- Reference TROUBLESHOOTING.md for operational procedures
- Update PLANNING.md for unfinished tasks only
- Update CHANGELOG.md for completed tasks

### Pull Request Review Guidelines

When reviewing pull requests, focus on:

#### Security Analysis

- Check for exposed secrets, API keys, or sensitive data
- Verify SSH key management follows best practices
- Ensure no hardcoded credentials in committed files
- Review variable sensitivity markings

#### Infrastructure Best Practices

- Validate Terraform syntax and structure
- Check for proper resource naming conventions
- Verify state management patterns
- Ensure modular and reusable code

#### Code Quality

- Review variable documentation and validation
- Check for proper error handling
- Verify lifecycle management rules
- Ensure consistent formatting

#### Operational Readiness

- Validate deployment procedures
- Check for proper backup and recovery considerations
- Review monitoring and alerting setup
- Ensure documentation is updated
