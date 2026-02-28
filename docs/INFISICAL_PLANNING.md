# Infisical Planning

<!-- DO NOT DELETE - Active planning document -->

Self-hosted Infisical deployment on Proxmox infrastructure.

**Status:** IN PROGRESS — Container provisioned via Terraform, Ansible configuration pending

## Overview

Infisical is an open-source secrets management platform that provides
centralized secret storage, rotation, and injection with native
integrations for Terraform, Ansible, and CI/CD platforms.

## Why Self-Hosted Infisical

- **Data sovereignty**: All secrets remain on-premises
- **No SaaS dependency**: Eliminates Doppler subscription cost
- **Native integrations**: Terraform provider, Ansible lookup plugin, CLI
- **Web UI**: Browser-based secret management and audit trails
- **RBAC**: Fine-grained access control per project and environment

## Container Specification

| Property | Value |
| --- | --- |
| **VM ID** | 120 |
| **Hostname** | infisical |
| **IP** | `network_prefix`.120 (derived from VM ID) |
| **Type** | LXC (Docker-in-LXC, unprivileged) |
| **CPU** | 2 cores |
| **RAM** | 4 GB (+ 2 GB swap) |
| **Root Disk** | 16 GB on local-zfs |
| **Data Volume** | 30 GB on local-zfs mounted at /opt/infisical |
| **Pool** | infrastructure |
| **Tags** | terraform, container, secrets, docker |
| **Features** | nesting, keyctl, fuse (Docker-in-LXC) |

### Architecture

All services run inside a single LXC container via Docker Compose:

```text
┌─────────────────────────────────────────┐
│ LXC Container (ID 120)                  │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ Docker Compose                  │    │
│  │  ├─ infisical-server (:8443)    │    │
│  │  ├─ postgresql                  │    │
│  │  └─ redis                       │    │
│  └─────────────────────────────────┘    │
│                                         │
│  /opt/infisical/                        │
│    ├─ postgres-data/                    │
│    ├─ redis-data/                       │
│    ├─ docker-compose.yml                │
│    └─ backups/   (staging for S3 push)  │
└─────────────────────────────────────────┘
```

### Network Integration

- Internal access only (no public exposure)
- DNS entry via Technitium: `infisical.example.local`
- TLS via ACME certificate module (existing)
- Firewall: inbound DROP, outbound ACCEPT
  - Port 22 (SSH) from management_network
  - Port 8443 (HTTPS API/Web UI) from internal_networks
  - ICMP from internal_networks

### Firewall Security Group

Uses dedicated `secrets-svc` security group applied to containers tagged `secrets`:

```text
Inbound:  internal-access (SSH, ICMP) + secrets-svc (8443/tcp)
Outbound: ACCEPT (needed for Docker pulls, updates, S3 backup uploads)
```

## Disaster Recovery / Backup Strategy

**Goal**: Full recovery from total Proxmox host failure with < 24h RPO.

### What Must Be Backed Up

| Data | Location | Criticality |
| --- | --- | --- |
| PostgreSQL database | /opt/infisical/postgres-data/ | **Critical** — all secrets, projects, users |
| Infisical encryption keys | Environment variables / Docker Compose | **Critical** — needed to decrypt DB contents |
| Redis data | /opt/infisical/redis-data/ | Low — ephemeral cache, auto-rebuilds |
| Docker Compose config | /opt/infisical/docker-compose.yml | Medium — reproducible from Ansible role |

### Backup Architecture

```text
┌──────────────────┐    pg_dump     ┌──────────────────┐    aws s3 cp    ┌─────────────┐
│ PostgreSQL (LXC) │ ──────────────→│ /opt/infisical/  │ ──────────────→│ S3 Bucket   │
│                  │   daily cron   │ backups/          │   after dump   │ (encrypted) │
└──────────────────┘                └──────────────────┘                └─────────────┘

Encryption keys → SOPS-encrypted file in git (terraform.sops.json or dedicated file)
```

### Backup Components

1. **Automated PostgreSQL dumps (daily)**
   - Ansible cron job: `pg_dump` → compressed `.sql.gz` in `/opt/infisical/backups/`
   - Retention: 7 daily + 4 weekly locally, unlimited in S3 with lifecycle rules
   - Runs inside the container via Docker exec

2. **S3 offsite push (after each dump)**
   - `aws s3 cp` with server-side encryption (SSE-S3 or SSE-KMS)
   - Uses dedicated IAM role with write-only S3 access
   - aws-vault credentials injected by Ansible at deploy time
   - S3 bucket configured with versioning and lifecycle rules

