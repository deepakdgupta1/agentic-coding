#!/usr/bin/env bash
# ============================================================
# ACFS Installer - Local Desktop Integration Test
#
# Tests the --local/--desktop installation pathway with LXD.
# Requires LXD to be available on the test host.
#
# Usage:
#   ./tests/vm/test_local_install.sh
#   ./tests/vm/test_local_install.sh --skip-cleanup  # Keep container after test
#   ./tests/vm/test_local_install.sh --quick         # Skip full install, test CLI only
#
# Requirements:
#   - LXD installed and initialized (lxd init)
#   - User in lxd group
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test configuration
TEST_CONTAINER_NAME="acfs-test-local-$$"
SKIP_CLEANUP=false
QUICK_MODE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-cleanup)
            SKIP_CLEANUP=true
            shift
            ;;
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [--skip-cleanup] [--quick]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ============================================================
# Test Utilities
# ============================================================

passed=0
failed=0

pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((passed++))
}

fail() {
    echo -e "${RED}✖${NC} $1"
    ((failed++))
}

skip() {
    echo -e "${YELLOW}○${NC} $1 (skipped)"
}

cleanup() {
    if [[ "$SKIP_CLEANUP" == "true" ]]; then
        echo ""
        echo "Skipping cleanup (--skip-cleanup). Container: $TEST_CONTAINER_NAME"
        return
    fi

    echo ""
    echo "Cleaning up..."
    # Override container name for cleanup
    ACFS_CONTAINER_NAME="$TEST_CONTAINER_NAME" \
        "$REPO_ROOT/scripts/local/acfs_container.sh" destroy --force 2>/dev/null || true
}

trap cleanup EXIT

# ============================================================
# Prerequisites Check
# ============================================================

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  ACFS Local Desktop Installation Test"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check LXD availability
if ! command -v lxc &>/dev/null; then
    skip "LXD not installed"
    echo ""
    echo "This test requires LXD to be installed and initialized."
    echo "Skip this test in environments without LXD."
    exit 0
fi

if ! lxc info &>/dev/null 2>&1; then
    skip "LXD not initialized"
    echo ""
    echo "Run 'lxd init' to initialize LXD first."
    exit 0
fi

pass "LXD available and initialized"

# ============================================================
# Test: Sandbox Library Loads
# ============================================================

echo ""
echo "── Testing Sandbox Library ──"

if source "$REPO_ROOT/scripts/lib/sandbox.sh" 2>/dev/null; then
    pass "sandbox.sh sources without error"
else
    fail "sandbox.sh failed to source"
    exit 1
fi

if declare -f acfs_sandbox_create &>/dev/null; then
    pass "acfs_sandbox_create function exists"
else
    fail "acfs_sandbox_create function missing"
fi

if declare -f is_lxd_container &>/dev/null; then
    pass "is_lxd_container function exists"
else
    fail "is_lxd_container function missing"
fi

# ============================================================
# Test: OS Detection Functions
# ============================================================

echo ""
echo "── Testing OS Detection ──"

source "$REPO_ROOT/scripts/lib/os_detect.sh"

if declare -f is_lxd_container &>/dev/null; then
    pass "is_lxd_container available from os_detect.sh"
else
    fail "is_lxd_container not in os_detect.sh"
fi

if declare -f is_container &>/dev/null; then
    pass "is_container (generic) function available"
else
    fail "is_container function missing"
fi

# On the host, is_lxd_container should return false
if ! is_lxd_container; then
    pass "is_lxd_container correctly returns false on host"
else
    fail "is_lxd_container incorrectly returns true on host"
fi

# ============================================================
# Test: CLI Wrapper
# ============================================================

echo ""
echo "── Testing CLI Wrapper ──"

if [[ -x "$REPO_ROOT/scripts/local/acfs_container.sh" ]]; then
    pass "acfs_container.sh is executable"
else
    fail "acfs_container.sh not executable"
fi

# Test help command
if "$REPO_ROOT/scripts/local/acfs_container.sh" help 2>&1 | grep -q "ACFS Local"; then
    pass "CLI help output works"
