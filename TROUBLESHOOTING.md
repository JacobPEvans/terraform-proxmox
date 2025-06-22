# Terraform/Terragrunt Troubleshooting Guide

## Common Issues and Solutions

### State Lock Issues

#### Problem: Persistent DynamoDB locks from interrupted runs
```bash
# Error: Error acquiring the state lock
# Lock Info: ID: terraform-proxmox-state-{region}-{id}/terraform-proxmox/./terraform.tfstate-md5
```

#### Solutions:
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

#### Solution:
```bash
# Remove orphaned resources from state
terragrunt state rm module.security.random_password.vm_password
terragrunt state rm module.security.tls_private_key.vm_key
```

### Timeout Issues

#### Problem: Proxmox API calls timing out during plan/apply refresh phase
Debug logs show: `module.vms.proxmox_virtual_environment_vm.vms["vm_name"]: Refreshing state...` then timeout

#### Root Cause Analysis:
- Configuration loads successfully
- SSH key data source works
- Timeout occurs during state refresh API calls to Proxmox
- VMs exist in state with specific IDs (e.g., 100, 110, 120)

#### Solutions:
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

#### Problem: Cannot reach Proxmox API endpoint

#### Troubleshooting:
1. **Test API connectivity:**
   ```bash
   curl -k -X GET "https://pve.example.com:8006/api2/json/version" \
     -H "Authorization: PVEAPIToken=root@pve!root=example-token-here"
   ```

2. **Verify SSH connectivity:**
   ```bash
   ssh -i ~/.ssh/id_rsa_pve root@pve.example.com
   ```

## Best Practices

### Before Running Terragrunt Commands:
1. Check for existing locks: `aws dynamodb scan --table-name terraform-proxmox-locks-{region} --region {region}`
2. Verify state consistency: `terragrunt state list`
3. Test connectivity: `curl -k <proxmox-api-endpoint>/version`

### During Development:
1. Use targeted operations for testing: `terragrunt plan -target=<resource>`
2. Run with reduced logging: `--log-level=warn`
3. Set reasonable timeouts in provider configuration

### After Interrupted Runs:
1. Clean up locks immediately
2. Verify state consistency
3. Check for orphaned resources

## Emergency Procedures

### State Inconsistency Fix:
```bash
# When state shows resources but they don't exist in Proxmox
# Remove only data sources that are computed values
terragrunt state rm data.local_file.vm_ssh_public_key
```

### Complete State Reset (Use with extreme caution):
```bash
# Only if all other methods fail and you need to start fresh
# This will destroy all managed infrastructure!
terragrunt state list | xargs -I {} terragrunt state rm {}
```

### Lock Table Cleanup:
```bash
# Remove all locks (use only when no legitimate operations are running)
aws dynamodb scan --table-name terraform-proxmox-locks-{region} --region {region} \
  --query 'Items[].LockID.S' --output text | \
  xargs -I {} aws dynamodb delete-item \
    --table-name terraform-proxmox-locks-{region} \
    --region {region} \
    --key '{"LockID": {"S": "{}"}}'
```

## Monitoring and Maintenance

### Regular Health Checks:
- Monitor DynamoDB lock table size
- Check state file consistency
- Verify API token validity
- Monitor Proxmox server resources

### Performance Optimization:
- Use targeted operations when possible
- Enable parallel execution where safe
- Optimize provider timeout settings
- Monitor API response times
