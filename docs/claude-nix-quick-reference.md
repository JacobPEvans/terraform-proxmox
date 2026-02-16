# Claude Code: Nix Shell Quick Reference

**Quick reference for Claude Code to autonomously use Nix shells with this Terraform repository.**

## Setup

The repository ships an `.envrc` file that auto-activates the Nix shell via direnv.
On first use, run `direnv allow`. As a fallback, use:

```bash
nix develop "${NIX_CONFIG_PATH:-$HOME/git/nix-config/main}/shells/terraform"
```

This provides: terraform, terragrunt, ansible, tfsec, checkov, trivy,
aws-cli, docker, and all other required tools.

**Important**: Direnv handles the Nix shell activation, but **terragrunt commands still require wrappers**:

- `aws-vault exec default --` for AWS credentials (remote state)
- `doppler run --` for Proxmox credentials (PROXMOX_VE_* env vars)

## Essential Workflows

### 1. Validate Configuration (Most Common)

```bash
# Validation only - no credentials needed for syntax check
terragrunt validate && \
  tflint && \
  echo 'Validation complete'
```

### 2. Plan Infrastructure Changes

```bash
# Requires both aws-vault (AWS) and doppler (Proxmox)
aws-vault exec default -- doppler run -- terragrunt init && \
  aws-vault exec default -- doppler run -- terragrunt plan
```

### 3. Security Scan

```bash
tfsec --concise-output . && \
  checkov --directory . --quiet && \
  trivy config --severity HIGH,CRITICAL .
```

### 4. Full Pre-Commit Check

```bash
# Syntax and security checks - no credentials needed
terragrunt validate && \
  terraform fmt -check -recursive && \
  tflint && \
  tfsec . && \
  echo 'All checks passed'
```

### 5. Format Code

```bash
terraform fmt -recursive
```

## Interactive Shell Sessions

When you need to run multiple commands:

```bash
# Enter the shell (if direnv is not active)
nix develop ~/git/nix-config/main/shells/terraform

# Now you're in the Nix environment with all tools available
# Run commands as normal:
terragrunt init
terragrunt validate
terragrunt plan
```

Exit with `exit` or Ctrl+D.

## Common Command Patterns

### Pattern: Init, Validate, Plan

```bash
terragrunt init && \
  terragrunt validate && \
  terragrunt plan -out=tfplan
```

### Pattern: Security-First Workflow

```bash
tfsec . || exit 1
checkov --directory . || exit 1
terragrunt validate || exit 1
echo 'Security and validation passed'
```

### Pattern: Generate Documentation

```bash
cd modules/proxmox-vm && \
  terraform-docs markdown table --output-file README.md . && \
  echo 'Documentation generated'
```

## Parallel Execution (Claude's Strength)

Run multiple independent checks in parallel using separate tool calls:

**Tool Call 1:**

```bash
tfsec .
```

**Tool Call 2:**

```bash
checkov --directory .
```

**Tool Call 3:**

```bash
terragrunt validate
```

## Environment Setup (One-Time)

### Option A: Auto-activate with direnv

The `.envrc` is already shipped in the repo:

```bash
direnv allow
# Shell auto-activates when you cd into the directory
```

### Option B: Manual activation each time

```bash
nix develop ~/git/nix-config/main/shells/terraform
# Run your commands
exit
```

## Tools Available in Shell

| Category        | Tools                              |
| --------------- | ---------------------------------- |
| **IaC**         | terraform, terragrunt, opentofu    |
| **Security**    | tfsec, checkov, terrascan, trivy   |
| **Docs/Lint**   | terraform-docs, tflint             |
| **Config Mgmt** | ansible, ansible-lint, molecule    |
| **Cloud**       | aws-cli, docker                    |
| **Utilities**   | jq, yq, git, python3               |
| **Cost**        | infracost                          |

## Error Handling

### If Nix shell fails to load

```bash
nix flake update ~/git/nix-config/main/shells/terraform
nix develop ~/git/nix-config/main/shells/terraform --rebuild
```

### If providers fail to download

```bash
rm -rf .terraform .terraform.lock.hcl
terragrunt init
```

### If state lock errors occur

```bash
# Wait 2 minutes for lock to expire, or
terragrunt force-unlock <lock-id>
```

## Decision Matrix: When to Use Nix Shell

| Task               | Use Nix Shell? | Command                        |
| ------------------ | -------------- | ------------------------------ |
| Read files         | No             | Use Read tool directly         |
| Terraform validate | Yes            | `terragrunt validate`          |
| Security scan      | Yes            | `tfsec .`                      |
| Git operations     | No             | Git is allowed without Nix     |
| Format code        | Yes            | `terraform fmt -recursive`     |
| Generate docs      | Yes            | `terraform-docs ...`           |
| Plan changes       | Yes            | `terragrunt plan`              |
| Apply changes      | Yes            | `terragrunt apply`             |

## Best Practices for Claude

1. **Always validate before planning**: Run `terragrunt validate` before `terragrunt plan`
2. **Run security scans early**: Catch issues before they become problems
3. **Use parallel commands**: Run independent checks simultaneously
4. **Format before committing**: Run `terraform fmt -recursive` before git operations
5. **Initialize when needed**: Run `terragrunt init` if you see provider errors

## Example Autonomous Workflow

```bash
# 1. Enter directory (direnv auto-activates nix shell)
cd ~/git/terraform-proxmox/main

# 2. Run comprehensive check
echo '=== Initializing ===' && \
  terragrunt init && \
  echo '=== Formatting ===' && \
  terraform fmt -recursive && \
  echo '=== Validating ===' && \
  terragrunt validate && \
  echo '=== Linting ===' && \
  tflint && \
  echo '=== Security Scan ===' && \
  tfsec --concise-output . && \
  echo '=== Planning ===' && \
  terragrunt plan -out=tfplan && \
  echo '=== Complete ==='

# 3. Review results and proceed
```

## Integration with Existing Commands

With direnv active, all commands work directly:

```bash
# Pre-commit hooks
pre-commit run --all-files

# Terragrunt operations
terragrunt plan

# Ansible testing
cd ansible/roles/common && molecule test
```

## Summary: Three Things Claude Needs to Know

1. **direnv auto-activates**: The `.envrc` file handles Nix shell activation
2. **All Tools Available**: terraform, terragrunt, ansible, tfsec, checkov,
   trivy, aws-cli, docker
3. **Fallback**: `nix develop ~/git/nix-config/main/shells/terraform`

This provides a reproducible, isolated environment with all required tools,
no version conflicts, and no manual installation.
