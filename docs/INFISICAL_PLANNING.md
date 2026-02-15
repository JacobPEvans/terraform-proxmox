# Infisical Planning

<!-- DO NOT DELETE - Active planning document -->

Self-hosted Infisical deployment on Proxmox infrastructure.

**Status:** PLANNED

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

## Proposed Architecture

### Deployment Target

| Component | Resource | Notes |
| --- | --- | --- |
| Infisical Server | LXC container or VM | Docker Compose deployment |
| PostgreSQL | Same container or dedicated | Infisical backend database |
| Redis | Same container | Caching and queue |

### Network Integration

- Internal access only (no public exposure)
- DNS entry via Technitium: `infisical.example.local`
- TLS via ACME certificate module (existing)
- Firewall rules via existing firewall module

### Resource Estimates

| Resource | Minimum | Recommended |
| --- | --- | --- |
| CPU | 2 cores | 4 cores |
| RAM | 2 GB | 4 GB |
| Disk | 10 GB | 20 GB |

## Migration Plan

### Phase 1: Deploy and Validate

1. Provision LXC container via terraform-proxmox
2. Deploy Infisical via Docker Compose (Ansible role)
3. Configure initial projects and environments
4. Validate API access and CLI connectivity

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
| Single point of failure | Daily PostgreSQL backups to S3 |
| Infisical upgrades break API | Pin version, test upgrades in staging |
| Lost admin credentials | Recovery keys stored in SOPS-encrypted file |
| Container failure | Proxmox HA restart policy |

## Decision Criteria

Proceed with implementation when:

- [ ] SOPS + Age integration is stable across repos
- [ ] Proxmox cluster has available capacity
- [ ] Infisical Terraform provider reaches stable release
- [ ] Current Doppler costs justify migration effort

## References

- [Infisical Documentation](https://infisical.com/docs)
- [Infisical Terraform Provider](https://registry.terraform.io/providers/Infisical/infisical/latest)
- [Infisical Self-Hosting Guide](https://infisical.com/docs/self-hosting/overview)
