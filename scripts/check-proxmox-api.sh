#!/usr/bin/env bash
# Test Proxmox API health before running Terraform operations
# Run this script before terragrunt plan/apply to verify API connectivity
set -euo pipefail

echo "=== Proxmox API Health Check ==="
echo "Endpoint: ${PROXMOX_VE_ENDPOINT:-<not set>}"
echo ""

if [[ -z "${PROXMOX_VE_ENDPOINT:-}" ]]; then
  echo "ERROR: PROXMOX_VE_ENDPOINT is not set"
  echo "Run: doppler run -- <this-script>"
  exit 1
fi

if [[ -z "${PROXMOX_VE_API_TOKEN:-}" ]]; then
  echo "ERROR: PROXMOX_VE_API_TOKEN is not set"
  echo "Run: doppler run -- <this-script>"
  exit 1
fi

# Test 1: Version endpoint (fastest)
echo "1. Version check (should be <1s):"
time curl -k -s -m 10 \
  -X GET "${PROXMOX_VE_ENDPOINT}/api2/json/version" \
  -H "Authorization: PVEAPIToken=${PROXMOX_VE_API_TOKEN}" | jq -r '.data.version'

# Test 2: Node status
echo ""
echo "2. Node status (shows load):"
time curl -k -s -m 10 \
  -X GET "${PROXMOX_VE_ENDPOINT}/api2/json/nodes/${PROXMOX_VE_NODE:-pve}/status" \
  -H "Authorization: PVEAPIToken=${PROXMOX_VE_API_TOKEN}" | jq '{cpu: .data.cpu, memory: .data.memory}'

# Test 3: List VMs (exercises state refresh path)
echo ""
echo "3. List VMs (state refresh test):"
time curl -k -s -m 15 \
  -X GET "${PROXMOX_VE_ENDPOINT}/api2/json/nodes/${PROXMOX_VE_NODE:-pve}/qemu" \
  -H "Authorization: PVEAPIToken=${PROXMOX_VE_API_TOKEN}" | jq '.data | length' | xargs echo "VMs found:"

# Test 4: List containers
echo ""
echo "4. List containers:"
time curl -k -s -m 15 \
  -X GET "${PROXMOX_VE_ENDPOINT}/api2/json/nodes/${PROXMOX_VE_NODE:-pve}/lxc" \
  -H "Authorization: PVEAPIToken=${PROXMOX_VE_API_TOKEN}" | jq '.data | length' | xargs echo "Containers found:"

echo ""
echo "=== Health Check Complete ==="
echo "If any test takes >5s, consider waiting before running Terraform."
echo "If any test fails, check Proxmox host resources and network connectivity."
