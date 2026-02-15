#!/usr/bin/env bash
# ============================================================
# ACFS Local - macOS Multipass Bootstrap
#
# Host-side bootstrap for macOS local mode.
# Handles Multipass lifecycle, workspace mount, and in-VM installer handoff.
# ============================================================

set -euo pipefail

# ============================================================
# Config
# ============================================================
YES_MODE="${YES_MODE:-false}"
IDEMPOTENCY_AUDIT="${IDEMPOTENCY_AUDIT:-false}"
MODE="${MODE:-vibe}"
ACFS_RAW="${ACFS_RAW:-https://raw.githubusercontent.com/deepakdgupta1/agentic-coding/main}"
ACFS_INSTALL_SCRIPT_DIR="${ACFS_INSTALL_SCRIPT_DIR:-}"
ACFS_LOCAL_INSTALL_ARGS_B64="${ACFS_LOCAL_INSTALL_ARGS_B64:-}"

VM_NAME="${ACFS_MACOS_VM_NAME:-acfs-host}"
VM_CPUS="${ACFS_MACOS_VM_CPUS:-4}"
VM_MEM="${ACFS_MACOS_VM_MEM:-8G}"
VM_DISK="${ACFS_MACOS_VM_DISK:-40G}"

ACFS_HOST_HOME="${ACFS_HOST_HOME:-$HOME/.acfs}"
ACFS_MACOS_STATE_DIR="${ACFS_MACOS_STATE_DIR:-$ACFS_HOST_HOME/state}"
ACFS_MACOS_STATE_FILE="${ACFS_MACOS_STATE_FILE:-$ACFS_MACOS_STATE_DIR/macos_bootstrap.env}"
ACFS_RUN_ID="${ACFS_RUN_ID:-$(date +%Y%m%d_%H%M%S)_$$}"
ACFS_EVENT_LOG="${ACFS_EVENT_LOG:-$ACFS_HOST_HOME/logs/install/${ACFS_RUN_ID}.jsonl}"

# ============================================================
# Logging
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { printf "%b\n" "$*" >&2; }
log_step() { printf "[%s] %s\n" "$1" "$2" >&2; }
log_warn() { printf "⚠ %b\n" "$*" >&2; }
log_error() { printf "✖ %b\n" "$*" >&2; }
log_success() { printf "✓ %b\n" "$*" >&2; }
log_fatal() { log_error "$*"; exit 1; }

# ============================================================
# Observability (host-side, same event model)
# ============================================================
ensure_observability_paths() {
    mkdir -p "$(dirname "$ACFS_EVENT_LOG")" 2>/dev/null || true
    mkdir -p "$ACFS_MACOS_STATE_DIR" 2>/dev/null || true
}

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

emit_event() {
    local event_type="${1:-unknown}"
    local stage="${2:-}"
    shift 2 2>/dev/null || true

    ensure_observability_paths

    local ts
    ts="$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)"
    local json="{\"run_id\":\"$(json_escape "$ACFS_RUN_ID")\",\"event\":\"$(json_escape "$event_type")\",\"stage\":\"$(json_escape "$stage")\",\"ts\":\"$(json_escape "$ts")\""
    local kv=""
    local k=""
    local v=""
    for kv in "$@"; do
        k="${kv%%=*}"
        v="${kv#*=}"
        json+=",\"$(json_escape "$k")\":\"$(json_escape "$v")\""
    done
    json+="}"

    printf '%s\n' "$json" >> "$ACFS_EVENT_LOG" 2>/dev/null || true
}

# ============================================================
# Host bootstrap state (resumability marker)
# ============================================================
state_get_field() {
    local key="$1"
    [[ -f "$ACFS_MACOS_STATE_FILE" ]] || return 1
    grep -E "^${key}=" "$ACFS_MACOS_STATE_FILE" 2>/dev/null | head -n1 | cut -d'=' -f2-
}

state_set() {
    local stage="$1"
    local detail="${2:-}"
    ensure_observability_paths
    cat > "$ACFS_MACOS_STATE_FILE" <<EOF
SCHEMA=1
RUN_ID=$ACFS_RUN_ID
STAGE=$stage
VM_NAME=$VM_NAME
DETAIL=$detail
UPDATED_AT=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)
EOF
}

