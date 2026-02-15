#!/usr/bin/env bash
# shellcheck disable=SC2329
# ============================================================
# ACFS Fault Injection Tests
#
# Simulates failure conditions to verify the installer's
# defensive engineering controls. Each test validates a
# specific failure mode and recovery path.
#
# Usage:
#   ./tests/vm/fault_injection.sh              # Run all tests
#   ./tests/vm/fault_injection.sh <test_name>  # Run specific test
#
# These tests are deterministic and do not require LXD by default.
# They validate fault handling in the installer libraries directly.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source test harness
# shellcheck source=tests/vm/lib/test_harness.sh
if [[ -f "$SCRIPT_DIR/lib/test_harness.sh" ]]; then
    source "$SCRIPT_DIR/lib/test_harness.sh"
fi

# ============================================================
# Test Utilities
# ============================================================

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

test_start() {
    echo "━━━ TEST: $1 ━━━"
}

test_pass() {
    echo "  ✓ $1"
    ((TESTS_PASSED++)) || true
}

test_fail() {
    echo "  ✗ $1" >&2
    ((TESTS_FAILED++)) || true
}

test_skip() {
    echo "  ⊘ $1"
    ((TESTS_SKIPPED++)) || true
}

source_repo_lib() {
    local rel_path="$1"
    local abs_path="$REPO_ROOT/$rel_path"

    if [[ ! -f "$abs_path" ]]; then
        test_skip "Missing library: $rel_path"
        return 1
    fi

    # shellcheck disable=SC1090
    if ! source "$abs_path" 2>/dev/null; then
        test_skip "Unable to source: $rel_path"
        return 1
    fi

    return 0
}

new_temp_dir() {
    mktemp -d "${TMPDIR:-/tmp}/acfs-fi-$1.XXXXXX"
}

# ============================================================
# Fault Injection Tests
# ============================================================

# Test 1: Verify installer detects network loss and classifies correctly
test_network_loss() {
    test_start "Network loss detection"

    unset _ACFS_ERROR_TRACKING_SH_LOADED ERROR_RETRY_POLICY ERROR_REMEDIATION RETRY_DELAYS || true
    if ! source_repo_lib "scripts/lib/error_tracking.sh"; then
        return 0
    fi

    local class
    class="$(classify_error 7 "Failed to connect to github.com")"
    if [[ "$class" == "transient_network" ]]; then
        test_pass "classify_error maps curl 7 to transient_network"
    else
        test_fail "Expected transient_network for curl 7, got '$class'"
    fi

    local old_retry_delays=("${RETRY_DELAYS[@]}")
    RETRY_DELAYS=(0 0 0)

    local counter_file
    counter_file="$(mktemp "${TMPDIR:-/tmp}/acfs-fi-network-attempts.XXXXXX")"
    printf '0\n' > "$counter_file"

    _fi_network_cmd() {
        local attempts
        attempts="$(cat "$counter_file" 2>/dev/null || echo 0)"
        attempts=$((attempts + 1))
        printf '%s\n' "$attempts" > "$counter_file"

        if [[ "$attempts" -lt 3 ]]; then
            echo "curl: (7) Failed to connect to github.com port 443" >&2
            return 7
        fi
        echo "network restored"
        return 0
    }

    local output="" rc=0
    output="$(retry_with_backoff "Simulated network fetch" _fi_network_cmd 2>/dev/null)" || rc=$?
    if [[ $rc -eq 0 && "$output" == "network restored" ]]; then
        test_pass "retry_with_backoff succeeds after transient network recovery"
    else
        test_fail "Expected retry_with_backoff success after recovery (rc=$rc, output='$output')"
    fi

    local attempts
    attempts="$(cat "$counter_file" 2>/dev/null || echo 0)"
    if [[ "$attempts" == "3" ]]; then
        test_pass "Transient network fault retried exactly 2 times before success"
    else
        test_fail "Expected 3 attempts, got $attempts"
    fi

    if is_retryable_error 7 "Failed to connect to github.com"; then
        test_pass "Transient network error is classified as retryable"
    else
        test_fail "Transient network error should be retryable"
    fi

    RETRY_DELAYS=("${old_retry_delays[@]}")
    unset -f _fi_network_cmd
}

