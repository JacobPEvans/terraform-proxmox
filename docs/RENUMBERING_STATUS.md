# Infrastructure Renumbering Status

**Date**: 2025-12-27
**Branch**: feat/deploy-containers
**Status**: In Progress

---

## ✅ Completed Files

### Documentation
- [x] `docs/INFRASTRUCTURE_NUMBERING.md` - Created complete reference
- [x] `docs/CONTAINER_MIGRATION_PLAN.md` - Fully updated with v2.0 numbering
- [x] `README.md` - Updated VM/container configurations

### Specs Adjusted
- [x] Splunk indexers: 200GB storage (not 300GB)
- [x] AI containers: Only claude1 (220), reserved 221-225
- [x] Resource totals: 21 cores, 21GB RAM, 592GB storage

---

## 📋 Remaining Files in Current Worktree

### High Priority - Terraform Configuration
- [ ] `terraform.tfvars.example` - Update all VM/container IDs and IPs
- [ ] `variables.tf` - Update default splunk_network variable
- [ ] `modules/firewall/variables.tf` - Update splunk_network default
- [ ] `container.tf` - Update container definitions
- [ ] `locals.tf` - Update any hardcoded IDs

### Medium Priority - Documentation
- [ ] `docs/splunk-cluster-spec.md` - Major update needed (135/136→100/101, 130→205)
- [ ] `docs/tasks.md` - Update all ID references
- [ ] `TROUBLESHOOTING.md` - Update example IDs
- [ ] `modules/proxmox-vm/README.md` - Update example configurations

### Low Priority - Other Files
- [ ] `cloud-init/ansible-server-example.yml` - Update IP addresses if hardcoded

---

## 📋 Parent Docs Directory (../../docs/)

These files are in `/Users/jevans/git/terraform-proxmox/docs/`:

- [ ] `CONTAINER_MIGRATION_PLAN.md` - Full rewrite with v2.0 numbering
- [ ] `splunk-cluster-spec.md` - Major update (same as worktree version)
- [ ] `tasks.md` - Update all ID references
- [ ] `TERRAFORM_STATE_INIT_SESSION.md` - Update infrastructure references

---

## Key Changes Summary

### Old → New Numbering

**VMs**:
- 135 → 100 (splunk-idx1)
- 136 → 101 (splunk-idx2)

**Containers**:
- 100 → 200 (ansible)
- 130 → 205 (splunk-mgmt)
- 120 → 210/211 (syslog → cribl-edge-1/2)
- 110 → 220 (claude → claude1)
- 140 → REMOVED (containers VM deprecated)

**Reserved**:
- 221-225 (claude2, gemini1/2, copilot, llm)

### Network Addresses

**VMs**:
- 192.168.1.100/32 - splunk-idx1
- 192.168.1.101/32 - splunk-idx2

**Containers**:
- 192.168.1.200/32 - ansible
- 192.168.1.205/32 - splunk-mgmt
- 192.168.1.210/32 - cribl-edge-1
- 192.168.1.211/32 - cribl-edge-2
- 192.168.1.220/32 - claude1

### Splunk Cluster Network

Old: `192.168.1.130,192.168.1.135,192.168.1.136`
New: `192.168.1.100,192.168.1.101,192.168.1.205`

### Splunk Cluster Manager URI

Old: `https://192.168.1.130:8089`
New: `https://192.168.1.205:8089`

---

## Search & Replace Patterns

Use these patterns for bulk updates:

### IDs
```
135 → 100  (splunk-idx1)
136 → 101  (splunk-idx2)
130 → 205  (splunk-mgmt)
```

### IP Addresses
```
192.168.1.135 → 192.168.1.100
192.168.1.136 → 192.168.1.101
192.168.1.130 → 192.168.1.205
```

### Splunk Network Variable
```
Old: "192.168.1.130,192.168.1.135,192.168.1.136"
New: "192.168.1.100,192.168.1.101,192.168.1.205"
```

---

## Critical Notes

1. **DO NOT touch main branch files** - Only update feat/deploy-containers and ../../docs/
2. **Storage remains 200GB** for Splunk indexers (not 300GB)
3. **Only 1 AI container** (claude1 at 220) for initial deployment
4. **Reserve IDs 221-225** for future AI containers
5. **Splunk indexers upgraded** to 6 cores, 6GB RAM (from 4 cores, 4GB)

---

## Next Steps

1. Update terraform.tfvars.example with new numbering
2. Update variables.tf splunk_network default
3. Update modules/firewall/variables.tf
4. Update docs/splunk-cluster-spec.md (major file)
5. Update docs/tasks.md
6. Update parent docs/ directory files
7. Verify all references with grep
8. Test terraform validate and plan
