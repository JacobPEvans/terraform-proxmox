variable "acme_accounts" {
  description = "ACME account configurations for Let's Encrypt certificate management"
  type = map(object({
    email      = string  # Email address for Let's Encrypt notifications
    directory  = string  # ACME directory URL (production or staging)
    tos_agreed = bool    # Must be true to accept Let's Encrypt TOS
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.acme_accounts :
      can(regex("^[^@]+@[^@]+\\.[^@]+$", v.email))
    ])
    error_message = "Each email must be a valid email address."
  }

  validation {
    condition = alltrue([
      for k, v in var.acme_accounts :
      can(regex(
        "^(https://acme-v02\\.api\\.letsencrypt\\.org/directory|https://acme-staging-v02\\.api\\.letsencrypt\\.org/directory)$",
        v.directory
      ))
    ])
    error_message = "Each directory must be an HTTPS URL pointing to the Let's Encrypt ACME v2 production or staging directory."
  }
}

variable "dns_plugins" {
  description = "DNS challenge plugins for ACME validation (e.g., AWS Route53)"
  type = map(object({
    plugin_type = string # Plugin identifier (e.g., "route53")
    api         = string # AWS credentials as JSON string (e.g., {\"access_key\": \"...\", \"secret_key\": \"...\"})
  }))
  default = {}

  sensitive = true # Contains DNS provider credentials
}

variable "acme_certificates" {
  description = "ACME certificates to provision and manage"
  type = map(object({
    node_name      = string # Proxmox node name (e.g., "pve")
    domain         = string # Primary domain for certificate
    account_id     = string # Associated ACME account ID
    dns_plugin_id  = string # DNS plugin ID for validation
  }))
  default = {}
}

variable "environment" {
  description = "Environment name for tagging and organization"
  type        = string
  default     = "homelab"
}
