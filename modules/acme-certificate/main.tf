terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.90.0"
    }
  }
}

# ACME Account - Let's Encrypt account registration
# This is a prerequisite for certificate ordering
resource "proxmox_virtual_environment_acme_account" "accounts" {
  for_each = var.acme_accounts

  name      = each.key
  contact   = each.value.email
  directory = each.value.directory
  tos       = each.value.tos_url

  # Prevent unnecessary drift after initial creation
  # Account properties are managed by Let's Encrypt
  lifecycle {
    ignore_changes = [tos]
  }
}

# DNS Challenge Plugin - AWS Route53
# Configures Route53 as the DNS-01 challenge provider for ACME validation
# This allows certificate validation without exposing port 80 publicly
resource "proxmox_virtual_environment_acme_dns_plugin" "dns_plugins" {
  for_each = var.dns_plugins

  plugin = each.key                # Plugin identifier (e.g., "myroute53")
  api    = each.value.plugin_type  # API plugin name (e.g., "route53")
  data   = each.value.data         # DNS plugin data (credentials as key=value pairs)
}

# ACME Certificate - the actual TLS certificate
# This resource manages the certificate lifecycle including ordering and renewal
# Proxmox automatically renews certificates 30 days before expiry via pve-daily-update.service
resource "proxmox_virtual_environment_acme_certificate" "certificates" {
  for_each = var.acme_certificates

  node_name = each.value.node_name
  account   = each.value.account_id
  domains = [
    {
      domain = each.value.domain
      plugin = each.value.dns_plugin_id
    }
  ]

  # Note: Proxmox manages certificate renewal automatically via pve-daily-update.service
  # Terraform manages the certificate resource but respects Proxmox's automatic renewal

  # Ensure dependencies are satisfied
  depends_on = [
    proxmox_virtual_environment_acme_account.accounts,
    proxmox_virtual_environment_acme_dns_plugin.dns_plugins
  ]
}
