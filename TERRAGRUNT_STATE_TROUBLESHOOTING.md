# Terragrunt Remote State & DynamoDB Lock Troubleshooting Guide

## Overview

This document provides comprehensive troubleshooting guidance for persistent
Terragrunt remote state issues, DynamoDB lock problems, and state drift scenarios
encountered during provider version updates and infrastructure operations.

## Problem Summary

During the 2025-07-13 session, attempts to update Terraform providers to latest
versions and import existing Proxmox VMs into Terraform state resulted in severe
DynamoDB lock abandonment issues and state drift problems that prevented
successful infrastructure state synchronization.

### Key Issues Identified

1. **Persistent DynamoDB Lock Abandonment**: Import operations consistently
   timeout during VM refresh phase, leaving locks in DynamoDB table
2. **State vs Infrastructure Mismatch**: Terraform state shows no managed VMs
   while actual VMs exist in Proxmox (IDs: 100, 110, 120)
3. **Import Operation Failures**: VM imports hang indefinitely during refresh step
4. **Backend Configuration Conflicts**: Changes to terragrunt.hcl generate block
   causing repeated backend initialization issues

## Detailed Session Analysis

### Initial State Assessment

**Command**: `terragrunt state list`
**Result**: Only shows `data.local_file.vm_ssh_public_key`
**Expected**: Should show VMs: ansible (100), claude (110), splunk (120)

```bash
# Actual Terraform state
data.local_file.vm_ssh_public_key

# Expected state should include
module.vms.proxmox_virtual_environment_vm.vms["ansible"]
module.vms.proxmox_virtual_environment_vm.vms["claude"]
module.vms.proxmox_virtual_environment_vm.vms["splunk"]
```

### Version Update Process

#### Successful Updates

1. **Terraform Core**: Already at latest stable (1.12.2)
2. **bpg/proxmox Provider**: Confirmed at latest (0.79.0)
3. **hashicorp/tls Provider**: Updated from ~> 4.0 to ~> 4.1
4. **Backend Reconfiguration**: Successfully resolved initial backend changes

#### Update Commands Executed

```bash
# Updated version constraints in main.tf and terragrunt.hcl
# From: version = "~> 4.0"
# To:   version = "~> 4.1"

# Backend reconfiguration resolved initial conflicts
terragrunt init -reconfigure
# Status: ✅ SUCCESS - Backend configured properly

# Configuration validation passed
terragrunt validate
# Status: ✅ SUCCESS - All syntax valid
```

### DynamoDB Lock Abandonment

#### Root Cause Analysis

The import operations consistently fail during the Proxmox VM refresh phase:

```bash
# Import command pattern
terragrunt import 'module.vms.proxmox_virtual_environment_vm.vms["ansible"]' pve/100

# Execution trace shows:
data.local_file.vm_ssh_public_key: Reading...
data.local_file.vm_ssh_public_key: Read complete after 0s \
  [id=622568fee6b73b58369927278e441705d1e80063]
module.vms.proxmox_virtual_environment_vm.vms["ansible"]: Importing from ID "pve/100"...
module.vms.proxmox_virtual_environment_vm.vms["ansible"]: Import prepared!
  Prepared proxmox_virtual_environment_vm for import
module.vms.proxmox_virtual_environment_vm.vms["ansible"]: Refreshing state... [id=100]
# ⚠️ HANGS INDEFINITELY AT THIS POINT
```

#### Lock Information from Multiple Failures

**Lock ID 1**: `b71cd269-bd22-3ad0-bf1f-0157e1d622db`
- Path: `terraform-proxmox-state-useast2-${get_aws_account_id()}/terraform-proxmox/
  ./terraform.tfstate`
- Who: `jev@JarvisMobile`
- Version: `1.12.2`
- Created: `2025-07-13 00:44:19.520754859 +0000 UTC`
- Operation: `OperationTypeInvalid`

**Lock ID 2**: `75fb13c9-8a29-2805-6a72-f5c6bbad26cc`
- Path: `terraform-proxmox-state-useast2-${get_aws_account_id()}/terraform-proxmox/./terraform.tfstate`
- Who: `jev@JarvisMobile`
- Version: `1.12.2`
- Created: `2025-07-13 00:47:52.327738569 +0000 UTC`
- Operation: `OperationTypeInvalid`

