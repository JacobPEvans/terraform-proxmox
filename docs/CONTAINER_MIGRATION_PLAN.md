# Container Migration Plan

**Date**: 2025-12-27
**Status**: Planning
**Branch**: `feat/deploy-containers`
**Infrastructure Version**: 2.0

## Overview

Transition from VM-based infrastructure to native Proxmox containers for control nodes and log forwarding. Only Splunk indexers remain as VMs for optimal I/O performance.

## Current Infrastructure (Legacy - To Be Migrated)

Old VM-based infrastructure under Terraform state management:

| Old ID | Old Name      | Type | Purpose                    | Migration Action  |
|--------|---------------|------|----------------------------|-------------------|
| 100    | ansible       | VM   | Ansible control node       | → LXC 200         |
| 110    | claude        | VM   | Claude development         | → LXC 220/221     |
| 120    | syslog        | VM   | Centralized logging        | → LXC 210/211     |
| 130    | splunk        | VM   | Splunk management          | → LXC 205         |
| 135    | splunk-idx1   | VM   | Splunk indexer 1           | → VM 100 (renumber) |
| 136    | splunk-idx2   | VM   | Splunk indexer 2           | → VM 101 (renumber) |
| 140    | containers    | VM   | k3s/Docker (deprecated)    | REMOVE            |

## Target Architecture (v2.0)

### VMs - Splunk Indexers Only (100-101)

Managed by Terraform with enhanced production specs:

| ID  | Name         | Cores | RAM  | Storage | Purpose                    |
|-----|--------------|-------|------|---------|----------------------------|
| 100 | splunk-idx1  | 6     | 6GB  | 200GB   | Splunk indexer peer 1      |
| 101 | splunk-idx2  | 6     | 6GB  | 200GB   | Splunk indexer peer 2      |

**Terraform Management**: ✅ Full lifecycle management

### LXC Containers - Control Plane (200-209)

Created manually via Proxmox UI (unmanaged by Terraform):

| ID  | Name          | Cores | RAM  | Storage | Purpose                              |
|-----|---------------|-------|------|---------|--------------------------------------|
| 200 | ansible       | 2     | 2GB  | 64GB    | Ansible control node                 |
| 205 | splunk-mgmt   | 3     | 3GB  | 100GB   | Splunk management (all roles)        |

**Terraform Management**: Only splunk-mgmt LXC (205) managed

### LXC Containers - Log Forwarding (210-219)

Created manually via Proxmox UI (unmanaged by Terraform):

| ID  | Name          | Cores | RAM  | Storage | Purpose                              |
|-----|---------------|-------|------|---------|--------------------------------------|
| 210 | cribl-edge-1  | 2     | 2GB  | 32GB    | Cribl Edge log forwarder 1           |
| 211 | cribl-edge-2  | 2     | 2GB  | 32GB    | Cribl Edge log forwarder 2           |

### LXC Containers - AI Development (220-229)

Created manually via Proxmox UI (unmanaged by Terraform):

| ID  | Name          | Cores | RAM  | Storage | Purpose                              |
|-----|---------------|-------|------|---------|--------------------------------------|
| 220 | claude1       | 2     | 2GB  | 64GB    | Claude Code primary environment      |

**Reserved for Future**: IDs 221-225 (claude2, gemini1/2, copilot, llm)

## Migration Steps

### Phase 1: Update Terraform Configuration

1. **Update Splunk Indexer VMs** (renumber 135→100, 136→101)
   ```bash
   # Remove old indexers from state
   terragrunt state rm 'module.vms.proxmox_virtual_environment_vm.vms["splunk-idx1"]'
   terragrunt state rm 'module.vms.proxmox_virtual_environment_vm.vms["splunk-idx2"]'
   ```

2. **Update Configuration Files**
   - Update `variables.tf` with new default VM IDs (100, 101)
   - Update `terraform.tfvars.example` with new numbering
   - Update `modules/firewall/variables.tf` with new splunk_network
   - Update `container.tf` with new splunk-mgmt ID (205)

3. **Update Splunk Cluster Network Variable**
   ```hcl
   splunk_network = "192.168.1.100,192.168.1.101,192.168.1.205"
   ```

### Phase 2: Create Native LXC Containers (Proxmox UI)

#### Control Plane Containers
1. **ansible (200)** - Ansible control node
   - Container template: Ubuntu 24.04 LTS
   - Cores: 2, RAM: 2GB, Storage: 64GB
   - Network: 192.168.1.200/32
   - Copy configuration from old VM 100

2. **splunk-mgmt (205)** - Splunk management
   - Container template: Ubuntu 24.04 LTS
   - Cores: 3, RAM: 3GB, Storage: 100GB
   - Network: 192.168.1.205/32
   - Roles: Search Head, Deployment Server, License Manager, Monitoring Console, Cluster Manager

#### Log Forwarding Containers
3. **cribl-edge-1 (210)** - Primary log forwarder
   - Container template: Ubuntu 24.04 LTS
   - Cores: 2, RAM: 2GB, Storage: 32GB
   - Network: 192.168.1.210/32

4. **cribl-edge-2 (211)** - Redundant log forwarder
   - Container template: Ubuntu 24.04 LTS
   - Cores: 2, RAM: 2GB, Storage: 32GB
   - Network: 192.168.1.211/32

#### AI Development Containers
5. **claude1 (220)** - Primary Claude Code environment
   - Container template: Ubuntu 24.04 LTS
   - Cores: 2, RAM: 2GB, Storage: 64GB
   - Network: 192.168.1.220/32

**Reserved for Future**: IDs 221-225 for additional AI containers (claude2, gemini1/2, copilot, llm)

### Phase 3: Remove Old VMs from Terraform State

