# SOPS Secrets Management Setup

This repository uses [SOPS](https://github.com/getsops/sops) with
[age](https://github.com/FiloSottile/age) encryption to commit deployment
configuration alongside the code.

## What SOPS Is (and Isn't)

**SOPS replaces `.env/terraform.tfvars`** — it's the encrypted version of your
deployment config committed to git. This includes:

- Proxmox node name, environment name
- Network ranges and IP addresses (management, Splunk, etc.)
- Container and VM definitions
- Pool and datastore configuration
- Splunk VM sizing and IDs

**SOPS does NOT replace Doppler.** Doppler continues to manage all credentials:

| Secret | Provider | How Injected |
|--------|----------|--------------|
| `PROXMOX_VE_ENDPOINT` | Doppler | BPG provider reads from env var |
| `PROXMOX_VE_API_TOKEN` | Doppler | BPG provider reads from env var |
| `PROXMOX_VE_INSECURE` | Doppler | BPG provider reads from env var |
| `PROXMOX_SSH_PRIVATE_KEY` | Doppler | Terragrunt injects into provider SSH block |
| `SPLUNK_PASSWORD` | Doppler | Terragrunt passes as TF variable |
| `SPLUNK_HEC_TOKEN` | Doppler | Terragrunt passes as TF variable |

## The Run Command

There is **one command**. Doppler and SOPS work together, not as alternatives:

```bash
aws-vault exec terraform -- doppler run -- terragrunt plan
```

Terragrunt automatically decrypts `terraform.sops.json` if present. No extra flags needed.

## Prerequisites

SOPS and age are provided by the Nix terraform shell. No manual installation needed:

```bash
which sops  # should resolve via direnv/nix
which age   # should resolve via direnv/nix
```

## One-Time Key Setup

Generate an age keypair (once per machine):

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

Note the public key printed to stdout (starts with `age1...`).

Update `.sops.yaml` with your public key:

```yaml
creation_rules:
  - path_regex: \.sops\.json$
    age: "age1your-actual-public-key"
```

## Creating Your Config File

```bash
# Start from the example template
cp terraform.sops.json.example terraform.sops.json

# Fill in real values (node name, IPs, container definitions, etc.)
$EDITOR terraform.sops.json

# Encrypt in-place — safe to commit after this
sops --encrypt --in-place terraform.sops.json

# Add to git
git add terraform.sops.json
```

## Running Terraform

```bash
# Doppler provides credentials, SOPS provides config — always together
aws-vault exec terraform -- doppler run -- terragrunt plan
aws-vault exec terraform -- doppler run -- terragrunt apply
```

## Editing Encrypted Config

```bash
# Opens in $EDITOR, decrypts for editing, re-encrypts on save
sops terraform.sops.json
```

## JSON Structure

`terraform.sops.json` contains deployment config only — no credentials:

```json
{
  "proxmox_node": "pve",
  "environment": "homelab",
  "management_network": "192.168.0.0/24",
  "splunk_network": ["192.168.0.200"],
  "pools": { ... },
  "containers": { ... }
}
```

All keys map 1:1 to `variables.tf`. Complex types (objects, lists) use standard
JSON notation and coerce to HCL types automatically via `jsondecode()`.

## Key Rotation

To re-encrypt with a new age key:

1. Update `.sops.yaml` with the new public key.
2. Run `sops updatekeys terraform.sops.json` to re-encrypt with the new master key.
3. Commit both the re-encrypted `terraform.sops.json` and updated `.sops.yaml`.

## Security Notes

- The age private key (`keys.txt`) must **never** be committed to git
- The `.sops.yaml` file contains only the **public** key (safe to commit)
- `terraform.sops.json` is safe to commit once encrypted (values are ciphertext)
- Credentials (API tokens, passwords, SSH keys) live in Doppler — never in SOPS
