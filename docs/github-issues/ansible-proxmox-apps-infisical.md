# GitHub Issue for ansible-proxmox-apps

**Create this issue at**: https://github.com/JacobPEvans/ansible-proxmox-apps/issues/new

**Labels**: `type:feature`, `type:security`, `priority:high`, `size:l`, `ai:created`

---

## Title

```
feat(infisical_docker): add role to deploy Infisical secrets manager via Docker Compose
```

## Body

### Summary

Add a new `infisical_docker` Ansible role to deploy self-hosted [Infisical](https://infisical.com/) secrets management platform via Docker Compose on LXC container ID 120.

**Upstream**: Container provisioned in [terraform-proxmox](https://github.com/JacobPEvans/terraform-proxmox) (ID 120, 2 cores, 4GB RAM, 30GB data volume at `/opt/infisical`).

### Scope

This issue covers everything that **cannot** be done via Terraform — all configuration management and application deployment.

#### Role: `infisical_docker`

- [ ] Docker Compose deployment (Infisical server + embedded PostgreSQL + Redis)
- [ ] TLS configuration (ACME certificate or reverse proxy)
- [ ] Persistent data at `/opt/infisical/` (postgres-data, redis-data)
- [ ] Environment variable configuration (`ENCRYPTION_KEY`, `AUTH_SECRET`, database URLs)
- [ ] Secrets managed via SOPS or Doppler (`INFISICAL_ENCRYPTION_KEY`, `INFISICAL_AUTH_SECRET`)
- [ ] DNS record in Technitium: `infisical.example.local`
- [ ] Health check validation (curl HTTPS endpoint)

#### Backup Automation (Critical)

Infisical is a secrets manager — data loss is catastrophic. Backup must survive **total Proxmox host failure**.

- [ ] Automated daily `pg_dump` via cron (Docker exec into PostgreSQL container)
- [ ] Compressed backup stored at `/opt/infisical/backups/`
- [ ] S3 upload after each dump (encrypted, server-side SSE-S3/KMS)
- [ ] S3 bucket with versioning + lifecycle rules (7 daily, 4 weekly retention)
- [ ] IAM role with write-only S3 access for the backup job
- [ ] Encryption key backup procedure documented (keys stored in Doppler AND SOPS)
- [ ] Restore playbook/script that pulls latest backup from S3 and loads into fresh PostgreSQL
- [ ] Backup monitoring/alerting (optional: ntfy notification on backup failure)

#### Integration

- [ ] Add `infisical_group` to inventory in `load_terraform.yml`
- [ ] Integrate with `site.yml` playbook
- [ ] Add secrets to `secrets.enc.yaml.example`
- [ ] Add validate-pipeline play for Infisical service

#### Testing

- [ ] Molecule test for the `infisical_docker` role
- [ ] Template render tests
- [ ] Backup/restore integration test

### Recovery Procedure

After total Proxmox host failure:

```bash
# 1. Terraform recreates empty LXC container (ID 120)
aws-vault exec terraform -- doppler run -- terragrunt apply

# 2. Ansible deploys Infisical stack
ansible-playbook -i inventory/ playbooks/site.yml --tags infisical_docker

# 3. Restore database from S3
ansible-playbook -i inventory/ playbooks/infisical-restore.yml

# 4. Verify
curl -k https://infisical.example.local:8443/api/status
```

**RPO**: < 24 hours | **RTO**: ~1 hour

### Related

- terraform-proxmox: Container provisioning (ID 120, `secrets` tag, `secrets-svc` firewall group)
- [INFISICAL_PLANNING.md](https://github.com/JacobPEvans/terraform-proxmox/blob/main/docs/INFISICAL_PLANNING.md) — Full architecture and backup design
- [SECRETS_ROADMAP.md](https://github.com/JacobPEvans/terraform-proxmox/blob/main/docs/SECRETS_ROADMAP.md) — Migration path from Doppler
- #74 — Prior art: mailpit and ntfy Docker roles
- #72 — Prior art: mssql_docker role
- #84 — Related: validate-pipeline plays

### Test plan

- [ ] Verify `uv run ansible-lint` passes
- [ ] Deploy to LXC container 120
- [ ] Confirm Infisical is reachable at https://infisical.example.local:8443
- [ ] Run backup manually and verify S3 upload
- [ ] Test restore procedure on a fresh container
- [ ] Verify encryption keys allow decryption of restored data
