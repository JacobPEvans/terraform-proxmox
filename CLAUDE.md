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

## Running Terraform Commands

**CRITICAL**: All Terraform/Terragrunt commands require the complete toolchain wrapper.

### The Complete Command Pattern

```bash
nix develop ~/git/nix-config/main/shells/terraform --command bash -c "aws-vault exec terraform -- doppler run --name-transformer tf-var -- terragrunt <COMMAND>"
```

### Command Breakdown

1. **`nix develop ~/git/nix-config/main/shells/terraform`** - Enters Nix shell with Terraform/Terragrunt/Ansible
2. **`aws-vault exec terraform`** - Provides AWS credentials for S3 backend (profile: `terraform`)
3. **`doppler run --name-transformer tf-var`** - Injects Proxmox secrets as `TF_VAR_*` environment variables
4. **`terragrunt <COMMAND>`** - The actual Terraform command to run

### Common Commands

```bash
# Validate configuration
nix develop ~/git/nix-config/main/shells/terraform --command bash -c "aws-vault exec terraform -- doppler run --name-transformer tf-var -- terragrunt validate"

# Plan changes
nix develop ~/git/nix-config/main/shells/terraform --command bash -c "aws-vault exec terraform -- doppler run --name-transformer tf-var -- terragrunt plan"

# Apply changes
nix develop ~/git/nix-config/main/shells/terraform --command bash -c "aws-vault exec terraform -- doppler run --name-transformer tf-var -- terragrunt apply"

# Show state
nix develop ~/git/nix-config/main/shells/terraform --command bash -c "aws-vault exec terraform -- doppler run --name-transformer tf-var -- terragrunt show"
```

### Doppler Configuration

Each worktree needs Doppler configured:

```bash
doppler setup --project <YOUR_PROJECT> --config <YOUR_CONFIG>
```

This creates a local `.doppler.yaml` (gitignored) with project/config settings.

**Note**: Actual project/config names are in your local `SECRETS_SETUP.md` (gitignored).

### Why All Three Tools?

- **Nix**: Provides consistent tool versions (Terraform 1.14.0, Terragrunt 0.93.11, Ansible 2.19.4)
- **aws-vault**: Secures AWS credentials for S3 backend (never stored in files)
- **Doppler**: Manages Proxmox API credentials (never stored in tfvars or git)

## Repository Context

- Infrastructure-as-code for Proxmox VE homelab
- Real infrastructure details in separate private repository
- This repo contains placeholder/example values only

## Development Workflow

### Terraform/Terragrunt

**Before ANY commits**, run validation and planning:

```bash
# 1. Validate syntax
nix develop ~/git/nix-config/main/shells/terraform --command bash -c "aws-vault exec terraform -- doppler run --name-transformer tf-var -- terragrunt validate"

# 2. Plan changes to review what will be modified
nix develop ~/git/nix-config/main/shells/terraform --command bash -c "aws-vault exec terraform -- doppler run --name-transformer tf-var -- terragrunt plan"
```

**Best Practices**:
- Test in isolated resource pools, never production-first
- Use feature branches for all changes
- Follow conventional commit messages
- Never commit without running validate + plan first

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
