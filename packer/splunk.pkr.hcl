packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-clone" "splunk" {
  # Connection - uses Doppler env vars
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  # Clone from base template
  clone_vm             = "debian-12-base"
  vm_id                = 9001
  template_name        = "splunk-enterprise-10"
  template_description = "Splunk 10.0.2 on Debian 12 (Packer)"
  full_clone           = true

  # SSH (matches base template cloud-init)
  ssh_username = "debian"
  ssh_password = var.packer_ssh_password

  # Build resources
  cores  = 4
  memory = 4096
}

build {
  sources = ["source.proxmox-clone.splunk"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y wget"
    ]
  }

  provisioner "shell" {
    inline = [
      "wget -O splunk.deb 'https://download.splunk.com/products/splunk/releases/10.0.2/linux/splunk-10.0.2-e2d18b4767e9-linux-amd64.deb'",
      "sudo dpkg -i splunk.deb",
      "rm splunk.deb",
      "sudo sh -c 'echo \"[user_info]\" > /opt/splunk/etc/system/local/user-seed.conf'",
      "sudo sh -c 'echo \"USERNAME = admin\" >> /opt/splunk/etc/system/local/user-seed.conf'",
      "sudo sh -c 'echo \"PASSWORD = ${var.splunk_admin_password}\" >> /opt/splunk/etc/system/local/user-seed.conf'",
      "sudo /opt/splunk/bin/splunk enable boot-start --accept-license --answer-yes --no-prompt",
      "sudo cloud-init clean",
      "sudo truncate -s 0 /etc/machine-id"
    ]
  }
}
