#!/usr/bin/env bash
# ============================================================
# Integration Test: Library Global Variable Scoping
#
# Validates that key globals declared in scripts/lib/*.sh survive
# being sourced inside a function (as detect_environment() does).
#
# This catches the class of bugs where declare -A/-a without -g
# creates function-local arrays that vanish when the function returns.
#
# Related bugs: #85-#90
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
GENERATED_DIR="$REPO_ROOT/scripts/generated"

errors=0
passed=0

echo "=== Library Globals Scoping Integration Test ==="
echo ""

# Provide minimal stubs that the libs expect
export YES_MODE=true
export DRY_RUN=false
export MODE=vibe
export ACFS_VERSION="0.0.0-test"
export TARGET_USER="ubuntu"
export TARGET_HOME="/tmp/test_lib_globals_home"
export ACFS_HOME="$TARGET_HOME/.acfs"
export ACFS_STATE_FILE="$ACFS_HOME/state.json"
export ACFS_LOG_DIR="/tmp/test_lib_globals_logs"
export ACFS_LIB_DIR="$LIB_DIR"
export ACFS_GENERATED_DIR="$GENERATED_DIR"
export ACFS_ASSETS_DIR="$REPO_ROOT/acfs"
export ACFS_CHECKSUMS_YAML="$REPO_ROOT/checksums.yaml"
export ACFS_MANIFEST_YAML="$REPO_ROOT/acfs.manifest.yaml"
export SKIP_POSTGRES=false
export SKIP_VAULT=false
export SKIP_CLOUD=false
export ACFS_RAW="https://raw.githubusercontent.com/test/test/main"
export ACFS_CHECKSUMS_RAW="$ACFS_RAW"
export ACFS_CHECKSUMS_REF="main"
export _ACFS_LOGGING_SH_LOADED=1
export ACFS_CI=true

mkdir -p "$TARGET_HOME/.acfs" "$ACFS_LOG_DIR" 2>/dev/null || true

# Provide minimal logging stubs
log_info() { echo "[INFO] $*"; }
log_warn() { echo "[WARN] $*"; }
log_error() { echo "[ERROR] $*" >&2; }
log_detail() { echo "[DETAIL] $*"; }
log_debug() { echo "[DEBUG] $*"; }
log_fatal() { echo "[FATAL] $*" >&2; exit 1; }
export -f log_info log_warn log_error log_detail log_debug log_fatal

# Mimic detect_environment(): source libs inside a function
source_libs_in_function() {
    local libs=(
        "state.sh"
        "install_helpers.sh"
        "autofix.sh"
        "error_tracking.sh"
    )

    for lib in "${libs[@]}"; do
        local path="$LIB_DIR/$lib"
        if [[ -f "$path" ]]; then
            # shellcheck source=/dev/null
            source "$path" 2>/dev/null || {
                echo "[WARN] Failed to source $lib (non-fatal, may need deps)"
            }
        else
            echo "[WARN] Lib not found: $lib"
        fi
    done
}

# Call the function - this is the critical test
source_libs_in_function

echo "Verifying globals survive function return..."
echo ""

# Check each key global variable
check_global() {
    local var_name="$1"
    local description="$2"

    if declare -p "$var_name" &>/dev/null; then
        echo "  PASS: $var_name ($description)"
        ((passed++)) || true
    else
        echo "  FAIL: $var_name is NOT defined after function return ($description)"
        ((errors++)) || true
    fi
}

# Key globals from state.sh
check_global "ACFS_PHASE_NAMES" "state.sh: associative array of phase display names"

# Key globals from install_helpers.sh
check_global "ACFS_EFFECTIVE_RUN" "install_helpers.sh: module execution map"
check_global "ACFS_EFFECTIVE_PLAN" "install_helpers.sh: ordered execution plan"

# Key globals from autofix.sh
check_global "ACFS_CHANGE_RECORDS" "autofix.sh: change record map"
check_global "ACFS_CHANGE_ORDER" "autofix.sh: ordered change IDs"

# Key globals from error_tracking.sh
check_global "ACFS_FAILED_TOOLS" "error_tracking.sh: failed tool list"
check_global "ACFS_SUCCESSFUL_TOOLS" "error_tracking.sh: successful tool list"

echo ""
echo "---"
echo "Results: $passed passed, $errors failed"

# Cleanup
rm -rf "$TARGET_HOME" "$ACFS_LOG_DIR" 2>/dev/null || true

if [[ $errors -gt 0 ]]; then
    echo ""
    echo "FAIL: $errors global(s) did not survive function scoping."
    echo "Ensure all declare -A/-a in lib files use the -g flag."
    exit 1
fi

echo "PASS: All key globals survive function-scoped sourcing."
exit 0
