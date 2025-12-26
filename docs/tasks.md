# Splunk Cluster Infrastructure - Terraform Implementation Tasks

**Spec**: `docs/splunk-cluster-spec.md`
**Branch**: `feat/initial-splunk` (Terraform-only)
**Related Branch**: `feat/initial-splunk-ansible` (Ansible automation)
**Created**: 2025-12-25
**Status**: In Progress
**Related Issues**: #27 (Terraform), #28 (Ansible)

---

## Task Summary

| Group | Total | Completed | Pending |
|-------|-------|-----------|---------|
| 1. Bug Fixes | 5 | 5 | 0 |
| 2. Terraform Modules | 4 | 0 | 4 |
| 3. Terraform Configuration | 3 | 0 | 3 |
| 4. Scripts and Tooling | 2 | 0 | 2 |
| 5. Documentation | 2 | 0 | 2 |
| 6. Terraform Validation | 3 | 0 | 3 |
| **Total** | **19** | **5** | **14** |

---

**Note**: Ansible-related tasks have been moved to the `feat/initial-splunk-ansible` branch and GitHub issue #28. This branch focuses exclusively on Terraform infrastructure code.

---

## Group 1: Bug Fixes (Priority: Critical)

These issues were identified during WIP commit review. Fix before proceeding with new work.

### 1.1 Fix Splunk Version in Ansible Defaults

- [x] **Update Splunk version from 9.4.0 to 10.0.2**
  - File: `ansible/roles/splunk/defaults/main.yml`
  - Change `splunk_version: "9.4.0"` to `splunk_version: "10.0.2"`
  - Change `splunk_build: "6b4ebe426ca6"` to `splunk_build: "e2d18b4767e9"`

### 1.2 Fix IP Subnet in terraform.tfvars.example

- [x] **Update IP format from /24 to /32 for Splunk nodes**
  - File: `terraform.tfvars.example`
  - Line 104: Change `10.0.1.135/24` to `192.168.1.135/32`
  - Line 149: Change `10.0.1.136/24` to `192.168.1.136/32`
  - Line 193: Change `10.0.1.130/24` to `192.168.1.130/32`

### 1.3 Fix Example IPs (10.0.1.x to 192.168.1.x)

- [x] **Replace real network IPs with example IPs**
  - File: `terraform.tfvars.example`
  - Replace all `10.0.1.x` with `192.168.1.x` for Splunk nodes
  - Update gateway from `10.0.1.1` to `192.168.1.1` for Splunk nodes
  - Update `management_network` from `10.0.1.0/24` to `192.168.1.0/24`
  - Update `splunk_network` to `192.168.1.130,192.168.1.135,192.168.1.136`

### 1.4 Fix Pool Name

- [x] **Change pool from "splunk" to "logging"**
  - File: `terraform.tfvars.example`
  - Line 85, 130, 179: Change `pool_id = "splunk"` to `pool_id = "logging"`
  - Lines 200-203: Change pool key from `"splunk"` to `"logging"`
  - Update pool comment to `"Logging cluster infrastructure"`

### 1.5 Fix Network Config in Ansible Defaults

- [x] **Update network references in Ansible defaults**
  - File: `ansible/roles/splunk/defaults/main.yml`
  - Line 22: Update `splunk_cluster_master_uri` to use placeholder `https://{{ splunk_mgmt_ip | default('192.168.1.130') }}:8089`
  - Consider making network-specific values overridable via inventory vars

---

## Group 2: Terraform Modules (Priority: High)

Create reusable module to eliminate DRY violation.

### 2.1 Create Splunk Indexer Module Structure

- [ ] **Create module directory and files**
  - Create: `modules/splunk-indexer/`
  - Create: `modules/splunk-indexer/main.tf`
  - Create: `modules/splunk-indexer/variables.tf`
  - Create: `modules/splunk-indexer/outputs.tf`

### 2.2 Implement Splunk Indexer Module

- [ ] **Define module with shared indexer configuration**
  - File: `modules/splunk-indexer/main.tf`
  - Use `proxmox_virtual_environment_vm` resource
  - Hardcode shared config: 4 cores, 4096MB RAM, 200GB disk
  - Parameterize: vm_id, name, ip_address, node_name, pool_id

### 2.3 Define Module Variables

- [ ] **Create variables.tf with required inputs**
  - File: `modules/splunk-indexer/variables.tf`
  - Variables: `vm_id`, `name`, `ip_address`, `gateway`, `node_name`, `pool_id`
  - Variables: `template_id`, `datastore_id`, `bridge`, `ssh_public_key`
  - Add descriptions and validation where appropriate

