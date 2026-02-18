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

### ACTIVE: SOPS + Age (Git-Committed Encrypted Secrets)

Encrypt secrets in git using SOPS with Age keys, read natively by Terragrunt.

**How it works:**

- `terraform.sops.json` (encrypted) is committed to git alongside the code
- Terragrunt's `sops_decrypt_file()` decrypts it automatically at plan/apply time
- No `doppler run --` needed when SOPS file is present
- Backward compatible: Doppler env vars still work when no SOPS file exists

**Integration pattern:**

```hcl
# In terragrunt.hcl:
sops_secrets = try(jsondecode(sops_decrypt_file("terraform.sops.json")), {})
inputs       = merge(env_var_defaults, local.sops_inputs)
```

**Files:**

| File | Status | Purpose |
|------|--------|---------|
| `.sops.yaml` | Committed | Age public key config |
| `terraform.sops.json` | Committed (encrypted) | All secrets for Terragrunt |
| `terraform.sops.json.example` | Committed | Template with placeholder values |
| `.env/terraform.sops.json` | Gitignored | Pre-filled plaintext template |

**Repositories using SOPS:**

| Repository | Status |
|------------|--------|
| terraform-proxmox | ACTIVE |
| ansible-proxmox-apps | Planned |
| ansible-splunk | Planned |

See [docs/SOPS_SETUP.md](./SOPS_SETUP.md) for full setup and usage instructions.

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
├── Runtime injection ──→ Terraform (fallback when no SOPS file)
├── Runtime injection ──→ Ansible
├── secrets-sync ──────→ GitHub Actions
└── Age private key ───→ SOPS decryption

aws-vault (local)
└── STS sessions ──────→ Terraform S3 backend

macOS Keychain (local)
└── ai-secrets ────────→ Claude Code / AI agents

SOPS + Age (ACTIVE)
└── terraform.sops.json (encrypted in git)
    └── sops_decrypt_file() ──→ Terragrunt inputs + provider auth

Infisical (planned)
└── Self-hosted ───────→ Replace/complement Doppler
```

## Migration Path

```text
Current:  SOPS/Age (terraform-proxmox) → sops_decrypt_file() → Terragrunt
          Doppler → env vars → Ansible, other Terraform repos
                  → secrets-sync → GitHub Actions

Near-term: + Extend SOPS to ansible-proxmox-apps and ansible-splunk
           + Pre-commit guards against committing unencrypted secrets

Future:    Infisical (self-hosted) as primary
           Doppler as fallback/migration source
           SOPS/Age for offline/air-gapped scenarios
```