# Test 2: Verify installer detects and handles apt lock
test_apt_lock() {
    test_start "APT lock detection"

    unset _ACFS_ERROR_TRACKING_SH_LOADED ERROR_RETRY_POLICY ERROR_REMEDIATION RETRY_DELAYS || true
    if ! source_repo_lib "scripts/lib/error_tracking.sh"; then
        return 0
    fi

    local lock_message="E: Could not get lock /var/lib/dpkg/lock-frontend - open (11: Resource temporarily unavailable)"
    local class
    class="$(classify_error 1 "$lock_message")"
    if [[ "$class" == "dependency_conflict" ]]; then
        test_pass "classify_error maps apt lock to dependency_conflict"
    else
        test_fail "Expected dependency_conflict for apt lock, got '$class'"
    fi

    local old_retry_delays=("${RETRY_DELAYS[@]}")
    RETRY_DELAYS=(0 2 4)

    local counter_file
    counter_file="$(mktemp "${TMPDIR:-/tmp}/acfs-fi-apt-lock-attempts.XXXXXX")"
    printf '0\n' > "$counter_file"

    _fi_apt_lock_cmd() {
        local attempts
        attempts="$(cat "$counter_file" 2>/dev/null || echo 0)"
        attempts=$((attempts + 1))
        printf '%s\n' "$attempts" > "$counter_file"
        echo "$lock_message" >&2
        return 1
    }

    local start_s end_s elapsed_s rc=0
    start_s="$(date +%s)"
    retry_with_backoff "Simulated apt install with lock" _fi_apt_lock_cmd >/dev/null 2>&1 || rc=$?
    end_s="$(date +%s)"
    elapsed_s=$((end_s - start_s))

    if [[ $rc -ne 0 ]]; then
        test_pass "apt lock failure returns non-zero"
    else
        test_fail "apt lock simulation should fail"
    fi

    local attempts
    attempts="$(cat "$counter_file" 2>/dev/null || echo 0)"
    if [[ "$attempts" == "1" ]]; then
        test_pass "apt lock is fail-fast (no retries attempted)"
    else
        test_fail "Expected fail-fast single attempt, got $attempts attempts"
    fi

    if [[ "$elapsed_s" -lt 2 ]]; then
        test_pass "apt lock failure does not wait on retry delays"
    else
        test_fail "Expected fail-fast behavior (<2s), observed ${elapsed_s}s"
    fi

    if ! is_retryable_error 1 "$lock_message"; then
        test_pass "apt lock error is correctly marked non-retryable"
    else
        test_fail "apt lock should not be retryable"
    fi

    RETRY_DELAYS=("${old_retry_delays[@]}")
    unset -f _fi_apt_lock_cmd
}

# Test 3: Verify preflight catches low disk
test_low_disk() {
    test_start "Low disk space detection"

    unset _ACFS_STATE_SH_LOADED || true
    if ! source_repo_lib "scripts/lib/state.sh"; then
        return 0
    fi

    local temp_root fake_bin target_file old_path
    temp_root="$(new_temp_dir low-disk)"
    fake_bin="${temp_root}/bin"
    mkdir -p "$fake_bin"
    target_file="${temp_root}/state.json"

    cat > "${fake_bin}/df" <<'EOF'
#!/usr/bin/env bash
echo "Filesystem 1024-blocks Used Available Capacity Mounted on"
echo "fakefs 1000 995 100 99% /"
EOF
    chmod +x "${fake_bin}/df"

    old_path="$PATH"
    PATH="${fake_bin}:$PATH"

    local rc=0
    state_write_atomic "$target_file" '{"schema_version":3}' || rc=$?
    if [[ $rc -eq 1 ]]; then
        test_pass "state_write_atomic fails when available disk is below 1MB"
    else
        test_fail "Expected low-disk write failure (rc=1), got rc=$rc"
    fi

    if [[ ! -f "$target_file" ]]; then
        test_pass "No partial state file is created on low-disk failure"
    else
        test_fail "State file should not be written when low-disk check fails"
    fi

    PATH="$old_path"
}

