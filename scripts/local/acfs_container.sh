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
#   acfs-local dashboard  - Open dashboard in browser
#   acfs-local doctor     - Run acfs doctor inside container
#   acfs-local update     - Run acfs update inside container
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

cmd_create() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    printf "║           ACFS Local Desktop Installation                     ║\n"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""

    install_acfs_local_wrapper

    # Create container
    acfs_sandbox_create

    echo ""
    echo "Container ready. Installing ACFS inside sandbox..."
    echo ""

    # Copy installer and repo files to container via tar pipe
    # This bypasses "Forbidden" errors some LXD setups produce when trying to read host files directly.
    log_detail "Transferring ACFS repo to container..."
    tar -C "$REPO_ROOT" -cf - install.sh scripts acfs acfs.manifest.yaml checksums.yaml 2>/dev/null | \
        acfs_lxc exec "$ACFS_CONTAINER_NAME" -- tar -xf - -C /tmp/

    # Run installer inside container
    # We set ACFS_BOOTSTRAP_DIR=/tmp so install.sh knows where to find its own scripts/lib
    set_terminal_title "ACFS Local: Running Installer..."
    acfs_sandbox_exec_root "
        export DEBIAN_FRONTEND=noninteractive
        export ACFS_CI=true
        export ACFS_BOOTSTRAP_DIR=/tmp
        cd /tmp
        bash /tmp/install.sh --local --yes --mode vibe --skip-ubuntu-upgrade
    "

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
  dashboard   Open dashboard in browser
  doctor      Run acfs doctor inside container
  update      Run acfs update inside container
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
        dashboard)
            cmd_dashboard "$@"
            ;;
        doctor)
            cmd_doctor "$@"
            ;;
        update)
            cmd_update "$@"
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
