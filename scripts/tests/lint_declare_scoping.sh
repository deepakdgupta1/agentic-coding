#!/usr/bin/env bash
# ============================================================
# Lint: Declare Scoping
#
# All scripts/lib/*.sh files are sourced inside detect_environment(),
# which is a function. Without the -g flag, declare -A and declare -a
# create function-local arrays that vanish when the function returns.
#
# This linter scans for any declare -A or declare -a that is missing
# the -g flag and exits non-zero on violation.
#
# Related bugs: #85-#90 (chg_0001: unbound variable crash)
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"

errors=0
checked=0

echo "=== Declare Scoping Linter ==="
echo "Scanning scripts/lib/*.sh for declare -A/-a missing -g flag..."
echo ""

for file in "$LIB_DIR"/*.sh; do
    [[ -f "$file" ]] || continue
    basename_file="$(basename "$file")"

    # Skip test files - they run standalone, not sourced inside a function
    if [[ "$basename_file" == test_* ]]; then
        continue
    fi

    ((checked++)) || true

    # Find declare -A or declare -a lines that do NOT have -g
    # Valid patterns:   declare -gA, declare -gA, declare -Ag, declare -ga
    # Invalid patterns: declare -A, declare -a (no -g anywhere in flags)
    while IFS= read -r match; do
        [[ -z "$match" ]] && continue
        lineno="${match%%:*}"
        line="${match#*:}"

        # Skip comments
        stripped="${line#"${line%%[![:space:]]*}"}"
        if [[ "$stripped" == \#* ]]; then
            continue
        fi

        # Skip lines inside functions that intentionally use local scope
        # (declare inside a function without -g is intentional local scoping)
        # We only flag top-level declares in lib files, which ARE sourced
        # inside detect_environment(). The -g flag is always needed for lib files.

        echo "ERROR: $basename_file:$lineno: declare without -g flag (will be function-local when sourced)"
        echo "  $line"
        echo "  Fix: Add -g flag (e.g., 'declare -gA' or 'declare -ga')"
        echo ""
        ((errors++)) || true
    done < <(grep -nE '^\s*declare\s+-[Aa]\b' "$file" | grep -vE 'declare\s+-[A-Za-z]*g' || true)
done

echo "---"
echo "Checked $checked lib files, found $errors violations."

if [[ $errors -gt 0 ]]; then
    echo ""
    echo "FAIL: $errors declare statement(s) missing -g flag."
    echo "All declare -A/-a in scripts/lib/*.sh must use -g for global scope."
    exit 1
fi

echo "PASS: All declare statements use -g flag."
exit 0
