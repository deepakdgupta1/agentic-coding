#!/usr/bin/env bash
# ============================================================
# ACFS Installer - Sandbox Library (LXD)
# Manages LXD system containers for local desktop installations
#
# Provides OS-enforced isolation for invasive ACFS operations.
# ============================================================

set -euo pipefail

# Prevent multiple sourcing
if [[ -n "${_ACFS_SANDBOX_SH_LOADED:-}" ]]; then
    return 0 2>/dev/null || exit 0
fi
_ACFS_SANDBOX_SH_LOADED=1

# ============================================================
# Configuration
# ============================================================
ACFS_CONTAINER_NAME="${ACFS_CONTAINER_NAME:-acfs-local}"
ACFS_CONTAINER_IMAGE="${ACFS_CONTAINER_IMAGE:-ubuntu:24.04}"
ACFS_WORKSPACE_HOST="${ACFS_WORKSPACE_HOST:-$HOME/acfs-workspace}"
ACFS_WORKSPACE_CONTAINER="/data/projects"
ACFS_DASHBOARD_PORT="${ACFS_DASHBOARD_PORT:-38080}"
ACFS_PROFILE_NAME="acfs-local-profile"
# Optional ZFS storage configuration for LXD (host-side)
# If ACFS_LXD_ZFS_DEVICE is set, ACFS will attempt to create/use a ZFS pool.
ACFS_LXD_ZFS_DEVICE="${ACFS_LXD_ZFS_DEVICE:-}"
ACFS_LXD_ZFS_POOL="${ACFS_LXD_ZFS_POOL:-lxd_pool}"
ACFS_LXD_STORAGE_DRIVER="${ACFS_LXD_STORAGE_DRIVER:-dir}"

# ============================================================
# Logging (fallbacks if not sourced from install.sh)
# ============================================================
if ! declare -f log_detail &>/dev/null; then
    log_detail() { echo -e "$1" | sed "s/^/  /" >&2; }
    log_success() { echo -e "$1" | sed "1s/^/✓ /; 1!s/^/  /" >&2; }
    log_warn() { echo -e "$1" | sed "1s/^/⚠ /; 1!s/^/  /" >&2; }
    log_error() { echo -e "$1" | sed "1s/^/✖ /; 1!s/^/  /" >&2; }
    log_fatal() { log_error "$1"; exit 1; }
    log_step() { printf "[%s] %s\n" "$1" "$2" >&2; }
fi

if ! declare -f set_terminal_title &>/dev/null; then
    set_terminal_title() {
        if [[ "${ACFS_CI:-false}" != "true" ]] && [[ -t 2 ]]; then
            printf "\033]0;%s\007" "$1" >&2
        fi
    }
fi

# ============================================================
# Sudo helper (supports non-interactive runs)
# ============================================================
ACFS_SUDO_NOPASSWD_LOADED="${ACFS_SUDO_NOPASSWD_LOADED:-false}"
ACFS_SUDO_NOPASSWD_CMDS="${ACFS_SUDO_NOPASSWD_CMDS:-}"

acfs_sudo_load_nopasswd() {
    if [[ "$ACFS_SUDO_NOPASSWD_LOADED" == "true" ]]; then
        return 0
    fi
    ACFS_SUDO_NOPASSWD_LOADED=true

    if [[ -z "${ACFS_SUDO_PASS:-}" ]]; then
        return 0
    fi

    local sudo_list line cmds
    sudo_list=$(printf '%s\n' "$ACFS_SUDO_PASS" | sudo -S -p '' -l 2>/dev/null || true)
    while IFS= read -r line; do
        if [[ "$line" == *"NOPASSWD:"* ]]; then
            cmds="${line#*NOPASSWD:}"
            cmds="${cmds//,/ }"
            ACFS_SUDO_NOPASSWD_CMDS+=" $cmds"
        fi
    done <<< "$sudo_list"
}

acfs_sudo() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
        return $?
    fi

    if [[ -n "${ACFS_SUDO_PASS:-}" ]]; then
        acfs_sudo_load_nopasswd
        if [[ -n "${ACFS_SUDO_NOPASSWD_CMDS:-}" ]]; then
            local cmd_path=""
            cmd_path=$(command -v "$1" 2>/dev/null || true)
            if [[ -n "$cmd_path" && " $ACFS_SUDO_NOPASSWD_CMDS " == *" $cmd_path "* ]]; then
                sudo "$@"
                return $?
            fi
        fi
        if sudo -n true 2>/dev/null; then
            sudo "$@"
            return $?
        fi
        if [[ -t 0 ]]; then
            printf '%s\n' "$ACFS_SUDO_PASS" | sudo -S -p '' "$@"
        else
            { printf '%s\n' "$ACFS_SUDO_PASS"; cat; } | sudo -S -p '' "$@"
        fi
        return $?
    fi

    sudo "$@"
}

