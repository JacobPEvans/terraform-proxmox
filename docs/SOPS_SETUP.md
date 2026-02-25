# Configuration Management Setup

This repository uses a 3-layer architecture for deployment configuration.

## The 3 Layers

```
LAYER 1: deployment.json (committed, plaintext, git-diffable)
  containers, VMs, pools, template IDs, disk sizes, CPU/memory/tags, proxmox_node

LAYER 2: terraform.sops.json (committed, SOPS-encrypted, 3 values)
  network_prefix, vm_ssh_public_key_path, vm_ssh_private_key_path

LAYER 3: Doppler (runtime env vars, never committed)
  PROXMOX_VE_*, PROXMOX_SSH_*, passwords, API tokens

DERIVED (locals.tf — no input needed):
  management_network = "${network_prefix}.0/24"
  splunk_network     = IPs from splunk_vm_id + containers tagged "splunk"
```

## What Goes Where

| Value | File | Why |
|-------|------|-----|
| Container/VM definitions | `deployment.json` | Not secret |
| Pool definitions | `deployment.json` | Not secret |
| Template/ISO names | `deployment.json` | Not secret |
| Disk sizes, CPU, memory | `deployment.json` | Not secret |
| `proxmox_node`, `environment` | `deployment.json` | Not secret |
| `network_prefix` | `terraform.sops.json` | Reveals internal network range |
| `vm_ssh_public_key_path` | `terraform.sops.json` | SSH key filesystem path |
| `vm_ssh_private_key_path` | `terraform.sops.json` | SSH key filesystem path |
| `management_network` | **Derived** in `locals.tf` | `= "${network_prefix}.0/24"` |
| `splunk_network` | **Derived** in `locals.tf` | From `splunk_vm_id` + splunk-tagged containers |
| API tokens, SSH key content | Doppler | Actual credentials |
| Passwords | Doppler | Actual credentials |

## The Run Command

One command — always this, always both:

```bash
aws-vault exec terraform -- doppler run -- terragrunt plan
```

Terragrunt reads `deployment.json` automatically. Terragrunt decrypts `terraform.sops.json`
automatically. Doppler injects credentials. No extra flags needed.

## Setting Up Layer 1: deployment.json

`deployment.json` is committed plaintext. Edit it directly and commit like any other file.

```bash
# Edit directly and commit like any other file
$EDITOR deployment.json

# Commit — no encryption needed
git add deployment.json
git commit -m "chore: add deployment config"
```

Changes to `deployment.json` produce clean, readable `git diff` output.

## Setting Up Layer 2: terraform.sops.json

`terraform.sops.json` is committed but SOPS-encrypted. It holds only 3 values:
`network_prefix`, `vm_ssh_public_key_path`, `vm_ssh_private_key_path`.

### One-Time Key Setup

SOPS and age are provided by the Nix terraform shell. No manual installation needed.

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

### Creating Your SOPS File

```bash
# Start from the example
cp terraform.sops.json.example terraform.sops.json

# Fill in your network prefix and SSH key paths
$EDITOR terraform.sops.json

# Encrypt in-place — safe to commit after this
sops --encrypt --in-place terraform.sops.json

# Add to git
git add terraform.sops.json
```

### Editing Encrypted Values

```bash
# Opens in $EDITOR, decrypts for editing, re-encrypts on save
sops terraform.sops.json
```

## Layer 3: Doppler (no setup needed here)

Doppler provides all credentials via environment variables. See your local environment
documentation for Doppler project/config details.

| Secret | Purpose |
|--------|---------|
| `PROXMOX_VE_ENDPOINT` | API URL |
| `PROXMOX_VE_API_TOKEN` | API token |
| `PROXMOX_VE_INSECURE` | Skip TLS verification |
| `PROXMOX_SSH_PRIVATE_KEY` | SSH private key content for BPG provider |
| `SPLUNK_PASSWORD` | Splunk admin password |
| `SPLUNK_HEC_TOKEN` | Splunk HEC token |

## Key Rotation

To re-encrypt the SOPS file with a new age key:

1. Update `.sops.yaml` with the new public key.
2. Run `sops updatekeys terraform.sops.json` to re-encrypt with the new key.
3. Commit both the re-encrypted `terraform.sops.json` and updated `.sops.yaml`.

## Security Notes

- The age private key (`keys.txt`) must **never** be committed to git
- The `.sops.yaml` file contains only the **public** key (safe to commit)
- `terraform.sops.json` is safe to commit once encrypted (values are ciphertext)
- `deployment.json` contains no secrets — commit freely, edit directly
- `management_network` and `splunk_network` are derived from other values — never set manually
