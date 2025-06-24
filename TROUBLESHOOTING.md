# Terraform/Terragrunt Troubleshooting Guide

## Common Issues and Solutions

### State Lock Issues

#### Problem: Persistent DynamoDB locks from interrupted runs

```bash
# Error: Error acquiring the state lock
# Lock Info: ID: terraform-proxmox-state-{region}-{id}/terraform-proxmox/./terraform.tfstate-md5
```

#### Solutions

1. **Check active locks:**

   ```bash
   aws dynamodb scan --table-name terraform-proxmox-locks-{region} --region us-east-2
   ```

2. **Force unlock via Terragrunt:**

   ```bash
   terragrunt force-unlock -force <LOCK_ID>
   ```

3. **Manual DynamoDB cleanup (if force-unlock fails):**

   ```bash
   aws dynamodb delete-item \
     --table-name terraform-proxmox-locks-{region} \
     --region {region} \
     --key '{"LockID": {"S": "{LOCK_ID}"}}'
   ```

### State Drift Issues

#### Problem: Resources in state but not in configuration

```bash
# Shows resources like module.security.* when security module was removed
terragrunt state list
```

#### Solution

```bash
# Remove orphaned resources from state
terragrunt state rm module.security.random_password.vm_password
terragrunt state rm module.security.tls_private_key.vm_key
```

### Timeout Issues

#### Problem: Proxmox API calls timing out during plan/apply refresh phase

Debug logs show: `module.vms.proxmox_virtual_environment_vm.vms["vm_name"]: Refreshing state...` then timeout

#### Root Cause Analysis

- Configuration loads successfully
- SSH key data source works
- VMs exist in state with specific IDs (e.g., 100, 110, 120)

#### Solutions

1. **Test API connectivity first:**

   ```bash
   curl -k -X GET "https://pve.example.com:8006/api2/json/version" \
     -H "Authorization: PVEAPIToken=root@pve!root=example-token-here" --max-time 10
   ```

2. **Emergency: Replace problematic VM resources:**

   ```bash
   # If specific VMs are causing issues, recreate them
   terragrunt state rm module.vms.proxmox_virtual_environment_vm.vms["problematic-vm"]
   terragrunt import module.vms.proxmox_virtual_environment_vm.vms["problematic-vm"] <vm-id>
   ```

### Network/Connectivity Issues

#### Problem: Cannot reach infrastructure API endpoint

#### Troubleshooting

1. **Test API connectivity:**

   ```bash
   curl -k -X GET "<api-endpoint>/version" \
     -H "Authorization: <auth-header>"
   ```

2. **Verify SSH connectivity:**

   ```bash
   ssh -i <ssh-key-path> <user>@<host>
   ```

### State vs Infrastructure Mismatch

#### Problem: Terraform state shows different resources than actual infrastructure

This occurs when operations are interrupted, leaving orphaned resources in infrastructure but not in state, or vice versa.

#### Root Cause Analysis

- **State vs Reality**: Terraform state may show empty while infrastructure has running resources
- **Interrupted Operations**: Destroy/apply operations interrupted before state update completion
- **Configuration vs Outputs**: Outputs may display from configuration variables rather than actual resources

#### Solutions

1. **Verify state consistency:**

   ```bash
   # Check Terraform state
   terragrunt state list
   
   # Check actual infrastructure via API
   curl -k GET "<api-endpoint>/resources"
   ```

2. **Manual cleanup of orphaned resources:**

   ```bash
   # Stop and remove orphaned resources via API
   curl -k DELETE "<api-endpoint>/resource/<resource-id>"
   ```

3. **Import existing resources into state:**

   ```bash
   terragrunt import <resource-type>.<resource-name> <resource-id>
   ```

### Destroy Operations

#### Problem: Incomplete destroy operations leaving orphaned resources

#### Proper Destroy Procedures

1. **Pre-Destroy Checks:**

   ```bash
   # Check for active locks
   aws dynamodb scan --table-name <lock-table> --region <region>
   
   # Verify current state
   terragrunt state list
   
   # Check infrastructure reality
   curl -k GET "<api-endpoint>/resources"
   ```

2. **Execute Destroy:**

   ```bash
   # Use appropriate timeout and parallelism
   terragrunt destroy --terragrunt-parallelism=4
   ```

3. **Post-Destroy Verification:**

   ```bash
   # Verify state is empty
   terragrunt state list
   
   # Verify infrastructure is clean
   curl -k GET "<api-endpoint>/resources"
   
   # Clean up any orphaned resources manually
   curl -k DELETE "<api-endpoint>/resource/<resource-id>"
   ```

#### Key Findings

- Infrastructure deployment configurations work correctly with proper specifications
- Timeout settings effectively prevent indefinite hangs
- Command timeouts can interrupt state updates, creating orphaned resources
- Destroy operations require careful monitoring to ensure completion

## Best Practices

### Before Running Terragrunt Commands

1. Check for existing locks: `aws dynamodb scan --table-name <lock-table> --region <region>`
2. Verify state consistency: `terragrunt state list`
3. Test connectivity: `curl -k <api-endpoint>/version`
4. Verify state vs infrastructure consistency

### During Development

1. Use targeted operations for testing: `terragrunt plan -target=<resource>`
2. Set reasonable timeouts in provider configuration

### After Interrupted Runs

1. Clean up locks immediately
2. Verify state consistency between Terraform and actual infrastructure
3. Check for orphaned resources in both state and infrastructure
4. Perform manual cleanup of orphaned resources if found
5. Implement post-operation verification checks

## Emergency Procedures

### State Inconsistency Fix

```bash
# When state shows resources but they don't exist in Proxmox
# Remove only data sources that are computed values
terragrunt state rm data.local_file.vm_ssh_public_key
```

### Complete State Reset (Use with extreme caution)

```bash
# Only if all other methods fail and you need to start fresh
# This will destroy all managed infrastructure!
terragrunt state list | xargs -I {} terragrunt state rm {}
```

### Lock Table Cleanup

```bash
# Remove all locks (use only when no legitimate operations are running)
aws dynamodb scan --table-name <lock-table> --region <region> \
  --query 'Items[].LockID.S' --output text | \
  xargs -I {} aws dynamodb delete-item \
    --table-name <lock-table> \
    --region <region> \
    --key '{"LockID": {"S": "{}"}}'
```

## Operational Best Practices

### Timeout Strategy

- Set appropriate timeouts to prevent indefinite hangs (5-15 minutes typically)
- Ensure command timeouts are longer than resource timeouts
- Monitor operations through both Terraform output and infrastructure console

### State Management

- Perform regular state consistency checks between Terraform and infrastructure
- Backup state files before major operations
- Implement automated cleanup scripts for orphaned resources

### Monitoring Requirements

- Monitor both Terraform output and infrastructure console during operations
- Use API calls to verify actual infrastructure state
- Track resource IDs and states throughout lifecycle
- Implement infrastructure drift detection
- Monitor infrastructure API for untracked resources
- Alert on state inconsistencies

## Monitoring and Maintenance

### Regular Health Checks

- Monitor DynamoDB lock table size
- Check state file consistency
- Verify API token validity
- Monitor Proxmox server resources

### Performance Optimization

- Use targeted operations when possible
- Enable parallel execution where safe
- Optimize provider timeout settings
- Monitor API response times
