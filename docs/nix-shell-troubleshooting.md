# Nix Shell Troubleshooting

Common issues and advanced usage for the Nix development shell.

**Back to:** [Nix Shell Setup](nix-shell-setup.md)

## Common Issues

### Nix shell not found

**Symptom**: `error: getting status of '/nix/store/...': No such file or directory`

```bash
nix flake update "github:JacobPEvans/nix-devenv?dir=shells/terraform"
nix develop "github:JacobPEvans/nix-devenv?dir=shells/terraform" --rebuild
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

This repository uses the shared `nix-devenv` terraform shell (see [nix-devenv](https://github.com/JacobPEvans/nix-devenv/tree/main/shells/terraform)).
To add local customizations without modifying the upstream shell, set extra environment variables in your `.envrc` after `use flake`:

```bash
# .envrc (local only, gitignored for personal overrides)
use flake "github:JacobPEvans/nix-devenv?dir=shells/terraform"
export TF_LOG=DEBUG
```

To add packages or change shell behavior, submit a PR to [nix-devenv](https://github.com/JacobPEvans/nix-devenv) and update the shell there.

### Running Commands Outside the Shell

```bash
nix develop "github:JacobPEvans/nix-devenv?dir=shells/terraform" --command terragrunt plan
nix develop "github:JacobPEvans/nix-devenv?dir=shells/terraform" --command bash ./scripts/deploy.sh
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
          nix develop "github:JacobPEvans/nix-devenv?dir=shells/terraform" --command bash -c "
            terragrunt init
            terragrunt validate
            tflint
            tfsec .
          "
```

## Additional Resources

- **Nix Shell Definition**: [nix-devenv shells/terraform](https://github.com/JacobPEvans/nix-devenv/tree/main/shells/terraform)
- **Terraform Documentation**: [developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform/docs)
- **Terragrunt Documentation**: [terragrunt.gruntwork.io](https://terragrunt.gruntwork.io/docs/)
- **Proxmox Provider**: [registry.terraform.io/providers/bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
