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
ACFS_LXD_STORAGE_POOL="${ACFS_LXD_STORAGE_POOL:-}"

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
    # LXD CLI hangs on write operations when stdin is a pipe (e.g. via
    # multipass exec).  Redirect stdin from /dev/null for non-exec commands
    # to prevent this; exec commands need interactive stdin for shells.
    local need_stdin=false
    if [[ "${1:-}" == "exec" ]]; then
        need_stdin=true
    fi

    if [[ -n "${ACFS_SUDO_PASS:-}" ]]; then
        if [[ "$need_stdin" == "true" ]]; then
            acfs_sudo lxc "$@"
        else
            acfs_sudo lxc "$@" < /dev/null
        fi
        return $?
    fi

    if [[ "$need_stdin" == "true" ]]; then
        lxc "$@"
    else
        lxc "$@" < /dev/null
    fi
}

# Wrapper for `acfs_sudo lxc` calls that ensures stdin is redirected from
# /dev/null for non-exec LXD commands.  Use this instead of raw
# `acfs_sudo lxc` to avoid hanging in piped/non-interactive environments.
_acfs_sudo_lxc() {
    if [[ "${1:-}" == "exec" ]]; then
        acfs_sudo lxc "$@"
    else
        acfs_sudo lxc "$@" < /dev/null
    fi
}

# ============================================================
# LXD compatibility helpers
# ============================================================
# LXD 5.21 does not support `lxc profile device show <profile> <device>`
# or `lxc config device show <instance> <device>`. These helpers use grep
# to check for a specific device in the full device listing.

# Check if a device exists on a profile: _lxc_profile_has_device <profile> <device>
_lxc_profile_has_device() {
    acfs_lxc profile device show "$1" 2>/dev/null | grep -q "^${2}:"
}