**Lock ID 3**: `fab054a8-e083-7be8-2439-426513616819`
- Path: `terraform-proxmox-state-useast2-${get_aws_account_id()}/terraform-proxmox/./terraform.tfstate`
- Who: `jev@JarvisMobile`
- Version: `1.12.2`
- Created: `2025-07-13 00:51:36.20716418 +0000 UTC`
- Operation: `OperationTypeInvalid`

### Force Unlock Operations

#### Successful Unlock Commands

```bash
# Pattern used for each abandoned lock
echo "yes" | terragrunt force-unlock <LOCK_ID>

# Specific successful unlocks
echo "yes" | terragrunt force-unlock b71cd269-bd22-3ad0-bf1f-0157e1d622db
echo "yes" | terragrunt force-unlock 75fb13c9-8a29-2805-6a72-f5c6bbad26cc
echo "yes" | terragrunt force-unlock fab054a8-e083-7be8-2439-426513616819
```

**Output Pattern**:
```
Do you really want to force-unlock?
  Terraform will remove the lock on the remote state.
  This will allow local Terraform commands to modify this state, even though it
  may still be in use. Only 'yes' will be accepted to confirm.
  Enter a value:

Terraform state has been successfully unlocked!
The state has been unlocked, and Terraform commands should now be able to
obtain a new lock on the remote state.
```

### Alternative Approaches Attempted

#### Direct Terraform Operations

```bash
# Attempted direct terraform commands in cache directory
cd .terragrunt-cache/*/2wL3H7Z-e9-cUl5eYaJ4cCrHpQY
terraform import 'module.vms.proxmox_virtual_environment_vm.vms["ansible"]' pve/100
# Status: ❌ TIMEOUT - Same hanging behavior at refresh step
```

#### Lock-Disabled Operations

```bash
# Attempted import without state locking
terragrunt import -lock=false 'module.vms.proxmox_virtual_environment_vm.vms["ansible"]' pve/100
# Status: ❌ TIMEOUT - Hangs at same refresh step, indicating provider-level issue

# Successfully verified plan without locks
terragrunt plan -lock=false
# Status: ✅ SUCCESS - Shows all VMs need to be created (confirms no imports succeeded)
```

### Backend Configuration Issues

#### Terragrunt.hcl Changes Detected

During session, `terragrunt.hcl` was modified with these changes:

```diff
# remote_state block changes
remote_state {
  backend = "s3"
- #generate = {
- #  path      = "backend.tf"
- #  if_exists = "overwrite_terragrunt"
- #}
+ generate = {
+   path      = "backend.tf"
+   if_exists = "overwrite_terragrunt"
+ }
  config = {
    # ... config unchanged
  }
}
```

**Impact**: Enabled backend.tf generation, which may have contributed to backend
configuration conflicts requiring repeated `init -reconfigure` operations.

## Technical Analysis

### Provider Communication Issues

The consistent hanging during VM refresh operations suggests several possible causes:

#### 1. Proxmox API Connectivity Problems

```bash
# Test command for API verification (not executed during session)
curl -k -X GET "https://proxmox.mgmt:8006/api2/json/version" \
  -H "Authorization: PVEAPIToken=root@pam!terraform=<token>" --max-time 10
```

#### 2. VM Configuration Mismatches

The hanging refresh suggests that the actual VM configuration in Proxmox may not
match what the Terraform provider expects based on the configuration. Potential
mismatches:

- **Network Interface Configuration**: VM may have different bridge/VLAN settings
- **Disk Interface Type**: May be using different interface than defined in config
- **Cloud-init Configuration**: Existing VMs may have cloud-init settings that
  conflict with Terraform's expectations
- **CPU/Memory Settings**: Hardware allocation may differ from Terraform config

#### 3. bpg/proxmox Provider Behavior

The provider may be attempting to reconcile significant differences between the
actual VM state and expected state, causing timeout during state refresh.

### State Consistency Analysis

#### Current State vs Expected State

**Terraform State**: Empty (only data source)
**Proxmox Reality**: 3 VMs exist (100, 110, 120)
**Configuration**: Expects 3 VMs to be managed

**Plan Output Verification**:
```bash
terragrunt plan -lock=false | head -20
# Shows: Will create all 3 VMs
# Indicates: No VMs currently in state
```

