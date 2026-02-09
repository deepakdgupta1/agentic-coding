#!/usr/bin/env bash
# ============================================================
# ACFS Local - Desktop Container Manager
#
# User-facing CLI for managing ACFS sandbox container on desktop.
#
# Usage:
#   acfs-local create     - Provision container and run ACFS installer
#   acfs-local shell      - Enter sandbox shell as ubuntu user
#   acfs-local attach     - Alias for shell
#   acfs-local status     - Show container status and access info
#   acfs-local stop       - Stop container
#   acfs-local start      - Start container
#   acfs-local destroy    - Remove container (preserves workspace)
#   acfs-local uninstall  - Remove container + optional cleanup
#   acfs-local dashboard  - Open dashboard in browser
#   acfs-local doctor     - Run acfs doctor inside container
#   acfs-local update     - Run acfs update inside container
#   acfs-local audit      - Dry-run idempotency audit (no changes)
# ============================================================

set -euo pipefail

# Capture original arguments for potential restart (group refresh)
export ACFS_ORIG_ARGS="$*"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source sandbox library
# shellcheck source=scripts/lib/sandbox.sh
source "$REPO_ROOT/scripts/lib/sandbox.sh"

# ============================================================
# Commands
# ============================================================

install_acfs_local_wrapper() {
    local bin_dir="$HOME/.local/bin"
    local wrapper_path="$bin_dir/acfs-local"

    if [[ -x "$wrapper_path" ]]; then
        return 0
    fi

    mkdir -p "$bin_dir"
    cat > "$wrapper_path" <<EOF
#!/usr/bin/env bash
set -euo pipefail

ACFS_LOCAL_REPO="${REPO_ROOT}"

if [[ ! -x "\$ACFS_LOCAL_REPO/scripts/local/acfs_container.sh" ]]; then
  echo "acfs-local: repo not found at \$ACFS_LOCAL_REPO" >&2
  echo "Reinstall from a valid ACFS repo checkout." >&2
  exit 1
fi

exec "\$ACFS_LOCAL_REPO/scripts/local/acfs_container.sh" "\$@"
EOF
    chmod +x "$wrapper_path"

    if ! command -v acfs-local &>/dev/null; then
        echo "Added acfs-local to $wrapper_path (ensure ~/.local/bin is in PATH)"
    fi
}

wait_for_sandbox_ready() {
    if ! acfs_sandbox_running; then
        acfs_sandbox_start || return 1
    fi
    if ! acfs_sandbox_wait_ready 30; then
        log_error "Sandbox container is running but not responding."
        return 1
    fi
    return 0
}

ensure_sandbox_egress() {
    if ! declare -f _acfs_sandbox_container_has_egress &>/dev/null; then
        return 0
    fi
    if _acfs_sandbox_container_has_egress; then
        return 0
    fi
    log_warn "Container egress not detected. Attempting network fix..."
    _acfs_sandbox_fix_container_network || true
    if ! _acfs_sandbox_container_has_egress; then
        log_warn "Container still has no outbound egress. Installer may fail."
    fi
}

transfer_repo_with_retries() {
    local attempts=0
    while [[ $attempts -lt 3 ]]; do
        if tar -C "$REPO_ROOT" -cf - install.sh scripts acfs packages/onboard acfs.manifest.yaml checksums.yaml 2>/dev/null | \
            acfs_lxc exec "$ACFS_CONTAINER_NAME" -- tar -xf - -C /tmp/; then
            return 0
        fi
        attempts=$((attempts + 1))
        log_warn "Repo transfer failed (attempt $attempts/3). Retrying..."
        wait_for_sandbox_ready || true
        sleep 2
    done
    return 1
}

acfs_local_install_healthy() {
    local missing=0

    if ! acfs_sandbox_exec "test -x ~/.local/bin/acfs" >/dev/null 2>&1; then
        missing=1
    fi
    if ! acfs_sandbox_exec_root "test -x /usr/local/bin/acfs" >/dev/null 2>&1; then
        missing=1
    fi
    if ! acfs_sandbox_exec "test -f ~/.acfs/scripts/lib/dashboard.sh" >/dev/null 2>&1; then
        missing=1
    fi
    if ! acfs_sandbox_exec "test -x ~/.local/bin/onboard" >/dev/null 2>&1; then
        missing=1
    fi

    if [[ $missing -eq 1 ]]; then
        return 1
    fi
    return 0
}

