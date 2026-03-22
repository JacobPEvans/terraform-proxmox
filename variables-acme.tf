# ACME variables: Let's Encrypt accounts, DNS challenge plugins, and certificates

variable "acme_accounts" {
  description = "ACME account configurations for Let's Encrypt certificate management"
  type = map(object({
    email     = string
    directory = string
    tos       = string
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
      can(regex("^https://[A-Za-z0-9._~:/?#\\[\\]@!$&'()*+,;=%-]+$", v.directory))
    ])
    error_message = "Each ACME directory must be a valid HTTPS URL (e.g., https://acme-v02.api.letsencrypt.org/directory)."
  }
}

variable "dns_plugins" {
  description = "DNS challenge plugins for ACME validation (e.g., AWS Route53)"
  type = map(object({
    plugin_type = string      # API plugin name (e.g., "route53")
    data        = map(string) # DNS plugin data as key=value pairs (e.g., AWS credentials)
  }))
  default = {}

  sensitive = true
}

variable "acme_certificates" {
  description = "ACME certificates to provision and manage"
  type = map(object({
    node_name     = string
    domain        = string
    account_id    = string
    dns_plugin_id = string
  }))
  default = {}
}

# NOTE: Route53 DNS configuration is now managed separately in aws-infra/
# See aws-infra/variables.tf for AWS-related variables
