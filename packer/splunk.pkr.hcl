packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-clone" "splunk" {
  proxmox_url              = local.proxmox_url
  username                 = local.proxmox_username
  token                    = local.proxmox_token
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  clone_vm      = "debian-12-base"
  vm_id         = 9200
  vm_name       = "splunk-aio-template"
  template_name = "splunk-aio-template"
  full_clone    = true

  ssh_username = "debian"
  ssh_host     = var.packer_ssh_host
  ssh_timeout  = "120s"

  cloud_init              = true
  cloud_init_storage_pool = "local-zfs"

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }
  ipconfig {
    ip      = var.packer_ip_address
    gateway = var.packer_gateway
  }

  cores  = 4
  memory = 4096
}

build {
  sources = ["source.proxmox-clone.splunk"]

  provisioner "shell" {
    inline = [
      "cloud-init status --wait || true",
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
