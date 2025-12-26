# Splunk Cluster Infrastructure - Implementation Tasks

**Spec**: `docs/splunk-cluster-spec.md`
**Branch**: `feat/initial-splunk`
**Created**: 2025-12-25
**Status**: In Progress

---

## Task Summary

| Group | Total | Completed | Pending |
|-------|-------|-----------|---------|
| 1. Bug Fixes | 5 | 5 | 0 |
| 2. Terraform Modules | 4 | 0 | 4 |
| 3. Terraform Configuration | 3 | 0 | 3 |
| 4. Ansible Role Fixes | 3 | 2 | 1 |
| 5. Ansible Molecule Tests | 4 | 0 | 4 |
| 6. Ansible Integration | 3 | 0 | 3 |
| 7. CI/CD Updates | 2 | 0 | 2 |
| 8. Scripts and Tooling | 2 | 0 | 2 |
| 9. Documentation | 2 | 0 | 2 |
| 10. Validation | 6 | 0 | 6 |
| **Total** | **34** | **7** | **27** |

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

## Group 4: Ansible Role Fixes (Priority: High)

Fix configuration issues in the splunk role.

### 4.1 Update Package Name Variable

- [x] **Ensure package_name matches version 10.0.2**
  - File: `ansible/roles/splunk/defaults/main.yml`
  - Verify `splunk_package_name` template is correct after version update

### 4.2 Tag iptables Tasks for Molecule Skip

- [x] **Add molecule-notest tag to firewall tasks**
  - File: `ansible/roles/splunk/tasks/firewall.yml`
  - Add `tags: [molecule-notest]` to iptables tasks
  - Docker containers cannot manage iptables rules

### 4.3 Review Task FQCN Compliance

- [ ] **Verify all tasks use Fully Qualified Collection Names**
  - Files: `ansible/roles/splunk/tasks/*.yml`
  - Ensure modules use `ansible.builtin.*` prefix
  - Check for any shorthand module names

---

## Group 5: Ansible Molecule Tests (Priority: High)

Create comprehensive Molecule test configuration.

### 5.1 Create molecule.yml Configuration

- [ ] **Create Molecule configuration for splunk role**
  - File: `ansible/roles/splunk/molecule/default/molecule.yml`
  - Use Docker driver with `geerlingguy/docker-ubuntu2404-ansible:latest`
  - Configure dependency to use `../../requirements.yml`
  - Set roles_path to find common role dependency
  - Enable idempotence testing

### 5.2 Create converge.yml Playbook

- [ ] **Create playbook to apply splunk role**
  - File: `ansible/roles/splunk/molecule/default/converge.yml`
  - Apply splunk role to test instance
  - Include common role as dependency
  - Set appropriate test variables (use mock package path)

### 5.3 Create verify.yml Playbook

- [ ] **Create verification tests**
  - File: `ansible/roles/splunk/molecule/default/verify.yml`
  - Verify splunk user exists
  - Verify splunk group exists
  - Verify /opt/splunk directory structure
  - Note: Cannot verify service in Docker container

### 5.4 Create prepare.yml (Optional)

- [ ] **Create pre-test preparation if needed**
  - File: `ansible/roles/splunk/molecule/default/prepare.yml`
  - Create mock package directory if needed for testing
  - Install any test dependencies

---

## Group 6: Ansible Integration (Priority: Medium)

Integrate splunk role into project playbooks and inventory.

### 6.1 Update site.yml with Splunk Plays

- [ ] **Add Splunk indexer and management plays**
  - File: `ansible/playbooks/site.yml`
  - Add play for `splunk_indexers` group with `splunk_role: indexer`
  - Add play for `splunk_management` group with `splunk_role: all_in_one`

### 6.2 Update hosts.yml.example

- [ ] **Add Splunk cluster host groups**
  - File: `ansible/inventory/hosts.yml.example`
  - Add `splunk_indexers` group with `splunk-idx1` and `splunk-idx2`
  - Add `splunk_management` group with `splunk-mgmt`
  - Use example IPs (192.168.1.x)

### 6.3 Create Splunk Group Variables

- [ ] **Create group_vars files for Splunk hosts**
  - Create: `ansible/inventory/group_vars/splunk_indexers.yml`
  - Create: `ansible/inventory/group_vars/splunk_management.yml`
  - Set role-specific variables per group