else
    fail "CLI help output missing"
fi

# ============================================================
# Test: Container Creation (if not quick mode)
# ============================================================

if [[ "$QUICK_MODE" == "true" ]]; then
    skip "Container creation test (--quick mode)"
else
    echo ""
    echo "── Testing Container Creation ──"
    echo "(This may take a few minutes for initial image download)"

    # Use a test-specific container name
    export ACFS_CONTAINER_NAME="$TEST_CONTAINER_NAME"
    export ACFS_WORKSPACE_HOST="/tmp/acfs-test-workspace-$$"
    export ACFS_DASHBOARD_PORT="38099"  # Avoid conflicts

    # Create workspace
    mkdir -p "$ACFS_WORKSPACE_HOST"

    # Test container creation (without full ACFS install for speed)
    # We just test the LXD provisioning, not the full installer
    if acfs_sandbox_create; then
        pass "Container created successfully"
    else
        fail "Container creation failed"
        exit 1
    fi

    # Verify container is running
    if acfs_sandbox_running; then
        pass "Container is running"
    else
        fail "Container not running after creation"
    fi

    # Verify ubuntu user exists inside container
    if lxc exec "$TEST_CONTAINER_NAME" -- id ubuntu &>/dev/null; then
        pass "Ubuntu user exists in container"
    else
        fail "Ubuntu user missing from container"
    fi

    # Verify workspace mount
    if lxc exec "$TEST_CONTAINER_NAME" -- test -d /data/projects; then
        pass "Workspace mounted at /data/projects"
    else
        fail "Workspace not mounted"
    fi

    # Test file sync between host and container
    echo "test-sync-$$" > "$ACFS_WORKSPACE_HOST/sync-test.txt"
    if lxc exec "$TEST_CONTAINER_NAME" -- cat /data/projects/sync-test.txt 2>/dev/null | grep -q "test-sync-$$"; then
        pass "Host-to-container file sync works"
    else
        fail "File sync failed"
    fi

    # Verify container is_lxd_container returns true inside
    if lxc exec "$TEST_CONTAINER_NAME" -- bash -c 'echo $container' | grep -q lxc; then
        pass "Container environment variable set correctly"
    else
        # This might not be set in all LXD versions, so just warn
        echo -e "${YELLOW}⚠${NC} Container environment variable may not be set (fallback detection will work)"
    fi

    # Test stop/start
    if acfs_sandbox_stop &>/dev/null; then
        pass "Container stopped"
    else
        fail "Container stop failed"
    fi

    if acfs_sandbox_start &>/dev/null; then
        pass "Container restarted"
    else
        fail "Container restart failed"
    fi

    # Cleanup workspace
    rm -rf "$ACFS_WORKSPACE_HOST"
fi

# ============================================================
# Test: Install.sh --local Flag Parsing
# ============================================================

echo ""
echo "── Testing Install.sh Flag Parsing ──"

# Test that --local flag is recognized (dry run, checking parse only)
# We can't actually run install.sh --local in the test because it would
# try to exec the container CLI, but we can verify the flag exists

if grep -q "LOCAL_MODE=false" "$REPO_ROOT/install.sh"; then
    pass "LOCAL_MODE variable declared in install.sh"
else
    fail "LOCAL_MODE variable missing from install.sh"
fi

if grep -q "\-\-local|\-\-desktop)" "$REPO_ROOT/install.sh"; then
    pass "--local/--desktop flag handler in install.sh"
else
    fail "--local/--desktop flag handler missing"
fi

if grep -q "is_lxd_container" "$REPO_ROOT/install.sh"; then
    pass "LXD container detection referenced in install.sh"
else
    fail "LXD detection missing from install.sh"
fi

# ============================================================
# Results Summary
# ============================================================

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Results: ${passed} passed, ${failed} failed"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [[ $failed -gt 0 ]]; then
    exit 1
fi

echo -e "${GREEN}All tests passed!${NC}"