### 2.4 Define Module Outputs

- [ ] **Create outputs.tf for module consumers**
  - File: `modules/splunk-indexer/outputs.tf`
  - Outputs: `vm_id`, `name`, `ip_address`, `mac_address`

---

## Group 3: Terraform Configuration Updates (Priority: High)

Integrate module and clean up configuration.

### 3.1 Update main.tf to Use Splunk Indexer Module

- [ ] **Add module instantiations for splunk-idx1 and splunk-idx2**
  - File: `main.tf`
  - Add `module "splunk_idx1"` block
  - Add `module "splunk_idx2"` block
  - Pass variables from root module

### 3.2 Add Splunk Indexer Variables to Root Module

- [ ] **Define variables for splunk indexer configuration**
  - File: `variables.tf`
  - Add `splunk_indexers` variable (map of indexer configs)
  - Alternative: Use for_each with the module

### 3.3 Remove Duplicated VM Blocks from tfvars.example

- [ ] **Replace verbose VM definitions with module reference example**
  - File: `terraform.tfvars.example`
  - Remove lines 78-166 (duplicated splunk-idx1 and splunk-idx2 blocks)
  - Add simplified configuration example using the new module
  - Document module usage in comments

---

## Group 4: Scripts and Tooling (Priority: Low)

Create supporting scripts for testing and measurement.

### 4.1 Create Timing Script

- [ ] **Create terragrunt timing measurement script**
  - Create directory: `scripts/`
  - Create: `scripts/timing.sh`
  - Measure `terragrunt plan` and `terragrunt apply` execution times
  - Output results to `scripts/timing-results.txt`
  - Make script executable

### 4.2 Add timing-results.txt to .gitignore

- [ ] **Exclude timing results from version control**
  - File: `.gitignore`
  - Add `scripts/timing-results.txt` entry

---

## Group 5: Documentation (Priority: Low)

Create supporting documentation and future work tracking.

### 5.1 Update CHANGELOG.md

- [ ] **Document changes in this feature branch**
  - File: `CHANGELOG.md`
  - Add entry for Splunk cluster infrastructure
  - Document new Terraform modules and configurations

---

## Group 6: Terraform Validation (Priority: Critical)

Final validation before PR creation.

### 6.1 Run Terraform Formatting

- [ ] **Run terraform fmt**
  ```bash
  terraform fmt -recursive
  ```

### 6.2 Run Terraform Validation

- [ ] **Run terraform validate**
  ```bash
  terraform validate
  ```

### 6.3 Run Terraform Plan (Dry Run)

- [ ] **Run terraform plan**
  ```bash
  terraform plan
  ```

---

## Dependency Graph

```
Group 1 (Bug Fixes)
    |
    v
Group 2 (Terraform Modules) ---> Group 3 (Terraform Config)
    |                                  |
    v                                  v
Group 4 (Scripts) ----> Group 5 (Documentation)
                            |
                            v
                    Group 6 (Validation)
```

---

## Execution Order (Recommended)

1. **Phase 1**: Groups 1-3 (Terraform fixes and modules)
2. **Phase 2**: Group 4 (Scripts and tooling)
3. **Phase 3**: Group 5 (Documentation)
4. **Phase 4**: Group 6 (Final validation)

---

## Notes

### File Locations Summary

| Component | Path |
|-----------|------|
| Terraform root | `.` |
| Terraform modules | `modules/` |
| Terraform configs | `main.tf`, `variables.tf`, `container.tf`, `outputs.tf` |
| Terraform examples | `terraform.tfvars.example` |
| GitHub workflows | `.github/workflows/` |
| Spec document | `docs/splunk-cluster-spec.md` |

### Key Configuration Values

| Item | Correct Value |
|------|---------------|
| Splunk Version | 10.0.2 |
| Splunk Build | e2d18b4767e9 |
| Example Network | 192.168.1.0/24 |
| IP Format | /32 per host |
| Pool Name | logging |
| Management IP | 192.168.1.130 |
| Indexer 1 IP | 192.168.1.135 |
| Indexer 2 IP | 192.168.1.136 |

### Constraints

- Real `terraform.tfvars` is never committed (in .gitignore)
- Example values use 192.168.1.x/32 network
- All real infrastructure details sanitized from committed files
- Related Ansible automation in separate `feat/initial-splunk-ansible` branch

### Related Branches and Issues

- **Terraform Branch**: `feat/initial-splunk` (this branch)
- **Terraform Issue**: #27
- **Ansible Branch**: `feat/initial-splunk-ansible`
- **Ansible Issue**: #28
