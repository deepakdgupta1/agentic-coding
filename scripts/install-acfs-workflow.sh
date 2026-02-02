#!/bin/bash
# Install ACFS notification workflow in a repository
#
# Usage:
#   ./install-acfs-workflow.sh [TOOL_NAME] [INSTALLER_PATH]
#
# Examples:
#   ./install-acfs-workflow.sh                    # Uses directory name and install.sh
#   ./install-acfs-workflow.sh beads_rust         # Custom tool name
#   ./install-acfs-workflow.sh my_tool scripts/install.sh  # Custom path
#
# This script:
# 1. Downloads the latest notify-acfs workflow template from ACFS
# 2. Customizes it with your tool name and installer path
# 3. Saves it to .github/workflows/notify-acfs.yml
#
# After running, you still need to:
# 1. Create the ACFS_NOTIFY_TOKEN secret in your repository settings
# 2. Verify the tool name matches your entry in ACFS checksums.yaml
# 3. Commit and push the workflow file

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
TOOL_NAME="${1:-$(basename "$PWD")}"
INSTALLER_PATH="${2:-install.sh}"
ACFS_TEMPLATE_URL="https://raw.githubusercontent.com/deepakdgupta1/agentic-coding/main/templates/notify-acfs-workflow.yml"

echo "Installing ACFS notification workflow..."
echo ""
echo "  Tool name:      $TOOL_NAME"
echo "  Installer path: $INSTALLER_PATH"
echo ""

# Check if installer exists
if [[ ! -f "$INSTALLER_PATH" ]]; then
    echo -e "${YELLOW}Warning: Installer not found at '$INSTALLER_PATH'${NC}"
    echo "Make sure the path is correct before pushing the workflow."
    echo ""
fi

# Check if we're in a git repo
if [[ ! -d ".git" ]]; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    echo "Run this script from the root of your repository."
    exit 1
fi

# Create workflows directory if needed
mkdir -p .github/workflows

# Check if workflow already exists
if [[ -f ".github/workflows/notify-acfs.yml" ]]; then
    echo -e "${YELLOW}Warning: .github/workflows/notify-acfs.yml already exists${NC}"
    read -p "Overwrite? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Download and customize template
echo "Downloading template from ACFS..."
if ! curl -sL "$ACFS_TEMPLATE_URL" \
    | sed "s/{{ TOOL_NAME_PLACEHOLDER }}/$TOOL_NAME/g" \
    | sed "s|INSTALLER_PATH: 'install.sh'|INSTALLER_PATH: '$INSTALLER_PATH'|g" \
    > .github/workflows/notify-acfs.yml; then
    echo -e "${RED}Error: Failed to download template${NC}"
    exit 1
fi

echo -e "${GREEN}Workflow installed at .github/workflows/notify-acfs.yml${NC}"
echo ""

# Compute current checksum
if [[ -f "$INSTALLER_PATH" ]]; then
    CURRENT_SHA256=$(sha256sum "$INSTALLER_PATH" | cut -d' ' -f1)
    echo "Current installer SHA256: $CURRENT_SHA256"
    echo ""
fi

echo "Next steps:"
echo ""
echo "  1. Create ACFS_NOTIFY_TOKEN secret:"
echo "     - Go to your repository Settings > Secrets > Actions"
echo "     - Create a new secret named 'ACFS_NOTIFY_TOKEN'"
echo "     - Use a GitHub PAT with 'repo' scope for:"
echo "       deepakdgupta1/agentic-coding"
echo ""
echo "  2. Verify your tool is in ACFS checksums.yaml:"
echo "     - Check: https://github.com/deepakdgupta1/agentic-coding/blob/main/checksums.yaml"
echo "     - Look for entry: $TOOL_NAME"
echo ""
echo "  3. Commit and push the workflow:"
echo "     git add .github/workflows/notify-acfs.yml"
echo "     git commit -m 'chore: add ACFS installer notification workflow'"
echo "     git push"
echo ""
echo "  4. Test the workflow:"
echo "     gh workflow run notify-acfs.yml -f dry_run=true"
echo ""

# Also install validation workflow
echo "Installing validation workflow..."
VALIDATE_TEMPLATE_URL="https://raw.githubusercontent.com/deepakdgupta1/agentic-coding/main/templates/validate-acfs-workflow.yml"
if curl -sL "$VALIDATE_TEMPLATE_URL" \
    | sed "s/{{ TOOL_NAME_PLACEHOLDER }}/$TOOL_NAME/g" \
    | sed "s|INSTALLER_PATH: 'install.sh'|INSTALLER_PATH: '$INSTALLER_PATH'|g" \
    > .github/workflows/validate-acfs.yml 2>/dev/null; then
    echo -e "${GREEN}Validation workflow installed at .github/workflows/validate-acfs.yml${NC}"
    echo ""
    echo "To validate your setup:"
    echo "  gh workflow run validate-acfs.yml"
fi
