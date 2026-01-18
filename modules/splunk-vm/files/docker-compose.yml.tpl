# Splunk Docker Compose Configuration
# Managed by Terraform - do not edit directly
# Rendered from template with secrets injected via cloud-init

services:
  splunk:
    image: splunk/splunk:latest
    hostname: splunk-aio
    user: root
    environment:
      SPLUNK_START_ARGS: "--accept-license"
      SPLUNK_PASSWORD: "${splunk_password}"
      SPLUNK_HEC_TOKEN: "${splunk_hec_token}"
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
