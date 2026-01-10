# ACME Certificate Module

This module manages ACME (Let's Encrypt) certificates for Proxmox VE nodes using the BPG Proxmox provider.

## Overview

The module handles three key components:

1. **ACME Accounts** - Let's Encrypt account registration
2. **DNS Challenge Plugins** - DNS-01 validation via AWS Route53
3. **ACME Certificates** - Certificate ordering and lifecycle management

## Features

- ✅ Let's Encrypt certificate provisioning
- ✅ AWS Route53 DNS-01 challenge support
- ✅ Automatic certificate renewal (via Proxmox)
- ✅ Multi-account and multi-certificate support via `for_each`
- ✅ Terraform state management for existing certificates

## Prerequisites

1. **Proxmox VE** with ACME support (tested with 7.x+)
2. **AWS Route53** access for DNS challenge validation
3. **Doppler** configured with Route53 credentials
4. **BPG Proxmox Provider** >= 0.90.0

## Usage

```hcl
module "acme_certificates" {
  source = "./modules/acme-certificate"

  acme_accounts = {
    "letsencrypt" = {
      email      = "admin@example.com"
      directory  = "https://acme-v02.api.letsencrypt.org/directory"
      tos_agreed = true
    }
  }

  dns_plugins = {
    "route53" = {
      plugin_type = "route53"
      api_type    = "aws"
    }
  }

  acme_certificates = {
    "pve-cert" = {
      node_name      = "pve"
      domain         = "pve.example.com"
      account_id     = "letsencrypt"
      dns_plugin_id  = "route53"
    }
  }

  environment = "homelab"
}
```

## Variables

### `acme_accounts`

Map of ACME account configurations.

**Example:**
```hcl
acme_accounts = {
  "letsencrypt" = {
    email      = "admin@example.com"
    directory  = "https://acme-v02.api.letsencrypt.org/directory"  # Production
    tos_agreed = true
  }
  "letsencrypt-staging" = {
    email      = "admin@example.com"
    directory  = "https://acme-staging-v02.api.letsencrypt.org/directory"  # Testing
    tos_agreed = true
  }
}
```

**Fields:**
- `email` - Email for Let's Encrypt notifications (required)
- `directory` - ACME directory URL (required)
  - Production: `https://acme-v02.api.letsencrypt.org/directory`
  - Staging: `https://acme-staging-v02.api.letsencrypt.org/directory`
- `tos_agreed` - Agree to Let's Encrypt TOS (default: true)

### `dns_plugins`

Map of DNS challenge plugin configurations.

**Example (Route53):**
```hcl
dns_plugins = {
  "route53" = {
    plugin_type = "route53"
    api_type    = "aws"
  }
}
```

**Fields:**
- `plugin_type` - Plugin identifier (e.g., "route53", "dns01")
- `api_type` - API type (e.g., "aws")

**Note:** API credentials (AWS access key, secret key) are configured in Proxmox at `/etc/pve/priv/acme/plugins.cfg`. These are populated via the Proxmox API but not directly managed by this module.

### `acme_certificates`

Map of certificate configurations.

**Example:**
```hcl
acme_certificates = {
  "pve-cert" = {
    node_name      = "pve"
    domain         = "pve.example.com"
    account_id     = "letsencrypt"
    dns_plugin_id  = "route53"
  }
}
```

**Fields:**
- `node_name` - Proxmox node name (e.g., "pve")
- `domain` - Primary domain for certificate
- `account_id` - Associated ACME account ID
- `dns_plugin_id` - DNS plugin ID for DNS-01 validation

### `environment`

Environment name for organization and tagging.

**Default:** `"homelab"`

## Outputs

### `acme_accounts`

Account information including ID and email address.

```hcl
output "accounts" {
  value = module.acme_certificates.acme_accounts
}
# {
#   "letsencrypt" = {
#     id    = "letsencrypt"
#     email = "admin@example.com"
#   }
# }
```

### `dns_plugins`

Configured DNS challenge plugins.

```hcl
output "plugins" {
  value = module.acme_certificates.dns_plugins
}
# {
#   "route53" = {
#     id       = "route53"
#     plugin   = "route53"
#     api_type = "aws"
#   }
# }
```

### `certificates`

Certificate details including node, account, and domains.

```hcl
output "certs" {
  value = module.acme_certificates.certificates
}
# {
#   "pve-cert" = {
#     node_name = "pve"
#     account   = "letsencrypt"
#     domains   = ["pve.example.com"]
#   }
# }
```

## Certificate Lifecycle

### Ordering

When a certificate is first created:
1. Proxmox contacts Let's Encrypt ACME directory
2. Proxmox creates DNS TXT records for validation
3. Let's Encrypt validates DNS records
4. Certificate is issued and stored in Proxmox

### Renewal

Proxmox automatically renews certificates via `pve-daily-update.service`:
- Runs daily
- Checks certificates 30 days before expiry
- Re-validates via DNS-01 challenge
- Updates certificate in place

**Monitor renewal:**
```bash
systemctl status pve-daily-update.timer
journalctl -u pve-daily-update.service --since "7 days ago"
```

### Manual Renewal

If needed, trigger renewal manually:
```bash
pvenode acme cert order
```

## Importing Existing Certificates

If you have existing ACME certificates in Proxmox, import them:

```bash
# Import ACME account
terraform import 'module.acme_certificates.proxmox_virtual_environment_acme_account.accounts["letsencrypt"]' 'letsencrypt'

# Import DNS plugin
terraform import 'module.acme_certificates.proxmox_virtual_environment_acme_dns_plugin.dns_plugins["route53"]' 'route53'

# Import certificate
terraform import 'module.acme_certificates.proxmox_virtual_environment_acme_certificate.certificates["pve-cert"]' 'pve'
```

## Troubleshooting

### Certificate ordering fails with DNS validation error

**Issue:** Let's Encrypt cannot validate DNS records

**Causes:**
- Route53 credentials incorrect
- IAM permissions insufficient
- DNS records not propagating
- Proxmox cannot reach AWS

**Solution:**
1. Verify Route53 IAM policy allows DNS operations
2. Check DNS propagation: `dig -t TXT _acme-challenge.pve.example.com @8.8.8.8`
3. Monitor Proxmox logs: `journalctl -u pve-daily-update.service`

### Certificate renewal fails

**Issue:** Proxmox cannot renew existing certificate

**Causes:**
- Route53 credentials expired or revoked
- DNS plugin misconfiguration
- Proxmox service issues

**Solution:**
1. Verify Doppler secrets are up to date
2. Check Proxmox service status: `systemctl status pveproxy`
3. Review renewal logs: `journalctl -u pve-daily-update.service`

### Terraform plan shows changes after import

**Issue:** Imported resources don't match Terraform configuration

**Solution:**
1. Extract imported state: `terraform state show 'module.acme_certificates.proxmox_virtual_environment_acme_account.accounts["letsencrypt"]'`
2. Compare with variable values
3. Update variables to match Proxmox configuration
4. Re-run plan to verify zero drift

## Best Practices

1. **Use production Let's Encrypt** - Only use staging for testing due to rate limits
2. **Monitor renewals** - Set up alerts for renewal failures
3. **Rotate credentials** - Rotate Route53 IAM keys quarterly
4. **Backup certificates** - Keep exported certificate copies
5. **Document changes** - Keep Terraform configuration in sync with manual changes

## References

- [BPG Proxmox Provider](https://github.com/bpg/terraform-provider-proxmox)
- [Proxmox Certificate Management](https://pve.proxmox.com/wiki/Certificate_Management)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [ACME DNS API Support](https://github.com/acmesh-official/acme.sh/blob/master/dnsapi/README.md)