state_resume_if_needed() {
    local previous_stage=""
    previous_stage="$(state_get_field STAGE 2>/dev/null || true)"
    if [[ -n "$previous_stage" && "$previous_stage" != "complete" ]]; then
        log_info "Resuming macOS host bootstrap from stage: $previous_stage"
        emit_event "resume" "macos_host" "state_stage=$previous_stage" "state_file=$ACFS_MACOS_STATE_FILE"
    fi
}

# ============================================================
# Arg forwarding for in-VM install
# ============================================================
decode_forwarded_install_args() {
    local -n _out="$1"
    local payload="${ACFS_LOCAL_INSTALL_ARGS_B64:-}"
    local decoded=""
    local item=""

    _out=()
    [[ -n "$payload" ]] || return 1

    if decoded="$(printf '%s' "$payload" | base64 --decode 2>/dev/null)"; then
        :
    elif decoded="$(printf '%s' "$payload" | base64 -d 2>/dev/null)"; then
        :
    else
        return 1
    fi

    while IFS= read -r -d $'\x1f' item; do
        [[ -n "$item" ]] || continue
        _out+=("$item")
    done < <(printf '%s' "$decoded")

    [[ ${#_out[@]} -gt 0 ]]
}

shell_escape_args() {
    local out=""
    local arg=""
    local q=""
    for arg in "$@"; do
        printf -v q '%q' "$arg"
        [[ -n "$out" ]] && out+=" "
        out+="$q"
    done
    printf '%s' "$out"
}

build_inner_install_args() {
    local -n _out="$1"
    local -a decoded_args=()
    _out=(--local --yes --mode "${MODE:-vibe}" --skip-ubuntu-upgrade)
    if decode_forwarded_install_args decoded_args; then
        _out=("${decoded_args[@]}")
        local has_local=false
        local has_yes=false
        local has_skip_upgrade=false
        local idx=0
        for ((idx = 0; idx < ${#_out[@]}; idx++)); do
            case "${_out[$idx]}" in
                --local|--desktop) has_local=true ;;
                --yes|-y) has_yes=true ;;
                --skip-ubuntu-upgrade) has_skip_upgrade=true ;;
            esac
        done
        [[ "$has_local" == "true" ]] || _out=(--local "${_out[@]}")
        [[ "$has_yes" == "true" ]] || _out=(--yes "${_out[@]}")
        [[ "$has_skip_upgrade" == "true" ]] || _out+=(--skip-ubuntu-upgrade)
    fi
}

# ============================================================
# Multipass helpers
# ============================================================
multipass_supports_wait_ready() {
    multipass help wait-ready >/dev/null 2>&1
}

multipass_wait_ready() {
    local timeout="${1:-120}"
    local attempts=0
    if multipass_supports_wait_ready; then
        while [[ $attempts -lt 3 ]]; do
            if multipass wait-ready --timeout "$timeout" >/dev/null 2>&1; then
                return 0
            fi
            attempts=$((attempts + 1))
            sleep 2
        done
        return 1
    fi

    attempts=0
    while [[ $attempts -lt 5 ]]; do
        if multipass version >/dev/null 2>&1; then
            return 0
        fi
        attempts=$((attempts + 1))
        sleep 2
    done
    return 1
}

multipass_get_state() {
    local vm="$1"
    multipass info "$vm" 2>/dev/null | awk -F': ' '/^State:/{print $2; exit}' || true
}

multipass_ensure_vm_running() {
    local vm="$1"
    local state
    state="$(multipass_get_state "$vm")"
    if [[ "$state" == "Running" ]]; then
        return 0
    fi
    if [[ "$state" == "Stopped" || "$state" == "Suspended" ]]; then
        multipass start "$vm" >/dev/null 2>&1 && return 0
    fi
    multipass restart "$vm" >/dev/null 2>&1 && return 0
    multipass start "$vm" >/dev/null 2>&1 && return 0
    return 1
}

multipass_wait_for_exec() {
    local vm="$1"
    local retry=0
    while ! multipass exec "$vm" -- true >/dev/null 2>&1; do
        retry=$((retry + 1))
        if [[ $retry -eq 8 ]]; then
            log_warn "VM '$vm' not responding yet. Attempting restart..."
            multipass_ensure_vm_running "$vm" || true
        fi
        [[ $retry -gt 30 ]] && return 1
        sleep 2
    done
    return 0
}

multipass_mount_workspace() {
    local vm="$1"
    local host_path="$2"
    local target="acfs-workspace"

    if multipass exec "$vm" -- bash -c 'if command -v mountpoint >/dev/null 2>&1; then mountpoint -q /home/ubuntu/acfs-workspace; else grep -q " /home/ubuntu/acfs-workspace " /proc/mounts; fi' >/dev/null 2>&1; then
        return 0
    fi
    if multipass mount "$host_path" "$vm:$target" >/dev/null 2>&1; then
        if multipass exec "$vm" -- test -d "/home/ubuntu/$target" >/dev/null 2>&1; then
            return 0
        fi
    fi

    log_warn "Workspace mount failed. Retrying after unmount..."
    multipass umount "$vm:$target" >/dev/null 2>&1 || true
    multipass umount "$vm:/home/ubuntu/$target" >/dev/null 2>&1 || true
    sleep 1

    if multipass mount "$host_path" "$vm:$target" >/dev/null 2>&1; then
        if multipass exec "$vm" -- test -d "/home/ubuntu/$target" >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

multipass_exec_retry() {
    local vm="$1"
    local cmd="$2"
    local attempts=0
    while [[ $attempts -lt 3 ]]; do
        if multipass exec "$vm" -- bash -c "$cmd"; then
            return 0
        fi
        attempts=$((attempts + 1))
        log_warn "Command failed in VM (attempt $attempts/3). Retrying..."
        multipass_ensure_vm_running "$vm" || true
        sleep 2
    done
    return 1
}

# ============================================================
# Audit mode
# ============================================================
run_audit() {
    local issues=0
    log_step "VM" "Idempotency audit (macOS Multipass)..."
    emit_event "stage_start" "macos_audit"

    if ! command -v multipass &>/dev/null; then
        log_warn "Multipass not installed. Would install via Homebrew."
        issues=$((issues + 1))
    else
        if ! multipass_wait_ready 30; then
            log_warn "Multipass daemon not ready. Would retry and prompt restart."
            issues=$((issues + 1))
        fi

        local workspace_host="${ACFS_WORKSPACE_HOST:-$HOME/acfs-workspace}"
        if [[ -e "$workspace_host" && ! -d "$workspace_host" ]]; then
            log_warn "Workspace path '$workspace_host' is not a directory."
            issues=$((issues + 1))
        elif [[ ! -d "$workspace_host" ]]; then
            log_warn "Workspace path '$workspace_host' does not exist."
            issues=$((issues + 1))
        elif [[ ! -w "$workspace_host" ]]; then
            log_warn "Workspace path '$workspace_host' is not writable."
            issues=$((issues + 1))
        fi

        if multipass list 2>/dev/null | awk '{print $1}' | grep -qx "$VM_NAME"; then
            local state
            state="$(multipass_get_state "$VM_NAME" || true)"
            if [[ -z "$state" ]]; then
                log_warn "Unable to read VM state."
                issues=$((issues + 1))
            elif [[ "$state" != "Running" ]]; then
                log_warn "VM '$VM_NAME' is $state."
                issues=$((issues + 1))
            else
                if ! multipass exec "$VM_NAME" -- true >/dev/null 2>&1; then
                    log_warn "VM '$VM_NAME' not responding to exec."
                    issues=$((issues + 1))
                else
                    if ! multipass exec "$VM_NAME" -- bash -c 'if command -v mountpoint >/dev/null 2>&1; then mountpoint -q /home/ubuntu/acfs-workspace; else grep -q " /home/ubuntu/acfs-workspace " /proc/mounts; fi' >/dev/null 2>&1; then
                        log_warn "Workspace mount missing in VM."
                        issues=$((issues + 1))
                    fi
                    if multipass exec "$VM_NAME" -- bash -c 'command -v acfs-local >/dev/null 2>&1'; then
                        if ! multipass exec "$VM_NAME" -- bash -c 'acfs-local audit' >/dev/null 2>&1; then
                            log_warn "In-VM audit reported issues."
                            issues=$((issues + 1))
                        fi
                    else
                        log_warn "acfs-local not found inside VM; in-VM audit skipped."
                    fi
                fi
            fi
        else
            log_warn "VM '$VM_NAME' not found."
            issues=$((issues + 1))
        fi
    fi

    if [[ $issues -eq 0 ]]; then
        log_success "Idempotency audit: no issues detected."
        emit_event "stage_end" "macos_audit" "status=success"
        emit_event "install_end" "macos_host" "status=success" "mode=audit"
        return 0
    fi

    log_warn "Idempotency audit: $issues issue(s) detected."
    emit_event "stage_end" "macos_audit" "status=failed" "issues=$issues"
    emit_event "install_end" "macos_host" "status=failed" "mode=audit" "issues=$issues"
    return "$issues"
}

# ============================================================
# Main bootstrap
# ============================================================
main() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        log_fatal "macOS bootstrap script must run on Darwin hosts."
    fi

    ensure_observability_paths
    state_resume_if_needed
    emit_event "install_start" "macos_host" "mode=${MODE:-unknown}" "vm_name=$VM_NAME"
    state_set "start" "bootstrap_begin"

    if [[ "$IDEMPOTENCY_AUDIT" == "true" ]]; then
        run_audit
        return $?
    fi

    state_set "multipass_check" "ensure_multipass"
    emit_event "stage_start" "multipass_check"
    if ! command -v multipass &>/dev/null; then
        log_warn "Multipass is required for macOS Local installation."
        if command -v brew &>/dev/null; then
            if [[ "$YES_MODE" == "true" ]]; then
                log_step "VM" "Installing Multipass via Homebrew..."
                if ! brew install --cask multipass; then
                    emit_event "stage_end" "multipass_check" "status=failed" "reason=brew_install_failed"
                    state_set "error" "multipass_install_failed"
                    emit_event "install_end" "macos_host" "status=failed" "reason=multipass_install_failed"
                    log_fatal "Failed to install Multipass via Homebrew."
                fi
            else
                printf "  Install Multipass via Homebrew now? [Y/n]: "
                read -r install_choice
                if [[ "$install_choice" =~ ^[Nn] ]]; then
                    emit_event "stage_end" "multipass_check" "status=failed" "reason=user_declined_install"
                    state_set "error" "user_declined_multipass_install"
                    emit_event "install_end" "macos_host" "status=failed" "reason=user_declined_multipass_install"
                    log_fatal "Please install Multipass and re-run this installer."
                fi
                if ! brew install --cask multipass; then
                    emit_event "stage_end" "multipass_check" "status=failed" "reason=brew_install_failed"
                    state_set "error" "multipass_install_failed"
                    emit_event "install_end" "macos_host" "status=failed" "reason=multipass_install_failed"
                    log_fatal "Failed to install Multipass via Homebrew."
                fi
            fi
        else
            emit_event "stage_end" "multipass_check" "status=failed" "reason=brew_missing"
            state_set "error" "brew_missing"
            emit_event "install_end" "macos_host" "status=failed" "reason=brew_missing"
            log_fatal "Homebrew not found. Install Multipass manually (brew install --cask multipass)."
        fi
    fi
    emit_event "stage_end" "multipass_check" "status=success"

    state_set "daemon_ready" "multipass_wait_ready"
    emit_event "stage_start" "daemon_ready"
    if ! multipass_wait_ready 120; then
        emit_event "stage_end" "daemon_ready" "status=failed" "reason=daemon_not_ready"
        state_set "error" "daemon_not_ready"
        emit_event "install_end" "macos_host" "status=failed" "reason=daemon_not_ready"
        log_fatal "Multipass daemon did not become ready. Please restart Multipass and try again."
    fi
    emit_event "stage_end" "daemon_ready" "status=success"

    if [[ "$YES_MODE" == "false" ]]; then
        echo ""
        echo "─── macOS Local VM Configuration ───"
        printf "  VM Instance Name [%s]: " "$VM_NAME"
        read -r input && [[ -n "$input" ]] && VM_NAME="$input"
        printf "  CPU Cores [%s]: " "$VM_CPUS"
        read -r input && [[ -n "$input" ]] && VM_CPUS="$input"
        printf "  Memory (e.g. 8G) [%s]: " "$VM_MEM"
        read -r input && [[ -n "$input" ]] && VM_MEM="$input"
        printf "  Disk Size (e.g. 40G) [%s]: " "$VM_DISK"
        read -r input && [[ -n "$input" ]] && VM_DISK="$input"
        echo ""
    fi

    if [[ ! "$VM_CPUS" =~ ^[0-9]+$ ]] || [[ "$VM_CPUS" -lt 1 ]]; then
        log_warn "Invalid CPU value '$VM_CPUS'. Using default: 4"
        VM_CPUS="4"
    fi
    if [[ ! "$VM_MEM" =~ ^[0-9]+[GM]$ ]]; then
        log_warn "Invalid memory value '$VM_MEM'. Using default: 8G"
        VM_MEM="8G"
    fi
    if [[ ! "$VM_DISK" =~ ^[0-9]+[GM]$ ]]; then
        log_warn "Invalid disk value '$VM_DISK'. Using default: 40G"
        VM_DISK="40G"
    fi

    state_set "workspace_prepare" "workspace_validation"
    emit_event "stage_start" "workspace_prepare"
    log_step "VM" "Checking workspace availability..."
    local workspace_host="${ACFS_WORKSPACE_HOST:-$HOME/acfs-workspace}"
    if [[ -e "$workspace_host" && ! -d "$workspace_host" ]]; then
        local fallback
        fallback="$HOME/acfs-workspace-$(date +%Y%m%d-%H%M%S)"
        log_warn "Workspace path '$workspace_host' is not a directory. Using '$fallback' instead."
        workspace_host="$fallback"
    fi
    mkdir -p "$workspace_host"
    if [[ ! -w "$workspace_host" ]]; then
        local fallback
        fallback="$HOME/acfs-workspace-$(date +%Y%m%d-%H%M%S)"
        log_warn "Workspace path '$workspace_host' is not writable. Using '$fallback' instead."
        workspace_host="$fallback"
        mkdir -p "$workspace_host"
    fi
    ACFS_WORKSPACE_HOST="$workspace_host"
    export ACFS_WORKSPACE_HOST
    emit_event "stage_end" "workspace_prepare" "status=success" "workspace_host=$workspace_host"

    state_set "vm_ready" "ensure_vm_running"
    emit_event "stage_start" "vm_ready" "vm_name=$VM_NAME"
    if multipass list 2>/dev/null | awk '{print $1}' | grep -qx "$VM_NAME"; then
        log_warn "VM '$VM_NAME' already exists."
        if [[ "$YES_MODE" == "false" ]]; then
            printf "  Use existing VM? [Y/n]: "
            read -r use_existing
            if [[ "$use_existing" =~ ^[Nn] ]]; then
                emit_event "stage_end" "vm_ready" "status=failed" "reason=user_declined_existing_vm"
                state_set "error" "user_declined_existing_vm"
                emit_event "install_end" "macos_host" "status=failed" "reason=user_declined_existing_vm"
                log_fatal "Aborting. Choose a different name or delete existing VM: multipass delete $VM_NAME"
            fi
        fi
        if ! multipass_ensure_vm_running "$VM_NAME"; then
            log_warn "Unable to start existing VM '$VM_NAME'."
        fi
    else
        log_step "VM" "Launching Multipass VM: $VM_NAME ($VM_CPUS CPUs, $VM_MEM RAM, $VM_DISK Disk)..."
        if ! multipass launch --name "$VM_NAME" --cpus "$VM_CPUS" --memory "$VM_MEM" --disk "$VM_DISK" 24.04; then
            emit_event "stage_end" "vm_ready" "status=failed" "reason=launch_failed"
            state_set "error" "vm_launch_failed"
            emit_event "install_end" "macos_host" "status=failed" "reason=vm_launch_failed"
            log_fatal "Failed to launch Multipass VM."
        fi
    fi
    emit_event "stage_end" "vm_ready" "status=success"

    state_set "vm_exec_ready" "wait_for_exec"
    emit_event "stage_start" "vm_exec_ready"
    log_step "VM" "Waiting for VM '$VM_NAME' to be reachable..."
    if ! multipass_wait_for_exec "$VM_NAME"; then
        emit_event "stage_end" "vm_exec_ready" "status=failed" "reason=vm_not_reachable"
        state_set "error" "vm_not_reachable"
        emit_event "install_end" "macos_host" "status=failed" "reason=vm_not_reachable"
        log_fatal "VM '$VM_NAME' did not become reachable via SSH after 60 seconds."
    fi
    emit_event "stage_end" "vm_exec_ready" "status=success"

    state_set "workspace_mount" "mount_workspace"
    emit_event "stage_start" "workspace_mount"
    log_step "VM" "Mounting workspace: $workspace_host → /home/ubuntu/acfs-workspace..."
    if ! multipass_mount_workspace "$VM_NAME" "$workspace_host"; then
        log_warn "Workspace mount failed. Continuing without host workspace sharing."
        emit_event "check_failed" "workspace_mount" "type=mount" "status=degraded"
        emit_event "stage_end" "workspace_mount" "status=degraded"
    else
        emit_event "stage_end" "workspace_mount" "status=success"
    fi

    local -a inner_install_args=()
    local inner_install_args_q=""
    build_inner_install_args inner_install_args
    inner_install_args_q="$(shell_escape_args "${inner_install_args[@]}")"

    state_set "install_handoff" "start_in_vm_install"
    emit_event "stage_start" "install_handoff"
    log_step "VM" "Preparing installer inside VM..."
    if [[ -z "${ACFS_INSTALL_SCRIPT_DIR:-}" ]]; then
        log_step "VM" "Running installer inside VM via curl..."
        if ! multipass_exec_retry "$VM_NAME" "ACFS_LOCAL_INSTALL_ARGS_B64='${ACFS_LOCAL_INSTALL_ARGS_B64}' curl -fsSL \"$ACFS_RAW/install.sh\" | bash -s -- ${inner_install_args_q}"; then
            emit_event "stage_end" "install_handoff" "status=failed" "reason=in_vm_install_failed_curl"
            state_set "error" "in_vm_install_failed_curl"
            emit_event "install_end" "macos_host" "status=failed" "reason=in_vm_install_failed_curl"
            log_fatal "Installer failed inside VM. Check network connectivity and retry."
        fi
    else
        log_step "VM" "Transferring local ACFS repo to VM..."
        local tmp_tar="acfs-repo-$(date +%s).tar"
        local tmp_dir
        tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/acfs-transfer.XXXXXX")"
        local tmp_tar_path="$tmp_dir/$tmp_tar"

        (cd "$ACFS_INSTALL_SCRIPT_DIR" && COPYFILE_DISABLE=1 tar -cf "$tmp_tar_path" --exclude=".git" --exclude="node_modules" .)

        if ! multipass transfer "$tmp_tar_path" "$VM_NAME:/home/ubuntu/$tmp_tar"; then
            log_warn "Transfer failed. Retrying..."
            multipass_ensure_vm_running "$VM_NAME" || true
            if ! multipass transfer "$tmp_tar_path" "$VM_NAME:/home/ubuntu/$tmp_tar"; then
                emit_event "stage_end" "install_handoff" "status=failed" "reason=repo_transfer_failed"
                state_set "error" "repo_transfer_failed"
                emit_event "install_end" "macos_host" "status=failed" "reason=repo_transfer_failed"
                log_fatal "Transfer failed after retry. Check VM connectivity and retry."
            fi
        fi

        multipass exec "$VM_NAME" -- rm -rf /home/ubuntu/agentic-coding
        multipass exec "$VM_NAME" -- mkdir -p /home/ubuntu/agentic-coding
        multipass exec "$VM_NAME" -- tar -xf "/home/ubuntu/$tmp_tar" -C /home/ubuntu/agentic-coding
        multipass exec "$VM_NAME" -- rm "/home/ubuntu/$tmp_tar"

        log_step "VM" "Starting ACFS installation inside VM..."
        if ! multipass_exec_retry "$VM_NAME" "cd /home/ubuntu/agentic-coding && ACFS_LOCAL_INSTALL_ARGS_B64='${ACFS_LOCAL_INSTALL_ARGS_B64}' ./install.sh ${inner_install_args_q}"; then
            emit_event "stage_end" "install_handoff" "status=failed" "reason=in_vm_install_failed_local_checkout"
            state_set "error" "in_vm_install_failed_local_checkout"
            emit_event "install_end" "macos_host" "status=failed" "reason=in_vm_install_failed_local_checkout"
            log_fatal "Installer failed inside VM. Review logs inside VM and retry."
        fi
    fi
    emit_event "stage_end" "install_handoff" "status=success"

    state_set "complete" "bootstrap_complete"
    emit_event "install_end" "macos_host" "status=success" "vm_name=$VM_NAME"
    log_success "ACFS installed in macOS host VM: $VM_NAME"
    echo ""
    echo "═════════════════════════════════════════════════════════════════"
    echo "  Your ACFS environment is ready!"
    echo "─────────────────────────────────────────────────────────────────"
    echo "  To enter your ACFS sandbox:"
    echo "    1. Connect to VM:      ${BLUE}multipass shell $VM_NAME${NC}"
    echo "    2. Enter sandbox:      ${BLUE}acfs-local shell${NC}"
    echo ""
    echo "  Your Mac folder ${BLUE}$workspace_host${NC}"
    echo "  is shared as ${BLUE}/data/projects${NC} inside the sandbox."
    echo "═════════════════════════════════════════════════════════════════"
    echo ""
}

main "$@"
