# AWS Infrastructure

AWS resources for the Proxmox VE homelab, managed **separately** from Proxmox
infrastructure.

## Architecture

```text
terraform-proxmox/
├── aws-infra/                    # THIS DIRECTORY - AWS resources only
│   ├── main.tf                   # AWS provider, module instantiations
│   ├── variables.tf              # AWS-specific variables
│   ├── outputs.tf                # AWS-specific outputs
│   ├── terragrunt.hcl            # Separate state (aws-infra/terraform.tfstate)
│   └── modules/
│       └── route53-records/      # Route53 A record management
│
└── (root)                        # Proxmox resources only
    ├── main.tf                   # Proxmox provider, VMs, containers
    ├── terragrunt.hcl            # Separate state (terraform.tfstate)
    └── modules/
        ├── acme-certificate/     # Proxmox ACME (uses Route53 for DNS-01)
        ├── proxmox-vm/
        └── ...
```

## Why Separate?

1. **Different providers** - AWS and Proxmox have different auth, APIs, lifecycles
2. **Independent state** - AWS changes don't require Proxmox state lock
3. **Clear boundaries** - AWS resources in one place, Proxmox in another
4. **Different credentials** - AWS uses IAM, Proxmox uses API tokens

## Usage

### Prerequisites

1. Add AWS credentials to Doppler:

   ```bash
   doppler secrets set AWS_ROUTE53_ACCESS_KEY=AKIA...
   doppler secrets set AWS_ROUTE53_SECRET_KEY=...
   doppler secrets set ROUTE53_ZONE_ID=Z0123456789ABCDEFGHIJ
   doppler secrets set PROXMOX_DOMAIN=pve.example.com
   doppler secrets set PROXMOX_IP_ADDRESS=192.0.2.10
   ```

2. Run from this directory:

   ```bash
   cd aws-infra/
   nix develop /path/to/terraform-nix-shell --command bash -c \
     "aws-vault exec terraform -- doppler run -- terragrunt init"
   ```

   **NOTE**: Replace `/path/to/terraform-nix-shell` with your local Nix dev shell for Terraform.

### Commands

```bash
# Validate
nix develop /path/to/terraform-nix-shell --command bash -c \
  "aws-vault exec terraform -- doppler run -- terragrunt validate"

# Plan
nix develop /path/to/terraform-nix-shell --command bash -c \
  "aws-vault exec terraform -- doppler run -- terragrunt plan"

# Apply
nix develop /path/to/terraform-nix-shell --command bash -c \
  "aws-vault exec terraform -- doppler run -- terragrunt apply"
```

## Modules

| Module          | Purpose                                    |
| --------------- | ------------------------------------------ |
| route53-records | Manages A record for Proxmox VE UI domain  |

## Cross-Reference with Proxmox

The Proxmox ACME module uses Route53 for DNS-01 validation. The workflow:

1. **Deploy aws-infra first** - Creates the A record for pve.example.com
2. **Deploy Proxmox** - ACME module validates domain ownership via Route53

The ACME module in Proxmox needs AWS credentials for DNS-01 challenges. These
are passed via `dns_plugins` variable from Doppler.

## State Management

| Root Module | State Key                                         |
| ----------- | ------------------------------------------------- |
| aws-infra   | `terraform-proxmox/aws-infra/terraform.tfstate`   |
| Proxmox     | `terraform-proxmox/terraform.tfstate`             |

Both use the same S3 bucket and DynamoDB table for state locking.