---

## Group 7: CI/CD Updates (Priority: Medium)

Update GitHub Actions workflows for splunk role testing.

### 7.1 Add Splunk Role to Molecule Matrix

- [ ] **Update ansible.yml workflow**
  - File: `.github/workflows/ansible.yml`
  - Add `splunk` to the `role` matrix (line 35)
  - Result: `role: [common, splunk]`

### 7.2 Verify Workflow Dependencies

- [ ] **Ensure workflow installs required collections**
  - File: `.github/workflows/ansible.yml`
  - Verify ansible.posix and community.general are installed
  - Add any additional collections needed by splunk role

---

## Group 8: Scripts and Tooling (Priority: Low)

Create supporting scripts for testing and measurement.

### 8.1 Create Timing Script

- [ ] **Create terragrunt timing measurement script**
  - Create directory: `scripts/`
  - Create: `scripts/timing.sh`
  - Measure `terragrunt plan` and `terragrunt apply` execution times
  - Output results to `scripts/timing-results.txt`
  - Make script executable

### 8.2 Add timing-results.txt to .gitignore

- [ ] **Exclude timing results from version control**
  - File: `.gitignore`
  - Add `scripts/timing-results.txt` entry

---

## Group 9: Documentation (Priority: Low)

Create supporting documentation and future work tracking.

### 9.1 Create GitHub Issue for Cluster Communication

- [ ] **Draft issue for deferred Splunk configuration**
  - Title: `feat(ansible): Automate Splunk-to-Splunk cluster communication`
  - Content should include:
    - Cluster peer registration automation
    - Replication port configuration (8080)
    - Bucket policies setup
    - Search head cluster expansion (future)
  - Labels: `enhancement`, `ansible`, `splunk`

### 9.2 Update CHANGELOG.md

- [ ] **Document changes in this feature branch**
  - File: `CHANGELOG.md`
  - Add entry for Splunk cluster infrastructure
  - Document new modules, roles, and configurations

---

## Group 10: Validation (Priority: Critical)

Final validation before PR creation.

### 10.1 Terraform Validation

- [ ] **Run terraform fmt**
  ```bash
  cd /Users/jevans/git/terraform-proxmox/feat/initial-splunk && terraform fmt -recursive
  ```

- [ ] **Run terraform validate**
  ```bash
  cd /Users/jevans/git/terraform-proxmox/feat/initial-splunk && terraform validate
  ```

- [ ] **Run terraform plan (dry run)**
  ```bash
  cd /Users/jevans/git/terraform-proxmox/feat/initial-splunk && terraform plan
  ```

### 10.2 Ansible Validation

- [ ] **Run ansible-lint**
  ```bash
  cd ansible && ansible-lint
  ```

- [ ] **Run molecule test for splunk role**
  ```bash
  cd ansible/roles/splunk && molecule test
  ```

### 10.3 Pre-commit Hooks

- [ ] **Run all pre-commit hooks**
  ```bash
  cd /Users/jevans/git/terraform-proxmox/feat/initial-splunk && pre-commit run --all-files
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
Group 4 (Ansible Fixes) ---------> Group 5 (Molecule Tests)
    |                                  |
    v                                  v
Group 6 (Ansible Integration) --> Group 7 (CI/CD)
    |                                  |
    v                                  v
Group 8 (Scripts) -------------> Group 9 (Docs)
                                       |
                                       v
                               Group 10 (Validation)
```

---

## Execution Order (Recommended)

1. **Phase 1**: Groups 1-3 (Terraform fixes and modules)
2. **Phase 2**: Groups 4-5 (Ansible fixes and tests)
3. **Phase 3**: Groups 6-7 (Integration and CI)
4. **Phase 4**: Groups 8-9 (Scripts and docs)
5. **Phase 5**: Group 10 (Final validation)

---

## Notes

### File Locations Summary

| Component | Path |
|-----------|------|
| Terraform root | `` |
| Terraform modules | `modules/` |
| Ansible roles | `ansible/roles/` |
| Ansible playbooks | `ansible/playbooks/` |
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

- Docker containers cannot test iptables rules (use `molecule-notest` tag)
- Splunk package must exist at `/opt/splunk-packages/` on target hosts
- Real `terraform.tfvars` is never committed (in .gitignore)
- Air-gapped environment - no internet access from Splunk nodes
