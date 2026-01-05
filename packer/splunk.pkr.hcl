packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-clone" "splunk" {
  # Connection - uses Doppler env vars (token auth preferred)
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  node                     = var.proxmox_node
  insecure_skip_tls_verify = var.proxmox_insecure_skip_tls_verify

  # Clone from base template
  clone_vm             = "debian-12-base"
  vm_id                = 9200
  template_name        = "splunk-enterprise-10"
  template_description = "Splunk ${var.splunk_version} on Debian 12 (Packer)"
  full_clone           = true

  # SSH (matches base template cloud-init)
  ssh_username = "debian"
  ssh_password = var.packer_ssh_password
  ssh_timeout  = "15m"

  # Build resources
  cores  = 4
  memory = 4096
}

build {
  sources = ["source.proxmox-clone.splunk"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y wget",
      "wget -O splunk.deb 'https://download.splunk.com/products/splunk/releases/${var.splunk_version}/linux/splunk-${var.splunk_version}-${var.splunk_build}-linux-amd64.deb'",
      "echo \"${var.splunk_download_sha512}  splunk.deb\" | sha512sum -c -",
      "sudo dpkg -i splunk.deb",
      "rm splunk.deb",
      "sudo tee /opt/splunk/etc/system/local/user-seed.conf > /dev/null <<EOF\n[user_info]\nUSERNAME = admin\nPASSWORD = ${var.splunk_admin_password}\nEOF",
      "sudo /opt/splunk/bin/splunk enable boot-start --accept-license --answer-yes --no-prompt",
      "sudo cloud-init clean",
      "sudo truncate -s 0 /etc/machine-id"
    ]
  }
}
