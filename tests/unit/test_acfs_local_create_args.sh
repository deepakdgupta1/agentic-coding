#!/usr/bin/env bash
# ============================================================
# ACFS Local create arg resolution tests
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

has_arg() {
    local needle="$1"
    shift
    local item=""
    for item in "$@"; do
        if [[ "$item" == "$needle" ]]; then
            return 0
        fi
    done
    return 1
}

has_pair() {
    local flag="$1"
    local value="$2"
    shift 2
    local -a args=("$@")
    local i=0
    for ((i = 0; i + 1 < ${#args[@]}; i++)); do
        if [[ "${args[$i]}" == "$flag" && "${args[$((i + 1))]}" == "$value" ]]; then
            return 0
        fi
    done
    return 1
}

encode_payload() {
    local sep=$'\x1f'
    local payload=""
    local arg=""
    for arg in "$@"; do
        payload+="${arg}${sep}"
    done
    printf '%s' "$payload" | base64 | tr -d '\n'
}

# shellcheck source=scripts/local/acfs_container.sh
source "$REPO_ROOT/scripts/local/acfs_container.sh"

test_default_args() {
    local -a resolved=()
    local timeout=""
    ACFS_LOCAL_INSTALL_ARGS_B64=""
    ACFS_LOCAL_INSTALL_TIMEOUT_SECONDS="7200"

    if resolve_create_install_args resolved timeout; then
        :
    else
        fail "resolve_create_install_args default path returned non-zero"
        return
    fi

    if has_arg "--local" "${resolved[@]}" && has_arg "--yes" "${resolved[@]}" && has_arg "--skip-ubuntu-upgrade" "${resolved[@]}"; then
        pass "default create args enforce --local --yes --skip-ubuntu-upgrade"
    else
        fail "default create args missing required flags"
    fi

    if [[ "$timeout" == "7200" ]]; then
        pass "default timeout is 7200 seconds"
    else
        fail "default timeout expected 7200, got '$timeout'"
    fi
}

test_forwarded_payload() {
    local -a resolved=()
    local timeout=""
    ACFS_LOCAL_INSTALL_ARGS_B64="$(encode_payload --mode safe --strict)"
    ACFS_LOCAL_INSTALL_TIMEOUT_SECONDS="7200"

    if resolve_create_install_args resolved timeout; then
        :
    else
        fail "resolve_create_install_args failed for forwarded payload"
        return
    fi

    if has_pair "--mode" "safe" "${resolved[@]}" && has_arg "--strict" "${resolved[@]}"; then
        pass "forwarded payload args are preserved"
    else
        fail "forwarded payload args missing expected flags"
    fi

    if has_arg "--local" "${resolved[@]}" && has_arg "--yes" "${resolved[@]}" && has_arg "--skip-ubuntu-upgrade" "${resolved[@]}"; then
        pass "forwarded payload still enforces required local flags"
    else
        fail "forwarded payload missing required local flags"
    fi
}

test_cli_passthrough_overrides_payload() {
    local -a resolved=()
    local timeout=""
    ACFS_LOCAL_INSTALL_ARGS_B64="$(encode_payload --mode safe --strict)"
    ACFS_LOCAL_INSTALL_TIMEOUT_SECONDS="7200"

    if resolve_create_install_args resolved timeout --mode vibe --resume --stop-after stack; then
        :
    else
        fail "resolve_create_install_args failed for CLI passthrough"
        return
    fi

    if has_pair "--mode" "vibe" "${resolved[@]}" && has_arg "--resume" "${resolved[@]}" && has_pair "--stop-after" "stack" "${resolved[@]}"; then
        pass "CLI passthrough args are used for acfs-local create"
    else
        fail "CLI passthrough args not resolved as expected"
    fi
}

test_timeout_flag() {
    local -a resolved=()
    local timeout=""
    ACFS_LOCAL_INSTALL_ARGS_B64=""
    ACFS_LOCAL_INSTALL_TIMEOUT_SECONDS="7200"

    if resolve_create_install_args resolved timeout --install-timeout 45 --strict; then
        :
    else
        fail "resolve_create_install_args rejected valid --install-timeout"
        return
    fi

    if [[ "$timeout" == "45" ]]; then
        pass "--install-timeout overrides timeout seconds"
    else
        fail "--install-timeout expected 45, got '$timeout'"
    fi
}

test_invalid_timeout_flag() {
    local -a resolved=()
    local timeout=""
    ACFS_LOCAL_INSTALL_ARGS_B64=""
    ACFS_LOCAL_INSTALL_TIMEOUT_SECONDS="7200"

    if resolve_create_install_args resolved timeout --install-timeout nope >/dev/null 2>&1; then
        fail "invalid --install-timeout should fail"
    else
        pass "invalid --install-timeout returns non-zero"
    fi
}

test_install_runner_injects_timeout_and_parent_run() {
    local captured_cmd=""

    acfs_sandbox_exec_root() {
        captured_cmd="$1"
        return 0
    }

    if run_container_install_once "echo test-install" "33" "parent-run-1"; then
        :
    else
        fail "run_container_install_once should return success when sandbox exec succeeds"
        return
    fi

    if [[ "$captured_cmd" == *"timeout --foreground 33 bash /tmp/install.sh echo test-install"* ]]; then
        pass "run_container_install_once wraps installer with timeout"
    else
        fail "run_container_install_once missing timeout wrapper"
    fi

    if [[ "$captured_cmd" == *"export ACFS_PARENT_RUN_ID=parent-run-1"* ]]; then
        pass "run_container_install_once forwards parent run ID"
    else
        fail "run_container_install_once missing ACFS_PARENT_RUN_ID export"
    fi
}

main() {
    echo "=== test_acfs_local_create_args.sh ==="
    test_default_args
    test_forwarded_payload
    test_cli_passthrough_overrides_payload
    test_timeout_flag
    test_invalid_timeout_flag
    test_install_runner_injects_timeout_and_parent_run
    echo "Results: ${passed} passed, ${failed} failed"
    [[ $failed -eq 0 ]]
}

main "$@"
