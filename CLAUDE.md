# AI Instructions for Terraform Proxmox Repository

## Critical: Version Management

**NEVER hardcode dependency versions unless explicitly requested.**

- Always use latest stable versions (no pinning)
- Let package managers resolve compatible versions
- If version conflicts occur, investigate current ecosystem state
- When unsure about compatibility, ask the user or research current docs

**If you find yourself suggesting old versions or deprecated features, STOP and research the current state first.**

## Technology Stack

This repo uses:

- **Terraform/Terragrunt** - Infrastructure provisioning
- **Ansible** - Configuration management (tested via Molecule)
- **Python 3.12+** - Required for Ansible tooling
- **GitHub Actions** - CI/CD
- **Nix Shell** - Provides Terraform/Terragrunt/Ansible tooling
- **aws-vault** - Securely manages AWS credentials for S3 backend
- **Doppler** - Manages Proxmox API secrets as environment variables
- **SOPS/age** - Git-committed encrypted secrets (alternative to Doppler)

## Running Terraform Commands

**CRITICAL**: All Terraform/Terragrunt commands require the complete toolchain wrapper.

### The Complete Command Pattern

```bash
aws-vault exec terraform -- doppler run -- terragrunt <COMMAND>
```

The Nix shell (providing Terraform/Terragrunt/Ansible) is activated automatically via direnv when you enter the repository directory.

### Command Breakdown

1. **`aws-vault exec terraform`** - Provides AWS credentials for S3 backend (profile: `terraform`)
2. **`doppler run --`** - Injects Proxmox secrets as `PROXMOX_VE_*` environment variables
3. **`terragrunt <COMMAND>`** - The actual Terraform command to run

