variable "password_length" {
  description = "Length of the generated password"
  type        = number
  default     = 16
}

variable "password_special" {
  description = "Include special characters in the password"
  type        = bool
  default     = true
}

variable "rsa_bits" {
  description = "Number of bits for RSA key generation"
  type        = number
  default     = 2048
  validation {
    condition     = contains([2048, 3072, 4096], var.rsa_bits)
    error_message = "RSA bits must be 2048, 3072, or 4096."
  }
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "homelab"
}