cmd_audit() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    printf "║              ACFS Local Idempotency Audit                     ║\n"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""

    local issues=0

    if ! command -v lxc &>/dev/null; then
        log_warn "LXD not installed. Would install and initialize LXD."
        issues=$((issues + 1))
    else
        if ! acfs_lxc info >/dev/null 2>&1; then
            log_warn "LXD not initialized or permission denied. Would init and refresh group."
            issues=$((issues + 1))
        fi
    fi

    local pool="${ACFS_LXD_STORAGE_POOL:-default}"
    if command -v lxc &>/dev/null; then
        if _acfs_sudo_lxc storage show "$pool" >/dev/null 2>&1; then
            local status
            status="$(_acfs_sudo_lxc storage show "$pool" 2>/dev/null | awk -F': ' '/^status:/{print $2; exit}' || true)"
            if [[ "$status" == "Unavailable" ]]; then
                log_warn "LXD storage pool '$pool' unavailable. Would repair or recreate."
                issues=$((issues + 1))
            fi
        else
            log_warn "LXD storage pool '$pool' missing. Would create it."
            issues=$((issues + 1))
        fi

        if ! _acfs_sudo_lxc profile device show default 2>/dev/null | grep -q '^root:'; then
            log_warn "Default profile root device missing. Would add root disk device."
            issues=$((issues + 1))
        fi
    fi

    if [[ -e "$ACFS_WORKSPACE_HOST" && ! -d "$ACFS_WORKSPACE_HOST" ]]; then
        log_warn "Workspace path '$ACFS_WORKSPACE_HOST' is not a directory. Would choose fallback."
        issues=$((issues + 1))
    elif [[ ! -d "$ACFS_WORKSPACE_HOST" ]]; then
        log_warn "Workspace path '$ACFS_WORKSPACE_HOST' does not exist. Would create it."
        issues=$((issues + 1))
    elif [[ ! -w "$ACFS_WORKSPACE_HOST" ]]; then
        log_warn "Workspace path '$ACFS_WORKSPACE_HOST' is not writable. Would fix or choose fallback."
        issues=$((issues + 1))
    fi

    if command -v lxc &>/dev/null; then
        if _acfs_sudo_lxc profile show "$ACFS_PROFILE_NAME" >/dev/null 2>&1; then
            if ! _lxc_profile_has_device "$ACFS_PROFILE_NAME" workspace; then
                log_warn "Profile workspace device missing. Would add it."
                issues=$((issues + 1))
            fi
            if ! _lxc_profile_has_device "$ACFS_PROFILE_NAME" dashboard-proxy; then
                log_warn "Profile dashboard proxy missing. Would add it."
                issues=$((issues + 1))
            fi
        else
            log_warn "LXD profile '$ACFS_PROFILE_NAME' missing. Would create it."
            issues=$((issues + 1))
        fi
    fi

    if command -v lxc &>/dev/null; then
        if ! acfs_sandbox_exists; then
            log_warn "Sandbox container '$ACFS_CONTAINER_NAME' missing. Would create it."
            issues=$((issues + 1))
        else
            if ! acfs_sandbox_running; then
                log_warn "Sandbox container '$ACFS_CONTAINER_NAME' stopped. Would start it."
                issues=$((issues + 1))
            fi
            if ! _acfs_sandbox_container_has_workspace_device; then
                log_warn "Sandbox workspace device missing. Would attach it."
                issues=$((issues + 1))
            fi

            if acfs_sandbox_running; then
                if ! acfs_sandbox_wait_ready 10; then
                    log_warn "Sandbox container not responding to exec. Would restart."
                    issues=$((issues + 1))
                else
                    if ! _acfs_sandbox_container_workspace_mounted; then
                        log_warn "Workspace mount not present in container. Would restart to apply mount."
                        issues=$((issues + 1))
                    fi
                    if ! _acfs_sandbox_container_has_egress; then
                        log_warn "Container egress not detected. Would add macvlan NIC."
                        issues=$((issues + 1))
                    fi

                    local missing=0
                    if ! acfs_lxc exec "$ACFS_CONTAINER_NAME" -- sudo -u ubuntu bash -c 'test -x ~/.local/bin/acfs' >/dev/null 2>&1; then
                        missing=1
                    fi
                    if ! acfs_lxc exec "$ACFS_CONTAINER_NAME" -- sudo -u ubuntu bash -c 'test -x ~/.local/bin/onboard' >/dev/null 2>&1; then
                        missing=1
                    fi
                    if ! acfs_lxc exec "$ACFS_CONTAINER_NAME" -- sudo -u ubuntu bash -c 'test -f ~/.acfs/scripts/lib/dashboard.sh' >/dev/null 2>&1; then
                        missing=1
                    fi
                    if ! acfs_lxc exec "$ACFS_CONTAINER_NAME" -- bash -c 'test -x /usr/local/bin/acfs' >/dev/null 2>&1; then
                        missing=1
                    fi
                    if [[ $missing -eq 1 ]]; then
                        log_warn "In-VM install drift detected. Would re-run installer."
                        issues=$((issues + 1))
                    fi
                fi
            else
                log_warn "Skipping in-VM audit; container not running."
            fi
        fi
    fi

    if [[ $issues -eq 0 ]]; then
        log_success "Idempotency audit: no issues detected."
    else
        log_warn "Idempotency audit: $issues issue(s) detected."
    fi

    return $issues
}

