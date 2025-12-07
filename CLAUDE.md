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

Verify commands:
```bash
terraform version && terragrunt --version
ansible --version && molecule --version
python --version
```

## Repository Context

- Infrastructure-as-code for Proxmox VE homelab
- Real infrastructure details in separate private repository
- This repo contains placeholder/example values only

## Development Workflow

### Terraform/Terragrunt
- Run `terragrunt validate` then `terragrunt plan` before commits
- Test in isolated resource pools, never production-first
- Use feature branches for all changes
- Follow conventional commit messages

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
|------|----------|
| General docs | README.md |
| Troubleshooting | TROUBLESHOOTING.md |
| Incomplete tasks | PLANNING.md |
| Change history | CHANGELOG.md |
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