3. **Encryption key backup**
   - `ENCRYPTION_KEY` and `AUTH_SECRET` stored in Doppler (current) or SOPS
   - Keys are also needed for restore — without them, database is useless
   - Recovery procedure documented in this file (see below)

4. **Container rebuild (Ansible-driven)**
   - Terraform recreates the empty LXC container
   - Ansible role redeploys Docker Compose stack
   - Restore script loads latest S3 backup into fresh PostgreSQL

### Recovery Procedure

**Total Proxmox host failure recovery:**

```bash
# 1. Rebuild infrastructure (new Proxmox host)
aws-vault exec terraform -- doppler run -- terragrunt apply

# 2. Run Ansible to deploy Infisical stack
cd ~/git/ansible-proxmox-apps
ansible-playbook -i inventory/ playbooks/infisical.yml

# 3. Restore database from S3 (run on infisical container)
# Ansible restore playbook handles this, or manual:
aws s3 cp s3://BUCKET/infisical/latest.sql.gz /opt/infisical/backups/
docker exec -i infisical-postgres psql -U infisical < /opt/infisical/backups/latest.sql

# 4. Verify Infisical is operational
curl -k https://infisical.example.local:8443/api/status
```

**RPO**: < 24 hours (daily backups)
**RTO**: ~1 hour (Terraform + Ansible + restore)

## Migration Plan

### Phase 1: Deploy and Validate (current)

1. [x] Provision LXC container via terraform-proxmox
2. [ ] Deploy Infisical via Docker Compose (Ansible role) — see ansible-proxmox-apps issue
3. [ ] Configure S3 backup bucket and IAM role
4. [ ] Set up automated backup cron job
5. [ ] Configure initial projects and environments
6. [ ] Validate API access and CLI connectivity
7. [ ] Test backup and restore procedure

### Phase 2: Mirror Doppler Secrets

1. Export Doppler secrets (excluding rotation-sensitive ones)
2. Import into Infisical projects matching Doppler structure
3. Run both systems in parallel for validation
4. Verify terraform and ansible can read from Infisical

### Phase 3: Migrate Consumers

1. Update terraform-proxmox to use Infisical provider
2. Update ansible repos to use Infisical lookup plugin
3. Configure Infisical GitHub Actions integration (replace secrets-sync)
4. Update CI/CD workflows

### Phase 4: Decommission Doppler

1. Verify all consumers use Infisical
2. Remove Doppler CLI references from toolchain docs
3. Cancel Doppler subscription
4. Keep Doppler CLI installed as emergency fallback (30 days)

## Terraform Integration

```hcl
# Example: Infisical provider configuration
provider "infisical" {
  host          = "https://infisical.example.local"
  client_id     = var.infisical_client_id
  client_secret = var.infisical_client_secret
}

data "infisical_secrets" "proxmox" {
  env_slug     = "prd"
  project_id   = var.infisical_project_id
  folder_path  = "/proxmox"
}
```

## Ansible Integration

```yaml
# Example: Infisical lookup plugin
- name: Get Splunk HEC token
  ansible.builtin.set_fact:
    splunk_hec_token: "{{ lookup('infisical', 'SPLUNK_HEC_TOKEN',
      project_id=infisical_project_id,
      environment='prd') }}"
```

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Single point of failure | Daily PostgreSQL backups to S3 (off-host) |
| Total Proxmox host loss | S3 backups + SOPS encryption keys enable full rebuild |
| Infisical upgrades break API | Pin version, test upgrades in staging |
| Lost admin credentials | Recovery keys stored in SOPS-encrypted file |
| Lost encryption keys | Keys stored in Doppler AND SOPS (dual backup) |
| Container failure | Proxmox start_on_boot + Ansible can redeploy |
| S3 backup corruption | S3 versioning enabled, multiple retention tiers |

## Decision Criteria

Proceed with implementation when:

- [x] SOPS + Age integration is stable across repos
- [x] Proxmox cluster has available capacity
- [ ] Infisical Terraform provider reaches stable release
- [ ] Current Doppler costs justify migration effort

## References

- [Infisical Documentation](https://infisical.com/docs)
- [Infisical Terraform Provider](https://registry.terraform.io/providers/Infisical/infisical/latest)
- [Infisical Self-Hosting Guide](https://infisical.com/docs/self-hosting/overview)
