# Transform Terraform ansible_inventory to Ansible inventory YAML format
# Build groups from resource types
#
# Note: The `add` function merges an array of objects into a single object.
# We use `add // {}` to handle empty input: if there are no resources in a
# category (e.g., no containers), `to_entries` returns an empty array, `map`
# produces an empty array, and `add` returns null. The `// {}` coalesces
# null to an empty object for graceful handling of missing resource types.

{
  "all": {
    "children": {
      "lxc_containers": {
        "hosts": (
          .containers // {} | to_entries | map({
            (.key): {
              "ansible_host": .value.ip,
              "ansible_connection": .value.ansible_connection,
              "ansible_pct_vmid": .value.ansible_pct_vmid,
              "vmid": .value.vmid,
              "proxmox_node": .value.node,
              "tags": .value.tags,
              "pool_id": .value.pool_id
            }
          }) | add // {}
        )
      },
      "vms": {
        "hosts": (
          .vms // {} | to_entries | map({
            (.key): {
              "ansible_host": .value.ip,
              "ansible_connection": .value.ansible_connection,
              "vmid": .value.vmid,
              "proxmox_node": .value.node,
              "tags": .value.tags,
              "pool_id": .value.pool_id
            }
          }) | add // {}
        )
      },
      "splunk_vms": {
        "hosts": (
          .splunk_vm // {} | to_entries | map({
            (.key): {
              "ansible_host": .value.ip,
              "ansible_connection": .value.ansible_connection,
              "vmid": .value.vmid,
              "proxmox_node": .value.node
            }
          }) | add // {}
        )
      }
    }
  }
}
