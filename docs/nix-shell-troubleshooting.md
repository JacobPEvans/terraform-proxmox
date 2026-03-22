# Nix Shell Troubleshooting

Common issues and advanced usage for the Nix development shell.

**Back to:** [Nix Shell Setup](nix-shell-setup.md)

## Common Issues

### Nix shell not found

**Symptom**: `error: getting status of '/nix/store/...': No such file or directory`

```bash
nix flake update ~/git/terraform-proxmox/main
nix develop ~/git/terraform-proxmox/main --rebuild
```

### Docker not available in Nix shell

**Symptom**: `Cannot connect to the Docker daemon`

The Nix shell provides the Docker CLI client only. Docker must be running on the host system:

```bash
# macOS: Ensure Docker Desktop is running
open -a Docker

# Linux: Start Docker service
sudo systemctl start docker
```

### AWS credentials not found

**Symptom**: `Error: No valid credential sources found`

This repository uses aws-vault. See
[aws-vault-terraform.md](aws-vault-terraform.md) for credential setup.

```bash
aws-vault list                                 # verify credentials
aws-vault exec default -- terragrunt plan      # provide credentials
```

### Terraform provider download fails

**Symptom**: `Failed to install provider from shared cache`

```bash
rm -rf ~/.terraform.d/plugin-cache
rm -rf .terraform
terragrunt init
```

### Terragrunt state locking errors

**Symptom**: `Error acquiring the state lock`

```bash
aws dynamodb scan --table-name terraform-state-lock  # list active locks
terragrunt force-unlock <lock-id>                    # force unlock (use with caution)
```

## Advanced Usage

### Using Multiple Nix Shells Simultaneously

```bash
# Terminal 1: Main development
cd ~/git/terraform-proxmox/main
# direnv auto-activates

# Terminal 2: Parallel testing
cd ~/git/terraform-proxmox/main
# direnv auto-activates
```

### Customizing the Shell

The repo's `flake.nix` defines `devShells.default`.
To add local customizations without modifying the committed flake, set extra environment variables in your `.envrc` after `use flake`:

```bash
# .envrc (local only, gitignored for personal overrides)
use flake
export TF_LOG=DEBUG
```

Alternatively, extend the shell by editing `flake.nix` in your feature branch.

### Running Commands Outside the Shell

```bash
nix develop ~/git/terraform-proxmox/main --command terragrunt plan
nix develop ~/git/terraform-proxmox/main --command bash ./scripts/deploy.sh
```

## Integration with CI/CD

The same Nix shell can be used in CI/CD pipelines:

```yaml
# .github/workflows/terraform.yml
name: Terraform Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: cachix/install-nix-action@v27
        with:
          nix_path: nixpkgs=channel:nixos-unstable

      - name: Enter Nix shell and validate
        run: |
          nix develop . --command bash -c "
            terragrunt init
            terragrunt validate
            tflint
            tfsec .
          "
```

## Additional Resources

- **Nix Shell Definition**: `~/git/terraform-proxmox/main/flake.nix`
- **Terraform Documentation**: [developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform/docs)
- **Terragrunt Documentation**: [terragrunt.gruntwork.io](https://terragrunt.gruntwork.io/docs/)
- **Proxmox Provider**: [registry.terraform.io/providers/bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
