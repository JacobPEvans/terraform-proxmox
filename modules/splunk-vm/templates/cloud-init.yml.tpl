#cloud-config
# Splunk Docker VM Cloud-Init Configuration
# Managed by Terraform - do not edit directly
# Firewall rules managed by Proxmox firewall module (not iptables)

hostname: ${hostname}

runcmd:
  # --- Data disk setup (idempotent) ---
  # disk_setup/fs_setup modules run before user-data is available in Proxmox NoCloud,
  # causing them to be silently skipped. Disk initialization is handled here instead.
  - |
    if ! blkid /dev/vdb | grep -q ext4; then
      parted /dev/vdb --script mklabel gpt mkpart primary ext4 0% 100%
      sleep 1
      mkfs.ext4 -L splunk-data /dev/vdb1
    fi
  - |
    if ! grep -q '/dev/vdb1' /etc/fstab; then
      echo '/dev/vdb1 /opt/splunk ext4 defaults,nofail 0 2' >> /etc/fstab
    fi
  - mkdir -p /opt/splunk
  - mount -a

  # --- Swap setup (8 GB) ---
  - |
    if [ ! -f /swapfile ]; then
      fallocate -l 8G /swapfile
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi

  # --- Splunk directories ---
  # Permissions allow container entrypoint to chown to splunk user
  # (SPLUNK_HOME_OWNERSHIP_ENFORCEMENT=true handles this dynamically)
  - mkdir -p /opt/splunk/var
  - mkdir -p /opt/splunk/etc
  - chmod 777 /opt/splunk /opt/splunk/var /opt/splunk/etc

  # Create config directory on root filesystem (not data disk)
  - mkdir -p /opt/splunk-config
  - chown -R root:root /opt/splunk-config

  # Write Splunk configuration files
  - |
    cat > /opt/splunk-config/indexes.conf << 'INDEXES_EOF'
${indexes_conf}
INDEXES_EOF

  - |
    cat > /opt/splunk-config/inputs.conf << 'INPUTS_EOF'
${inputs_conf}
INPUTS_EOF

  # Write docker-compose.yml with secrets
  - |
    cat > /opt/splunk-config/docker-compose.yml << 'COMPOSE_EOF'
${docker_compose}
COMPOSE_EOF

  # Wait for Docker daemon to be fully initialized
  - |
    while ! docker info >/dev/null 2>&1; do
      echo "Waiting for Docker daemon to be ready..."
      sleep 1
    done

  # Start Splunk container
  - cd /opt/splunk-config && /usr/bin/docker compose up -d

  # Create systemd service for docker-compose
  - |
    cat > /etc/systemd/system/splunk-docker.service << 'SERVICE_EOF'
[Unit]
Description=Splunk Docker Compose Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/splunk-config
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
SERVICE_EOF

  - systemctl daemon-reload
  - systemctl enable splunk-docker.service

# Final message
final_message: "Splunk Docker VM initialized in $UPTIME seconds"
