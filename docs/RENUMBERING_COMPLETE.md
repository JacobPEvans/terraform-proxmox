# Infrastructure Renumbering - COMPLETE ✅

**Date Completed**: 2025-12-27
**Branch**: feat/deploy-containers
**Status**: ✅ All files updated and verified

---

## Summary

Successfully renumbered entire infrastructure to current scheme:
- **VMs**: Splunk indexers now at 100-101 (was 135-136)
- **Containers**: Native LXC containers at 200-229 range
- **Splunk Management**: Container at 205 (was VM at 130)

---

## Files Updated

### Terraform Configuration ✅
- [x] `variables.tf` - Updated splunk_network default
- [x] `terraform.tfvars.example` - Updated all VM IDs, IPs, and specs
- [x] `modules/firewall/variables.tf` - Updated splunk_network default

### Documentation in Worktree ✅
- [x] `README.md` - Updated VM/container configurations
- [x] `TROUBLESHOOTING.md` - Updated example references
- [x] `docs/INFRASTRUCTURE_NUMBERING.md` - Created comprehensive reference
- [x] `docs/CONTAINER_MIGRATION_PLAN.md` - Complete rewrite for renumbered infrastructure
- [x] `docs/RENUMBERING_STATUS.md` - Created tracking document
- [x] `docs/splunk-cluster-spec.md` - Updated all IDs and specs
- [x] `docs/tasks.md` - Updated all IP and ID references
- [x] `cloud-init/ansible-server-example.yml` - Updated splunk IP

### Parent Docs Directory ✅
- [x] `../../docs/CONTAINER_MIGRATION_PLAN.md` - Copied updated version
- [x] `../../docs/splunk-cluster-spec.md` - Copied updated version
- [x] `../../docs/tasks.md` - Copied updated version
- [x] `../../docs/TERRAFORM_STATE_INIT_SESSION.md` - Added renumbering notice

---

## New Infrastructure Layout

### VMs (100-101)
| ID  | Name         | Cores | RAM  | Storage | IP              |
|-----|--------------|-------|------|---------|-----------------|
| 100 | splunk-idx1  | 6     | 6GB  | 200GB   | 192.168.1.100/32|
| 101 | splunk-idx2  | 6     | 6GB  | 200GB   | 192.168.1.101/32|

### LXC Containers - Control (200-209)
| ID  | Name          | Cores | RAM  | Storage | IP              |
|-----|---------------|-------|------|---------|-----------------|
| 200 | ansible       | 2     | 2GB  | 64GB    | 192.168.1.200/32|
| 205 | splunk-mgmt   | 3     | 3GB  | 100GB   | 192.168.1.205/32|

### LXC Containers - Logging (210-219)
| ID  | Name          | Cores | RAM  | Storage | IP              |
|-----|---------------|-------|------|---------|-----------------|
| 210 | cribl-edge-1  | 2     | 2GB  | 32GB    | 192.168.1.210/32|
| 211 | cribl-edge-2  | 2     | 2GB  | 32GB    | 192.168.1.211/32|

### LXC Containers - AI Development (220-229)
| ID  | Name          | Cores | RAM  | Storage | IP              |
|-----|---------------|-------|------|---------|-----------------|
| 220 | claude1       | 2     | 2GB  | 64GB    | 192.168.1.220/32|
| 221-225 | RESERVED  | -     | -    | -       | Reserved        |

---

## Configuration Values Updated

### Splunk Cluster Network
```hcl
Old: "192.168.1.130,192.168.1.135,192.168.1.136"
New: "192.168.1.100,192.168.1.101,192.168.1.205"
```

### Splunk Cluster Manager URI
```
Old: https://192.168.1.130:8089
New: https://192.168.1.205:8089
```

### Resource Specifications

**Splunk Indexers (Enhanced)**:
- Cores: 4 → 6
- RAM: 4GB → 6GB
- Storage: 200GB (unchanged)

**Splunk Management (Enhanced)**:
- Cores: 2 → 3
- RAM: 2GB → 3GB
- Storage: 50GB → 100GB

---

## Verification Results

### Terraform Files
```bash
grep -r "192\.168\.1\.130\|192\.168\.1\.135\|192\.168\.1\.136" \
  --include="*.tf" --include="*.tfvars*" .
```
**Result**: 0 matches ✅ (All old IPs removed)

### ID References
Old VM IDs (100, 110, 120, 130, 135, 136, 140) only appear in:
- Migration documentation (intentional, showing old→new mapping)
- Historical session notes (intentional, with renumbering notice added)

---

## Resource Totals

### Terraform-Managed
- 2 VMs: 12 cores, 12GB RAM, 400GB storage
- 1 Container: 3 cores, 3GB RAM, 100GB storage

### Manually-Managed Containers
- 4 containers: 6 cores, 6GB RAM, 192GB storage

### Grand Total
- 7 resources: 21 cores, 21GB RAM, 592GB storage
- **Oversubscription**: 2.6x CPU, 1.3x RAM (conservative)

---

## Next Steps

1. **Test Terraform Configuration**
   ```bash
   terragrunt validate
   terragrunt plan
   ```

2. **Review Changes**
   ```bash
   git diff
   git status
   ```

3. **Commit Updates**
   ```bash
   git add .
   git commit -m "feat: complete infrastructure renumbering"
   ```

4. **Container Migration**
   - Follow `docs/CONTAINER_MIGRATION_PLAN.md`
   - Create LXC containers manually via Proxmox UI
   - Import Splunk resources into Terraform state

---

## Reference Documents

- `docs/INFRASTRUCTURE_NUMBERING.md` - Complete numbering reference
- `docs/CONTAINER_MIGRATION_PLAN.md` - Step-by-step migration guide
- `docs/splunk-cluster-spec.md` - Splunk cluster technical specification

---

## Safety Notes

✅ **Only updated feat/deploy-containers worktree** - Main branch untouched
✅ **Splunk storage remains 200GB** - Not increased to 300GB as requested
✅ **Only 1 AI container** - claude1 (220), others reserved for future
✅ **All Terraform files verified** - Zero old IP addresses remaining

---

**Renumbering Complete!** 🎉
