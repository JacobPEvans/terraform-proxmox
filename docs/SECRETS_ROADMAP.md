# Secrets Roadmap

Unified secrets strategy across the Proxmox homelab ecosystem.

## Current State

### ACTIVE: Doppler (Primary Runtime Secrets)

Doppler is the primary secrets manager for all runtime credentials.

**How it works:**

- Secrets stored in Doppler projects, organized by config (dev/stg/prd)
- Injected at runtime via `doppler run --` command wrapper
- BPG Proxmox provider reads `PROXMOX_VE_*` env vars directly
- Configured once at bare repo root; all worktrees inherit automatically

**Repositories using Doppler:**

| Repository | Doppler Project | Secrets Managed |
| --- | --- | --- |
| terraform-proxmox | iac-conf-mgmt | `PROXMOX_VE_*`, `SPLUNK_*` |
| ansible-proxmox-apps | iac-conf-mgmt | `PROXMOX_*`, `SPLUNK_HEC_TOKEN` |
| ansible-splunk | iac-conf-mgmt | `SPLUNK_*`, `PROXMOX_*` |
| ansible-proxmox | iac-conf-mgmt | `PROXMOX_*` |

**Strengths:**

- Zero secrets in git or environment files
- Automatic worktree inheritance via bare repo config
- Audit logging and access controls
- Easy rotation without code changes

### ACTIVE: aws-vault (AWS Credential Management)

Secures AWS credentials for Terraform S3 backend access.

**How it works:**

- Credentials stored in macOS Keychain
- Temporary STS sessions via `aws-vault exec <profile> --`
- Never written to `~/.aws/credentials`

**Repositories using aws-vault:**

- terraform-proxmox (S3 state backend)
- terraform-aws (AWS infrastructure)
- terraform-aws-bedrock (Bedrock AI)

### ACTIVE: secrets-sync (Doppler to GitHub Actions)

Synchronizes Doppler secrets to GitHub Actions repository secrets.

**How it works:**

- Doppler secrets-sync integration configured per repository
- Automatically pushes secret updates to GitHub Actions secrets
- CI/CD workflows reference secrets via `${{ secrets.SECRET_NAME }}`

### ACTIVE: macOS Keychain (AI Agent Keys)

API keys for Claude Code and AI agents stored in a dedicated keychain.

**How it works:**

- Dedicated `ai-secrets` keychain in macOS Keychain Access
- Retrieved at runtime by Claude Code plugins
- Never stored in files or environment variables

## Planned

### PLANNED: SOPS + Age (Git-Committed Encrypted Secrets)

<!-- DO NOT DELETE - Active planning item -->

Encrypt sensitive files (tfvars, ansible vars) in git using SOPS with Age keys.

**Use cases:**

- Encrypted `terraform.tfvars` committed to git (no more `.env/` gitignored dirs)
- Encrypted Ansible vault files alongside playbooks
- Reproducible deployments without external secret manager dependency

**Implementation plan:**

1. Generate Age key pair, store private key in Doppler
2. Create `.sops.yaml` config at repo root with path-based rules
3. Encrypt existing `.env/terraform.tfvars` files
4. Update CI/CD to decrypt with Age key from Doppler
5. Add pre-commit hook to prevent committing unencrypted secrets

**Target repositories:**

- terraform-proxmox
- ansible-proxmox-apps
- ansible-splunk

**Status:** Implementation in progress. See shared rule in
`ai-assistant-instructions` for cross-repo patterns.

### PLANNED: Self-Hosted Infisical

<!-- DO NOT DELETE - Active planning item -->

Self-hosted secrets manager running on Proxmox infrastructure.

**Motivation:**

- Reduce dependency on Doppler SaaS
- Full control over secrets infrastructure
- Native Terraform and Ansible integrations
- Web UI for team management

See [INFISICAL_PLANNING.md](./INFISICAL_PLANNING.md) for detailed planning.

## Under Consideration

### CONSIDERATION: Google Secrets Manager

Evaluating as potential alternative or complement to Doppler for
cloud-native workloads.

**Pros:**

- Native GCP integration
- Pay-per-use pricing
- Strong IAM integration

**Cons:**

- Adds GCP dependency to primarily AWS/on-prem stack
- No clear advantage over Doppler for current use cases
- Would require additional credential management

**Decision:** On hold. Revisit if GCP workloads are added to the ecosystem.

## Secrets Flow Summary

```text
Doppler (SaaS)
├── Runtime injection ──→ Terraform, Ansible
├── secrets-sync ──────→ GitHub Actions
└── Age private key ───→ SOPS decryption (planned)

aws-vault (local)
└── STS sessions ──────→ Terraform S3 backend

macOS Keychain (local)
└── ai-secrets ────────→ Claude Code / AI agents

SOPS + Age (planned)
└── Encrypted files ───→ Git repos (decrypted at runtime)

Infisical (planned)
└── Self-hosted ───────→ Replace/complement Doppler
```

## Migration Path

```text
Current:  Doppler → env vars → Terraform/Ansible
                  → secrets-sync → GitHub Actions

Near-term: + SOPS/Age for git-committed encrypted values
           + Pre-commit guards against unencrypted secrets

Future:    Infisical (self-hosted) as primary
           Doppler as fallback/migration source
           SOPS/Age for offline/air-gapped scenarios
```