**Note**: The BPG Proxmox provider reads directly from `PROXMOX_VE_*` environment variables.
No `--name-transformer` is needed. See [BPG provider docs](https://registry.terraform.io/providers/bpg/proxmox/latest/docs).

### Common Commands

```bash
# Validate configuration
aws-vault exec terraform -- doppler run -- terragrunt validate

# Plan changes
aws-vault exec terraform -- doppler run -- terragrunt plan

# Apply changes
aws-vault exec terraform -- doppler run -- terragrunt apply

# Show state
aws-vault exec terraform -- doppler run -- terragrunt show
```

### Doppler Configuration

Doppler is configured once at the repository root and automatically inherited by all
worktrees. See your local environment documentation for project and config details.

### Doppler Secret Naming (BPG Standard)

Doppler secrets use `PROXMOX_VE_*` naming to match the BPG Terraform provider:

| Secret | Purpose |
| --- | --- |
| `PROXMOX_VE_ENDPOINT` | API URL (without /api2/json) |
| `PROXMOX_VE_API_TOKEN` | API token (user@realm!tokenid=secret) |
| `PROXMOX_VE_USERNAME` | Username for token |
| `PROXMOX_VE_INSECURE` | Skip TLS verification |
| `PROXMOX_VE_NODE` | Proxmox node name |

### Why All Three Tools?

- **Nix + direnv**: Provides consistent tool versions (Terraform, Terragrunt, Ansible) via `.envrc` auto-activation
- **aws-vault**: Secures AWS credentials for S3 backend (never stored in files)
- **Doppler**: Manages Proxmox API credentials using `PROXMOX_VE_*` naming (never stored in tfvars or git)

### SOPS Secrets (Alternative to Doppler)

SOPS with age encryption provides git-committed encrypted secrets.
See [docs/SOPS_SETUP.md](./docs/SOPS_SETUP.md) for setup and usage.

- `.sops.yaml` - Age public key configuration (safe to commit)
- `secrets.enc.yaml` - Encrypted secrets template (safe to commit once encrypted)

## Repository Context

- Infrastructure-as-code for Proxmox VE homelab
- Real infrastructure details in separate private repository
- This repo contains placeholder/example values only

## Pipeline Architecture (This Repo's Role)

This repo is the **single source of truth** for infrastructure: VMs, containers, IPs, ports, and firewall rules.

### IP Derivation

All IPs are derived from VM/container ID: `network_prefix.vm_id` (e.g., VM 250 = `192.168.0.250`).
Never hardcode IPs in any repo - they come from terraform output.

### Pipeline Constants

`locals.tf` defines `pipeline_constants` with service and syslog port mappings.
These are exposed via `ansible_inventory.constants` in `outputs.tf` for downstream Ansible repos.

### Downstream Repos

| Repo | Consumes | Purpose |
| --- | --- | --- |
| ansible-proxmox | N/A | Proxmox host config (kernel, ZFS, monitoring) |
| ansible-proxmox-apps | `ansible_inventory` (containers, docker_vms, constants) | Cribl, HAProxy, DNS |
| ansible-splunk | `ansible_inventory` (splunk_vm) | Splunk Enterprise (Docker) |

### Regenerating Inventory

After `terragrunt apply`, regenerate inventory for downstream repos:

```bash
# For ansible-proxmox-apps
terragrunt output -json ansible_inventory > ~/git/ansible-proxmox-apps/main/inventory/terraform_inventory.json

# For ansible-splunk
terragrunt output -json ansible_inventory > ~/git/ansible-splunk/main/inventory/terraform_inventory.json
```

## Development Workflow

### Terraform/Terragrunt

**Before ANY commits**, run validation and planning:

```bash
# 1. Validate syntax
aws-vault exec terraform -- doppler run -- terragrunt validate

# 2. Plan changes to review what will be modified
aws-vault exec terraform -- doppler run -- terragrunt plan
```

**Best Practices**:

- Test in isolated resource pools, never production-first
- Use feature branches for all changes
- Follow conventional commit messages
- Never commit without running validate + plan first

### Timeout and Debug Logging

When experiencing "context deadline exceeded" or slow Terraform operations:

#### Pre-Operation Health Check

```bash
# Test API connectivity before running Terraform
doppler run -- ./scripts/check-proxmox-api.sh
```

#### Debug Logging

```bash
# Full debug logging with file output
TF_LOG=DEBUG TF_LOG_PATH=/tmp/terraform-debug.log \
  terragrunt plan 2>&1 | tee /tmp/terraform-output.log

# Monitor in second terminal
tail -f /tmp/terraform-debug.log | grep -E "GET|POST|Refreshing|timeout|deadline"
```

#### Real-Time Monitoring (Multi-Terminal)

```bash
# Terminal 1: Run with logging
TF_LOG=DEBUG terragrunt apply -auto-approve 2>&1 | tee /tmp/tf.log

# Terminal 2: Monitor progress
./scripts/monitor-terraform.sh /tmp/tf.log

# Terminal 3 (optional): Watch Proxmox host
ssh root@proxmox-host 'while true; do clear; date; free -h; qm list; pct list; sleep 10; done'
```

#### Timeout Configuration

Resource-level timeouts are configured in modules (15 min standard, 30 min for clone/create):

- `modules/proxmox-vm/main.tf`
- `modules/splunk-vm/main.tf`

For slow operations, reduce parallelism:

```bash
terragrunt apply -parallelism=1 -auto-approve
```

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for detailed timeout analysis.

### Ansible

- Lint with `ansible-lint` before commits
- Test roles with `molecule test`
- Ensure idempotency (running twice produces no changes)
- Use FQCN for modules (e.g., `ansible.builtin.apt`)

## Best Practices

### Terraform

- Modular resource definitions
- Document variables with descriptions and validation
- Mark secrets with `sensitive = true`
- Remote state with encryption (S3 + DynamoDB)
- Never update VMs directly; use Terragrunt or Ansible

### Ansible

- Roles in `ansible/roles/` with Molecule tests
- Collections in `ansible/requirements.yml`
- Config in `ansible/.ansible-lint` (profile: production)
- Docker-based testing with geerlingguy images

### Security

- Never commit secrets, API tokens, or passwords
- Reference private context for real infrastructure details
- Separate SSH keys per environment
- Enable state file encryption

## File References

| Need | Location |
| ---- | -------- |
| Architecture (canonical) | docs/ARCHITECTURE.md |
| Secrets roadmap | docs/SECRETS_ROADMAP.md |
| General docs | README.md |
| Troubleshooting | TROUBLESHOOTING.md |
| Planning | GitHub Issues |
| Change history | PR descriptions and commits |
| Ansible config | ansible/.ansible-lint |
| Molecule tests | ansible/roles/*/molecule/ |
| CI workflows | .github/workflows/ |

## When to Ask for Clarification

Ask the user before proceeding if:

- Current tool versions are unclear
- Multiple valid implementation approaches exist
- Changes affect production infrastructure
- Security implications are uncertain
- Breaking changes may be introduced

## PR Review Checklist

- [ ] No exposed secrets or credentials
- [ ] Variables documented with `sensitive = true` where needed
- [ ] Terraform: `terragrunt validate` passes
- [ ] Ansible: `ansible-lint` passes
- [ ] Ansible roles: `molecule test` passes
- [ ] Conventional commit message
- [ ] Documentation updated if needed
