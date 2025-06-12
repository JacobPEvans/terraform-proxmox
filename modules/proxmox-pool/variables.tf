variable "pools" {
  description = "Map of resource pools to create"
  type = map(object({
    comment = optional(string, "Terraform managed pool")
  }))
  default = {}
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "homelab"
}