cmd_create() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    printf "║           ACFS Local Desktop Installation                     ║\n"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""

    install_acfs_local_wrapper

    # Create container
    acfs_sandbox_create
    if ! wait_for_sandbox_ready; then
        return 1
    fi
    ensure_sandbox_egress

    echo ""
    echo "Container ready. Installing ACFS inside sandbox..."
    echo ""

    local needs_install=true
    if acfs_local_install_healthy; then
        log_info "ACFS already installed in sandbox. Skipping reinstall."
        needs_install=false
    fi

    if [[ "$needs_install" == "true" ]]; then
        # Copy installer and repo files to container via tar pipe
        # This bypasses "Forbidden" errors some LXD setups produce when trying to read host files directly.
        log_detail "Transferring ACFS repo to container..."
        if ! transfer_repo_with_retries; then
            log_error "Failed to transfer ACFS repo to container"
            return 1
        fi

        # Verify critical bootstrap files exist in container
        if ! acfs_lxc exec "$ACFS_CONTAINER_NAME" -- test -f /tmp/scripts/acfs-global 2>/dev/null; then
            log_error "Bootstrap verification failed: scripts/acfs-global not in container"
            return 1
        fi
        if ! acfs_lxc exec "$ACFS_CONTAINER_NAME" -- test -f /tmp/packages/onboard/onboard.sh 2>/dev/null; then
            log_error "Bootstrap verification failed: packages/onboard/onboard.sh not in container"
            return 1
        fi

        # Run installer inside container
        # We set ACFS_BOOTSTRAP_DIR=/tmp so install.sh knows where to find its own scripts/lib
        set_terminal_title "ACFS Local: Running Installer..."
        if ! acfs_sandbox_exec_root "
            export DEBIAN_FRONTEND=noninteractive
            export ACFS_CI=true
            export ACFS_BOOTSTRAP_DIR=/tmp
            cd /tmp
            bash /tmp/install.sh --local --yes --mode vibe --skip-ubuntu-upgrade
        "; then
            log_warn "Installer failed. Checking network and retrying once..."
            ensure_sandbox_egress
            if ! acfs_sandbox_exec_root "
                export DEBIAN_FRONTEND=noninteractive
                export ACFS_CI=true
                export ACFS_BOOTSTRAP_DIR=/tmp
                cd /tmp
                bash /tmp/install.sh --local --yes --mode vibe --skip-ubuntu-upgrade
            "; then
                log_error "Installer failed inside container. Review logs and retry."
                return 1
            fi
        fi
    fi

    # Post-install verification
    log_info "Verifying installation..."
    local verification_warnings=0

    # Check user-local acfs command
    if ! acfs_sandbox_exec "test -x ~/.local/bin/acfs" 2>/dev/null; then
        log_warn "User acfs command not found at ~/.local/bin/acfs"
        verification_warnings=1
    fi

    # Check global wrapper
    if ! acfs_sandbox_exec_root "test -x /usr/local/bin/acfs" 2>/dev/null; then
        log_warn "Global acfs wrapper not found at /usr/local/bin/acfs"
        verification_warnings=1
    fi

    # Check critical library scripts
    if ! acfs_sandbox_exec "test -f ~/.acfs/scripts/lib/dashboard.sh" 2>/dev/null; then
        log_warn "dashboard.sh not found in ~/.acfs/scripts/lib/"
        verification_warnings=1
    fi

    if [[ $verification_warnings -eq 1 ]]; then
        log_warn "Some ACFS components may not have installed correctly"
        log_info "Run 'acfs-local shell' then 'acfs doctor' to diagnose"
    fi

    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                    Installation Complete!                     ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║                                                               ║"
    echo "║  Enter sandbox:     acfs-local shell                          ║"
    echo "║  View status:       acfs-local status                         ║"
    echo "║  Open dashboard:    acfs-local dashboard                      ║"
    echo "║                                                               ║"
    printf "║  Your workspace:    %-41s ║\n" "$ACFS_WORKSPACE_HOST"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
}

