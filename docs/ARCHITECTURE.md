# Infrastructure Architecture

Canonical architecture reference for the Proxmox homelab ecosystem.
All other repositories link here; this is the single source of truth.

## Repository Dependency Graph

```mermaid
graph TD
    subgraph "Infrastructure Layer"
        TP[terraform-proxmox]
        TA[terraform-aws]
        TAB[terraform-aws-bedrock]
        TAS[terraform-aws-static-website]
    end

    subgraph "Configuration Layer"
        AP[ansible-proxmox]
        APA[ansible-proxmox-apps]
        AS[ansible-splunk]
    end

    subgraph "Development & Applications"
        NC[nix-config]
        CR[cribl]
        SP[splunk]
    end

    subgraph "Secrets & Credentials"
        DOP[Doppler]
        AV[aws-vault]
        SOPS_AGE[SOPS + Age]
    end

    TP -->|ansible_inventory| APA
    TP -->|ansible_inventory| AS
    TP -->|VM/container IDs, IPs| AP
    TA -->|Route53 DNS| TP
    DOP -->|PROXMOX_VE_* env vars| TP
    DOP -->|SPLUNK_* env vars| AS
    DOP -->|env vars| APA
    AV -->|AWS creds for S3 backend| TP
    AV -->|AWS creds| TA
    NC -->|nix develop shells| TP
    NC -->|nix develop shells| TA
    CR -->|packs & configs| APA
    SP -->|add-ons| AS
    SOPS_AGE -.->|planned| TP
    SOPS_AGE -.->|planned| APA
```

## Data Pipeline Flow

```mermaid
flowchart LR
    subgraph Sources["Syslog Sources"]
        U[UniFi :1514]
        PA[Palo Alto :1515]
        CA[Cisco ASA :1516]
        LN[Linux :1517]
        WN[Windows :1518]
    end

    subgraph LB["Load Balancer"]
        HAP[HAProxy LXC<br/>:1514-1518 UDP/TCP<br/>Stats :8404]
    end

    subgraph Collectors["Docker Swarm Host"]
        CE1[Cribl Edge replica 1]
        CE2[Cribl Edge replica 2]
        PQ[(100GB persistent queue)]
    end

    subgraph Destination["Splunk Enterprise VM"]
        HEC[HEC :8088]
        WEB[Web UI :8000]
        MGMT[Mgmt :8089]
    end

    Sources --> HAP
    HAP -->|round-robin| CE1
    HAP -->|round-robin| CE2
    CE1 --> PQ
    CE2 --> PQ
    PQ -->|HEC HTTP| HEC
```

## Secrets Chain

```mermaid
flowchart TD
    subgraph Runtime["Runtime Secrets (Active)"]
        DOP[Doppler<br/>Project: iac-conf-mgmt]
        AV[aws-vault<br/>Profile: terraform]
        KC[macOS Keychain<br/>ai-secrets keychain]
    end

    subgraph Sync["Secrets Sync (Active)"]
        DS[doppler secrets-sync]
    end

    subgraph GitCommitted["Git-Committed Secrets (Planned)"]
        SOPS[SOPS + Age]
    end

    subgraph Consumers["Consumers"]
        TF[Terraform/Terragrunt]
        ANS[Ansible Playbooks]
        GHA[GitHub Actions]
        AI[Claude Code / AI Agents]
    end

    DOP -->|PROXMOX_VE_*| TF
    DOP -->|SPLUNK_*, env vars| ANS
    DOP -->|secrets-sync| DS
    DS -->|repository secrets| GHA
    AV -->|AWS_* creds| TF
    KC -->|API keys| AI
    SOPS -.->|encrypted tfvars| TF
    SOPS -.->|encrypted vars| ANS
```

## Infrastructure Components

### Proxmox VE Host

Single-node hypervisor running VMs and LXC containers.
Managed by `ansible-proxmox` (kernel, ZFS, monitoring, firewall).

### VMs (terraform-proxmox)

Provisioned via BPG Proxmox Terraform provider. IPs derived from VM ID:
`network_prefix.vm_id` (e.g., VM 200 = `192.168.0.200`).

| Resource | Type | Purpose |
| --- | --- | --- |
| Splunk VM | VM (dedicated module) | Splunk Enterprise in Docker |
| Docker Host | VM | Docker Swarm for Cribl Edge |
| Ansible VM | VM | Ansible control node |

### LXC Containers (terraform-proxmox)

| Resource | Type | Purpose |
| --- | --- | --- |
| HAProxy | LXC | Syslog load balancer |
| Technitium DNS | LXC | Internal DNS |
| apt-cacher-ng | LXC | APT package cache |

### Terraform Modules

| Module | Purpose |
| --- | --- |
| `proxmox-vm` | Generic VM provisioning |
| `proxmox-container` | LXC container provisioning |
| `proxmox-pool` | Resource pool management |
| `splunk-vm` | Splunk-specific VM with Docker |
| `firewall` | Proxmox firewall rules |
| `storage` | Datastore configuration |
| `acme-certificate` | Let's Encrypt via Route53 |
| `security` | Security policies |

### State Management

- **Backend**: S3 + DynamoDB (us-east-2)
- **Encryption**: Enabled at rest
- **Locking**: DynamoDB table per repo
- **Credential**: aws-vault (never stored in files)

## Downstream Inventory Flow

terraform-proxmox produces `ansible_inventory` output consumed by Ansible repos:

```bash
# Regenerate after terragrunt apply
terragrunt output -json ansible_inventory > \
  ~/git/ansible-proxmox-apps/main/inventory/terraform_inventory.json

terragrunt output -json ansible_inventory > \
  ~/git/ansible-splunk/main/inventory/terraform_inventory.json
```

The inventory includes:

- `containers` - LXC containers with `proxmox_pct_remote` connection
- `vms` - VMs with SSH connection
- `docker_vms` - VMs tagged "docker" (subset of vms)
- `splunk_vm` - Dedicated Splunk VM
- `constants` - Pipeline port definitions from `locals.tf`

## Tool Chain

All Terraform commands require the full toolchain wrapper:

```text
nix develop → aws-vault exec → doppler run → terragrunt <command>
```

- **Nix**: Consistent tool versions (Terraform, Terragrunt, Ansible)
- **aws-vault**: AWS credentials for S3 backend
- **Doppler**: Proxmox API credentials (`PROXMOX_VE_*` env vars)
- **Terragrunt**: Wrapper with remote state and provider generation

## Related Documentation

- [LOGGING_PIPELINE.md](./LOGGING_PIPELINE.md) - Detailed syslog pipeline
- [SECRETS_ROADMAP.md](./SECRETS_ROADMAP.md) - Unified secrets strategy
- [INFISICAL_PLANNING.md](./INFISICAL_PLANNING.md) - Self-hosted secrets manager planning