#### Resource Identification

From successful plan output, expected resources:
- `module.vms.proxmox_virtual_environment_vm.vms["ansible"]` (vm_id = 100)
- `module.vms.proxmox_virtual_environment_vm.vms["claude"]` (vm_id = 110)
- `module.vms.proxmox_virtual_environment_vm.vms["splunk"]` (vm_id = 120)
- `null_resource.ansible_ssh_key_setup[0]`

## Comprehensive Resolution Strategies

### Strategy 1: VM Configuration Reconciliation

#### Step 1: Manual VM Configuration Audit

```bash
# Connect to Proxmox host and audit VM configurations
ssh -i ~/.ssh/id_rsa root@proxmox.mgmt

# Check VM configurations for each problematic VM
qm config 100  # ansible VM
qm config 110  # claude VM
qm config 120  # splunk VM

# Compare with Terraform configuration in modules/proxmox-vm/main.tf
```

#### Step 2: Targeted Configuration Alignment

Based on audit results, either:
1. **Modify VMs to match Terraform**: Update VM settings via Proxmox CLI/GUI
2. **Modify Terraform to match VMs**: Update configuration to reflect actual state

#### Step 3: Incremental Import Testing

```bash
# Test import with minimal timeout and verbose logging
TF_LOG=DEBUG terragrunt import -lock=false \
  'module.vms.proxmox_virtual_environment_vm.vms["ansible"]' pve/100 2>&1 | tee import-debug.log

# Analyze debug logs for specific hang point
grep -A 10 -B 10 "Refreshing state" import-debug.log
```

### Strategy 2: Clean State Rebuild

#### Step 1: Complete State Evacuation

```bash
# Remove all resources from state (preserves actual infrastructure)
terragrunt state list | xargs -I {} terragrunt state rm {}

# Verify empty state
terragrunt state list
# Should return empty result
```

#### Step 2: Manual Infrastructure Cleanup

```bash
# Connect to Proxmox and cleanly shut down VMs
ssh -i ~/.ssh/id_rsa root@proxmox.mgmt
qm stop 100 && qm destroy 100
qm stop 110 && qm destroy 110
qm stop 120 && qm destroy 120

# Verify cleanup
qm list
```

#### Step 3: Fresh Infrastructure Deployment

```bash
# Deploy fresh infrastructure
terragrunt plan
terragrunt apply -auto-approve
```

### Strategy 3: Provider-Level Debugging

#### Step 1: Enable Maximum Terraform Debugging

```bash
# Set comprehensive debug logging
export TF_LOG=TRACE
export TF_LOG_PATH=./terraform-debug.log

# Attempt import with full logging
terragrunt import -lock=false \
  'module.vms.proxmox_virtual_environment_vm.vms["ansible"]' pve/100
```

#### Step 2: Analyze Provider Communication

```bash
# Extract provider API calls from debug log
grep -i "proxmox" terraform-debug.log | grep -E "(GET|POST|PUT|DELETE)"

# Look for hung API calls or error responses
grep -A 20 -B 5 "timeout\|error\|failed" terraform-debug.log
```

#### Step 3: Network-Level Debugging

```bash
# Test network connectivity during import
# In separate terminal during import operation:
while true; do
  curl -k -s -w "%{time_total}\n" -o /dev/null \
    "https://proxmox.mgmt:8006/api2/json/version" \
    -H "Authorization: PVEAPIToken=root@pam!terraform=<token>"
  sleep 2
done
```

### Strategy 4: Backend Migration

#### Step 1: Backup Current State

```bash
# Download current state for backup
terragrunt state pull > state-backup-$(date +%Y%m%d-%H%M%S).json
```

#### Step 2: Migrate to Fresh Backend

```bash
# Temporarily modify terragrunt.hcl to use new S3 key path
# Change: key = "terraform-proxmox/${path_relative_to_include()}/terraform.tfstate"
# To:     key = "terraform-proxmox-clean/${path_relative_to_include()}/terraform.tfstate"

# Initialize with new backend
terragrunt init -migrate-state
```

#### Step 3: Import into Clean State

```bash
# Attempt imports with fresh state backend
terragrunt import 'module.vms.proxmox_virtual_environment_vm.vms["ansible"]' pve/100
```