# Test 4: Verify permission errors are classified correctly
test_permission_failure() {
    test_start "Permission error classification"

    unset _ACFS_ERROR_TRACKING_SH_LOADED ERROR_RETRY_POLICY ERROR_REMEDIATION RETRY_DELAYS || true
    if ! source_repo_lib "scripts/lib/error_tracking.sh"; then
        return 0
    fi

    local class
    class=$(classify_error 1 "Permission denied")
    if [[ "$class" == "permission" ]]; then
        test_pass "classify_error(1, 'Permission denied') = permission"
    else
        test_fail "Expected 'permission', got '$class'"
    fi

    class=$(classify_error 1 "operation not permitted")
    if [[ "$class" == "permission" ]]; then
        test_pass "classify_error(1, 'operation not permitted') = permission"
    else
        test_fail "Expected 'permission', got '$class'"
    fi

    class=$(classify_error 1 "read-only file system")
    if [[ "$class" == "permission" ]]; then
        test_pass "classify_error(1, 'read-only file system') = permission"
    else
        test_fail "Expected 'permission', got '$class'"
    fi

    class=$(classify_error 28 "")
    if [[ "$class" == "transient_network" ]]; then
        test_pass "classify_error(28, '') = transient_network"
    else
        test_fail "Expected 'transient_network', got '$class'"
    fi

    class=$(classify_error 1 "dpkg was interrupted")
    if [[ "$class" == "dependency_conflict" ]]; then
        test_pass "classify_error(1, 'dpkg was interrupted') = dependency_conflict"
    else
        test_fail "Expected 'dependency_conflict', got '$class'"
    fi

    class=$(classify_error 1 "some unknown error")
    if [[ "$class" == "unknown" ]]; then
        test_pass "classify_error(1, 'some unknown error') = unknown"
    else
        test_fail "Expected 'unknown', got '$class'"
    fi

    if ! is_retryable_error 1 "Permission denied"; then
        test_pass "Permission errors are correctly marked non-retryable"
    else
        test_fail "Permission errors should not be retryable"
    fi
}

# Test 5: Verify interrupted installation + resume works
test_interrupted_run() {
    test_start "Interrupted run recovery"

    unset _ACFS_STATE_SH_LOADED || true
    if ! source_repo_lib "scripts/lib/state.sh"; then
        return 0
    fi

    if ! command -v jq &>/dev/null; then
        test_skip "jq not available (required for state inspection)"
        return 0
    fi
    if ! command -v flock &>/dev/null; then
        test_skip "flock not available (required for state lock operations)"
        return 0
    fi

    local temp_root target_user
    temp_root="$(new_temp_dir interrupted)"
    target_user="$(id -un 2>/dev/null || echo ubuntu)"

    export ACFS_HOME="${temp_root}/.acfs"
    export ACFS_STATE_FILE="${ACFS_HOME}/state.json"
    export TARGET_USER="$target_user"
    export TARGET_HOME="${temp_root}/home/${target_user}"
    export MODE="vibe"
    export ACFS_VERSION="0.5.0-test"
    export SKIP_POSTGRES=false
    export SKIP_VAULT=false
    export SKIP_CLOUD=false
    mkdir -p "$ACFS_HOME" "$TARGET_HOME"
    unset ACFS_RESUME_FROM ACFS_STOP_AFTER _ACFS_RESUME_FROM_REACHED _ACFS_STOP_AFTER_REACHED || true

    if state_init; then
        test_pass "state_init succeeded for interrupted-run simulation"
    else
        test_fail "state_init failed for interrupted-run simulation"
        return 0
    fi

    if state_phase_start "languages" "Installing bun"; then
        test_pass "state_phase_start recorded active phase before interruption"
    else
        test_fail "state_phase_start failed before interruption"
        return 0
    fi

    if state_mark_interrupted; then
        test_pass "state_mark_interrupted wrote interruption marker"
    else
        test_fail "state_mark_interrupted failed"
        return 0
    fi

    local interrupted current_phase current_step
    interrupted="$(jq -r '.interrupted // false' "$ACFS_STATE_FILE" 2>/dev/null || echo false)"
    current_phase="$(jq -r '.current_phase' "$ACFS_STATE_FILE" 2>/dev/null || echo unknown)"
    current_step="$(jq -r '.current_step' "$ACFS_STATE_FILE" 2>/dev/null || echo unknown)"

    if [[ "$interrupted" == "true" && "$current_phase" == "null" && "$current_step" == "null" ]]; then
        test_pass "Interruption clears current phase/step and marks state as interrupted"
    else
        test_fail "Unexpected interrupted state (interrupted=$interrupted, current_phase=$current_phase, current_step=$current_step)"
    fi

    _fi_languages_resume_phase() {
        return 0
    }

    if run_phase "languages" "5/9 Languages" _fi_languages_resume_phase; then
        test_pass "run_phase succeeds when resuming interrupted languages phase"
    else
        test_fail "run_phase failed while resuming interrupted languages phase"
    fi

    if state_is_phase_completed "languages"; then
        test_pass "Resumed phase is marked completed after recovery"
    else
        test_fail "Resumed phase was not marked completed"
    fi

    unset -f _fi_languages_resume_phase
}

