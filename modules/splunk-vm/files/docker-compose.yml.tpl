# Splunk Docker Compose Configuration
# Managed by Terraform - do not edit directly
# Rendered from template with secrets injected via cloud-init
#
# IMPORTANT: The splunk/splunk image runs its entrypoint as 'ansible' user,
# which then uses gosu to run Splunk processes as 'splunk' user (UID 41812).
# This is the intended design - do NOT change the container user.

services:
  splunk:
    image: splunk/splunk:10.0.2
    hostname: splunk-aio
    # No explicit user - container entrypoint handles ownership via SPLUNK_HOME_OWNERSHIP_ENFORCEMENT
    environment:
      SPLUNK_START_ARGS: "--accept-license"
      SPLUNK_PASSWORD: "${splunk_password}"
      # SPLUNK_HEC_TOKEN: Configures HTTP Event Collector (HEC) input in the official image
      # The image automatically creates an HEC input listening on port 8088 with this token
      SPLUNK_HEC_TOKEN: "${splunk_hec_token}"
      # Let container entrypoint chown mounted volumes to splunk user at startup
      SPLUNK_HOME_OWNERSHIP_ENFORCEMENT: "true"
    ports:
      - "8000:8000"
      - "8088:8088"
      - "514:514/udp"
      - "514:514/tcp"
    volumes:
      - /opt/splunk/var:/opt/splunk/var
      - /opt/splunk/etc:/opt/splunk/etc
      - /opt/splunk-config/indexes.conf:/opt/splunk/etc/system/local/indexes.conf:ro
      - /opt/splunk-config/inputs.conf:/opt/splunk/etc/system/local/inputs.conf:ro
    restart: unless-stopped
    # Healthcheck uses curl to avoid permission issues with splunk CLI
    # The CLI runs as 'ansible' user but needs to read files owned by 'splunk'
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:8000/en-US/account/login >/dev/null || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 180s
