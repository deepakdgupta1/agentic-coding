#!/usr/bin/env bash
# ============================================================
# ACFS macOS Bootstrap Test (mocked Multipass)
#
# Verifies:
# 1) macOS VM settings can be configured via environment variables.
# 2) Installer flags are forwarded through macOS bootstrap payload.
#
# This test runs on Linux by mocking `uname` and `multipass`.
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

failures=0

pass() {
    echo "✓ $1"
}

fail() {
    echo "✖ $1" >&2
    failures=$((failures + 1))
}

require_contains() {
    local haystack="$1"
    local needle="$2"
    local label="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        pass "$label"
    else
        fail "$label (missing: $needle)"
    fi
}

setup_mock_case() {
    local case_root="$1"
    local mock_bin="$case_root/mock-bin"
    local log_file="$case_root/multipass.log"
    local vm_exists_file="$case_root/vm.exists"
    local home_dir="$case_root/home"

    mkdir -p "$mock_bin"
    mkdir -p "$home_dir"

    cat > "$mock_bin/uname" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-s" ]]; then
    echo "Darwin"
else
    echo "Darwin"
fi
EOF
    chmod +x "$mock_bin/uname"

    cat > "$mock_bin/multipass" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_file="${MOCK_MULTIPASS_LOG:?}"
vm_exists_file="${MOCK_MULTIPASS_VM_EXISTS_FILE:?}"
cmd="${1:-}"

printf 'CMD:%s\n' "$*" >> "$log_file"

case "$cmd" in
    help|wait-ready|start|restart|mount|umount|transfer|stop|delete|purge)
        exit 0
        ;;
    version)
        echo "multipass 1.14.0"
        exit 0
        ;;
    list)
        echo "Name                    State             IPv4             Image"
        if [[ -f "$vm_exists_file" ]]; then
            echo "acfs-ci-vm              Running           10.0.0.2         Ubuntu 24.04 LTS"
        fi
        exit 0
        ;;
    info)
        echo "Name: ${2:-acfs-host}"
        echo "State: Running"
        exit 0
        ;;
    launch)
        touch "$vm_exists_file"
        exit 0
        ;;
    exec)
        prev=""
        arg=""
        command_payload=""
        for arg in "$@"; do
            if [[ "$prev" == "-c" ]]; then
                command_payload="$arg"
                break
            fi
            prev="$arg"
        done
        printf 'EXEC_CMD:%s\n' "$command_payload" >> "$log_file"
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
EOF
    chmod +x "$mock_bin/multipass"

    echo "$mock_bin|$log_file|$vm_exists_file|$home_dir"
}

decode_payload_to_args() {
    local payload="$1"
    local decoded=""

    if decoded="$(printf '%s' "$payload" | base64 --decode 2>/dev/null)"; then
        :
    elif decoded="$(printf '%s' "$payload" | base64 -d 2>/dev/null)"; then
        :
    else
        return 1
    fi

    mapfile -d $'\x1f' -t FORWARDED_ARGS < <(printf '%s' "$decoded")
}