# Test 6: Verify postcondition drift detection on resume
test_postcondition_drift() {
    test_start "Postcondition drift detection"

    unset _ACFS_STATE_SH_LOADED || true
    if ! source_repo_lib "scripts/lib/state.sh"; then
        return 0
    fi

    if ! command -v jq &>/dev/null; then
        test_skip "jq not available (required for state inspection)"
        return 0
    fi
    if ! command -v flock &>/dev/null; then
        test_skip "flock not available (required for state lock operations)"
        return 0
    fi

    local temp_root target_user
    temp_root="$(new_temp_dir drift)"
    target_user="$(id -un 2>/dev/null || echo ubuntu)"

    export ACFS_HOME="${temp_root}/.acfs"
    export ACFS_STATE_FILE="${ACFS_HOME}/state.json"
    export TARGET_USER="$target_user"
    export TARGET_HOME="${temp_root}/home/${target_user}"
    export MODE="vibe"
    export ACFS_VERSION="0.5.0-test"
    export SKIP_POSTGRES=false
    export SKIP_VAULT=false
    export SKIP_CLOUD=false
    mkdir -p "$ACFS_HOME" "$TARGET_HOME"
    unset ACFS_RESUME_FROM ACFS_STOP_AFTER _ACFS_RESUME_FROM_REACHED _ACFS_STOP_AFTER_REACHED || true

    if ! state_init; then
        test_fail "state_init failed for postcondition drift simulation"
        return 0
    fi
    test_pass "state_init succeeded for drift simulation"

    if ! state_phase_complete "cli_tools"; then
        test_fail "Could not seed completed cli_tools phase"
        return 0
    fi
    test_pass "Seeded cli_tools as completed phase"

    local drift_checks=0 phase_runs=0
    _run_phase_postconditions() {
        local phase_id="$1"
        if [[ "$phase_id" == "cli_tools" ]]; then
            drift_checks=$((drift_checks + 1))
            return 1
        fi
        return 0
    }
    _fi_cli_tools_rebuild() {
        phase_runs=$((phase_runs + 1))
        return 0
    }

    if run_phase "cli_tools" "4/9 CLI Tools" _fi_cli_tools_rebuild; then
        test_pass "run_phase re-runs cli_tools when postcondition drift is detected"
    else
        test_fail "run_phase failed while handling postcondition drift"
    fi

    if [[ "$drift_checks" -ge 1 ]]; then
        test_pass "Postcondition check was evaluated for completed cli_tools phase"
    else
        test_fail "Postcondition check was not evaluated"
    fi

    if [[ "$phase_runs" == "1" ]]; then
        test_pass "Drifted phase executed exactly once after unmark"
    else
        test_fail "Expected cli_tools to execute once, observed $phase_runs executions"
    fi

    if state_is_phase_completed "cli_tools"; then
        test_pass "cli_tools is marked completed again after re-run"
    else
        test_fail "cli_tools should be completed after drift-triggered re-run"
    fi

    local cli_tools_count
    cli_tools_count="$(jq '[.completed_phases[] | select(. == "cli_tools")] | length' "$ACFS_STATE_FILE" 2>/dev/null || echo 0)"
    if [[ "$cli_tools_count" == "1" ]]; then
        test_pass "completed_phases does not duplicate cli_tools after re-run"
    else
        test_fail "Expected one cli_tools entry in completed_phases, got $cli_tools_count"
    fi

    unset -f _run_phase_postconditions _fi_cli_tools_rebuild
}

