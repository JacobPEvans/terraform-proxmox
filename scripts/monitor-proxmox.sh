#!/usr/bin/env bash
# Direct Proxmox monitoring via SSH - no waiting for Terraform timeouts
# Usage: ./scripts/monitor-proxmox.sh [vm_ids...]

set -euo pipefail

VM_IDS="${@}"
if [ -z "$VM_IDS" ]; then
    echo "No VM IDs provided. Using default pool 'logging'."
    VM_IDS=$(ssh pve "pvesh get /pools/logging --output-format json" | jq -r '.members[]? | .vmid' | tr '\n' ' ')
fi

echo "=== Proxmox Status Monitor ==="
echo "Checking VMs: $VM_IDS"
echo

# Check VMs and Containers
echo "--- Virtual Machines & Containers ---"
for id in $VM_IDS; do
    if [[ $id -lt 200 ]]; then
        status=$(ssh pve "qm status $id 2>/dev/null" || echo "not found")
        config=$(ssh pve "qm config $id 2>/dev/null | grep -E '^(name|cores|memory):' || echo 'N/A'")
        echo "VM $id: $status"
        echo "$config" | sed 's/^/  /'
        echo
    else
        status=$(ssh pve "pct status $id 2>/dev/null" || echo "not found")
        config=$(ssh pve "pct config $id 2>/dev/null | grep -E '^(hostname|cores|memory):' || echo 'N/A'")
        echo "CT $id: $status"
        echo "$config" | sed 's/^/  /'
        echo
    fi
done

# Summary
echo "--- Summary ---"
VM_ID_PATTERN="^($(echo "$VM_IDS" | tr ' ' '|'))[[:space:]]"
ssh pve "qm list | grep -E \"$VM_ID_PATTERN\" || echo 'No matching VMs'"
ssh pve "pct list | grep -E \"$VM_ID_PATTERN\" || echo 'No matching containers'"
