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
  username                 = var.PKR_PVE_USERNAME
  token                    = var.PROXMOX_TOKEN
  node                     = var.PROXMOX_VE_NODE
  insecure_skip_tls_verify = var.PROXMOX_VE_INSECURE == "true"

  clone_vm      = "debian-12-base"
  vm_id         = 9200
  vm_name       = "splunk-aio-template"
  template_name = "splunk-aio-template"
  full_clone    = true

  # CRITICAL: CPU and hardware configuration to prevent system freezes
  # These settings override Packer's defaults which can cause system instability:
  # - cpu_type: "host" exposes all host CPU features with native performance
  #   instead of kvm64 generic emulation which causes TSC clock instability
  # - scsi_controller: virtio-scsi-pci is modern/fast vs. LSI Logic (default)
  #   which is ancient (~2003) and adds high CPU overhead during disk I/O
  # - os: "l26" optimizes for Linux 2.6+ kernel instead of "other"
  # See: https://github.com/hashicorp/packer-plugin-proxmox/issues/307
  cpu_type        = "host"
  scsi_controller = "virtio-scsi-pci"
  os              = "l26"

  # SSH configuration: Use the VM-specific SSH key (id_rsa_vm) that matches
  # the public key configured in the base template's cloud-init.
  # Packer automatically detects the VM's IP address from Proxmox API.
  ssh_username         = "debian"
  ssh_timeout          = "300s"
  ssh_agent_auth       = false
  ssh_private_key_file = pathexpand("~/.ssh/id_rsa_vm")

  cloud_init              = true
  cloud_init_storage_pool = "local-zfs"

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }
  ipconfig {
    ip = "dhcp"
  }

  cores  = 4
  memory = 4096
}

build {
  sources = ["source.proxmox-clone.splunk"]

  # Splunk installation provisioner
  provisioner "shell" {
    inline = [
      "cloud-init status --wait || true",
      "sudo apt-get update",
      "sudo apt-get install -y wget",
      "TMPDIR=$${TMPDIR:-/tmp}",
      "cd $TMPDIR",
      "wget -O splunk-${var.SPLUNK_VERSION}-${var.SPLUNK_BUILD}-linux-${var.SPLUNK_ARCHITECTURE}.deb 'https://download.splunk.com/products/splunk/releases/${var.SPLUNK_VERSION}/linux/splunk-${var.SPLUNK_VERSION}-${var.SPLUNK_BUILD}-linux-${var.SPLUNK_ARCHITECTURE}.deb'",
      "echo \"${var.SPLUNK_DOWNLOAD_SHA512}  splunk-${var.SPLUNK_VERSION}-${var.SPLUNK_BUILD}-linux-${var.SPLUNK_ARCHITECTURE}.deb\" | sha512sum -c -",
      "sudo dpkg -i splunk-${var.SPLUNK_VERSION}-${var.SPLUNK_BUILD}-linux-${var.SPLUNK_ARCHITECTURE}.deb",
      "sudo ${var.SPLUNK_HOME}/bin/splunk enable boot-start -user ${var.SPLUNK_USER} --accept-license --answer-yes --no-prompt --seed-passwd '${var.SPLUNK_ADMIN_PASSWORD}'",
      "sudo chown -R ${var.SPLUNK_USER}:${var.SPLUNK_GROUP} ${var.SPLUNK_HOME}",
      "sudo cloud-init clean",
      "sudo truncate -s 0 /etc/machine-id"
    ]
  }

  # System tuning: Configure ulimits for Splunk performance
  # Splunk requires high file descriptor and process limits (64,000+)
  provisioner "shell" {
    inline = [
      "echo 'Configuring ulimits for Splunk...'",
      "sudo tee /etc/security/limits.d/99-splunk.conf > /dev/null <<'LIMITS'",
      "# Splunk requires high file descriptor and process limits",
      "# See: https://docs.splunk.com/Documentation/Splunk/latest/Installation/Systemrequirements",
      "${var.SPLUNK_USER} soft nofile 65536",
      "${var.SPLUNK_USER} hard nofile 65536",
      "${var.SPLUNK_USER} soft nproc 65536",
      "${var.SPLUNK_USER} hard nproc 65536",
      "LIMITS",
      "echo 'Configuring systemd service limits...'",
      "sudo mkdir -p /etc/systemd/system/splunk.service.d",
      "sudo tee /etc/systemd/system/splunk.service.d/limits.conf > /dev/null <<'SYSTEMD'",
      "[Service]",
      "LimitNOFILE=65536",
      "LimitNPROC=65536",
      "SYSTEMD",
      "echo 'Configuring systemd restart policy...'",
      "sudo tee /etc/systemd/system/splunk.service.d/restart.conf > /dev/null <<'RESTART'",
      "[Service]",
      "# Auto-restart Splunk if it fails during boot (race condition with other services)",
      "Restart=on-failure",
      "RestartSec=30",
      "StartLimitIntervalSec=300",
      "StartLimitBurst=3",
      "RESTART",
      "sudo systemctl daemon-reload",
      "echo 'systemd configuration complete'"
    ]
  }

  # Validation: Ensure all files in SPLUNK_HOME are owned by splunk:splunk
  provisioner "shell" {
    inline = [
      "echo 'Validating Splunk file ownership...'",
      "NON_SPLUNK_FILES=$(sudo find ${var.SPLUNK_HOME} \\( ! -user ${var.SPLUNK_USER} -o ! -group ${var.SPLUNK_GROUP} \\) 2>/dev/null | wc -l)",
      "if [ \"$NON_SPLUNK_FILES\" -ne 0 ]; then",
      "  echo \"ERROR: Found $NON_SPLUNK_FILES files not owned by ${var.SPLUNK_USER}:${var.SPLUNK_GROUP}\"",
      "  sudo find ${var.SPLUNK_HOME} \\( ! -user ${var.SPLUNK_USER} -o ! -group ${var.SPLUNK_GROUP} \\) 2>/dev/null | head -20",
      "  exit 1",
      "fi",
      "echo 'Validation passed: All files in ${var.SPLUNK_HOME} owned by ${var.SPLUNK_USER}:${var.SPLUNK_GROUP}'"
    ]
  }
}
