output "acme_accounts" {
  description = "ACME account details"
  value = {
    for k, v in proxmox_virtual_environment_acme_account.accounts : k => {
      id    = v.account_id
      email = v.email
    }
  }
}

output "dns_plugins" {
  description = "Configured DNS challenge plugins"
  value = {
    for k, v in proxmox_virtual_environment_acme_dns_plugin.dns_plugins : k => {
      id         = v.id
      plugin     = v.plugin
      api_type   = v.api
    }
  }
}

output "certificates" {
  description = "ACME certificates information"
  value = {
    for k, v in proxmox_virtual_environment_acme_certificate.certificates : k => {
      node_name = v.node_name
      account   = v.account
      domains   = [for d in v.domains : d.domain]
    }
  }
}
