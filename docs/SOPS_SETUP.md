# SOPS Secrets Management Setup

This repository uses [SOPS](https://github.com/getsops/sops) with
[age](https://github.com/FiloSottile/age) encryption to manage secrets
as an alternative to Doppler.

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

## Repository Configuration

1. Update `.sops.yaml` with your age public key:

   ```yaml
   creation_rules:
     - path_regex: secrets\.enc\.yaml$
       age: "age1your-actual-public-key"
   ```

2. Fill in real values in `secrets.enc.yaml` and encrypt:

   ```bash
   sops --encrypt --in-place secrets.enc.yaml
   ```

3. Set the age key file path in your `.envrc`:

   ```bash
   export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
   ```

## Usage

### Edit encrypted secrets

```bash
sops secrets.enc.yaml
```

This opens the file in your `$EDITOR`, decrypts for editing, and
re-encrypts on save.

### Decrypt to stdout

```bash
sops --decrypt secrets.enc.yaml
```

### Export as environment variables

```bash
eval $(sops --decrypt --output-type dotenv secrets.enc.yaml | sed 's/^/export /')
```

## Integration with Terraform

SOPS secrets can replace Doppler by exporting `PROXMOX_VE_*` environment
variables before running Terragrunt:

```bash
# Instead of: doppler run -- terragrunt plan
# Use:
eval $(sops --decrypt --output-type dotenv secrets.enc.yaml | sed 's/^/export /')
aws-vault exec terraform -- terragrunt plan
```

## Key Rotation

To re-encrypt with a new age key:

1. Decrypt with old key: `sops --decrypt secrets.enc.yaml > secrets.plain.yaml`
2. Update `.sops.yaml` with new public key
3. Re-encrypt: `sops --encrypt secrets.plain.yaml > secrets.enc.yaml`
4. Securely delete plaintext: `rm -P secrets.plain.yaml`

## Security Notes

- The age private key (`keys.txt`) must never be committed to git
- The `.sops.yaml` file contains only the public key (safe to commit)
- `secrets.enc.yaml` is safe to commit once encrypted (values are ciphertext)
- The unencrypted template in this repo uses placeholder values only
