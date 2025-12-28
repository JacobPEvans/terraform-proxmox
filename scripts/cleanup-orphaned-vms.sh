#!/usr/bin/env bash
# Cleanup VMs in pool that aren't defined in Terraform
# Usage: ./scripts/cleanup-orphaned-vms.sh <pool-name>

set -euo pipefail

POOL="${1:-logging}"

echo "=== Checking pool '$POOL' for orphaned resources ==="

# Get VMs in pool from Proxmox
echo "Fetching VMs from Proxmox pool..."
POOL_VMS=$(ssh pve "pvesh get /pools/$POOL --output-format json" | jq -r '.members[]? | select(.type=="qemu") | .vmid' | sort)
POOL_CTS=$(ssh pve "pvesh get /pools/$POOL --output-format json" | jq -r '.members[]? | select(.type=="lxc") | .vmid' | sort)

echo "VMs in pool: ${POOL_VMS:-none}"
echo "Containers in pool: ${POOL_CTS:-none}"
echo

# Get VMs defined in Terraform state
echo "Fetching VMs from Terraform state..."
cd "$(dirname "$0")/.."

TF_CMD="nix develop ~/git/nix-config/main/shells/terraform --command bash -c \"aws-vault exec terraform -- doppler run --name-transformer tf-var -- terragrunt\""

# Get VM IDs from state
STATE_VMS=$(eval "$TF_CMD state list 2>/dev/null | grep 'module.vms.proxmox_virtual_environment_vm.vms' | sed 's/.*\\[\"\\(.*\\)\"\\]/\\1/' || true")
STATE_CTS=$(eval "$TF_CMD state list 2>/dev/null | grep 'module.containers.proxmox_virtual_environment_container.containers' | sed 's/.*\\[\"\\(.*\\)\"\\]/\\1/' || true")

echo "VMs in Terraform state: ${STATE_VMS:-none}"
echo "Containers in Terraform state: ${STATE_CTS:-none}"
echo

# Find orphans (in pool but not in state)
echo "=== Orphaned Resources ==="

for vm in $POOL_VMS; do
    vm_name=$(ssh pve "qm config $vm | grep '^name:' | cut -d' ' -f2")
    if echo "$STATE_VMS" | grep -q "$vm_name"; then
        echo "✓ VM $vm ($vm_name) is managed by Terraform"
    else
        echo "⚠ VM $vm ($vm_name) is ORPHANED - not in Terraform state"
        read -p "Destroy VM $vm? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Destroying VM $vm..."
            ssh pve "qm stop $vm --skiplock || true"
            ssh pve "qm destroy $vm --purge"
            echo "✓ Destroyed VM $vm"
        fi
    fi
done

for ct in $POOL_CTS; do
    ct_name=$(ssh pve "pct config $ct | grep '^hostname:' | cut -d' ' -f2")
    if echo "$STATE_CTS" | grep -q "$ct_name"; then
        echo "✓ Container $ct ($ct_name) is managed by Terraform"
    else
        echo "⚠ Container $ct ($ct_name) is ORPHANED - not in Terraform state"
        read -p "Destroy container $ct? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Destroying container $ct..."
            ssh pve "pct stop $ct || true"
            ssh pve "pct destroy $ct --purge"
            echo "✓ Destroyed container $ct"
        fi
    fi
done

echo
echo "=== Cleanup complete ==="
