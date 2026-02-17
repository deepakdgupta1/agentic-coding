#!/usr/bin/env bash
# ============================================================
# install.sh unknown-flag behavior in unattended mode
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

passed=0
failed=0

pass() {
    echo "✓ $1"
    ((passed++)) || true
}

fail() {
    echo "✖ $1" >&2
    ((failed++)) || true
}

run_install_and_capture() {
    local -n _status_ref="$1"
    local -n _output_ref="$2"
    shift 2

    local cmd_output=""
    local cmd_status=0
    set +e
    cmd_output="$(bash "$REPO_ROOT/install.sh" "$@" </dev/null 2>&1)"
    cmd_status=$?
    set -e

    _status_ref="$cmd_status"
    _output_ref="$cmd_output"
}

test_unknown_before_yes_fails() {
    local status=0
    local output=""
    run_install_and_capture status output --definitely-unknown-flag --yes

    if [[ $status -ne 0 ]]; then
        pass "unknown flag before --yes exits non-zero"
    else
        fail "unknown flag before --yes should fail"
        return
    fi

    if [[ "$output" == *"Unknown option(s) in non-interactive mode"* ]] && [[ "$output" == *"--definitely-unknown-flag"* ]]; then
        pass "error message includes unknown flag in unattended mode"
    else
        fail "expected unattended unknown-option message not found"
    fi
}

test_unknown_with_yes_fails() {
    local status=0
    local output=""
    run_install_and_capture status output --yes --another-unknown-flag

    if [[ $status -ne 0 ]]; then
        pass "unknown flag with --yes exits non-zero"
    else
        fail "unknown flag with --yes should fail"
        return
    fi

    if [[ "$output" == *"Unknown option(s) in non-interactive mode"* ]] && [[ "$output" == *"--another-unknown-flag"* ]]; then
        pass "error output contains unknown flag text"
    else
        fail "expected unknown-flag text not found in output"
    fi
}

main() {
    echo "=== test_unattended_unknown_flags.sh ==="
    test_unknown_before_yes_fails
    test_unknown_with_yes_fails
    echo "Results: ${passed} passed, ${failed} failed"
    [[ $failed -eq 0 ]]
}

main "$@"