cmd_shell() {
    grant_acfs_sandbox_access
    if ! acfs_sandbox_exists; then
        echo "Container not found. Create it first:"
        echo "  acfs-local create"
        exit 1
    fi

    if ! acfs_sandbox_running; then
        echo "Starting container..."
        acfs_sandbox_start
    fi

    echo "Entering ACFS sandbox (type 'exit' to leave)..."
    echo ""
    acfs_sandbox_exec
}

cmd_status() {
    echo ""
    echo "═══ ACFS Local Status ═══"
    echo ""
    acfs_sandbox_status
    echo ""
}

cmd_start() {
    acfs_sandbox_start
}

cmd_stop() {
    acfs_sandbox_stop
}

cmd_destroy() {
    acfs_sandbox_destroy "$@"
}

cmd_uninstall() {
    local yes=false
    local purge_workspace=false
    local remove_wrapper=false
    local delete_lxd_pool=""
    local delete_zfs_pool=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|-y)
                yes=true
                ;;
            --purge-workspace)
                purge_workspace=true
                ;;
            --remove-wrapper)
                remove_wrapper=true
                ;;
            --delete-lxd-pool)
                shift
                delete_lxd_pool="${1:-}"
                ;;
            --delete-zfs-pool)
                shift
                delete_zfs_pool="${1:-}"
                ;;
            --help|-h)
                cat <<'EOF'
Usage: acfs-local uninstall [options]

Options:
  --yes, -y            Skip confirmation prompt
  --purge-workspace    Delete workspace directory on host
  --remove-wrapper     Remove ~/.local/bin/acfs-local
  --delete-lxd-pool    Delete an LXD storage pool (name required)
  --delete-zfs-pool    Destroy a ZFS pool (name required)
EOF
                return 0
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done

    if [[ "$yes" != "true" ]]; then
        if [[ -t 0 ]]; then
            echo ""
            echo "This will remove the ACFS container and profile."
            if [[ "$purge_workspace" == "true" ]]; then
                echo "Workspace WILL be deleted: $ACFS_WORKSPACE_HOST"
            else
                echo "Workspace will be preserved: $ACFS_WORKSPACE_HOST"
            fi
            if [[ -n "$delete_lxd_pool" ]]; then
                echo "LXD storage pool WILL be deleted: $delete_lxd_pool"
            fi
            if [[ -n "$delete_zfs_pool" ]]; then
                echo "ZFS pool WILL be destroyed: $delete_zfs_pool"
            fi
            echo ""
            read -r -p "Type 'uninstall' to confirm: " confirm
            if [[ "$confirm" != "uninstall" ]]; then
                echo "Cancelled"
                return 1
            fi
        else
            echo "Non-interactive shell. Re-run with --yes to proceed."
            return 1
        fi
    fi

    if acfs_sandbox_exists; then
        acfs_sandbox_destroy true || true
    else
        echo "Container not found. Skipping container removal."
    fi

    if [[ "$remove_wrapper" == "true" ]]; then
        rm -f "$HOME/.local/bin/acfs-local"
    fi

    if [[ "$purge_workspace" == "true" ]]; then
        if [[ -z "${ACFS_WORKSPACE_HOST:-}" || "$ACFS_WORKSPACE_HOST" == "/" ]]; then
            echo "Refusing to delete workspace: invalid path '$ACFS_WORKSPACE_HOST'"
        else
            rm -rf "$ACFS_WORKSPACE_HOST"
        fi
    fi

    if [[ -n "$delete_lxd_pool" ]]; then
        acfs_lxc storage delete "$delete_lxd_pool" 2>/dev/null || true
    fi

    if [[ -n "$delete_zfs_pool" ]]; then
        if command -v zpool &>/dev/null; then
            acfs_sudo zpool destroy "$delete_zfs_pool" || true
        else
            echo "zpool not found; cannot destroy ZFS pool '$delete_zfs_pool'"
        fi
    fi

    echo "Uninstall complete."
}

