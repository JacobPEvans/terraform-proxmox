# Splunk Cluster Infrastructure Specification

**Version**: 1.0.0
**Status**: In Development
**Branch**: `feat/initial-splunk`
**Created**: 2025-12-25
**Decision Maker**: Opus 4.5
**Executor**: Sonnet 4.5

---

## Executive Summary

This specification defines the implementation of a 3-node Splunk Enterprise cluster on Proxmox VE
for local log aggregation and analysis. The cluster consists of two indexer VMs and one management
LXC container, with complete network isolation to prevent outbound internet access while maintaining
internal cluster communication.

### Key Objectives

1. Deploy air-gapped Splunk cluster (no outbound internet)
2. Support development license (500MB/day ingestion)
3. Minimize resource usage (16GB RAM total on Proxmox host)
4. Provide centralized logging for homelab infrastructure
5. Maintain DRY principles in infrastructure code



---

## Architecture

### Infrastructure Summary

| Component | ID | IP | Specs | Storage | Purpose |
| --- | --- | --- | --- | --- | --- |
| splunk-mgmt (LXC) | 205 | 192.168.1.205/32 | 3 cores, 3GB RAM, 100GB | local-zfs | All-in-one management |
| splunk-idx1 (VM) | 100 | 192.168.1.100/32 | 6 cores, 6GB RAM, 200GB | local-zfs | Indexer 1 |
| splunk-idx2 (VM) | 101 | 192.168.1.101/32 | 6 cores, 6GB RAM, 200GB | local-zfs | Indexer 2 |


**Total Resource Allocation**: 15 cores, 15GB RAM, 500GB storage

### Network Configuration

**Real Environment** (from `terraform.tfvars`):

- Domain: `pve.example.com`
- Network: 192.168.1.0/24
- IP Format: /32 per host
- Gateway: 192.168.1.1
- Bridge: vmbr0
- Existing VMs: Example IDs (100, 110)

**Example Environment** (from `terraform.tfvars.example`):

- Network: 192.168.1.0/24 (placeholder values)
- IP Format: /32 per host
- Pool: "logging" (existing)

### Splunk Configuration

**Version**: Splunk Enterprise 10.0.2 (build e2d18b4767e9)
**Package Location**: `/opt/splunk-packages/splunk-10.0.2-e2d18b4767e9-linux-amd64.deb` on pve
**License**: Development (500MB/day)
**Installation Method**: Pre-staged package (air-gapped)

**Cluster Roles**:

- **splunk-mgmt**: Search Head, Deployment Server, License Manager, Monitoring Console, Cluster Manager
- **splunk-idx1**: Indexer peer
- **splunk-idx2**: Indexer peer

**Cluster Settings**:

