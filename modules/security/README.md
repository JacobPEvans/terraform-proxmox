# Security Module

This module generates and manages security-related resources including SSH keys, passwords, and other credentials for Proxmox infrastructure.

## Features

- ✅ Automated SSH key pair generation with configurable key size
- ✅ Secure random password generation with customizable complexity
- ✅ Proper lifecycle management to prevent credential regeneration
- ✅ Sensitive data handling with appropriate output marking
- ✅ RSA key validation and security best practices

## Usage

### Basic Security Setup

```hcl
module "security" {
  source = "./modules/security"

  environment      = "production"
  password_length  = 16
  password_special = true
  rsa_bits         = 2048
}
```

### Advanced Security Configuration

```hcl
module "security" {
  source = "./modules/security"

  environment      = "staging"
  password_length  = 24
  password_special = true
  password_upper   = true
  password_lower   = true
  password_numeric = true
  rsa_bits         = 4096
}
```

### Using Generated Credentials

```hcl
# Use in VM configuration
resource "proxmox_virtual_environment_vm" "example" {
  initialization {
    user_account {
      username = "ubuntu"
      password = module.security.vm_password
      keys     = [module.security.vm_public_key_trimmed]
    }
  }
}

# Access private key for SSH connections
locals {
  ssh_private_key = module.security.vm_private_key
}
```

## Input Variables

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `environment` | Environment name for resource naming | `string` | ✅ | - |
| `password_length` | Length of generated password | `number` | ❌ | `16` |
| `password_special` | Include special characters in password | `bool` | ❌ | `true` |
| `password_upper` | Include uppercase letters | `bool` | ❌ | `true` |
| `password_lower` | Include lowercase letters | `bool` | ❌ | `true` |
| `password_numeric` | Include numeric characters | `bool` | ❌ | `true` |
| `rsa_bits` | RSA key size in bits (2048, 3072, 4096) | `number` | ❌ | `2048` |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `vm_password` | Generated password for VM user accounts | ✅ |
| `vm_public_key` | SSH public key (with newlines) | ❌ |
| `vm_public_key_trimmed` | SSH public key (trimmed) | ❌ |
| `vm_private_key` | SSH private key | ✅ |
| `vm_private_key_filename` | Suggested filename for private key | ❌ |

## Security Best Practices

### Password Security
- Use minimum 16 characters for passwords
- Enable special characters for increased entropy
- Store passwords in secure parameter stores (AWS SSM, HashiCorp Vault)
- Rotate passwords regularly

### SSH Key Security
- Use minimum 2048-bit RSA keys (4096-bit for high-security environments)
- Store private keys securely with appropriate file permissions (600)
- Use separate keys for different environments
- Implement key rotation policies

### Terraform State Security
- Enable state encryption for remote backends
- Restrict access to state files
- Use state locking to prevent concurrent modifications
- Regular state backups with encryption

## Key Validation

The module includes validation rules for RSA key sizes:

```hcl
validation {
  condition     = contains([2048, 3072, 4096], var.rsa_bits)
  error_message = "RSA key size must be 2048, 3072, or 4096 bits."
}
```

## Lifecycle Management

Resources are configured with lifecycle rules to prevent accidental regeneration:

```hcl
lifecycle {
  create_before_destroy = true
  ignore_changes = [
    # Prevent password regeneration on plan/apply
    keepers
  ]
}
```

## Integration Examples

### With VM Module

```hcl
module "security" {
  source = "./modules/security"
  environment = var.environment
}

module "vms" {
  source = "./modules/proxmox-vm"

  vms = {
    "web-server" = {
      vm_id = 201
      name  = "web-server"

      user_account = {
        username = "ubuntu"
        password = module.security.vm_password
        keys     = [module.security.vm_public_key_trimmed]
      }
    }
  }
}
```

### With Container Module

```hcl
module "containers" {
  source = "./modules/proxmox-container"

  containers = {
    "app-container" = {
      vm_id = 301

      user_account = {
        password = module.security.vm_password
        keys     = [module.security.vm_public_key_trimmed]
      }
    }
  }
}
```

## Troubleshooting

### Common Issues

1. **Key regeneration**: Check lifecycle rules and keepers configuration
2. **Permission errors**: Ensure proper file permissions for private keys
3. **Validation failures**: Verify RSA key size is supported (2048, 3072, 4096)

### Accessing Generated Credentials

```bash
# View public key
terraform output vm_public_key

# Save private key to file (be careful with permissions)
terraform output -raw vm_private_key > ~/.ssh/proxmox_key
chmod 600 ~/.ssh/proxmox_key

# Test SSH connection
ssh -i ~/.ssh/proxmox_key ubuntu@vm-ip-address
```

## Requirements

- Terraform >= 1.0
- hashicorp/tls provider >= 4.1.0
- hashicorp/random provider >= 3.7.2

## Security Considerations

- Never commit private keys to version control
- Use secure backends for Terraform state
- Implement proper access controls for generated credentials
- Regular security audits and key rotation
- Monitor access to sensitive outputs
