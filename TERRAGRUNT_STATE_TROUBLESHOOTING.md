# Terragrunt State Management Reference

## Quick Reference Commands

### State Inspection

```bash
# Check current state
terragrunt state list

# View state details
terragrunt show

# Check for drift
terragrunt plan -refresh-only
```

### Backend Operations

```bash
# Initialize/reinitialize backend
terragrunt init -reconfigure

# Validate configuration
terragrunt validate

# Clean refresh state
terragrunt apply -refresh-only -auto-approve
```

### Targeted Operations

```bash
# Target specific VM
terragrunt apply -target=module.vms.proxmox_virtual_environment_vm.vms["vm-name"] -auto-approve
terragrunt destroy -target=module.vms.proxmox_virtual_environment_vm.vms["vm-name"] -auto-approve

# Target multiple resources
terragrunt apply \
  -target=module.vms.proxmox_virtual_environment_vm.vms["vm1"] \
  -target=module.vms.proxmox_virtual_environment_vm.vms["vm2"] \
  -auto-approve
```

### State Cleanup

```bash
# Remove resource from state (keeps infrastructure)
terragrunt state rm module.vms.proxmox_virtual_environment_vm.vms["vm-name"]

# Import existing resource
terragrunt import module.vms.proxmox_virtual_environment_vm.vms["vm-name"] vm-id
```

### Cache Management

```bash
# Clear terragrunt cache
rm -rf .terragrunt-cache

# Clear terraform cache
find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null
find . -name "*.tfstate*" -not -path "*/.terragrunt-cache/*" -exec rm -f {} + 2>/dev/null
```

### Emergency Procedures

#### Force Unlock (if needed)

```bash
# Check for locks first
aws dynamodb scan --table-name terraform-proxmox-locks-useast2 --region us-east-2

# Force unlock specific lock
echo "yes" | terragrunt force-unlock <LOCK_ID>
```

#### State Backup

```bash
# Backup current state
terragrunt state pull > state-backup-$(date +%Y%m%d-%H%M%S).json
```

### VM-Specific Operations

```bash
# Quick VM recreation cycle (2-5 minutes)
terragrunt destroy -target=module.vms.proxmox_virtual_environment_vm.vms["vm-name"] -auto-approve
terragrunt apply -target=module.vms.proxmox_virtual_environment_vm.vms["vm-name"] -auto-approve

# Check VM status
ssh -i <ssh-key> user@vm-ip 'sudo cloud-init status --long'
```

### Health Checks

```bash
# Pre-operation validation
terragrunt validate
terragrunt plan -refresh-only

# Post-operation verification
terragrunt state list
terragrunt show
```

### Performance Optimization

```bash
# Use parallelism for faster operations
terragrunt apply --terragrunt-parallelism=4
terragrunt destroy --terragrunt-parallelism=1  # Safer for destroy
```

## Troubleshooting Workflow

1. **Validate Configuration**: `terragrunt validate`
2. **Check State**: `terragrunt state list`
3. **Refresh State**: `terragrunt plan -refresh-only`
4. **Clear Cache if Needed**: `rm -rf .terragrunt-cache`
5. **Reinitialize**: `terragrunt init -reconfigure`
6. **Targeted Operations**: Use `-target` for specific resources
7. **Verify Results**: `terragrunt state list` and `terragrunt show`

## Best Practices

- Always use `terragrunt validate` before operations
- Use targeted operations for faster troubleshooting
- Clear cache when experiencing unexpected behavior
- Backup state before major changes
- Use `--terragrunt-parallelism=1` for destroy operations
- Monitor operation timing - refresh should complete in seconds

## File Information

- **Updated**: 2025-08-04
- **Purpose**: Essential CLI commands for Terragrunt state management
- **Scope**: Operational reference for common troubleshooting scenarios
