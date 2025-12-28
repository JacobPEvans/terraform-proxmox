#!/bin/bash
# Install pre-commit safety hooks to prevent committing real infrastructure values
#
# Usage: ./scripts/install-safety-hooks.sh

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_DIR="${REPO_ROOT}/.git/hooks"
PRE_COMMIT_HOOK="${HOOKS_DIR}/pre-commit"

echo "Installing safety hooks to prevent committing real infrastructure values..."

# Create hooks directory if it doesn't exist
mkdir -p "${HOOKS_DIR}"

# Create or append to pre-commit hook
if [ -f "${PRE_COMMIT_HOOK}" ]; then
  echo "Warning: ${PRE_COMMIT_HOOK} already exists."
  echo "Appending tfvars safety check to existing hook..."
  cat >> "${PRE_COMMIT_HOOK}" << 'EOF'

# Prevent committing real .tfvars files (only .example should be committed)
echo "Checking for real .tfvars files in commit..."
if git diff --cached --name-only | grep -E "\.tfvars$" | grep -v "\.example$"; then
  echo "❌ ERROR: Attempting to commit real .tfvars file!"
  echo ""
  echo "Found in staged files:"
  git diff --cached --name-only | grep -E "\.tfvars$" | grep -v "\.example$"
  echo ""
  echo "Only .tfvars.example files should be committed."
  echo "Real infrastructure values belong in terraform.tfvars (gitignored)."
  echo ""
  echo "To fix: git restore --staged <file>"
  exit 1
fi
echo "✅ No real .tfvars files detected in commit."
EOF
else
  cat > "${PRE_COMMIT_HOOK}" << 'EOF'
#!/bin/bash
# Pre-commit hook: Prevent committing real infrastructure values

set -euo pipefail

# Prevent committing real .tfvars files (only .example should be committed)
echo "Checking for real .tfvars files in commit..."
if git diff --cached --name-only | grep -E "\.tfvars$" | grep -v "\.example$"; then
  echo "❌ ERROR: Attempting to commit real .tfvars file!"
  echo ""
  echo "Found in staged files:"
  git diff --cached --name-only | grep -E "\.tfvars$" | grep -v "\.example$"
  echo ""
  echo "Only .tfvars.example files should be committed."
  echo "Real infrastructure values belong in terraform.tfvars (gitignored)."
  echo ""
  echo "To fix: git restore --staged <file>"
  exit 1
fi
echo "✅ No real .tfvars files detected in commit."

# Run any additional pre-commit checks here
EOF
fi

# Make hook executable
chmod +x "${PRE_COMMIT_HOOK}"

echo ""
echo "✅ Safety hooks installed successfully!"
echo ""
echo "The following protections are now active:"
echo "  - Prevents committing terraform.tfvars or any .tfvars files"
echo "  - Allows terraform.tfvars.example (placeholder values only)"
echo ""
echo "Hook location: ${PRE_COMMIT_HOOK}"
echo ""
echo "To test: git add terraform.tfvars && git commit -m 'test'"
echo "(Should be blocked with an error message)"
