# SOPS Secrets Management Setup

This repository uses [SOPS](https://github.com/getsops/sops) with
[age](https://github.com/FiloSottile/age) encryption to manage secrets
natively through Terragrunt's `sops_decrypt_file()` function.

## How It Works

`terragrunt.hcl` automatically reads `terraform.sops.json` if it exists:

```hcl
sops_secrets = try(jsondecode(sops_decrypt_file("terraform.sops.json")), {})
```

- **SOPS active**: Terragrunt decrypts the file and uses it for both provider auth
  and all Terraform variable inputs.
- **SOPS absent**: Falls back to Doppler environment variables (backward compatible).

## Prerequisites

SOPS and age are provided by the Nix terraform shell. No manual installation needed:

```bash
nix develop ~/git/nix-config/main/shells/terraform
which sops  # should resolve
which age   # should resolve
```

## One-Time Key Setup

Generate an age keypair (only done once per machine):

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

Note the public key printed to stdout (starts with `age1...`).

Update `.sops.yaml` with your age public key:

```yaml
creation_rules:
  - path_regex: \.sops\.json$
    age: "age1your-actual-public-key"
  - path_regex: secrets\.enc\.yaml$
    age: "age1your-actual-public-key"
```

## Creating Your Secrets File

Copy the pre-filled template, fill in real values, and encrypt:

```bash
# Start from the pre-filled template (gitignored, has all containers pre-populated)
cp .env/terraform.sops.json terraform.sops.json

# Or start from the minimal example
cp terraform.sops.json.example terraform.sops.json

# Edit real values
$EDITOR terraform.sops.json

# Encrypt in-place (safe to commit after this)
sops --encrypt --in-place terraform.sops.json

# Add to git
git add terraform.sops.json
```

## Running Terraform

With `terraform.sops.json` in the repo root:

```bash
# Terragrunt decrypts automatically - no doppler run needed
aws-vault exec terraform -- terragrunt plan
aws-vault exec terraform -- terragrunt apply
```

Backward-compatible Doppler workflow (when no SOPS file exists):

```bash
doppler run -- aws-vault exec terraform -- terragrunt plan
```

## Editing Encrypted Secrets

```bash
# Opens in $EDITOR, decrypts for editing, re-encrypts on save
sops terraform.sops.json
```

## JSON Structure

`terraform.sops.json` contains two categories of keys:

**Provider auth** (used by Terragrunt, not passed to Terraform variables):

| Key | Purpose |
|-----|---------|
| `proxmox_ve_endpoint` | API URL (e.g., `https://proxmox.example.local:8006`) |
| `proxmox_ve_api_token` | API token (`user@realm!tokenid=secret`) |
| `proxmox_ve_insecure` | Skip TLS verification (`"true"` or `"false"`) |

**Terraform variables** (passed directly as Terragrunt inputs):

All other keys map 1:1 to `variables.tf` — `proxmox_node`, `containers`,
`pools`, `splunk_password`, etc. Complex types (objects, lists) use standard
JSON notation and coerce to HCL types automatically.

## Key Rotation

To re-encrypt with a new age key:

1. Edit the file with the old key: `sops terraform.sops.json`
2. Update `.sops.yaml` with the new public key
3. Re-encrypt: `sops updatekeys terraform.sops.json`
4. Commit the re-encrypted file

## Security Notes

- The age private key (`keys.txt`) must **never** be committed to git
- The `.sops.yaml` file contains only the **public** key (safe to commit)
- `terraform.sops.json` is safe to commit once encrypted (values are ciphertext)
- The `.env/terraform.sops.json` pre-filled template is gitignored (contains plaintext)
- Run `sops --decrypt terraform.sops.json` to verify decryption works before relying on it
