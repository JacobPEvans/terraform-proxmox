output "vm_password" {
  description = "Generated password for VMs"
  value       = random_password.vm_password.result
  sensitive   = true
}

output "vm_private_key" {
  description = "Private SSH key for VMs"
  value       = tls_private_key.vm_key.private_key_pem
  sensitive   = true
}

output "vm_public_key" {
  description = "Public SSH key for VMs"
  value       = tls_private_key.vm_key.public_key_openssh
}

output "vm_public_key_trimmed" {
  description = "Trimmed public SSH key for VMs"
  value       = trimspace(tls_private_key.vm_key.public_key_openssh)
}
