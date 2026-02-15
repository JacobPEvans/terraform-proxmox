# Terraform Proxmox - AI Agent Documentation

Infrastructure-as-code for Proxmox VE homelab using Terraform/Terragrunt.

## Purpose

Provision VMs, containers, storage, and networking on Proxmox VE cluster.
This is the **infrastructure layer** - downstream Ansible repos handle
configuration management.

## Dependencies

### External Services

- **Doppler**: Proxmox API credentials (PROXMOX_VE_*)
- **aws-vault**: AWS credentials for S3 state backend
- **Nix + direnv**: Provides Terraform/Terragrunt toolchain (auto-activated via `.envrc`)

### State Backend

- **S3**: Terraform state storage
- **DynamoDB**: State locking

## Key Files

| Path | Purpose |
| ---- | ------- |
| `main.tf` | Root module orchestrating all resources |
| `outputs.tf` | Exports `ansible_inventory` for downstream repos |
| `modules/splunk-vm/` | Splunk VM module (VM 200) |
| `modules/proxmox-container/` | LXC container module |
| `modules/proxmox-vm/` | Generic VM module |
| `terragrunt.hcl` | Terragrunt configuration |

## Agent Tasks

### Running Terraform

The Nix shell is activated automatically via direnv (`.envrc`). All commands use the toolchain wrapper:

```bash
aws-vault exec terraform -- doppler run -- terragrunt <COMMAND>
```

Common operations:

- **Plan**: `terragrunt plan`
- **Apply**: `terragrunt apply`
- **Validate**: `terragrunt validate`

### Exporting Ansible Inventory

```bash
terragrunt output -json ansible_inventory > \
  <path-to-ansible-repo>/inventory/terraform_inventory.json
```

## Ansible Inventory Output

The `ansible_inventory` output provides structured data for Ansible:

```hcl
output "ansible_inventory" {
  value = {
    containers = { ... }
    vms = { ... }
    splunk_vm = {
      splunk = {
        vmid     = 200
        hostname = "splunk"
        ip       = "10.x.x.200"
      }
    }
  }
}
```

## Secrets Management

Secrets are loaded via Doppler using `PROXMOX_VE_*` naming:

- `PROXMOX_VE_ENDPOINT`: API URL
- `PROXMOX_VE_API_TOKEN`: API token
- `PROXMOX_VE_USERNAME`: Username
- `PROXMOX_VE_NODE`: Node name

## Related Repositories

- **ansible-splunk**: Splunk configuration (consumes inventory)
- **ansible-proxmox**: Proxmox host configuration
- **ansible-proxmox-apps**: Application deployment (Cribl, HAProxy)
