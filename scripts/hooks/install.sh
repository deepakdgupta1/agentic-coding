#!/usr/bin/env bash
# Install ACFS git hooks
#
# Usage: ./scripts/hooks/install.sh
#
# This script installs the ACFS pre-commit hook which:
# 1. Auto-regenerates scripts/generated/ when manifest changes
# 2. Chains to beads (bd) hooks if installed
#
# Safe to run multiple times - always overwrites with latest hook.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "Installing ACFS git hooks..."

# Check if there's an existing pre-commit hook that's NOT ours
if [[ -f "$HOOKS_DIR/pre-commit" ]]; then
    # Check if it's a beads-only shim (we'll replace with our composite hook)
    if grep -q "bd hooks run pre-commit" "$HOOKS_DIR/pre-commit" && \
       ! grep -q "ACFS" "$HOOKS_DIR/pre-commit"; then
        echo "ℹ️  Found existing beads hook - replacing with ACFS composite hook"
        echo "   (ACFS hook will chain to beads automatically)"
    elif grep -q "ACFS" "$HOOKS_DIR/pre-commit"; then
        echo "ℹ️  Updating existing ACFS hook"
    else
        echo "⚠️  Found unknown pre-commit hook - backing up to pre-commit.bak"
        cp "$HOOKS_DIR/pre-commit" "$HOOKS_DIR/pre-commit.bak"
    fi
fi

# Install pre-commit hook
cp "$SCRIPT_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"
echo "✅ Installed pre-commit hook"

echo ""
echo "Hooks installed. They will:"
echo "  - Auto-regenerate scripts/generated/ when manifest changes"
echo "  - Chain to beads (bd) hooks if available"
echo ""
echo "To bypass: git commit --no-verify"
echo "CI still enforces drift checks on all PRs."