has_arg() {
    local needle="$1"
    local item=""
    for item in "${FORWARDED_ARGS[@]:-}"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

has_pair() {
    local flag="$1"
    local value="$2"
    local i=0
    for ((i = 0; i + 1 < ${#FORWARDED_ARGS[@]}; i++)); do
        if [[ "${FORWARDED_ARGS[$i]}" == "$flag" && "${FORWARDED_ARGS[$((i + 1))]}" == "$value" ]]; then
            return 0
        fi
    done
    return 1
}

run_case_one() {
    echo "=== Case 1: Forward installer flags + custom VM settings ==="
    local case_root
    case_root="$(mktemp -d "${TMPDIR:-/tmp}/acfs-macos-bootstrap-case1.XXXXXX")"
    local setup
    setup="$(setup_mock_case "$case_root")"
    local mock_bin="${setup%%|*}"
    local rest="${setup#*|}"
    local log_file="${rest%%|*}"
    rest="${rest#*|}"
    local vm_exists_file="${rest%%|*}"
    local home_dir="${rest##*|}"

    mkdir -p "$case_root/workspace"

    PATH="$mock_bin:$PATH" \
    HOME="$home_dir" \
    MOCK_MULTIPASS_LOG="$log_file" \
    MOCK_MULTIPASS_VM_EXISTS_FILE="$vm_exists_file" \
    ACFS_MACOS_VM_NAME="acfs-ci-vm" \
    ACFS_MACOS_VM_CPUS="6" \
    ACFS_MACOS_VM_MEM="12G" \
    ACFS_MACOS_VM_DISK="80G" \
    ACFS_WORKSPACE_HOST="$case_root/workspace" \
    bash -s -- \
        --macos \
        --yes \
        --mode safe \
        --resume \
        --resume-from languages \
        --stop-after stack \
        --skip-postgres \
        --skip-vault \
        --skip-cloud \
        --skip-preflight \
        --strict \
        --checksums-ref feature/ref \
        --only lang.uv \
        --only-phase 5 \
        --skip cloud.gcp \
        --no-deps < "$REPO_ROOT/install.sh"

    local launch_line
    launch_line="$(grep -m1 '^CMD:launch ' "$log_file" || true)"
    require_contains "$launch_line" "--name acfs-ci-vm --cpus 6 --memory 12G --disk 80G 24.04" "VM launch uses env-configured name/size"

    local exec_cmd
    exec_cmd="$(grep '^EXEC_CMD:' "$log_file" | sed 's/^EXEC_CMD://' | grep 'curl -fsSL' | head -n1 || true)"
    require_contains "$exec_cmd" "ACFS_LOCAL_INSTALL_ARGS_B64=" "Forward payload is attached to in-VM install command"

    local payload=""
    if [[ "$exec_cmd" =~ ACFS_LOCAL_INSTALL_ARGS_B64=\'([^\']+)\' ]]; then
        payload="${BASH_REMATCH[1]}"
    else
        fail "Could not extract ACFS_LOCAL_INSTALL_ARGS_B64 payload"
        return
    fi

    if decode_payload_to_args "$payload"; then
        pass "Forward payload decodes successfully"
    else
        fail "Forward payload failed to decode"
        return
    fi

    if has_pair "--mode" "safe"; then pass "forwards --mode safe"; else fail "missing --mode safe"; fi
    if has_arg "--resume"; then pass "forwards --resume"; else fail "missing --resume"; fi
    if has_pair "--resume-from" "languages"; then pass "forwards --resume-from"; else fail "missing --resume-from languages"; fi
    if has_pair "--stop-after" "stack"; then pass "forwards --stop-after"; else fail "missing --stop-after stack"; fi
    if has_arg "--skip-postgres"; then pass "forwards --skip-postgres"; else fail "missing --skip-postgres"; fi
    if has_arg "--skip-vault"; then pass "forwards --skip-vault"; else fail "missing --skip-vault"; fi
    if has_arg "--skip-cloud"; then pass "forwards --skip-cloud"; else fail "missing --skip-cloud"; fi
    if has_arg "--skip-preflight"; then pass "forwards --skip-preflight"; else fail "missing --skip-preflight"; fi
    if has_arg "--strict"; then pass "forwards --strict"; else fail "missing --strict"; fi
    if has_pair "--checksums-ref" "feature/ref"; then pass "forwards --checksums-ref"; else fail "missing --checksums-ref feature/ref"; fi
    if has_pair "--only" "lang.uv"; then pass "forwards --only"; else fail "missing --only lang.uv"; fi
    if has_pair "--only-phase" "5"; then pass "forwards --only-phase"; else fail "missing --only-phase 5"; fi
    if has_pair "--skip" "cloud.gcp"; then pass "forwards --skip"; else fail "missing --skip cloud.gcp"; fi
    if has_arg "--no-deps"; then pass "forwards --no-deps"; else fail "missing --no-deps"; fi
    if has_arg "--skip-ubuntu-upgrade"; then pass "forces --skip-ubuntu-upgrade in local sandbox"; else fail "missing --skip-ubuntu-upgrade"; fi

    local state_file="$home_dir/.acfs/state/macos_bootstrap.env"
    if [[ -f "$state_file" ]] && grep -q '^STAGE=complete$' "$state_file"; then
        pass "writes host bootstrap state with complete stage"
    else
        fail "missing or incomplete host bootstrap state file"
    fi

    local event_log
    event_log="$(ls -1 "$home_dir/.acfs/logs/install/"*.jsonl 2>/dev/null | head -n1 || true)"
    if [[ -n "$event_log" ]] && grep -q '"event":"install_start"' "$event_log" && grep -q '"event":"install_end"' "$event_log"; then
        pass "writes host observability install_start/install_end events"
    else
        fail "missing host observability install lifecycle events"
    fi
}

run_case_two() {
    echo "=== Case 2: Invalid VM env values fall back to defaults ==="
    local case_root
    case_root="$(mktemp -d "${TMPDIR:-/tmp}/acfs-macos-bootstrap-case2.XXXXXX")"
    local setup
    setup="$(setup_mock_case "$case_root")"
    local mock_bin="${setup%%|*}"
    local rest="${setup#*|}"
    local log_file="${rest%%|*}"
    rest="${rest#*|}"
    local vm_exists_file="${rest%%|*}"
    local home_dir="${rest##*|}"

    mkdir -p "$case_root/workspace"

    PATH="$mock_bin:$PATH" \
    HOME="$home_dir" \
    MOCK_MULTIPASS_LOG="$log_file" \
    MOCK_MULTIPASS_VM_EXISTS_FILE="$vm_exists_file" \
    ACFS_MACOS_VM_NAME="acfs-ci-vm" \
    ACFS_MACOS_VM_CPUS="oops" \
    ACFS_MACOS_VM_MEM="bad" \
    ACFS_MACOS_VM_DISK="invalid" \
    ACFS_WORKSPACE_HOST="$case_root/workspace" \
    bash -s -- --macos --yes < "$REPO_ROOT/install.sh"

    local launch_line
    launch_line="$(grep -m1 '^CMD:launch ' "$log_file" || true)"
    require_contains "$launch_line" "--name acfs-ci-vm --cpus 4 --memory 8G --disk 40G 24.04" "Invalid VM env values revert to safe defaults"
}

run_case_three_resume_event() {
    echo "=== Case 3: Resume event emitted from host bootstrap state ==="
    local case_root
    case_root="$(mktemp -d "${TMPDIR:-/tmp}/acfs-macos-bootstrap-case3.XXXXXX")"
    local setup
    setup="$(setup_mock_case "$case_root")"
    local mock_bin="${setup%%|*}"
    local rest="${setup#*|}"
    local log_file="${rest%%|*}"
    rest="${rest#*|}"
    local vm_exists_file="${rest%%|*}"
    local home_dir="${rest##*|}"

    mkdir -p "$case_root/workspace"
    mkdir -p "$home_dir/.acfs/state"
    cat > "$home_dir/.acfs/state/macos_bootstrap.env" <<'EOF'
SCHEMA=1
RUN_ID=old-run
STAGE=workspace_mount
VM_NAME=acfs-ci-vm
DETAIL=previous_run
UPDATED_AT=2026-01-01T00:00:00
EOF

    PATH="$mock_bin:$PATH" \
    HOME="$home_dir" \
    MOCK_MULTIPASS_LOG="$log_file" \
    MOCK_MULTIPASS_VM_EXISTS_FILE="$vm_exists_file" \
    ACFS_MACOS_VM_NAME="acfs-ci-vm" \
    ACFS_WORKSPACE_HOST="$case_root/workspace" \
    bash -s -- --macos --yes < "$REPO_ROOT/install.sh"

    local event_log
    event_log="$(ls -1 "$home_dir/.acfs/logs/install/"*.jsonl 2>/dev/null | head -n1 || true)"
    if [[ -n "$event_log" ]] && grep -q '"event":"resume"' "$event_log"; then
        pass "emits resume event when prior host bootstrap state is incomplete"
    else
        fail "missing resume event for prior incomplete host bootstrap state"
    fi
}

main() {
    echo ""
    echo "=== ACFS macOS Bootstrap Tests (mocked) ==="
    run_case_one
    run_case_two
    run_case_three_resume_event
    echo ""
    if [[ "$failures" -gt 0 ]]; then
        echo "macOS bootstrap tests: $failures failure(s)" >&2
        exit 1
    fi
    echo "macOS bootstrap tests: all passed"
}

main "$@"
