#cloud-config
# Splunk Docker VM Cloud-Init Configuration
# Managed by Terraform - do not edit directly
# Firewall rules managed by Proxmox firewall module (not iptables)

hostname: ${hostname}

# Ensure data disk is formatted and mounted
disk_setup:
  /dev/vdb:
    table_type: gpt
    layout: true
    overwrite: true

fs_setup:
  - label: splunk-data
    filesystem: ext4
    device: /dev/vdb1
    partition: auto

mounts:
  - ["/dev/vdb1", "/opt/splunk", "ext4", "defaults,nofail", "0", "2"]

# Create necessary directories after mount
runcmd:
  # Ensure Splunk directories exist after mount
  - mkdir -p /opt/splunk/var
  - mkdir -p /opt/splunk/etc
  - chown -R 41812:41812 /opt/splunk

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