cmd_dashboard() {
    grant_acfs_sandbox_access
    if ! acfs_sandbox_running; then
        echo "Container not running. Start it first:"
        echo "  acfs-local start"
        exit 1
    fi

    local url="http://localhost:$ACFS_DASHBOARD_PORT"
    echo "Opening ACFS dashboard: $url"

    # Try various browser openers
    if command -v xdg-open &>/dev/null; then
        xdg-open "$url" 2>/dev/null &
    elif command -v open &>/dev/null; then
        open "$url" 2>/dev/null &
    else
        echo "Could not open browser. Visit: $url"
    fi
}

cmd_doctor() {
    grant_acfs_sandbox_access
    if ! acfs_sandbox_running; then
        echo "Container not running. Start it first:"
        echo "  acfs-local start"
        exit 1
    fi

    echo "Running acfs doctor inside container..."
    echo ""
    acfs_sandbox_exec "acfs doctor"
}

cmd_update() {
    grant_acfs_sandbox_access
    if ! acfs_sandbox_running; then
        echo "Container not running. Start it first:"
        echo "  acfs-local start"
        exit 1
    fi

    echo "Running acfs update inside container..."
    echo ""
    acfs_sandbox_exec "acfs update $*"
}

cmd_help() {
    cat <<'EOF'
ACFS Local - Desktop Container Manager

Usage: acfs-local <command> [options]

Commands:
  create      Provision container and install ACFS
  shell       Enter sandbox shell as ubuntu user
  attach      Alias for shell
  status      Show container status and access info
  start       Start the container
  stop        Stop the container
  destroy     Remove container (preserves workspace)
  uninstall   Remove container + optional cleanup
  dashboard   Open dashboard in browser
  doctor      Run acfs doctor inside container
  update      Run acfs update inside container
  audit       Dry-run idempotency audit (no changes)
  help        Show this help

Environment Variables:
  ACFS_CONTAINER_NAME     Container name (default: acfs-local)
  ACFS_WORKSPACE_HOST     Host workspace path (default: ~/acfs-workspace)
  ACFS_DASHBOARD_PORT     Dashboard port (default: 38080)

Examples:
  acfs-local create           # Fresh install
  acfs-local shell            # Enter sandbox
  acfs-local doctor           # Health check
  acfs-local destroy --force  # Remove without confirmation
  acfs-local uninstall --yes --purge-workspace --remove-wrapper
  acfs-local audit            # Idempotency audit
EOF
}

# ============================================================
# Main
# ============================================================

main() {
    local cmd="${1:-help}"
    shift || true

    case "$cmd" in
        create)
            cmd_create "$@"
            ;;
        shell|attach)
            cmd_shell "$@"
            ;;
        status)
            cmd_status "$@"
            ;;
        start)
            cmd_start "$@"
            ;;
        stop)
            cmd_stop "$@"
            ;;
        destroy)
            cmd_destroy "$@"
            ;;
        uninstall)
            cmd_uninstall "$@"
            ;;
        dashboard)
            cmd_dashboard "$@"
            ;;
        doctor)
            cmd_doctor "$@"
            ;;
        update)
            cmd_update "$@"
            ;;
        audit)
            cmd_audit "$@"
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            echo "Unknown command: $cmd"
            echo ""
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
