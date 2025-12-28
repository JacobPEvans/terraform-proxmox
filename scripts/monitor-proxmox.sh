#!/usr/bin/env bash
# Direct Proxmox monitoring via SSH - no waiting for Terraform timeouts
# Usage: ./scripts/monitor-proxmox.sh [vm_ids...]

set -euo pipefail

VM_IDS="${@:-100 101 205}"

echo "=== Proxmox Status Monitor ==="
echo "Checking VMs: $VM_IDS"
echo

# Check VMs
echo "--- Virtual Machines ---"
for id in $VM_IDS; do
    if [[ $id -lt 200 ]]; then
        status=$(ssh pve "qm status $id 2>/dev/null" || echo "not found")
        config=$(ssh pve "qm config $id 2>/dev/null | grep -E '^(name|cores|memory):' || echo 'N/A'")
        echo "VM $id: $status"
        echo "$config" | sed 's/^/  /'
        echo
    fi
done

# Check Containers
echo "--- Containers ---"
for id in $VM_IDS; do
    if [[ $id -ge 200 ]]; then
        status=$(ssh pve "pct status $id 2>/dev/null" || echo "not found")
        config=$(ssh pve "pct config $id 2>/dev/null | grep -E '^(hostname|cores|memory):' || echo 'N/A'")
        echo "CT $id: $status"
        echo "$config" | sed 's/^/  /'
        echo
    fi
done

# Summary
echo "--- Summary ---"
ssh pve "qm list | grep -E '($(echo $VM_IDS | tr ' ' '|'))' || echo 'No matching VMs'"
ssh pve "pct list | grep -E '($(echo $VM_IDS | tr ' ' '|'))' || echo 'No matching containers'"