# Check if a device exists on a container: _lxc_config_has_device <instance> <device>
_lxc_config_has_device() {
    acfs_lxc config device show "$1" 2>/dev/null | grep -q "^${2}:"
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

# Wait until the container responds to exec (basic readiness check).
acfs_sandbox_wait_ready() {
    local retries="${1:-30}"
    while [[ $retries -gt 0 ]]; do
        if acfs_lxc exec "$ACFS_CONTAINER_NAME" -- true >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
        retries=$((retries - 1))
    done
    return 1
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
    info="$(_acfs_sudo_lxc storage show default 2>/dev/null || true)"
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

# Ensure a storage pool exists (create if missing).
_acfs_sandbox_ensure_storage_pool() {
    local pool driver zfs_pool pools count
    driver="$(_acfs_sandbox_storage_driver)"

    if [[ -n "${ACFS_LXD_STORAGE_POOL:-}" ]]; then
        pool="$ACFS_LXD_STORAGE_POOL"
        if _acfs_sudo_lxc storage show "$pool" &>/dev/null 2>&1; then
            return 0
        fi
        log_warn "LXD storage pool '$pool' is missing. Creating it now."
        if [[ "$driver" == "zfs" ]]; then
            zfs_pool="${ACFS_LXD_ZFS_POOL:-lxd_pool}"
            _acfs_sandbox_ensure_zpool "$zfs_pool" "${ACFS_LXD_ZFS_DEVICE:-}"
            _acfs_sudo_lxc storage create "$pool" zfs source="$zfs_pool"
        else
            _acfs_sudo_lxc storage create "$pool" "$driver" || _acfs_sudo_lxc storage create "$pool" dir
        fi
        return 0
    fi

    if _acfs_sudo_lxc storage show default &>/dev/null 2>&1; then
        return 0
    fi

    pools="$(_acfs_sudo_lxc storage list --format csv 2>/dev/null | cut -d, -f1 || true)"
    count="$(printf '%s\n' "$pools" | sed '/^$/d' | wc -l | tr -d ' ')"
    if [[ "$count" -eq 0 ]]; then
        log_warn "No LXD storage pools found. Creating 'default' pool."
        if [[ "$driver" == "zfs" ]]; then
            zfs_pool="${ACFS_LXD_ZFS_POOL:-lxd_pool}"
            _acfs_sandbox_ensure_zpool "$zfs_pool" "${ACFS_LXD_ZFS_DEVICE:-}"
            _acfs_sudo_lxc storage create default zfs source="$zfs_pool"
        else
            _acfs_sudo_lxc storage create default "$driver" || _acfs_sudo_lxc storage create default dir
        fi
    fi
}

# Pick a storage pool name for the default profile root device.
_acfs_sandbox_default_storage_pool() {
    local pools
    pools="$(_acfs_sudo_lxc storage list --format csv 2>/dev/null | cut -d, -f1 || true)"

    if [[ -n "${ACFS_LXD_STORAGE_POOL:-}" ]]; then
        echo "$ACFS_LXD_STORAGE_POOL"
        return 0
    fi

    if printf '%s\n' "$pools" | grep -qx "default"; then
        echo "default"
        return 0
    fi

    if [[ -n "${ACFS_LXD_ZFS_POOL:-}" ]] && printf '%s\n' "$pools" | grep -qx "${ACFS_LXD_ZFS_POOL}"; then
        echo "${ACFS_LXD_ZFS_POOL}"
        return 0
    fi

    # If only one pool exists, use it.
    local count
    count="$(printf '%s\n' "$pools" | sed '/^$/d' | wc -l | tr -d ' ')"
    if [[ "$count" == "1" ]]; then
        printf '%s\n' "$pools"
        return 0
    fi

    if [[ -n "$pools" ]]; then
        local first_pool
        first_pool="$(printf '%s\n' "$pools" | sed -n '1p')"
        log_warn "Multiple LXD storage pools detected. Using '$first_pool'. Set ACFS_LXD_STORAGE_POOL to override."
        printf '%s\n' "$first_pool"
        return 0
    fi

    log_fatal "No suitable LXD storage pool found for default profile root device."
}

# Ensure the default profile has a root disk device.
_acfs_sandbox_ensure_root_device() {
    if _acfs_sudo_lxc profile device show default 2>/dev/null | grep -q '^root:'; then
        if [[ -n "${ACFS_LXD_STORAGE_POOL:-}" || -n "${ACFS_LXD_ZFS_DEVICE:-}" ]]; then
            local current_pool desired_pool
            current_pool="$(_acfs_sudo_lxc profile device get default root pool 2>/dev/null || true)"
            desired_pool="$(_acfs_sandbox_default_storage_pool)"
            if [[ -n "$desired_pool" && "$current_pool" != "$desired_pool" ]] && ! acfs_sandbox_exists; then
                log_warn "Updating default profile root pool from '$current_pool' to '$desired_pool'."
                _acfs_sudo_lxc profile device set default root pool "$desired_pool" || true
            fi
        fi
        return 0
    fi

    local pool
    pool="$(_acfs_sandbox_default_storage_pool)"
    log_warn "Default LXD profile missing root disk device. Adding root device (pool=$pool)."
    _acfs_sudo_lxc profile device add default root disk path=/ pool="$pool"
}

# Ensure the workspace directory exists and is usable on the host.
_acfs_sandbox_ensure_workspace_dir() {
    if [[ -e "$ACFS_WORKSPACE_HOST" && ! -d "$ACFS_WORKSPACE_HOST" ]]; then
        local fallback
        fallback="$HOME/acfs-workspace-$(date +%Y%m%d-%H%M%S)"
        log_warn "Workspace path '$ACFS_WORKSPACE_HOST' is not a directory. Using '$fallback' instead."
        ACFS_WORKSPACE_HOST="$fallback"
    fi

    mkdir -p "$ACFS_WORKSPACE_HOST"
    if [[ ! -w "$ACFS_WORKSPACE_HOST" ]]; then
        log_warn "Workspace path '$ACFS_WORKSPACE_HOST' is not writable. Attempting to fix permissions."
        acfs_sudo chown "$USER:$USER" "$ACFS_WORKSPACE_HOST" 2>/dev/null || true
        acfs_sudo chmod 0775 "$ACFS_WORKSPACE_HOST" 2>/dev/null || true
    fi
}

_acfs_sandbox_container_workspace_mounted() {
    acfs_lxc exec "$ACFS_CONTAINER_NAME" -- bash -c '
        if command -v mountpoint >/dev/null 2>&1; then
            mountpoint -q "'"$ACFS_WORKSPACE_CONTAINER"'"
        else
            grep -q " '"$ACFS_WORKSPACE_CONTAINER"' " /proc/mounts
        fi
    ' >/dev/null 2>&1
}

_acfs_sandbox_container_has_workspace_device() {
    _lxc_config_has_device "$ACFS_CONTAINER_NAME" workspace
}

_acfs_sandbox_ensure_container_workspace_device() {
    if _acfs_sandbox_container_has_workspace_device; then
        acfs_lxc config device set "$ACFS_CONTAINER_NAME" workspace source "$ACFS_WORKSPACE_HOST" >/dev/null 2>&1 || true
        acfs_lxc config device set "$ACFS_CONTAINER_NAME" workspace path "$ACFS_WORKSPACE_CONTAINER" >/dev/null 2>&1 || true
        if ! acfs_lxc config device set "$ACFS_CONTAINER_NAME" workspace shift true >/dev/null 2>&1; then
            acfs_lxc config device set "$ACFS_CONTAINER_NAME" workspace shift false >/dev/null 2>&1 || true
            acfs_lxc config set "$ACFS_CONTAINER_NAME" security.privileged true >/dev/null 2>&1 || true
        fi
        return 0
    fi

    if ! acfs_lxc config device add "$ACFS_CONTAINER_NAME" workspace disk \
        source="$ACFS_WORKSPACE_HOST" \
        path="$ACFS_WORKSPACE_CONTAINER" \
        shift=true >/dev/null 2>&1; then
        acfs_lxc config device add "$ACFS_CONTAINER_NAME" workspace disk \
            source="$ACFS_WORKSPACE_HOST" \
            path="$ACFS_WORKSPACE_CONTAINER" >/dev/null 2>&1 || true
        acfs_lxc config set "$ACFS_CONTAINER_NAME" security.privileged true >/dev/null 2>&1 || true
    fi
}

_acfs_sandbox_profile_dashboard_port() {
    local listen
    listen="$(acfs_lxc profile device get "$ACFS_PROFILE_NAME" dashboard-proxy listen 2>/dev/null || true)"
    if [[ -z "$listen" ]]; then
        listen="$(acfs_lxc profile device show "$ACFS_PROFILE_NAME" 2>/dev/null | awk '
            /^dashboard-proxy:/{blk=1; next}
            blk && /^[^ ]/{exit}
            blk && /listen:/{sub(/.*listen: /, ""); print; exit}
        ')"
    fi
    if [[ -n "$listen" ]]; then
        printf '%s\n' "${listen##*:}"
    fi
}

_acfs_sandbox_is_port_free() {
    local port="$1"
    if command -v ss &>/dev/null; then
        ss -ltn "sport = :$port" | grep -q ":$port" && return 1 || return 0
    fi
    if command -v lsof &>/dev/null; then
        lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1 && return 1 || return 0
    fi
    if command -v netstat &>/dev/null; then
        netstat -ltn 2>/dev/null | awk '{print $4}' | grep -qE ":${port}\$" && return 1 || return 0
    fi
    return 0
}

# Ensure dashboard port is available; pick a free one if not.
_acfs_sandbox_ensure_dashboard_port() {
    local profile_port
    profile_port="$(_acfs_sandbox_profile_dashboard_port)"
    if [[ -n "$profile_port" ]]; then
        if acfs_sandbox_running; then
            ACFS_DASHBOARD_PORT="$profile_port"
            return 0
        fi
        if _acfs_sandbox_is_port_free "$profile_port"; then
            ACFS_DASHBOARD_PORT="$profile_port"
            return 0
        fi
        log_warn "Dashboard port $profile_port from existing profile is in use. Selecting a new port."
    fi

    local base_port="${ACFS_DASHBOARD_PORT:-38080}"
    local port="$base_port"
    local max_tries=20
    local i=0
    while [[ $i -le $max_tries ]]; do
        if _acfs_sandbox_is_port_free "$port"; then
            break
        fi
        port=$((port + 1))
        i=$((i + 1))
    done

    if [[ $i -gt $max_tries ]]; then
        log_fatal "No free dashboard port found in range ${base_port}-${port}."
    fi

    if [[ "$port" != "$base_port" ]]; then
        log_warn "Dashboard port $base_port is in use. Using $port instead."
        ACFS_DASHBOARD_PORT="$port"
    fi
}

_acfs_sandbox_ensure_lxd_remotes() {
    local remotes
    remotes="$(_acfs_sudo_lxc remote list --format csv 2>/dev/null | cut -d, -f1 || true)"
    if ! printf '%s\n' "$remotes" | grep -qx "ubuntu"; then
        log_warn "LXD remote 'ubuntu' missing. Adding it now."
        _acfs_sudo_lxc remote add ubuntu https://cloud-images.ubuntu.com/releases --protocol simplestreams >/dev/null 2>&1 || true
    fi
}

_acfs_sandbox_host_default_iface() {
    ip route show default 2>/dev/null | awk 'NR==1 {print $5}'
}

_acfs_sandbox_container_has_default_route() {
    acfs_lxc exec "$ACFS_CONTAINER_NAME" -- bash -c 'ip route show default | grep -q default' >/dev/null 2>&1
}

_acfs_sandbox_container_has_egress() {
    acfs_lxc exec "$ACFS_CONTAINER_NAME" -- bash -c '
        if command -v timeout >/dev/null 2>&1; then
            timeout 3 bash -c "exec 3<>/dev/tcp/1.1.1.1/443" >/dev/null 2>&1
            exit $?
        fi
        ip route show default | grep -q default
    ' >/dev/null 2>&1
}

_acfs_sandbox_fix_container_network() {
    local parent iface_added=false
    if _acfs_sandbox_container_has_egress; then
        return 0
    fi

    parent="$(_acfs_sandbox_host_default_iface)"
    if [[ -z "$parent" ]]; then
        log_warn "Unable to detect host default interface for macvlan fallback."
        return 1
    fi

    if ! _lxc_config_has_device "$ACFS_CONTAINER_NAME" eth1; then
        log_warn "Adding macvlan NIC for container egress (parent=$parent)."
        if acfs_lxc config device add "$ACFS_CONTAINER_NAME" eth1 nic nictype=macvlan parent="$parent" name=eth1 2>/dev/null; then
            iface_added=true
        else
            log_warn "Failed to attach macvlan NIC (parent=$parent)."
            return 1
        fi
    fi

    if [[ "$iface_added" == "true" ]]; then
        acfs_lxc exec "$ACFS_CONTAINER_NAME" -- bash -c '
            cat >/etc/netplan/99-acfs-macvlan.yaml <<EOF
network:
  version: 2
  ethernets:
    eth1:
      dhcp4: true
      dhcp4-overrides:
        route-metric: 50
EOF
            netplan apply >/dev/null 2>&1 || netplan apply
        ' || true
        sleep 2
    fi

    _acfs_sandbox_container_has_egress
}

acfs_sandbox_preflight() {
    log_step "SANDBOX" "Running preflight checks..."
    acfs_sandbox_init_lxd
    _acfs_sandbox_ensure_storage_pool
    _acfs_sandbox_ensure_root_device
    _acfs_sandbox_ensure_lxd_remotes
    _acfs_sandbox_ensure_workspace_dir
    _acfs_sandbox_ensure_dashboard_port
}

# Ensure current user has access to LXD (auto-refresh permissions)
grant_acfs_sandbox_access() {
    # Check if LXD is usable by current user
    if acfs_lxc info &>/dev/null 2>&1; then
        return 0
    fi

    # Check if LXD is running but restricted (permission denied)
    # We check if sudo works (meaning LXD is up) but user access fails
    if [[ -z "${ACFS_SUDO_PASS:-}" ]] && _acfs_sudo_lxc info &>/dev/null 2>&1; then
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
    if _acfs_sudo_lxc info &>/dev/null 2>&1; then
        _acfs_sandbox_fix_storage_pool
        _acfs_sandbox_ensure_storage_pool
    else
        log_detail "Running LXD initialization..."
        local storage_driver storage_config zfs_pool storage_pool_name
        storage_driver="$(_acfs_sandbox_storage_driver)"
        storage_pool_name="${ACFS_LXD_STORAGE_POOL:-default}"
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
  - name: ${storage_pool_name}
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
        pool: ${storage_pool_name}
        type: disk
EOF
    fi

    _acfs_sandbox_ensure_storage_pool
    _acfs_sandbox_ensure_root_device

    # Ensure lxdbr0 exists if no other network is present
    if ! acfs_lxc network show lxdbr0 &>/dev/null 2>&1; then
        log_detail "Ensuring lxdbr0 network exists..."
        # Try to create it non-interactively
        _acfs_sudo_lxc network create lxdbr0 ipv4.address=auto ipv6.address=none 2>/dev/null || true
    fi

    log_success "LXD initialized"
}

# ============================================================
# Container Lifecycle
# ============================================================

# Create ACFS profile with workspace mount and port forwarding
_acfs_create_profile() {
    log_detail "Creating ACFS container profile..."

    _acfs_sandbox_ensure_workspace_dir

    # Create profile if missing
    if ! acfs_lxc profile show "$ACFS_PROFILE_NAME" &>/dev/null; then
        acfs_lxc profile create "$ACFS_PROFILE_NAME"
    fi

    acfs_lxc profile set "$ACFS_PROFILE_NAME" security.nesting=true

    # Configure workspace disk device
    # Detect if workspace is on a non-native filesystem (e.g. Multipass SSHFS mount)
    # where idmapped mounts (shift=true) won't work.  FUSE-backed bind mounts also
    # fail in unprivileged containers, so we need security.privileged=true.
    local use_shift=true
    if mountpoint -q "$ACFS_WORKSPACE_HOST" 2>/dev/null; then
        local ws_fstype
        ws_fstype="$(findmnt -n -o FSTYPE "$ACFS_WORKSPACE_HOST" 2>/dev/null || true)"
        if [[ "$ws_fstype" == "fuse"* || "$ws_fstype" == "9p" || "$ws_fstype" == "virtiofs" || "$ws_fstype" == "sshfs" ]]; then
            log_detail "Workspace is on $ws_fstype mount; using privileged container."
            use_shift=false
        fi
    fi

    if [[ "$use_shift" == "false" ]]; then
        # FUSE/SSHFS: privileged container with plain disk device (no shift/uid/gid)
        acfs_lxc profile set "$ACFS_PROFILE_NAME" security.privileged true 2>/dev/null || true
        if _lxc_profile_has_device "$ACFS_PROFILE_NAME" workspace; then
            acfs_lxc profile device set "$ACFS_PROFILE_NAME" workspace source "$ACFS_WORKSPACE_HOST" || true
            acfs_lxc profile device set "$ACFS_PROFILE_NAME" workspace path "$ACFS_WORKSPACE_CONTAINER" || true
            acfs_lxc profile device set "$ACFS_PROFILE_NAME" workspace shift false 2>/dev/null || true
        else
            acfs_lxc profile device add "$ACFS_PROFILE_NAME" workspace disk \
                source="$ACFS_WORKSPACE_HOST" \
                path="$ACFS_WORKSPACE_CONTAINER" || true
        fi
    elif _lxc_profile_has_device "$ACFS_PROFILE_NAME" workspace; then
        acfs_lxc profile device set "$ACFS_PROFILE_NAME" workspace source "$ACFS_WORKSPACE_HOST" || true
        acfs_lxc profile device set "$ACFS_PROFILE_NAME" workspace path "$ACFS_WORKSPACE_CONTAINER" || true
        if ! acfs_lxc profile device set "$ACFS_PROFILE_NAME" workspace shift true 2>/dev/null; then
            log_warn "Workspace device shift not supported. Falling back to privileged container."
            acfs_lxc profile device set "$ACFS_PROFILE_NAME" workspace shift false 2>/dev/null || true
            acfs_lxc profile set "$ACFS_PROFILE_NAME" security.privileged true 2>/dev/null || true
        fi
    else
        if ! acfs_lxc profile device add "$ACFS_PROFILE_NAME" workspace disk \
            source="$ACFS_WORKSPACE_HOST" \
            path="$ACFS_WORKSPACE_CONTAINER" \
            shift=true; then
            log_warn "Workspace device shift failed. Falling back to privileged container."
            acfs_lxc profile device add "$ACFS_PROFILE_NAME" workspace disk \
                source="$ACFS_WORKSPACE_HOST" \
                path="$ACFS_WORKSPACE_CONTAINER" || true
            acfs_lxc profile set "$ACFS_PROFILE_NAME" security.privileged true 2>/dev/null || true
        fi
    fi

    # Add ethernet device (lxdbr0)
    if _lxc_profile_has_device "$ACFS_PROFILE_NAME" eth0; then
        acfs_lxc profile device set "$ACFS_PROFILE_NAME" eth0 network lxdbr0 || true
        acfs_lxc profile device set "$ACFS_PROFILE_NAME" eth0 name eth0 || true
    else
        acfs_lxc profile device add "$ACFS_PROFILE_NAME" eth0 nic \
            name=eth0 \
            network=lxdbr0 || true
    fi

    # Add port forwarding for dashboard
    if _lxc_profile_has_device "$ACFS_PROFILE_NAME" dashboard-proxy; then
        acfs_lxc profile device set "$ACFS_PROFILE_NAME" dashboard-proxy listen "tcp:0.0.0.0:$ACFS_DASHBOARD_PORT" || true
        acfs_lxc profile device set "$ACFS_PROFILE_NAME" dashboard-proxy connect "tcp:127.0.0.1:8080" || true
    else
        if ! acfs_lxc profile device add "$ACFS_PROFILE_NAME" dashboard-proxy proxy \
            listen="tcp:0.0.0.0:$ACFS_DASHBOARD_PORT" \
            connect="tcp:127.0.0.1:8080"; then
            _acfs_sandbox_ensure_dashboard_port
            acfs_lxc profile device add "$ACFS_PROFILE_NAME" dashboard-proxy proxy \
                listen="tcp:0.0.0.0:$ACFS_DASHBOARD_PORT" \
                connect="tcp:127.0.0.1:8080" || true
        fi
    fi

    log_detail "Profile created: $ACFS_PROFILE_NAME"
}

# Create the ACFS container
acfs_sandbox_create() {
    grant_acfs_sandbox_access
    set_terminal_title "ACFS Sandbox: Creating..."
    log_step "SANDBOX" "Creating ACFS sandbox container..."

    acfs_sandbox_preflight

    if acfs_sandbox_exists; then
        log_detail "Container '$ACFS_CONTAINER_NAME' already exists"
        _acfs_create_profile
        if ! acfs_sandbox_running; then
            log_detail "Starting existing container..."
            acfs_lxc start "$ACFS_CONTAINER_NAME"
        fi
        _acfs_sandbox_ensure_container_workspace_device
        if ! acfs_sandbox_wait_ready 30; then
            log_warn "Container did not become ready. Attempting restart..."
            acfs_lxc restart "$ACFS_CONTAINER_NAME" >/dev/null 2>&1 || true
            acfs_sandbox_wait_ready 30 || log_warn "Container still not responding to exec."
        fi
        if ! _acfs_sandbox_container_workspace_mounted; then
            log_warn "Workspace mount not detected in container. Restarting to apply mount."
            acfs_lxc restart "$ACFS_CONTAINER_NAME" >/dev/null 2>&1 || true
            acfs_sandbox_wait_ready 30 || true
        fi
        if ! _acfs_sandbox_container_has_default_route; then
            log_warn "Existing container missing default route. Attempting network fix."
            _acfs_sandbox_fix_container_network || true
        fi
        return 0
    fi

    # Create profile
    _acfs_create_profile

    _acfs_sandbox_ensure_root_device

    # Launch container
    set_terminal_title "ACFS Sandbox: Launching Ubuntu..."
    log_detail "Launching Ubuntu container: $ACFS_CONTAINER_IMAGE"
    if ! acfs_lxc launch "$ACFS_CONTAINER_IMAGE" "$ACFS_CONTAINER_NAME" \
        --profile default \
        --profile "$ACFS_PROFILE_NAME" 2>&1; then
        # Launch can fail if shift=true isn't supported on the workspace
        # filesystem (e.g. Multipass virtiofs mounts).  Fall back to
        # uid/gid mapping and retry.
        log_warn "Container launch failed. Retrying with privileged container..."
        acfs_lxc delete "$ACFS_CONTAINER_NAME" --force 2>/dev/null || true
        if _lxc_profile_has_device "$ACFS_PROFILE_NAME" workspace; then
            acfs_lxc profile device remove "$ACFS_PROFILE_NAME" workspace 2>/dev/null || true
            acfs_lxc profile device add "$ACFS_PROFILE_NAME" workspace disk \
                source="$ACFS_WORKSPACE_HOST" \
                path="$ACFS_WORKSPACE_CONTAINER" || true
        fi
        acfs_lxc profile set "$ACFS_PROFILE_NAME" security.privileged true 2>/dev/null || true
        acfs_lxc launch "$ACFS_CONTAINER_IMAGE" "$ACFS_CONTAINER_NAME" \
            --profile default \
            --profile "$ACFS_PROFILE_NAME"
    fi

    # Wait for container to be ready
    set_terminal_title "ACFS Sandbox: Initializing..."
    log_detail "Waiting for container to initialize..."
    local retries=30
    while [[ $retries -gt 0 ]]; do
        if acfs_lxc exec "$ACFS_CONTAINER_NAME" -- systemctl is-system-running &>/dev/null 2>&1; then
            break
        fi
        sleep 1
        retries=$((retries - 1))
    done

    if [[ $retries -eq 0 ]]; then
        log_warn "Container may not be fully initialized, proceeding anyway..."
    fi
    if ! acfs_sandbox_wait_ready 30; then
        log_warn "Container did not respond to exec after launch."
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

    # Ensure workspace directory exists. Some host-backed mounts (sshfs/fuse/virtiofs)
    # can reject chown from inside the container, so treat ownership update as best-effort.
    acfs_lxc exec "$ACFS_CONTAINER_NAME" -- mkdir -p /data/projects
    if ! acfs_lxc exec "$ACFS_CONTAINER_NAME" -- bash -c 'chown ubuntu:ubuntu /data/projects 2>/dev/null'; then
        local ubuntu_can_write=false
        if acfs_lxc exec "$ACFS_CONTAINER_NAME" -- bash -c 'su -s /bin/sh -c "test -w /data/projects" ubuntu >/dev/null 2>&1'; then
            ubuntu_can_write=true
        fi

        if [[ "$ubuntu_can_write" == "true" ]]; then
            if _acfs_sandbox_container_workspace_mounted; then
                log_warn "Workspace mount does not allow chown on /data/projects. Continuing (ubuntu has write access)."
            else
                log_warn "Could not change ownership on /data/projects. Continuing (ubuntu has write access)."
            fi
        else
            if _acfs_sandbox_container_workspace_mounted; then
                log_error "Workspace mounted at /data/projects is not writable by ubuntu. Fix host workspace permissions for '$ACFS_WORKSPACE_HOST'."
            else
                log_error "Failed to set /data/projects ownership and ubuntu cannot write to it."
            fi
            return 1
        fi
    fi

    if ! _acfs_sandbox_container_has_egress; then
        log_warn "Container egress not detected. Attempting network fix."
        _acfs_sandbox_fix_container_network || true
    fi

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
    if ! acfs_sandbox_wait_ready 30; then
        log_warn "Container did not become ready. Attempting restart..."
        acfs_lxc restart "$ACFS_CONTAINER_NAME" >/dev/null 2>&1 || true
        if ! acfs_sandbox_wait_ready 30; then
            log_error "Container is running but not responding to exec."
            return 1
        fi
    fi
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
        log_warn "Container not running. Starting it now..."
        if ! acfs_sandbox_start; then
            log_error "Container could not be started."
            return 1
        fi
    fi

    if ! acfs_sandbox_wait_ready 20; then
        log_error "Container is not responding to exec."
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
        log_warn "Container not running. Starting it now..."
        if ! acfs_sandbox_start; then
            log_error "Container could not be started."
            return 1
        fi
    fi

    if ! acfs_sandbox_wait_ready 20; then
        log_error "Container is not responding to exec."
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
        local dashboard_port
        dashboard_port="$ACFS_DASHBOARD_PORT"
        local profile_port
        profile_port="$(_acfs_sandbox_profile_dashboard_port)"
        if [[ -n "$profile_port" ]]; then
            dashboard_port="$profile_port"
        fi
        log_detail "IP: ${ip:-unknown}"
        log_detail "Dashboard: http://localhost:$dashboard_port"
        log_detail "Workspace (host): $ACFS_WORKSPACE_HOST"
        log_detail "Workspace (container): $ACFS_WORKSPACE_CONTAINER"
    fi
}

# ============================================================
# Exports for sourcing
# ============================================================
export ACFS_CONTAINER_NAME ACFS_CONTAINER_IMAGE ACFS_WORKSPACE_HOST
export ACFS_WORKSPACE_CONTAINER ACFS_DASHBOARD_PORT ACFS_PROFILE_NAME
