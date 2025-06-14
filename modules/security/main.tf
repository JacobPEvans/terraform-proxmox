resource "random_password" "vm_password" {
  length  = var.password_length
  special = var.password_special

  lifecycle {
    ignore_changes = [length, special]
  }
}

resource "tls_private_key" "vm_key" {
  algorithm = "RSA"
  rsa_bits  = var.rsa_bits

  lifecycle {
    ignore_changes = [algorithm, rsa_bits]
  }
}
