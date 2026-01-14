#!/usr/bin/env bash
# Configure systemd service limits and restart policy for Splunk
# Consolidates ulimits and restart configuration into a single drop-in file

set -euo pipefail

echo 'Configuring ulimits for Splunk...'

# Configure PAM limits for Splunk user
# See: https://docs.splunk.com/Documentation/Splunk/latest/Installation/Systemrequirements
sudo tee /etc/security/limits.d/99-splunk.conf > /dev/null <<'LIMITS'
# Splunk requires high file descriptor and process limits
splunk soft nofile 65536
splunk hard nofile 65536
splunk soft nproc 65536
splunk hard nproc 65536
LIMITS

echo 'Configuring systemd service overrides...'

# Create systemd drop-in directory
sudo mkdir -p /etc/systemd/system/splunk.service.d

# Consolidate all systemd overrides into a single file
# This addresses the review feedback about maintaining a cohesive configuration
sudo tee /etc/systemd/system/splunk.service.d/override.conf > /dev/null <<'SYSTEMD'
[Service]
# Systemd service limits (must match PAM limits above)
LimitNOFILE=65536
LimitNPROC=65536

# Auto-restart policy to handle boot-time race conditions
# Splunk may fail to start before all dependencies are ready
Restart=on-failure
RestartSec=30
StartLimitIntervalSec=300
StartLimitBurst=3
SYSTEMD

# Reload systemd configuration
sudo systemctl daemon-reload

echo 'systemd configuration complete'
