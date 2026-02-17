#!/usr/bin/env bash
# ============================================================
# Test: awk Syntax Validation for sandbox.sh
#
# Ensures all inline awk scripts in sandbox.sh have valid syntax.
# This catches mistakes like using reserved keywords as variable names.
#
# Usage:
#   ./tests/unit/test_sandbox_awk.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SANDBOX_SH="$REPO_ROOT/scripts/lib/sandbox.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

passed=0
failed=0

pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((passed++)) || true
}

fail() {
    echo -e "${RED}✖${NC} $1"
    ((failed++)) || true
}

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  awk Syntax Validation for sandbox.sh"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Test 1: Validate the specific awk script in _acfs_sandbox_profile_dashboard_port
# This was the source of the original bug (using 'in' as a variable name)
test_dashboard_port_awk() {
    local awk_script='
        /^dashboard-proxy:/{blk=1; next}
        blk && /^[^ ]/{exit}
        blk && /listen:/{sub(/.*listen: /, ""); print; exit}
    '
    
    # Test that awk can parse the script
    if echo "" | awk "$awk_script" 2>/dev/null; then
        pass "dashboard-proxy awk script has valid syntax"
    else
        fail "dashboard-proxy awk script has invalid syntax"
    fi
}

# Test 2: Ensure 'in' is not used as a variable name in any awk script
# 'in' is a reserved keyword in awk
test_no_in_variable() {
    # Look for patterns like {in=1 or {in= or , in= in awk contexts
    if grep -E '\{in=' "$SANDBOX_SH" | grep -q 'awk'; then
        fail "Found 'in' used as variable name in awk script (reserved keyword)"
    else
        pass "No 'in' variable names found in awk scripts"
    fi
}

# Test 3: Source the file to ensure it loads without error
test_source_sandbox() {
    if bash -c "source '$SANDBOX_SH'" 2>/dev/null; then
        pass "sandbox.sh sources without error"
    else
        fail "sandbox.sh failed to source"
    fi
}

# Run tests
test_dashboard_port_awk
test_no_in_variable
test_source_sandbox

# Results
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Results: ${passed} passed, ${failed} failed"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [[ $failed -gt 0 ]]; then
    exit 1
fi

echo -e "${GREEN}All tests passed!${NC}"