# Test 7: Verify JSONL event log is created
test_event_log() {
    test_start "JSONL event log creation"

    if ! source_repo_lib "scripts/lib/observability.sh"; then
        return 0
    fi

    local temp_root
    temp_root="$(new_temp_dir events)"
    export ACFS_HOME="${temp_root}/.acfs"
    mkdir -p "$ACFS_HOME"

    export ACFS_RUN_ID="fault_injection_$(date +%s)_$$"
    export ACFS_INSTALL_START="$(date +%s)"
    ACFS_EVENT_LOG=""
    _observability_init

    _emit_event "install_start" "" "mode=vibe" "target_user=ubuntu"
    _emit_event "stage_start" "user_setup" "display=1/9 User Setup"
    _emit_event "stage_end" "user_setup" "status=success"
    _emit_event "resume" "" "state_file=${ACFS_HOME}/state.json"

    if [[ -n "${ACFS_EVENT_LOG:-}" && -f "${ACFS_EVENT_LOG:-}" ]]; then
        test_pass "Event log file created at $ACFS_EVENT_LOG"
    else
        test_fail "Event log file was not created"
        return 0
    fi

    if grep -q '"event":"install_start"' "$ACFS_EVENT_LOG"; then
        test_pass "Event log contains install_start event"
    else
        test_fail "Missing install_start event in JSONL log"
    fi

    if grep -q '"event":"stage_start".*"stage":"user_setup"' "$ACFS_EVENT_LOG"; then
        test_pass "Event log contains stage_start for user_setup"
    else
        test_fail "Missing stage_start user_setup event in JSONL log"
    fi

    if grep -q '"event":"stage_end".*"stage":"user_setup".*"status":"success"' "$ACFS_EVENT_LOG"; then
        test_pass "Event log contains successful stage_end for user_setup"
    else
        test_fail "Missing successful stage_end user_setup event in JSONL log"
    fi

    if command -v jq &>/dev/null; then
        local invalid_lines=0
        while IFS= read -r line; do
            if ! printf '%s\n' "$line" | jq -e . >/dev/null 2>&1; then
                invalid_lines=$((invalid_lines + 1))
            fi
        done < "$ACFS_EVENT_LOG"

        if [[ "$invalid_lines" == "0" ]]; then
            test_pass "All JSONL events are valid JSON"
        else
            test_fail "Found $invalid_lines invalid JSON event line(s)"
        fi
    else
        test_skip "jq not available (skipping JSON structural validation)"
    fi
}

# ============================================================
# Main
# ============================================================

main() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║            ACFS Fault Injection Tests                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    local test_filter="${1:-all}"

    case "$test_filter" in
        all)
            test_network_loss
            test_apt_lock
            test_low_disk
            test_permission_failure
            test_interrupted_run
            test_postcondition_drift
            test_event_log
            ;;
        *)
            # Run specific test
            if declare -f "test_$test_filter" &>/dev/null; then
                "test_$test_filter"
            else
                echo "Unknown test: $test_filter" >&2
                echo "Available: network_loss apt_lock low_disk permission_failure interrupted_run postcondition_drift event_log" >&2
                exit 1
            fi
            ;;
    esac

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed, $TESTS_SKIPPED skipped"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
