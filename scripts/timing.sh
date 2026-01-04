#!/bin/bash

###############################################################################
# Terragrunt Timing Script
#
# Purpose: Measure and log terragrunt plan and apply execution times
#
# Usage:
#   scripts/timing.sh --plan       # Run terragrunt plan with timing
#   scripts/timing.sh --apply      # Run terragrunt apply with timing
#
# Output:
#   - Displays execution time to stdout
#   - Appends result with timestamp to scripts/timing-results.txt
#
# Requirements:
#   - Must be run from the repository root directory
#   - Requires terragrunt to be available in PATH
###############################################################################

set -euo pipefail

# Script directory and log file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_FILE="${SCRIPT_DIR}/timing-results.txt"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

###############################################################################
# Helper Functions
###############################################################################

# Print usage information
usage() {
    echo "Usage: $0 --plan|--apply"
    echo ""
    echo "Options:"
    echo "  --plan    Run terragrunt plan with timing"
    echo "  --apply   Run terragrunt apply with timing"
    echo ""
    echo "Results are logged to: ${RESULTS_FILE}"
    exit 1
}

# Print error message and exit
error() {
    echo -e "${RED}ERROR: $*${NC}" >&2
    exit 1
}

# Print success message
success() {
    echo -e "${GREEN}$*${NC}"
}

# Print info message
info() {
    echo -e "${YELLOW}$*${NC}"
}

###############################################################################
# Main Execution
###############################################################################

# Check for required arguments
if [[ $# -ne 1 ]]; then
    usage
fi

COMMAND="$1"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
START_TIME=$(date +%s)

case "${COMMAND}" in
    --plan)
        info "Starting terragrunt plan execution at ${TIMESTAMP}..."

        # Run terragrunt plan and measure time
        if terragrunt plan; then
            END_TIME=$(date +%s)
            DURATION=$((END_TIME - START_TIME))

            # Log result with timestamp
            LOG_ENTRY="[${TIMESTAMP}] Terragrunt plan completed in ${DURATION} seconds"
            echo "${LOG_ENTRY}" >> "${RESULTS_FILE}"

            success "Execution completed in ${DURATION} seconds"
            echo "${LOG_ENTRY}"
        else
            error "terragrunt plan failed"
        fi
        ;;

    --apply)
        info "Starting terragrunt apply execution at ${TIMESTAMP}..."

        # Run terragrunt apply and measure time
        if terragrunt apply; then
            END_TIME=$(date +%s)
            DURATION=$((END_TIME - START_TIME))

            # Log result with timestamp
            LOG_ENTRY="[${TIMESTAMP}] Terragrunt apply completed in ${DURATION} seconds"
            echo "${LOG_ENTRY}" >> "${RESULTS_FILE}"

            success "Execution completed in ${DURATION} seconds"
            echo "${LOG_ENTRY}"
        else
            error "terragrunt apply failed"
        fi
        ;;

    *)
        error "Invalid option: ${COMMAND}"
        usage
        ;;
esac

exit 0
