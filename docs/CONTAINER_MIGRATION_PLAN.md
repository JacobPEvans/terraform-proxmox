# Container Migration Plan

**Date**: 2025-12-27
**Status**: Planning
**Branch**: `feat/init-terraform-state`

## Overview

Transition from VM-based infrastructure to native Proxmox containers for control nodes and log forwarding.

## Current Infrastructure (Post-Import)

All 5 VMs are now under Terraform state management:

| ID | Name | Status | Terraform |
|----|------|--------|-----------|
| 100 | ansible | VM (CONVERT) | ✓ Imported |
| 110 | claude | VM (CONVERT) | ✓ Imported |
| 120 | syslog | VM (REPLACE) | ✓ Imported |
| 130 | splunk | VM (KEEP) | ✓ Imported |
| 140 | containers | VM (REMOVE) | ✓ Imported |

## Target Architecture

### Native Proxmox Containers (Unmanaged)

These containers will be created manually/out-of-band, NOT via Terraform (no state tracking):

1. **ansible** (from VM 100)
   - Replaces VM 100
   - Purpose: Ansible control node for VM management
   - Based on VM 100's configuration
   - Unmanaged in Terraform state

2. **ai-playground** / **claude** (from VM 110)
   - Replaces VM 110
   - Purpose: Claude Code development environment
   - Unmanaged in Terraform state

3. **cribl-edge-1** & **cribl-edge-2** (from VM 120)
   - Replace syslog VM 120 (one-to-two conversion)
   - Purpose: Log forwarding/collection via Cribl Edge
   - Two identical containers for redundancy
   - Unmanaged in Terraform state

### Terraform-Managed Resources

1. **splunk VM (130)** - KEEP
   - Remains as VM with Terraform management
   - Unchanged in scope

### To Remove

- **containers VM (140)** - REMOVE from Terraform
  - Was temporary k3s/Docker VM
  - No longer needed with native containers approach
  - Unmanaged after removal from state

## Migration Steps

### Phase 1: Create Native Containers (Proxmox UI)

1. Create ansible container from VM 100 configuration
2. Create claude/ai-playground container from VM 110 configuration
3. Create cribl-edge-1 container
4. Create cribl-edge-2 container
5. Verify all containers boot and are reachable

### Phase 2: Update Terraform State

1. Remove VM 100 from Terraform state:
   ```bash
   terragrunt state rm module.vms.proxmox_virtual_environment_vm.vms[\"ansible\"]
   ```

2. Remove VM 110 from Terraform state:
   ```bash
   terragrunt state rm module.vms.proxmox_virtual_environment_vm.vms[\"claude\"]
   ```

3. Remove VM 120 from Terraform state:
   ```bash
   terragrunt state rm module.vms.proxmox_virtual_environment_vm.vms[\"syslog\"]
   ```

4. Remove VM 140 from Terraform state:
   ```bash
   terragrunt state rm module.vms.proxmox_virtual_environment_vm.vms[\"containers\"]
   ```

### Phase 3: Update Terraform Configuration

1. Remove `ansible`, `claude`, `syslog`, `containers` from `variables.tf` default VM definitions
2. Keep only `splunk` in VMs configuration
3. Update `main.tf` to reference only splunk VM
4. Update pool definitions to align with remaining infrastructure
5. Validate and test plan shows no changes

### Phase 4: Verify Alignment

1. Run `terragrunt plan` - should show no changes
2. Run `terragrunt state list` - should show only splunk VM (pools are created on-demand via tfvars if needed)
3. Verify Proxmox shows: 1 Terraform-managed VM (splunk) + 4 unmanaged containers

**Note**: Resource pools have no default configuration in variables.tf. They can be defined via `.tfvars` files if needed for organizing VMs,
but this migration plan assumes no pools are required for the minimal infrastructure (single splunk VM).

## Rationale

**Why not manage containers via Terraform?**

- Containers are control/operational infrastructure (ephemeral)
- VMs are persistent production infrastructure
- Simpler state management - only splunk (persistent) is in Terraform
- Containers can be recreated easily without state tracking
- Proxmox UI provides adequate container management for these use cases

## Timeline

| Phase | Task | Status |
|-------|------|--------|
| 1 | Create native containers | pending |
| 2 | Update Terraform state | pending |
| 3 | Update configuration files | pending |
| 4 | Validation and cleanup | pending |

## Validation Checklist

- [ ] All 4 containers created and accessible
- [ ] Ansible container can connect to splunk VM
- [ ] Cribl containers configured for log forwarding
- [ ] Terraform state reflects: splunk VM only (no pools defined by default)
- [ ] `terragrunt plan` shows no changes
- [ ] `terragrunt state list` shows correct resources
- [ ] Production splunk VM unchanged and functioning

## Related Documentation

- [TERRAGRUNT_STATE_TROUBLESHOOTING.md](./TERRAGRUNT_STATE_TROUBLESHOOTING.md) - State management reference
- [secrets-management.md](./secrets-management.md) - Credential handling
