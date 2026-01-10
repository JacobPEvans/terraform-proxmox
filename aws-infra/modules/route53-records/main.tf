terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# NOTE: AWS Provider is configured in parent module (aws-infra/main.tf)
# This module inherits the provider from its parent

# A Record for Proxmox VE UI
# Points the Proxmox domain to the Proxmox host IP address
resource "aws_route53_record" "proxmox" {
  zone_id = var.route53_zone_id
  name    = var.proxmox_domain
  type    = "A"
  ttl     = var.dns_ttl
  records = [var.proxmox_ip_address]

  lifecycle {
    # Prevent accidental deletion of critical DNS record
    prevent_destroy = false # Set to true in production
  }
}