- Replication Factor: 2
- Search Factor: 1
- Cluster Master URI: [https://192.168.1.205:8089](https://192.168.1.205:8089)


---

## Network Security

### Defense-in-Depth Firewall Strategy

**Layer 1: Proxmox Firewall** (hardware-level)

- Default policy: DROP all inbound and outbound
- Inbound ALLOW:
  - TCP 22 (SSH) from 192.168.1.0/24
  - TCP 8000 (Splunk Web) from 192.168.1.0/24
  - TCP 8089 (Management) from Splunk cluster IPs only
  - TCP 9997 (Forwarding) from Splunk cluster IPs only
  - TCP 8080, 9887 (Replication/Clustering) from Splunk cluster IPs only
- Outbound ALLOW:
  - To Splunk cluster IPs only (192.168.1.100, 101, 205)

**Layer 2: VM iptables** (OS-level)

- INPUT policy: DROP
- OUTPUT policy: DROP
- ALLOW established/related connections
- ALLOW loopback
- ALLOW SSH, Splunk ports from 192.168.1.0/24
- ALLOW outbound only to 192.168.1.0/24
- NO internet access


**Port Matrix**:

| Port | Protocol | Purpose | Allowed From |
| --- | --- | --- | --- |
| 22 | TCP | SSH | 192.168.1.0/24 |
| 8000 | TCP | Splunk Web UI | 192.168.1.0/24 |
| 8089 | TCP | Splunk Management | Splunk cluster only |
| 9997 | TCP | Splunk Forwarding | Splunk cluster only |
| 8080 | TCP | Replication | Splunk cluster only |
| 9887 | TCP | Clustering | Splunk cluster only |


---

## Secrets Management

### Approach: File-Based (Simplified)

**Rationale**: Proxmox is air-gapped with no internet access. Cloud-based secrets management (Vault, BWS) is not viable. File-based approach prioritizes simplicity.

**Local (Mac)**:
- Doppler: Stores Proxmox API credentials for Terraform execution
- SSH Keys: `~/.ssh/id_rsa_pve` (Proxmox), `~/.ssh/id_rsa_vm` (VMs)

**Proxmox Host**:
- Splunk Package: `/opt/splunk-packages/splunk-10.0.2-e2d18b4767e9-linux-amd64.deb`
- Files staged manually on Proxmox host
- No secrets service required

**Terraform State**:
- S3 Backend: `terraform-proxmox-state-useast2-${aws_account_id}`
- DynamoDB Locking: `terraform-proxmox-locks-useast2`
- Encryption: Enabled

**Splunk Credentials** (managed by Ansible role):
- Admin password: Set by Ansible during initial installation (must be provided via Ansible Vault or --extra-vars)
- Cluster secret key: Set by Ansible for cluster communication (must be provided via Ansible Vault or --extra-vars)
- **IMPORTANT**: No hardcoded defaults - credentials must be supplied securely for each deployment

---

## Implementation Phases

### Phase 1: Provider Updates ✅ COMPLETED

**Status**: Done (bpg/proxmox v0.90.0 installed)

- Updated `main.tf`: `~> 0.89`
- Updated `modules/proxmox-vm/main.tf`: `>= 0.89.0`
- Updated `modules/proxmox-container/main.tf`: `>= 0.89.0`
- Ran `terraform init -upgrade`
- Provider locked at v0.90.0

### Phase 2: Splunk Indexer Module (DRY) ❌ PENDING

**Current Problem**: Two 40+ line VM blocks duplicated in `terraform.tfvars.example`

**Solution**: Create reusable `modules/splunk-indexer/`

**Module Interface**:
```hcl
module "splunk_idx1" {
  source      = "./modules/splunk-indexer"
  vm_id       = 100
  name        = "splunk-idx1"
  ip_address  = "192.168.1.100/32"  # Example IP
  node_name   = var.proxmox_node
  pool_id     = "logging"
}
```

**Shared Configuration** (DRY inside module):
- CPU: 4 cores
- Memory: 4096 MB
- Disk: 200 GB (local-zfs, virtio, iothread=true)
- Network: vmbr0 bridge, virtio model, firewall=true
- Clone: template_id = 9000 (Debian cloud-init)
- OS: l26 (Linux 2.6+ kernel)

### Phase 3: Firewall Module ✅ COMPLETED

**Status**: Done

Created `modules/firewall/` with:
- `main.tf`: Proxmox firewall options and rules for VMs/containers
- `variables.tf`: node_name, splunk_vm_ids, splunk_container_ids, networks
- `outputs.tf`: Firewall enabled status

Integrated in `main.tf` after containers module.

### Phase 4: Terraform Configuration ⚠️ PARTIAL

**Completed**:
- ✅ Firewall variables added to `variables.tf`
- ✅ Firewall module integrated in `main.tf`
- ✅ Splunk management container added to `terraform.tfvars.example`

**Pending Fixes**:
- ❌ Remove duplicated splunk-idx1/idx2 blocks from `terraform.tfvars.example`
- ❌ Update pool from "splunk" to "logging"
- ❌ Update IP format from /24 to /32
- ❌ Update example IPs from 10.0.1.x to 192.168.1.x

### Phase 5: Ansible Splunk Role ⚠️ PARTIAL

**Completed**:
- ✅ Role structure created (`ansible/roles/splunk/`)
- ✅ Installation tasks (`tasks/install.yml`)
- ✅ Configuration tasks (`tasks/configure.yml`)
- ✅ Firewall tasks (`tasks/firewall.yml`)
- ✅ Handlers, meta, defaults

**Pending Fixes**:
- ❌ Update Splunk version from 9.4.0 to 10.0.2
- ❌ Update build from 6b4ebe426ca6 to e2d18b4767e9
- ❌ Create Molecule tests (`molecule/default/`)
- ❌ Update package_name variable

### Phase 6: Ansible Integration ❌ PENDING

**Files to Update**:
- `.github/workflows/ansible.yml`: Add "splunk" to matrix
- `ansible/playbooks/site.yml`: Add splunk_indexers and splunk_management plays
- `ansible/inventory/hosts.yml.example`: Add splunk groups

### Phase 7: Timing Script ❌ PENDING

**Create**: `scripts/timing.sh`

**Purpose**: Measure terragrunt plan/apply execution times

**Output**: `scripts/timing-results.txt`

### Phase 8: GitHub Issue ❌ PENDING

**Title**: `feat(ansible): Automate Splunk-to-Splunk cluster communication`

**Content**: Document deferred Splunk cluster peer registration, replication port configuration, and bucket policies.

---

## Validation Checklist

### Terraform
- [x] `terraform init -upgrade` passes
- [x] `terraform validate` passes
- [ ] `terraform fmt -check` passes
- [ ] `terraform plan` generates expected resources
- [ ] No DRY violations

### Ansible
- [ ] `ansible-lint` passes (production profile)
- [ ] `molecule test` passes for splunk role
- [ ] Idempotency verified (run twice, no changes)
- [ ] All tasks use FQCN (`ansible.builtin.*`)
- [ ] iptables tasks tagged `molecule-notest`

### Integration
- [ ] Firewall module resources created successfully
- [ ] Splunk indexer modules create VMs correctly
- [ ] Container firewall rules applied
- [ ] Network isolation verified (no outbound internet)

---

## Constraints and Decisions

### Hardware Constraints

**Proxmox Host**: Ryzen 7 1700 (8 cores), 16GB RAM

**Memory Allocation**:
- Original Plan: 2x 8GB indexers = 16GB (exceeds capacity)
- **Decision**: Reduced to 2x 4GB indexers + 2GB management = 10GB total
- Rationale: Leave 6GB for Proxmox host and other services

### DRY Principle

**Violation Identified**: Duplicated VM definitions in terraform.tfvars.example

**Decision**: Create `modules/splunk-indexer/` to eliminate duplication

**Enforcement**: Pre-commit hooks, code review checklist

### Secrets Management

**Decision**: File-based secrets (not Vault, BWS, Doppler on Proxmox)

**Rationale**:
- Proxmox has no internet access (air-gapped)
- Complexity of self-hosted Vault outweighs benefits for 3-node cluster
- File-based secrets sufficient for homelab use case

**Caveat**: Real terraform.tfvars never committed to git (.gitignore enforced)

### Manual Configuration

**Decision**: Splunk-to-Splunk communication configured manually by user

**Deferred to GitHub Issue**:
- Cluster peer registration
- Replication port configuration
- Bucket policies
- Search head cluster setup (if expanding beyond all-in-one)

**Rationale**: Focus on infrastructure deployment first, Splunk-specific config later

---

## Prerequisites

### Already Staged ✅

- Splunk Package: `/opt/splunk-packages/splunk-10.0.2-e2d18b4767e9-linux-amd64.deb` on pve
- Network: Real config in `terraform.tfvars` (example: 192.168.1.x/32)
- Pool: "logging" pool exists
- Domain: `pve.example.com`

### User Must Provide

1. **Cloud-init Template**: VM 9000 must exist on Proxmox with Debian 13
2. **SSH Keys**: `~/.ssh/id_rsa_vm`, `~/.ssh/id_rsa_pve` configured
3. **AWS Credentials**: For Terragrunt S3 backend
4. **Doppler**: Configured locally for Proxmox API credentials

---

## Testing Strategy

### Unit Testing

**Terraform**:
- `terraform validate`: Syntax and provider constraints
- `terraform fmt`: Code formatting
- `terraform plan`: Resource generation without apply

**Ansible**:
- `ansible-lint`: YAML syntax, best practices (production profile)
- `molecule test`: Docker-based role testing
  - Dependency resolution
  - Syntax check
  - Converge (apply role)
  - Idempotence (run twice, verify no changes)
  - Verification (check user/group created)

### Integration Testing

**Manual Verification**:
1. Run `terraform apply` in isolated environment
2. Verify VMs created with correct specs
3. Verify container created
4. Verify Proxmox firewall rules applied
5. Test SSH access to VMs
6. Test Splunk Web UI access (http://192.168.1.205:8000)
7. Verify network isolation (no outbound internet)
8. Verify cluster communication (8089, 9997, 8080, 9887 ports)

**Performance Testing**:
- Run `scripts/timing.sh` to measure terragrunt plan/apply times
- Record baseline metrics for future optimization

---

## Rollback Plan

### If Deployment Fails

**Terraform**:
1. Run `terraform destroy` to remove resources
2. Review error logs
3. Fix configuration issues
4. Re-run `terraform plan` and `terraform apply`

**Ansible**:
1. SSH into VMs manually
2. Stop Splunk service: `systemctl stop Splunkd`
3. Remove Splunk: `apt remove splunk` or `rm -rf /opt/splunk`
4. Flush iptables: `iptables -F && iptables -P INPUT ACCEPT && iptables -P OUTPUT ACCEPT`
5. Re-run Ansible playbook

**Proxmox Firewall**:
1. Disable firewall in Proxmox UI: Datacenter > Firewall > Options > Firewall: No
2. Remove firewall rules manually if needed

---

## Success Criteria

### Deployment Success

- [ ] All Terraform resources created without errors
- [ ] All Ansible tasks complete without failures
- [ ] All VMs accessible via SSH
- [ ] Splunk Web UI accessible from 192.168.1.0/24 network
- [ ] No outbound internet access (verified with curl/ping tests)
- [ ] Splunk cluster status shows all nodes online
- [ ] Log ingestion working (test with sample data)

### Code Quality

- [ ] No DRY violations
- [ ] All linting passes (terraform fmt, ansible-lint)
- [ ] Molecule tests pass
- [ ] Pre-commit hooks pass
- [ ] Conventional commit messages
- [ ] Documentation complete

---

## Future Enhancements

### Phase 2 (Post-Deployment)

1. **Automated Cluster Communication** (GitHub Issue)
   - Automate peer registration via Ansible
   - Configure replication ports
   - Set bucket policies
   - Test search head cluster setup

2. **Monitoring and Alerting**
   - Prometheus metrics exporter for Splunk
   - Grafana dashboards for cluster health
   - Alert on indexer failures

3. **Backup and Recovery**
   - Automated Splunk index backups
   - Configuration backups (etc/system/local/)
   - Disaster recovery testing

4. **Performance Optimization**
   - Index tuning (hot/warm/cold buckets)
   - Search optimization
   - Resource allocation tuning

5. **Additional Indexers**
   - Scale to 3+ indexers as needed
   - Rebalance replication factor

---

## References

### Documentation

- **Splunk Docs**: https://docs.splunk.com/
- **Proxmox VE**: https://pve.proxmox.com/wiki/
- **Terraform Proxmox Provider**: https://registry.terraform.io/providers/bpg/proxmox/
- **Ansible Best Practices**: https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html

### Internal

- **Plan File**: `/Users/jevans/.claude/plans/enchanted-sleeping-bentley.md`
- **Terraform Config**: `/Users/jevans/git/terraform-proxmox/feat/initial-splunk/`
- **Real Network Config**: `/Users/jevans/git/terraform-proxmox/terraform.tfvars` (not committed)

---

## Changelog

### v1.0.0 (2025-12-25)

**Initial specification created**

- Defined architecture (2 indexers + 1 management container)
- Documented network security (defense-in-depth firewall)
- Specified Splunk version 10.0.2
- Identified DRY violations and fixes required
- Committed WIP implementation (commit b342745)

**Status**: In Development
**Next**: Fix DRY violations, complete Ansible role, create timing script