acfs_lxc() {
    if [[ -n "${ACFS_SUDO_PASS:-}" ]]; then
        acfs_sudo lxc "$@"
        return $?
    fi

    lxc "$@"
}

# ============================================================
# Detection Functions
# ============================================================

# Check if LXD is available on the host
acfs_sandbox_has_lxd() {
    if command -v lxc &>/dev/null; then
        # Verify LXD is actually initialized (not just installed)
        if acfs_lxc info &>/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Check if we're running inside an LXD container
is_lxd_container() {
    # LXD sets container environment variable
    if [[ "${container:-}" == "lxc" ]]; then
        return 0
    fi
    # Fallback: check for LXD-specific cgroup/namespace markers
    if grep -q lxc /proc/1/cgroup 2>/dev/null; then
        return 0
    fi
    # Fallback: check for container-specific mount
    if [[ -f /dev/.lxc-boot-id ]]; then
        return 0
    fi
    return 1
}

# Check if ACFS container already exists
acfs_sandbox_exists() {
    acfs_lxc info "$ACFS_CONTAINER_NAME" &>/dev/null 2>&1
}

# Check if ACFS container is running
acfs_sandbox_running() {
    local state
    state=$(acfs_lxc info "$ACFS_CONTAINER_NAME" 2>/dev/null | grep -E "^Status:" | awk '{print $2}')
    [[ "$state" == "RUNNING" ]]
}

# ============================================================
# LXD Initialization
# ============================================================

# Determine desired storage driver for LXD init.
_acfs_sandbox_storage_driver() {
    if [[ -n "${ACFS_LXD_ZFS_DEVICE:-}" ]]; then
        echo "zfs"
        return 0
    fi
    echo "${ACFS_LXD_STORAGE_DRIVER:-dir}"
}

# Ensure a ZFS pool exists (create if missing and device provided).
_acfs_sandbox_ensure_zpool() {
    local pool="$1"
    local device="${2:-}"

    if ! command -v zpool &>/dev/null; then
        log_detail "Installing ZFS utilities..."
        acfs_sudo apt-get update -y >/dev/null 2>&1 || true
        acfs_sudo apt-get install -y zfsutils-linux >/dev/null 2>&1 || true
    fi

    if acfs_sudo zpool list -H -o name "$pool" &>/dev/null 2>&1; then
        return 0
    fi

    if [[ -z "$device" ]]; then
        log_fatal "ZFS pool '$pool' is missing. Set ACFS_LXD_ZFS_DEVICE to create it."
    fi
    if [[ ! -b "$device" ]]; then
        log_fatal "ZFS device not found: $device"
    fi

    log_warn "Creating ZFS pool '$pool' on device '$device' (this will wipe the device)."
    acfs_sudo zpool create -f "$pool" "$device"
}

# If LXD is already initialized, try to recover unavailable storage pools.
_acfs_sandbox_fix_storage_pool() {
    local info
    info="$(acfs_sudo lxc storage show default 2>/dev/null || true)"
    if [[ -z "$info" ]]; then
        return 0
    fi

    local driver status source
    driver="$(printf '%s\n' "$info" | awk -F': ' '/^driver:/{print $2; exit}')"
    status="$(printf '%s\n' "$info" | awk -F': ' '/^status:/{print $2; exit}')"
    source="$(printf '%s\n' "$info" | awk -F': ' '/^[[:space:]]*source:/{print $2; exit}')"

    if [[ "$status" == "Unavailable" && "$driver" == "zfs" ]]; then
        local pool="${source:-${ACFS_LXD_ZFS_POOL:-lxd_pool}}"
        log_warn "LXD storage pool 'default' is unavailable (driver=zfs, source=$pool)."
        _acfs_sandbox_ensure_zpool "$pool" "${ACFS_LXD_ZFS_DEVICE:-}"
    fi
}

# Ensure current user has access to LXD (auto-refresh permissions)
grant_acfs_sandbox_access() {
    # Check if LXD is usable by current user
    if acfs_lxc info &>/dev/null 2>&1; then
        return 0
    fi

    # Check if LXD is running but restricted (permission denied)
    # We check if sudo works (meaning LXD is up) but user access fails
    if [[ -z "${ACFS_SUDO_PASS:-}" ]] && acfs_sudo lxc info &>/dev/null 2>&1; then
        log_detail "LXD is running but current user lacks 'lxd' group permissions."
        
        # Attempt automated group refresh
        if [[ -f "$0" ]] && [[ -x "/usr/bin/sg" ]]; then
            if [[ "${ACFS_RESTARTED:-false}" == "true" ]]; then
                log_warn "Still no LXD permissions after group refresh. Proceeding with caution."
                return 0
            fi
            
            # Prevent infinite loops if sg fails silently or environment doesn't propagate
            if [[ "${ACFS_SG_ATTEMPTED:-false}" == "true" ]]; then
                return 0
            fi
            export ACFS_SG_ATTEMPTED=true

            log_detail "Attempting automated group refresh..."
            echo ""
            echo "╔═══════════════════════════════════════════════════════════════╗"
            echo "║      Refreshing Group Permissions (Autoswitching)             ║"
            echo "╠═══════════════════════════════════════════════════════════════╣"
            echo "║  Restarting installer with 'lxd' group enabled...             ║"
            echo "╚═══════════════════════════════════════════════════════════════╝"
            echo ""
            
            # Restart the script with the new group
            # We use ACFS_ORIG_ARGS if set (to preserve script args from inside function)
            # or fallback to $* (function args, likely empty but safe fallback)
            local args="${ACFS_ORIG_ARGS:-$*}"
            export ACFS_RESTARTED=true
            exec /usr/bin/sg lxd -c "$0 $args"
        else
            # Fallback for piped execution or missing sg
            log_warn "Cannot automate group refresh (script is piped or sg missing)."
            log_error "Please refresh your permissions manually:"
            echo ""
            echo "    newgrp lxd"
            echo "    $0 $*"
            echo ""
            # Don't exit here, let the caller decide if this is fatal (it usually is)
            return 1
        fi
    fi
    
    return 0
}

# Initialize LXD on the host system (idempotent)
acfs_sandbox_init_lxd() {
    log_step "LXD" "Initializing LXD for ACFS..."

    # Check if LXD is installed
    if ! command -v lxc &>/dev/null; then
        log_detail "Installing LXD via snap..."
        if command -v snap &>/dev/null; then
            acfs_sudo snap install lxd --channel=latest/stable
        else
            log_fatal "snap not available. Install snapd first: sudo apt install snapd"
        fi
    fi

    # Add current user to lxd group if not already
    if ! groups | grep -q '\blxd\b'; then
        log_detail "Adding $USER to lxd group..."
        acfs_sudo usermod -aG lxd "$USER"
        log_warn "You may need to log out and back in for group changes to take effect."
        log_warn "Or run: newgrp lxd"
    fi

    # Ensure access (handle group refresh)
    grant_acfs_sandbox_access

    # Initialize LXD if not already done (and sudo check failed)
    if acfs_sudo lxc info &>/dev/null 2>&1; then
        _acfs_sandbox_fix_storage_pool
    else
        log_detail "Running LXD initialization..."
        local storage_driver storage_config zfs_pool
        storage_driver="$(_acfs_sandbox_storage_driver)"
        storage_config=""
        if [[ "$storage_driver" == "zfs" ]]; then
            zfs_pool="${ACFS_LXD_ZFS_POOL:-lxd_pool}"
            _acfs_sandbox_ensure_zpool "$zfs_pool" "${ACFS_LXD_ZFS_DEVICE:-}"
            storage_config=$'    config:\n      source: '"$zfs_pool"
        fi

        # Use preseed for non-interactive init
        cat <<EOF | acfs_sudo lxd init --preseed
config: {}
networks:
  - name: lxdbr0
    type: bridge
    config:
      ipv4.address: auto
      ipv6.address: none
storage_pools:
  - name: default
    driver: ${storage_driver}
${storage_config}
profiles:
  - name: default
    devices:
      eth0:
        name: eth0
        network: lxdbr0
        type: nic
      root:
        path: /
        pool: default
        type: disk
EOF
    fi

    # Ensure lxdbr0 exists if no other network is present
    if ! acfs_lxc network show lxdbr0 &>/dev/null 2>&1; then
        log_detail "Ensuring lxdbr0 network exists..."
        # Try to create it non-interactively
        acfs_sudo lxc network create lxdbr0 ipv4.address=auto ipv6.address=none 2>/dev/null || true
    fi

    log_success "LXD initialized"
}

# ============================================================
# Container Lifecycle
# ============================================================

# Create ACFS profile with workspace mount and port forwarding
_acfs_create_profile() {
    log_detail "Creating ACFS container profile..."

    # Create workspace directory on host if it doesn't exist
    mkdir -p "$ACFS_WORKSPACE_HOST"

    # Delete existing profile if present (idempotent)
    acfs_lxc profile show "$ACFS_PROFILE_NAME" &>/dev/null && \
        acfs_lxc profile delete "$ACFS_PROFILE_NAME" 2>/dev/null || true

    # Create profile with workspace bind mount and port forwarding
    acfs_lxc profile create "$ACFS_PROFILE_NAME"

    acfs_lxc profile set "$ACFS_PROFILE_NAME" security.nesting=true

    # Add workspace disk device with shift=true for permissions
    acfs_lxc profile device add "$ACFS_PROFILE_NAME" workspace disk \
        source="$ACFS_WORKSPACE_HOST" \
        path="$ACFS_WORKSPACE_CONTAINER" \
        shift=true

    # Add ethernet device
    acfs_lxc profile device add "$ACFS_PROFILE_NAME" eth0 nic \
        name=eth0 \
        network=lxdbr0

    # Add port forwarding for dashboard
    acfs_lxc profile device add "$ACFS_PROFILE_NAME" dashboard-proxy proxy \
        listen="tcp:0.0.0.0:$ACFS_DASHBOARD_PORT" \
        connect="tcp:127.0.0.1:8080"

    log_detail "Profile created: $ACFS_PROFILE_NAME"
}

# Create the ACFS container
acfs_sandbox_create() {
    grant_acfs_sandbox_access
    set_terminal_title "ACFS Sandbox: Creating..."
    log_step "SANDBOX" "Creating ACFS sandbox container..."

    if acfs_sandbox_exists; then
        log_detail "Container '$ACFS_CONTAINER_NAME' already exists"
        if ! acfs_sandbox_running; then
            log_detail "Starting existing container..."
        acfs_lxc start "$ACFS_CONTAINER_NAME"
        fi
        return 0
    fi

    # Ensure LXD is initialized
    if ! acfs_sandbox_has_lxd; then
        acfs_sandbox_init_lxd
    fi

    # Create profile
    _acfs_create_profile

    # Launch container
    set_terminal_title "ACFS Sandbox: Launching Ubuntu..."
    log_detail "Launching Ubuntu container: $ACFS_CONTAINER_IMAGE"
    acfs_lxc launch "$ACFS_CONTAINER_IMAGE" "$ACFS_CONTAINER_NAME" \
        --profile default \
        --profile "$ACFS_PROFILE_NAME"

    # Wait for container to be ready
    set_terminal_title "ACFS Sandbox: Initializing..."
    log_detail "Waiting for container to initialize..."
    local retries=30
    while [[ $retries -gt 0 ]]; do
        if acfs_lxc exec "$ACFS_CONTAINER_NAME" -- systemctl is-system-running &>/dev/null 2>&1; then
            break
        fi
        sleep 1
        ((retries--))
    done

    if [[ $retries -eq 0 ]]; then
        log_warn "Container may not be fully initialized, proceeding anyway..."
    fi

    # Ensure ubuntu user exists inside container
    set_terminal_title "ACFS Sandbox: Setting up user..."
    log_detail "Setting up ubuntu user in container..."
    acfs_lxc exec "$ACFS_CONTAINER_NAME" -- bash -c '
        if ! id ubuntu &>/dev/null; then
            useradd -m -s /bin/bash -G sudo ubuntu
            echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-ubuntu-acfs
            chmod 440 /etc/sudoers.d/90-ubuntu-acfs
        fi
    '

    # Ensure workspace directory exists and is owned by ubuntu
    acfs_lxc exec "$ACFS_CONTAINER_NAME" -- bash -c '
        mkdir -p /data/projects
        chown ubuntu:ubuntu /data/projects
    '

    log_success "Container '$ACFS_CONTAINER_NAME' created and running"
}

# Start the container
acfs_sandbox_start() {
    grant_acfs_sandbox_access
    if ! acfs_sandbox_exists; then
        log_error "Container '$ACFS_CONTAINER_NAME' does not exist. Run: acfs-local create"
        return 1
    fi

    if acfs_sandbox_running; then
        log_detail "Container already running"
        return 0
    fi

    log_detail "Starting container..."
    acfs_lxc start "$ACFS_CONTAINER_NAME"
    log_success "Container started"
}

# Stop the container
acfs_sandbox_stop() {
    grant_acfs_sandbox_access
    if ! acfs_sandbox_exists; then
        log_warn "Container '$ACFS_CONTAINER_NAME' does not exist"
        return 0
    fi

    if ! acfs_sandbox_running; then
        log_detail "Container already stopped"
        return 0
    fi

    log_detail "Stopping container..."
    acfs_lxc stop "$ACFS_CONTAINER_NAME"
    log_success "Container stopped"
}

# Execute a command inside the container as ubuntu user
acfs_sandbox_exec() {
    local cmd="${1:-}"

    grant_acfs_sandbox_access

    if ! acfs_sandbox_running; then
        log_error "Container not running. Start it first: acfs-local start"
        return 1
    fi

    if [[ -z "$cmd" ]]; then
        # Interactive shell
    acfs_lxc exec "$ACFS_CONTAINER_NAME" -- sudo -u ubuntu -i
    else
        # Execute command
        acfs_lxc exec "$ACFS_CONTAINER_NAME" -- sudo -u ubuntu bash -c "$cmd"
    fi
}

# Execute a command as root inside the container
acfs_sandbox_exec_root() {
    local cmd="$1"

    grant_acfs_sandbox_access

    if ! acfs_sandbox_running; then
        log_error "Container not running. Start it first: acfs-local start"
        return 1
    fi

    acfs_lxc exec "$ACFS_CONTAINER_NAME" -- bash -c "$cmd"
}

# Destroy the container (with confirmation)
acfs_sandbox_destroy() {
    local force="${1:-false}"

    grant_acfs_sandbox_access

    if ! acfs_sandbox_exists; then
        log_detail "Container '$ACFS_CONTAINER_NAME' does not exist"
        return 0
    fi

    if [[ "$force" != "true" ]] && [[ "$force" != "--force" ]]; then
        echo ""
        echo "WARNING: This will permanently destroy the ACFS sandbox container."
        echo "Your workspace at $ACFS_WORKSPACE_HOST will NOT be deleted."
        echo ""
        read -r -p "Type 'destroy' to confirm: " confirm
        if [[ "$confirm" != "destroy" ]]; then
            log_detail "Cancelled"
            return 1
        fi
    fi

    log_detail "Stopping and deleting container..."
    acfs_lxc stop "$ACFS_CONTAINER_NAME" --force 2>/dev/null || true
    acfs_lxc delete "$ACFS_CONTAINER_NAME" --force

    # Clean up profile
    acfs_lxc profile delete "$ACFS_PROFILE_NAME" 2>/dev/null || true

    log_success "Container destroyed. Workspace preserved at: $ACFS_WORKSPACE_HOST"
}

# ============================================================
# Status and Info
# ============================================================

# Show container status
acfs_sandbox_status() {
    grant_acfs_sandbox_access

    if ! acfs_sandbox_exists; then
        log_detail "Status: Not created"
        echo ""
        log_detail "Create with: acfs-local create"
        return 0
    fi

    local state ip
    state=$(acfs_lxc info "$ACFS_CONTAINER_NAME" 2>/dev/null | grep -E "^Status:" | awk '{print $2}')

    log_detail "Container: $ACFS_CONTAINER_NAME"
    log_detail "Status: $state"

    if [[ "$state" == "RUNNING" ]]; then
        ip=$(acfs_lxc info "$ACFS_CONTAINER_NAME" 2>/dev/null | grep -A1 "eth0:" | grep "inet:" | awk '{print $2}' | cut -d/ -f1 | head -1)
        log_detail "IP: ${ip:-unknown}"
        log_detail "Dashboard: http://localhost:$ACFS_DASHBOARD_PORT"
        log_detail "Workspace (host): $ACFS_WORKSPACE_HOST"
        log_detail "Workspace (container): $ACFS_WORKSPACE_CONTAINER"
    fi
}

# ============================================================
# Exports for sourcing
# ============================================================
export ACFS_CONTAINER_NAME ACFS_CONTAINER_IMAGE ACFS_WORKSPACE_HOST
export ACFS_WORKSPACE_CONTAINER ACFS_DASHBOARD_PORT ACFS_PROFILE_NAME