1. Remove old ansible VM (100):
   ```bash
   terragrunt state rm 'module.vms.proxmox_virtual_environment_vm.vms["ansible"]'
   ```

2. Remove old claude VM (110):
   ```bash
   terragrunt state rm 'module.vms.proxmox_virtual_environment_vm.vms["claude"]'
   ```

3. Remove old syslog VM (120):
   ```bash
   terragrunt state rm 'module.vms.proxmox_virtual_environment_vm.vms["syslog"]'
   ```

4. Remove old splunk VM (130):
   ```bash
   terragrunt state rm 'module.vms.proxmox_virtual_environment_vm.vms["splunk"]'
   ```

5. Remove containers VM (140):
   ```bash
   terragrunt state rm 'module.vms.proxmox_virtual_environment_vm.vms["containers"]'
   ```

### Phase 4: Import New Splunk Resources

1. Import splunk-idx1 (100):
   ```bash
   terragrunt import 'module.vms.proxmox_virtual_environment_vm.vms["splunk-idx1"]' 100
   ```

2. Import splunk-idx2 (101):
   ```bash
   terragrunt import 'module.vms.proxmox_virtual_environment_vm.vms["splunk-idx2"]' 101
   ```

3. Import splunk-mgmt container (205):
   ```bash
   terragrunt import 'module.containers.proxmox_virtual_environment_container.containers["splunk-mgmt"]' 205
   ```

### Phase 5: Verify Alignment

1. Run `terragrunt plan` - should show no changes
2. Run `terragrunt state list` - should show:
   - 2 VMs (splunk-idx1, splunk-idx2)
   - 1 Container (splunk-mgmt)
3. Verify Proxmox shows:
   - 2 Terraform-managed VMs (100, 101)
   - 1 Terraform-managed container (205)
   - 4 manually-created containers (200, 210, 211, 220)

**Note**: Resource pools are optional. The Splunk cluster (3 resources) can be organized in the "logging" pool via `.tfvars` configuration.

## Rationale

### Why Only Splunk Indexers as VMs?

**Performance**: Splunk indexers require high disk I/O throughput
- VM direct disk access provides better performance than container overlay
- 200GB per indexer sufficient for homelab retention requirements
- 6GB RAM per indexer handles search load efficiently

**Persistence**: Index data is mission-critical
- VM snapshots provide better backup/restore capabilities
- Direct ZFS pool access for optimal write performance

### Why Containers for Everything Else?

**Efficiency**: Control plane and AI services don't need VM overhead
- Faster deployment and restart times
- Lower memory footprint (no guest OS overhead)
- Better CPU/RAM density on host

**Flexibility**: Operational services benefit from container agility
- Quick destroy/recreate cycles for testing
- No state management overhead in Terraform
- Easier to replicate and scale (e.g., multiple AI environments)

### Why Splunk Management as Container?

**Resource Efficiency**: Search Head and management roles are less I/O intensive
- 3GB RAM sufficient for search coordination
- 100GB storage adequate for configurations and dashboards
- Container overhead negligible for management tasks

## Timeline

| Phase | Task                              | Status  |
|-------|-----------------------------------|---------|
| 1     | Update Terraform configuration    | pending |
| 2     | Create native containers          | pending |
| 3     | Remove old VMs from state         | pending |
| 4     | Import new Splunk resources       | pending |
| 5     | Validation and verification       | pending |

## Validation Checklist

- [ ] All 5 containers created and accessible (200, 205, 210, 211, 220)
- [ ] Ansible container (200) can connect to all Splunk resources
- [ ] Cribl containers (210, 211) configured for log forwarding to Splunk cluster
- [ ] Claude1 (220) AI development container operational
- [ ] Terraform state reflects: 2 VMs (100, 101) + 1 container (205)
- [ ] `terragrunt plan` shows no changes
- [ ] `terragrunt state list` shows correct resources
- [ ] Splunk cluster operational (all 3 nodes communicating)
- [ ] Splunk Web UI accessible at http://192.168.1.205:8000
- [ ] Indexer replication working (RF=2, SF=1)

## Network Configuration

### Splunk Cluster Network
```
192.168.1.100,192.168.1.101,192.168.1.205
```

### Cluster Manager URI
```
https://192.168.1.205:8089
```

### All Resource IPs
- **VMs**: 192.168.1.100/32, 192.168.1.101/32
- **Control**: 192.168.1.200/32, 192.168.1.205/32
- **Logging**: 192.168.1.210/32, 192.168.1.211/32
- **AI**: 192.168.1.220/32 (221-225 reserved)

## Resource Summary

### Terraform-Managed
- 2 VMs (splunk-idx1, splunk-idx2): 12 cores, 12GB RAM, 400GB storage
- 1 Container (splunk-mgmt): 3 cores, 3GB RAM, 100GB storage

### Manually-Managed Containers
- 4 containers: 6 cores, 6GB RAM, 92GB storage

### Grand Total
- **VMs**: 2 (12 cores, 12GB RAM, 400GB)
- **Containers**: 5 (9 cores, 9GB RAM, 192GB)
- **Overall**: 21 cores, 21GB RAM, 592GB storage

**Hardware Capacity**: Ryzen 7 1700 (8 cores), 16GB RAM
**Oversubscription**: 2.6x CPU, 1.3x RAM (conservative allocation)

## Related Documentation

- [INFRASTRUCTURE_NUMBERING.md](./INFRASTRUCTURE_NUMBERING.md) - Complete numbering reference
- [TERRAGRUNT_STATE_TROUBLESHOOTING.md](./TERRAGRUNT_STATE_TROUBLESHOOTING.md) - State management reference
- [splunk-cluster-spec.md](./splunk-cluster-spec.md) - Splunk cluster specification
- [secrets-management.md](./secrets-management.md) - Credential handling
