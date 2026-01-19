#!/usr/bin/env bash
# Export Terraform ansible_inventory output for Ansible consumption
# Requires: Doppler, aws-vault, Terragrunt, jq
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Default output format
FORMAT="${1:-json}"
OUTPUT_FILE="${2:-}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [FORMAT] [OUTPUT_FILE]

Export Terraform ansible_inventory output.

Arguments:
  FORMAT       Output format: json (default), yaml, or ansible
  OUTPUT_FILE  Optional file path to write output (prints to stdout if omitted)

Formats:
  json     Raw JSON output from Terraform
  yaml     YAML format (requires yq)
  ansible  Ansible inventory YAML format for dynamic inventory plugin (requires yq)

Examples:
  $(basename "$0")                           # JSON to stdout
  $(basename "$0") json inventory.json       # JSON to file
  $(basename "$0") yaml inventory.yml        # YAML to file
  $(basename "$0") ansible hosts.yml         # Ansible inventory format

Required Environment (via Doppler):
  PROXMOX_VE_ENDPOINT, PROXMOX_VE_API_TOKEN, AWS credentials

Run with:
  doppler run -- ./scripts/$(basename "$0") [FORMAT] [OUTPUT_FILE]
EOF
}

# Check for help flag
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# Validate format
case "$FORMAT" in
  json|yaml|ansible) ;;
  *)
    echo "ERROR: Invalid format '$FORMAT'. Use: json, yaml, or ansible" >&2
    usage
    exit 1
    ;;
esac

# Check required tools
for cmd in jq terragrunt; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: $cmd is not installed" >&2
    exit 1
  fi
done

if [[ "$FORMAT" == "yaml" ]] || [[ "$FORMAT" == "ansible" ]]; then
  if ! command -v yq &>/dev/null; then
    echo "ERROR: yq is required for YAML output" >&2
    exit 1
  fi
fi

# Preserve caller's working directory for OUTPUT_FILE resolution
ORIGINAL_CWD="$(pwd)"
if [[ -n "$OUTPUT_FILE" && "$OUTPUT_FILE" != /* ]]; then
  OUTPUT_FILE="${ORIGINAL_CWD}/${OUTPUT_FILE}"
fi

cd "$REPO_ROOT"

echo "Exporting ansible_inventory from Terraform state..." >&2

# Get raw JSON output
RAW_JSON=$(terragrunt output -json ansible_inventory)

if [[ -z "$RAW_JSON" ]] || [[ "$RAW_JSON" == "null" ]]; then
  echo "ERROR: ansible_inventory output is empty or not found" >&2
  echo "Ensure Terraform state is applied and ansible_inventory output exists" >&2
  exit 1
fi

# Transform based on format
case "$FORMAT" in
  json)
    OUTPUT="$RAW_JSON"
    ;;
  yaml)
    OUTPUT=$(echo "$RAW_JSON" | yq -P -)
    ;;
  ansible)
    # Transform to Ansible inventory YAML format
    OUTPUT=$(echo "$RAW_JSON" | jq -r -f "${SCRIPT_DIR}/ansible-inventory.jq" | yq -P -)
    ;;
esac

# Output result
if [[ -n "$OUTPUT_FILE" ]]; then
  echo "$OUTPUT" > "$OUTPUT_FILE"
  echo "Inventory exported to: $OUTPUT_FILE" >&2
else
  echo "$OUTPUT"
fi
