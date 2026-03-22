# Using aws-vault with Terraform

This repository uses `aws-vault` to securely manage AWS credentials from the macOS Keychain for S3 state backend access.
With direnv handling the Nix shell, command patterns are simplified.

**Back to:** [Nix Shell Setup](nix-shell-setup.md)

## Understanding the Environments

You need **both** environments active simultaneously:

1. **Nix Shell**: Provides Terraform/Terragrunt CLI tools (handled by direnv)
2. **aws-vault**: Provides temporary AWS credentials via environment variables

## Method 1: Direct Commands (Recommended)

With direnv active, simply prefix commands with aws-vault:

```bash
aws-vault exec PROFILE_NAME -- terragrunt init
aws-vault exec PROFILE_NAME -- terragrunt plan
aws-vault exec PROFILE_NAME -- terragrunt apply
aws-vault exec PROFILE_NAME -- terragrunt refresh
```

## Method 2: aws-vault Shell (Longest Sessions)

For extended work sessions, use `aws-vault exec` to spawn a subshell:

```bash
# Start aws-vault session (credentials valid for duration of shell)
aws-vault exec PROFILE_NAME -- bash

# Run Terragrunt commands directly (credentials available)
terragrunt init
terragrunt plan
terragrunt apply

# Exit when done
exit
```

## Method 3: Manual Nix Shell (Fallback)

If direnv is not available, use the manual nix develop wrapper:

```bash
aws-vault exec PROFILE_NAME -- \
  nix develop ~/git/terraform-proxmox/main --command terragrunt plan
```

## Finding Your AWS Profile Name

```bash
aws-vault list

# Common profile names: default, terraform, proxmox
```

## Complete Workflow Example

```bash
# Direct commands (direnv handles nix shell)
cd ~/git/terraform-proxmox/main
aws-vault exec terraform -- terragrunt refresh
aws-vault exec terraform -- terragrunt plan

# Long session approach
cd ~/git/terraform-proxmox/main
aws-vault exec terraform -- bash
terragrunt refresh
terragrunt plan
```

## Troubleshooting

**Issue**: `aws-vault: error: exec: sessions should be nested with care`

Exit any existing aws-vault session first, or:

```bash
unset AWS_VAULT
aws-vault exec PROFILE_NAME -- terragrunt plan
```

**Issue**: `NoCredentialProviders: no valid providers in chain`

```bash
aws-vault list                                          # verify credentials exist
aws-vault exec --debug PROFILE_NAME -- terragrunt plan  # debug output
```

**Issue**: Commands work with aws-vault but not in Nix shell

Ensure direnv is allowed (`direnv allow`). If not using direnv, nest commands correctly:

```bash
# CORRECT - aws-vault wraps nix develop
aws-vault exec terraform -- \
  nix develop ~/git/terraform-proxmox/main --command terragrunt plan

# INCORRECT - nix develop doesn't have AWS credentials
nix develop ~/path/to/shell --command \
  aws-vault exec terraform -- terragrunt plan
```