## Prevention Strategies

### 1. Timeout Configuration

```hcl
# Add to provider configuration in terragrunt.hcl
generate "provider" {
  path      = "provider_override.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = ">= 1.12.2"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.79"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  # Add explicit timeouts
  timeout = 300  # 5 minutes max per API call
}
EOF
}
```

### 2. Pre-Operation Health Checks

```bash
#!/bin/bash
# pre-terraform-check.sh

echo "=== Pre-Terraform Health Check ==="

# Check DynamoDB locks
echo "Checking for existing DynamoDB locks..."
LOCKS=$(aws dynamodb scan --table-name terraform-proxmox-locks-useast2 \
  --region us-east-2 --query 'Count' --output text)
if [ "$LOCKS" -gt 0 ]; then
  echo "⚠️  WARNING: $LOCKS existing locks found"
  aws dynamodb scan --table-name terraform-proxmox-locks-useast2 \
    --region us-east-2 --query 'Items[].LockID.S' --output table
  exit 1
fi

# Check Proxmox API connectivity
echo "Testing Proxmox API connectivity..."
if ! curl -k -s --max-time 10 \
  "https://proxmox.mgmt:8006/api2/json/version" \
  -H "Authorization: PVEAPIToken=root@pam!terraform=$PROXMOX_API_TOKEN" \
  > /dev/null; then
  echo "❌ ERROR: Cannot reach Proxmox API"
  exit 1
fi

# Check current state size
echo "Checking Terraform state..."
STATE_RESOURCES=$(terragrunt state list | wc -l)
echo "✅ Current state contains $STATE_RESOURCES resources"

echo "✅ All health checks passed"
```

### 3. Incremental Operation Strategy

```bash
# Instead of bulk imports, use sequential single-resource operations
terragrunt import 'module.vms.proxmox_virtual_environment_vm.vms["ansible"]' pve/100
# Wait for completion and verify before next
terragrunt state list | grep ansible

terragrunt import 'module.vms.proxmox_virtual_environment_vm.vms["claude"]' pve/110
# Verify before continuing
terragrunt state list | grep claude

terragrunt import 'module.vms.proxmox_virtual_environment_vm.vms["splunk"]' pve/120
# Final verification
terragrunt state list
```

## Emergency Recovery Procedures

### Complete DynamoDB Lock Table Cleanup

```bash
#!/bin/bash
# emergency-lock-cleanup.sh
# ⚠️  USE ONLY WHEN NO TERRAFORM OPERATIONS ARE RUNNING

echo "⚠️  EMERGENCY: Cleaning ALL DynamoDB locks"
echo "Press CTRL+C within 10 seconds to abort..."
sleep 10

TABLE="terraform-proxmox-locks-useast2"
REGION="us-east-2"

# Get all lock IDs
LOCK_IDS=$(aws dynamodb scan --table-name "$TABLE" --region "$REGION" \
  --query 'Items[].LockID.S' --output text)

if [ -z "$LOCK_IDS" ]; then
  echo "✅ No locks found to clean"
  exit 0
fi

echo "Found locks to remove:"
echo "$LOCK_IDS"

# Remove each lock
echo "$LOCK_IDS" | tr '\t' '\n' | while read -r LOCK_ID; do
  if [ -n "$LOCK_ID" ]; then
    echo "Removing lock: $LOCK_ID"
    aws dynamodb delete-item \
      --table-name "$TABLE" \
      --region "$REGION" \
      --key "{\"LockID\": {\"S\": \"$LOCK_ID\"}}"
  fi
done

echo "✅ Emergency lock cleanup completed"
```

### State File Recovery

```bash
# If state becomes completely corrupted
# 1. Backup any existing state
terragrunt state pull > corrupted-state-backup.json

# 2. Clear state completely
terragrunt state list | xargs -I {} terragrunt state rm {}

# 3. Manually clean infrastructure if needed
ssh root@proxmox.mgmt 'qm list'
# Manually destroy VMs if they should not exist

# 4. Rebuild from configuration
terragrunt plan
terragrunt apply -auto-approve
```

## Monitoring and Detection

### Automated Lock Detection

