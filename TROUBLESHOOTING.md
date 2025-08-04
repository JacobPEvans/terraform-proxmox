# Terraform/Terragrunt Troubleshooting Guide

## ⚠️ Critical State Issues

**For comprehensive analysis of current DynamoDB lock abandonment and state synchronization failures, see [TERRAGRUNT_STATE_TROUBLESHOOTING.md](./TERRAGRUNT_STATE_TROUBLESHOOTING.md).**

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
   aws dynamodb scan --table-name <lock-table-name> --region <region>
   ```

2. **Force unlock via Terragrunt:**

   ```bash
   terragrunt force-unlock -force <LOCK_ID>
   ```

3. **Manual DynamoDB cleanup (if force-unlock fails):**

   ```bash
   aws dynamodb delete-item \
     --table-name <lock-table-name> \
     --region <region> \
     --key '{"LockID": {"S": "<LOCK_ID>"}}'
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
- VMs exist in state with specific IDs (e.g., 100, 110, 120, 130, 140)

#### Solutions

1. **Test API connectivity first:**

   ```bash
   curl -k -X GET "https://proxmox.example.com:8006/api2/json/version" \
     -H "Authorization: PVEAPIToken=<user>@<realm>!<token-name>=<token-value>" --max-time 10
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

## Targeted VM Operations for Fast Troubleshooting

### Problem: Full destroy/apply cycles take 30+ minutes

When troubleshooting cloud-init configurations, VM provisioning issues, or testing specific VM changes, full infrastructure cycles are  
inefficient and time-consuming.

### Solution: Targeted VM Operations

#### Single VM Operations

```bash
# Target single VM for destroy/apply (replace 'vm-name' with actual VM name)
terragrunt destroy -target=module.vms.proxmox_virtual_environment_vm.vms[\"vm-name\"] -auto-approve
terragrunt apply -target=module.vms.proxmox_virtual_environment_vm.vms[\"vm-name\"] -auto-approve

# Multiple VM targeting
terragrunt destroy \
  -target=module.vms.proxmox_virtual_environment_vm.vms[\"vm1\"] \
  -target=module.vms.proxmox_virtual_environment_vm.vms[\"vm2\"] \
  -auto-approve
```

#### Cloud-init Troubleshooting (2-5 minute cycles)

```bash
# Quick VM recreation for cloud-init testing
terragrunt destroy -target=module.vms.proxmox_virtual_environment_vm.vms[\"vm-name\"] -auto-approve
terragrunt apply -target=module.vms.proxmox_virtual_environment_vm.vms[\"vm-name\"] -auto-approve

# Test SSH and cloud-init status
ssh -i <ssh-key> <user>@<vm-ip> 'sudo cloud-init status --long'
ssh -i <ssh-key> <user>@<vm-ip> 'sudo cat /var/log/cloud-init-output.log'
```

#### Emergency VM Cleanup

```bash
# Remove VM from state if targeted destroy fails
terragrunt state rm module.vms.proxmox_virtual_environment_vm.vms[\"vm-name\"]

# Manually destroy via Proxmox host
ssh -i <ssh-key> <user>@<proxmox-host> 'qm stop <vm-id> && qm destroy <vm-id>'

# Re-create VM
terragrunt apply -target=module.vms.proxmox_virtual_environment_vm.vms[\"vm-name\"] -auto-approve
```

## Provider Timeout & Performance Issues

### Problem: Terragrunt operations hanging or timing out

Common causes include:

- Proxmox API timeouts during VM operations
- DynamoDB locks from previous interrupted operations  
- Network connectivity issues
- Resource contention on Proxmox host

### Solutions by Issue Type

#### API Connectivity Issues

```bash
# Test Proxmox API responsiveness
curl -k -X GET "https://proxmox.example.com:8006/api2/json/version" \
  -H "Authorization: PVEAPIToken=<user>@<realm>!<token-name>=<token-value>" --max-time 10

# Check basic connectivity
ping -c 3 proxmox.example.com
ssh -i <ssh-key> <user>@<proxmox-host> 'uptime'
```

#### DynamoDB Lock Management

```bash
# Check for existing locks
aws dynamodb scan --table-name <lock-table-name> --region <region>

# Force unlock specific lock
terragrunt force-unlock -force <LOCK_ID>

# Bulk lock cleanup (use with caution)
aws dynamodb scan --table-name <lock-table-name> --region <region> \
  --query 'Items[].LockID.S' --output text | \
  xargs -I {} terragrunt force-unlock -force {}
```

#### Resource Monitoring

```bash
# Check Proxmox host resources
ssh -i <ssh-key> <user>@<proxmox-host> 'free -h && df -h'

# List VMs and containers
ssh -i <ssh-key> <user>@<proxmox-host> 'qm list && pct list'
```

### Prevention & Best Practices

#### Pre-Operation Checks

```bash
# Check for locks and API connectivity before major operations
aws dynamodb scan --table-name <lock-table-name> --region <region> --query 'Count'
curl -k -s "https://proxmox.example.com:8006/api2/json/version" \
  -H "Authorization: PVEAPIToken=<token>" --max-time 10
```

#### Gradual Operations

```bash
# Phase operations instead of full destroy/apply cycles
terragrunt destroy \
  -target=module.vms.proxmox_virtual_environment_vm.vms[\"vm1\"] \
  -target=module.vms.proxmox_virtual_environment_vm.vms[\"vm2\"] \
  -auto-approve

terragrunt apply \
  -target=module.vms.proxmox_virtual_environment_vm.vms[\"vm1\"] \
  -auto-approve
```

## Best Practices

### Operational Guidelines

#### Before Operations

1. Check for existing locks
2. Verify state consistency: `terragrunt state list`
3. Test API connectivity
4. Use targeted operations for specific troubleshooting

#### After Interrupted Runs

1. Clean up locks immediately: `terragrunt force-unlock -force <LOCK_ID>`
2. Verify state vs infrastructure consistency
3. Remove orphaned resources from state if needed
4. Perform manual cleanup via API/SSH if necessary

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

### Complete Lock Table Cleanup

```bash
# Remove all locks (emergency use only when no operations are running)
aws dynamodb scan --table-name <lock-table> --region <region> \
  --query 'Items[].LockID.S' --output text | \
  xargs -I {} aws dynamodb delete-item \
    --table-name <lock-table> \
    --region <region> \
    --key '{"LockID": {"S": "{}"}}'
```

## Key Operational Principles

### Timeout Management

- Set appropriate timeouts (5-15 minutes typically)
- Monitor operations through both Terraform and infrastructure consoles
- Use targeted operations to reduce timeout exposure

### State Consistency

- Regular state vs infrastructure checks
- Backup state files before major operations
- Clean up orphaned resources promptly

### Monitoring

- Track DynamoDB lock table size
- Verify API connectivity before operations
- Monitor resource usage on Proxmox hosts
- Use targeted operations for faster troubleshooting cycles
