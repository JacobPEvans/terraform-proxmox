# Infisical Module (Reserved)

<!-- DO NOT DELETE - Placeholder for future Infisical Terraform provider integration -->

This module is reserved for future Infisical Terraform provider resources
(e.g., projects, environments, secret syncing) once the provider reaches
stable release.

**Current state:** The Infisical LXC container (ID 120) is provisioned via
the generic `proxmox-container` module through `deployment.json`. Docker
Compose deployment and service configuration are handled by Ansible in the
`ansible-proxmox-apps` repository.

**This module will be used when:**

- Infisical Terraform provider reaches stable release
- Migrating from Doppler to Infisical for secret injection
- Managing Infisical projects/environments as code

## References

- [Infisical Planning Document](../../docs/INFISICAL_PLANNING.md)
- [Secrets Roadmap](../../docs/SECRETS_ROADMAP.md)
- [Infisical Terraform Provider](https://registry.terraform.io/providers/Infisical/infisical/latest)
