#!/usr/bin/env bash
# Doppler-integrated Packer build script for Splunk template
# Usage: ./packer-build.sh [init|build|validate]
#
# Doppler secrets use PROXMOX_VE_* naming (same as BPG Terraform provider)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check for required tools
check_requirements() {
    local missing=()
    command -v doppler >/dev/null 2>&1 || missing+=("doppler")
    command -v packer >/dev/null 2>&1 || missing+=("packer")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing[*]}"
        exit 1
    fi
}

# Validate that required Doppler secrets exist
validate_secrets() {
    log_info "Validating Doppler secrets for Packer..."

    local required_secrets=(
        "PROXMOX_VE_ENDPOINT"
        "PROXMOX_VE_USERNAME"
        "PROXMOX_VE_API_TOKEN"
        "PROXMOX_VE_NODE"
    )

    local optional_secrets=(
        "PACKER_SSH_PASSWORD"
        "SPLUNK_ADMIN_PASSWORD"
        "SPLUNK_DOWNLOAD_SHA256"
    )

    local missing=()
    local secrets
    secrets=$(doppler secrets --only-names 2>/dev/null | tail -n +4 | head -n -1 | tr -d '│ ')

    for secret in "${required_secrets[@]}"; do
        if ! echo "$secrets" | grep -q "^${secret}$"; then
            missing+=("$secret")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required Doppler secrets: ${missing[*]}"
        exit 1
    fi

    log_info "Required secrets present."

    # Check optional secrets
    local missing_optional=()
    for secret in "${optional_secrets[@]}"; do
        if ! echo "$secrets" | grep -q "^${secret}$"; then
            missing_optional+=("$secret")
        fi
    done

    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        log_warn "Missing optional Doppler secrets (add these for full functionality):"
        for secret in "${missing_optional[@]}"; do
            echo "  - $secret"
        done
        echo ""
        log_info "Add missing secrets with:"
        echo "  doppler secrets set PACKER_SSH_PASSWORD"
        echo "  doppler secrets set SPLUNK_ADMIN_PASSWORD"
        echo "  doppler secrets set SPLUNK_DOWNLOAD_SHA256"
    fi
}

# Main
check_requirements

case "${1:-build}" in
    init)
        log_info "Initializing Packer plugins..."
        packer init .
        ;;
    validate)
        validate_secrets
        log_info "Validating Packer configuration..."
        # Doppler secrets use PROXMOX_VE_* naming - no mapping needed
        doppler run -- packer validate splunk.pkr.hcl
        ;;
    build)
        validate_secrets
        log_info "Building Splunk template (9001)..."
        # Doppler secrets use PROXMOX_VE_* naming - no mapping needed
        doppler run -- packer build splunk.pkr.hcl
        ;;
    *)
        echo "Usage: $0 [init|validate|build]"
        echo ""
        echo "Commands:"
        echo "  init      - Initialize Packer plugins"
        echo "  validate  - Validate configuration and secrets"
        echo "  build     - Build the Splunk template"
        echo ""
        echo "Environment:"
        echo "  Doppler secrets must include PROXMOX_VE_* variables"
        echo "  (same naming as BPG Terraform provider)"
        exit 1
        ;;
esac

log_info "Done!"
