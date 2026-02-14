#!/usr/bin/env bash
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
# Tests run inside LXD containers (requires test_harness.sh).
#
# WARNING: These tests intentionally break things. Never run
# directly on your workstation — only inside disposable VMs.
# ============================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test harness
# shellcheck source=tests/vm/test_harness.sh
if [[ -f "$SCRIPT_DIR/test_harness.sh" ]]; then
    source "$SCRIPT_DIR/test_harness.sh"
fi

# ============================================================
# Test Utilities
# ============================================================

TESTS_PASSED=0
TESTS_FAILED=0

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

# ============================================================
# Fault Injection Tests
# ============================================================

# Test 1: Verify installer detects network loss and classifies correctly
test_network_loss() {
    test_start "Network loss detection"

    # Simulate: Drop DNS after Phase 4 (cli_tools)
    # Expected: Phase 5 (languages) fails with transient_network class
    # Verify: --resume works after network restore

    # This test requires a container environment
    if ! command -v lxc &>/dev/null; then
        echo "  SKIP: lxc not available (run in VM test environment)"
        return 0
    fi

    # TODO: Implement with container networking
    # Steps:
    # 1. Launch container with install.sh --stop-after cli_tools
    # 2. Block outbound DNS/HTTP: iptables -A OUTPUT -p tcp --dport 443 -j DROP
    # 3. Run install.sh --resume-from languages
    # 4. Verify exit 1 + JSONL contains error_class=transient_network
    # 5. Restore network: iptables -D OUTPUT -p tcp --dport 443 -j DROP
    # 6. Run install.sh --resume
    # 7. Verify languages phase completes

    echo "  SKIP: Requires container orchestration (scaffold only)"
}

# Test 2: Verify installer detects and handles apt lock
test_apt_lock() {
    test_start "APT lock detection"

    # Simulate: Hold dpkg lock during installation
    # Expected: Phase fails fast, not infinite wait
    # Verify: Error class is dependency_conflict

    if ! command -v lxc &>/dev/null; then
        echo "  SKIP: lxc not available"
        return 0
    fi

    # TODO: Implement with container
    # Steps:
    # 1. Launch container
    # 2. flock /var/lib/dpkg/lock-frontend sleep 300 &
    # 3. Run install.sh
    # 4. Verify fails within 60s (not hang)
    # 5. Verify JSONL contains error_class=dependency_conflict

    echo "  SKIP: Requires container orchestration (scaffold only)"
}

# Test 3: Verify preflight catches low disk
test_low_disk() {
    test_start "Low disk space detection"

    # This can be tested locally using a tmpfs
    # Simulate: Mount a tiny tmpfs, set HOME to it, run preflight
    # Expected: Preflight reports failure

    if ! command -v lxc &>/dev/null; then
        echo "  SKIP: lxc not available"
        return 0
    fi

    # TODO: Implement with container
    # Steps:
    # 1. Launch container
    # 2. dd if=/dev/zero of=/bigfile bs=1M count=$((available - 10))
    # 3. Run scripts/preflight.sh --json
    # 4. Verify JSON output has errors > 0 and "Disk Space" failure

    echo "  SKIP: Requires container orchestration (scaffold only)"
}

# Test 4: Verify permission errors are classified correctly
test_permission_failure() {
    test_start "Permission error classification"

    # Unit-test classify_error directly
    source "$SCRIPT_DIR/../../scripts/lib/error_tracking.sh" 2>/dev/null || {
        echo "  SKIP: Cannot source error_tracking.sh"
        return 0
    }

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
}

# Test 5: Verify interrupted installation + resume works
test_interrupted_run() {
    test_start "Interrupted run recovery"

    # Simulate: SIGTERM during Phase 5
    # Expected: state_mark_interrupted records state, --resume picks up
    # Verify: Resumed installation completes phases 5-9

    if ! command -v lxc &>/dev/null; then
        echo "  SKIP: lxc not available"
        return 0
    fi

    # TODO: Implement with container
    # Steps:
    # 1. Launch container with install.sh
    # 2. Wait for Phase 5 to start (poll state.json)
    # 3. Send SIGTERM to installer PID
    # 4. Verify state.json has interrupted marker
    # 5. Run install.sh --resume
    # 6. Verify phases 5-9 complete

    echo "  SKIP: Requires container orchestration (scaffold only)"
}

# Test 6: Verify postcondition drift detection on resume
test_postcondition_drift() {
    test_start "Postcondition drift detection"

    # Simulate: Complete all phases, delete a binary, resume
    # Expected: Phase with missing binary is re-run

    if ! command -v lxc &>/dev/null; then
        echo "  SKIP: lxc not available"
        return 0
    fi

    # TODO: Implement with container
    # Steps:
    # 1. Complete full installation
    # 2. rm ~/.local/bin/fd (or similar)
    # 3. Run install.sh --resume
    # 4. Verify cli_tools phase is re-run (not skipped)
    # 5. Verify fd binary is restored

    echo "  SKIP: Requires container orchestration (scaffold only)"
}

# Test 7: Verify JSONL event log is created
test_event_log() {
    test_start "JSONL event log creation"

    if ! command -v lxc &>/dev/null; then
        echo "  SKIP: lxc not available"
        return 0
    fi

    # TODO: Implement with container
    # Steps:
    # 1. Run install.sh (at least --stop-after user_setup for speed)
    # 2. Verify ~/.acfs/logs/install/*.jsonl exists
    # 3. Verify it contains {"event":"install_start"...}
    # 4. Verify it contains {"event":"stage_start","stage":"user_setup"...}
    # 5. Verify it contains {"event":"stage_end","stage":"user_setup","status":"success"...}

    echo "  SKIP: Requires container orchestration (scaffold only)"
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
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
