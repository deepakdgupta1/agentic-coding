#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="/home/deeog/Desktop/agentic-coding"
ACFS_CONTAINER_NAME="acfs-local"

echo "Testing file push..."
lxc file push "$REPO_ROOT/install.sh" "$ACFS_CONTAINER_NAME/tmp/install.sh"
echo "Testing mkdir..."
lxc exec "$ACFS_CONTAINER_NAME" -- mkdir -p /tmp/scripts
echo "Testing recursive push..."
lxc file push -r "$REPO_ROOT/scripts/" "$ACFS_CONTAINER_NAME/tmp/"
echo "Success"
