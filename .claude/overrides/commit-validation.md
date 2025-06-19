# Terraform/Terragrunt Validation Guidelines

## Repository Context
This is a Terraform/Terragrunt repository for Proxmox Virtual Environment infrastructure management.

## Validation Priorities

### High Priority Checks
- **Terraform Syntax**: Ensure `terraform validate` passes
- **Code Formatting**: Check if `terraform fmt` is needed
- **Terragrunt Configuration**: Validate terragrunt.hcl if present
- **Plan Generation**: Verify `terragrunt plan` works without errors

### Security Considerations
- **No Hardcoded Secrets**: Scan for API tokens, passwords, or sensitive data
- **Variable Usage**: Prefer variables over hardcoded values
- **State File Safety**: Ensure no state files are being committed

### Infrastructure-Specific Concerns
- **Resource Naming**: Follow consistent naming conventions
- **Network Configurations**: Validate network settings make sense
- **VM Specifications**: Ensure resource allocations are reasonable
- **Dependencies**: Check for resource dependency issues

## Suggested Validation Flow
1. Run basic terraform validation commands
2. Check for formatting issues and suggest fixes
3. Scan for sensitive data exposure
4. Verify infrastructure changes make logical sense
5. Suggest testing approach for changes

## Common Issues to Watch For
- Hardcoded IP addresses that should be variables
- API endpoints that should reference variables
- Resource conflicts or naming collisions
- State backend configuration issues
- Provider version compatibility

## Flexibility Notes
- Use discretion when validation tools aren't available
- Adapt validation based on the scope of changes
- Consider the impact level of modifications
- Balance thoroughness with practicality