```bash
#!/bin/bash
# monitor-locks.sh

while true; do
  LOCK_COUNT=$(aws dynamodb scan \
    --table-name terraform-proxmox-locks-useast2 \
    --region us-east-2 \
    --query 'Count' --output text)

  if [ "$LOCK_COUNT" -gt 0 ]; then
    echo "$(date): ⚠️  $LOCK_COUNT active locks detected"
    aws dynamodb scan \
      --table-name terraform-proxmox-locks-useast2 \
      --region us-east-2 \
      --query 'Items[].[LockID.S,Operation.S,Who.S,Created.S]' \
      --output table
  else
    echo "$(date): ✅ No locks active"
  fi

  sleep 30
done
```

### State Drift Detection

```bash
#!/bin/bash
# detect-state-drift.sh

echo "=== State Drift Detection ==="

# Get expected resources from configuration
EXPECTED_VMS=("ansible" "claude" "splunk")

# Get actual state
echo "Current Terraform state:"
terragrunt state list

echo -e "\nExpected VMs in configuration:"
printf '%s\n' "${EXPECTED_VMS[@]}"

# Check Proxmox reality
echo -e "\nActual VMs in Proxmox:"
ssh root@proxmox.mgmt 'qm list | grep -E "(100|110|120)"'

echo -e "\n=== Drift Analysis ==="
for vm in "${EXPECTED_VMS[@]}"; do
  if terragrunt state list | grep -q "vms\[\"$vm\"\]"; then
    echo "✅ $vm: Present in state"
  else
    echo "❌ $vm: Missing from state"
  fi
done
```

## Lessons Learned

### 1. Import Operation Reliability

- **Issue**: VM imports consistently fail during refresh phase
- **Root Cause**: Likely configuration mismatch between actual VMs and Terraform expectations
- **Prevention**: Always audit VM configurations before import operations

### 2. DynamoDB Lock Management

- **Issue**: Timeouts leave persistent locks that block subsequent operations
- **Root Cause**: Import operations hanging without proper timeout handling
- **Prevention**: Implement pre-operation lock checks and automated cleanup

### 3. Backend Configuration Stability

- **Issue**: Changes to terragrunt.hcl generate blocks cause backend reinitializations
- **Root Cause**: Uncommitted generate block changes
- **Prevention**: Careful version control of terragrunt.hcl modifications

### 4. Debugging Strategy

- **Issue**: Limited visibility into provider-level communication failures
- **Root Cause**: Insufficient logging and timeout configuration
- **Prevention**: Enhanced debug logging and timeout configuration

## Next Steps and Recommendations

### Immediate Actions Required

1. **Resolve Current State Drift**: Choose and execute one of the resolution strategies
2. **Implement Health Checks**: Deploy pre-operation verification scripts
3. **Add Monitoring**: Implement automated lock and drift detection
4. **Document Procedures**: Create runbooks for common failure scenarios

### Long-term Improvements

1. **Provider Configuration**: Add explicit timeout and retry configuration
2. **State Management**: Implement automated state backup procedures
3. **Infrastructure Testing**: Create test environments for safe experimentation
4. **CI/CD Integration**: Add automated drift detection to deployment pipelines

### Alternative Solutions

If import operations continue to fail:

1. **Fresh Infrastructure Approach**: Destroy existing VMs and recreate via Terraform
2. **Hybrid Management**: Manage some resources outside Terraform temporarily
3. **Provider Alternatives**: Evaluate other Proxmox providers or direct API integration
4. **Simplified Configuration**: Reduce VM complexity to facilitate successful imports

## Conclusion

The session revealed significant challenges with Terraform state management when
dealing with existing infrastructure and provider updates. The primary issue appears
to be a mismatch between actual VM configurations and Terraform expectations, causing
import operations to hang during the refresh phase.

While provider versions were successfully updated and configuration validation passed,
the core issue of state synchronization remains unresolved. The comprehensive
troubleshooting strategies outlined above provide multiple paths to resolution,
ranging from configuration reconciliation to complete infrastructure rebuild.

Success will require careful analysis of the actual VM configurations in Proxmox
compared to Terraform expectations, followed by systematic alignment using one of
the proven resolution strategies.

## File Information

- **Created**: 2025-07-13
- **Purpose**: Comprehensive troubleshooting guide for Terragrunt state issues
- **Scope**: Session-specific problem analysis and general troubleshooting procedures
- **Status**: Active troubleshooting document
