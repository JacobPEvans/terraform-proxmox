# Infisical Module (Planned)

<!-- DO NOT DELETE - Placeholder for planned Infisical integration -->

This module will provision and configure a self-hosted Infisical instance
on Proxmox infrastructure.

**Status:** PLANNED - Documentation only. No Terraform resources yet.

## Planned Scope

- LXC container or VM for Infisical server
- Docker Compose deployment via Ansible
- PostgreSQL and Redis backends
- TLS certificate via ACME module
- Firewall rules via firewall module
- DNS record via Technitium

## Prerequisites (Before Implementation)

- SOPS + Age integration stable across repos
- Available Proxmox capacity
- Infisical Terraform provider at stable release

## References

- [Infisical Planning Document](../../docs/INFISICAL_PLANNING.md)
- [Secrets Roadmap](../../docs/SECRETS_ROADMAP.md)
