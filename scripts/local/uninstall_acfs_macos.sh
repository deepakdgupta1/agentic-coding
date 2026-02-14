#!/usr/bin/env bash
# ============================================================================
# ACFS macOS Full Uninstall Helper
#
# Removes local-desktop ACFS artifacts from a Mac host, including:
# - Multipass ACFS VMs
# - Host ACFS config and wrappers
# - ACFS shell-loader lines (with backups)
# - Default ACFS workspace and SSH key
# - Optional Multipass cask + local app data
#
# Usage:
#   ./scripts/local/uninstall_acfs_macos.sh
#   ./scripts/local/uninstall_acfs_macos.sh --yes
#   ./scripts/local/uninstall_acfs_macos.sh --dry-run
# ============================================================================

set -euo pipefail
shopt -s nullglob

YES_MODE=false
DRY_RUN=false
REMOVE_MULTIPASS_CASK=true

while [[ $# -gt 0 ]]; do
    case "$1" in
        --yes|-y)
            YES_MODE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --keep-multipass)
            REMOVE_MULTIPASS_CASK=false
            shift
            ;;
        --help|-h)
            cat <<'EOF'
Usage: uninstall_acfs_macos.sh [options]

Options:
  --yes, -y          Skip confirmation prompt
  --dry-run          Print actions only (no changes)
  --keep-multipass   Keep Multipass installed (still removes ACFS VMs)
  --help, -h         Show this help
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

run_cmd() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] $*"
        return 0
    fi
    "$@"
}

run_rm_f() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] rm -f $*"
        return 0
    fi
    rm -f "$@"
}

run_rm_rf() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] rm -rf $*"
        return 0
    fi
    rm -rf "$@"
}

confirm() {
    if [[ "$YES_MODE" == "true" || "$DRY_RUN" == "true" ]]; then
        return 0
    fi
    echo "This will remove ACFS local-desktop data from this Mac host."
    echo "It includes ACFS VMs, ACFS config, wrapper binaries, default workspace,"
    echo "and the default ACFS SSH key (~/.ssh/acfs_ed25519)."
    echo ""
    read -r -p "Type 'uninstall' to continue: " response
    [[ "$response" == "uninstall" ]]
}

remove_multipass_vms() {
    echo "[1/6] Removing ACFS Multipass VMs"
    if ! command -v multipass >/dev/null 2>&1; then
        echo "  multipass not found; skipping VM cleanup."
        return 0
    fi

    local found_any=false
    local vm=""
    while IFS= read -r vm; do
        [[ -n "$vm" ]] || continue
        found_any=true
        echo "  - $vm"
        run_cmd multipass umount "$vm:acfs-workspace" >/dev/null 2>&1 || true
        run_cmd multipass umount "$vm:/home/ubuntu/acfs-workspace" >/dev/null 2>&1 || true
        run_cmd multipass stop "$vm" >/dev/null 2>&1 || true
        run_cmd multipass delete "$vm" >/dev/null 2>&1 || true
    done < <(multipass list 2>/dev/null | awk 'NR>1{print $1}' | grep -E '^acfs(-|$)' || true)

    if [[ "$found_any" != "true" ]]; then
        echo "  no ACFS-named Multipass VMs found."
    fi
    run_cmd multipass purge >/dev/null 2>&1 || true
}

remove_host_acfs_files() {
    echo "[2/6] Removing ACFS files on host"
    run_rm_rf "$HOME/.acfs" "$HOME/.acfs_installed" "$HOME/.config/acfs"
    run_rm_f \
        "$HOME/.local/bin/acfs" \
        "$HOME/.local/bin/acfs-update" \
        "$HOME/.local/bin/onboard" \
        "$HOME/.local/bin/acfs-local"

    if [[ -e /usr/local/bin/acfs || -e /usr/local/bin/flywheel-update-agents-md ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[dry-run] sudo rm -f /usr/local/bin/acfs /usr/local/bin/flywheel-update-agents-md"
        else
            sudo rm -f /usr/local/bin/acfs /usr/local/bin/flywheel-update-agents-md
        fi
    fi
}

clean_shell_loader_lines() {
    echo "[3/6] Cleaning ACFS shell-loader lines (with backups)"
    local ts
    ts="$(date +%Y%m%d_%H%M%S)"
    local file
    for file in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshrc.local"; do
        [[ -f "$file" ]] || continue
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[dry-run] cp \"$file\" \"$file.pre-acfs-clean.$ts\""
            echo "[dry-run] sed -i '' ... \"$file\""
            continue
        fi
        cp "$file" "$file.pre-acfs-clean.$ts"
        sed -i '' \
            -e '/^# ACFS loader$/d' \
            -e '/\.acfs\/zsh\/acfs\.zshrc/d' \
            -e '/^# Added by ACFS - user binary paths$/d' \
            -e '/^# ACFS PATH$/d' \
            "$file"
    done
}

remove_workspace_and_ssh_key() {
    echo "[4/6] Removing default ACFS workspace and SSH key"
    run_rm_rf "$HOME/acfs-workspace" "$HOME"/acfs-workspace-*
    run_rm_f "$HOME/.ssh/acfs_ed25519" "$HOME/.ssh/acfs_ed25519.pub"
    if [[ -f "$HOME/.ssh/config" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[dry-run] sed -i '' '/acfs_ed25519/d' \"$HOME/.ssh/config\""
        else
            sed -i '' '/acfs_ed25519/d' "$HOME/.ssh/config"
        fi
    fi
}

remove_multipass_app_data() {
    echo "[5/6] Removing Multipass app + local data (optional)"
    if [[ "$REMOVE_MULTIPASS_CASK" != "true" ]]; then
        echo "  keeping Multipass cask and local data by request (--keep-multipass)."
        return 0
    fi

    if command -v brew >/dev/null 2>&1; then
        run_cmd brew uninstall --cask multipass >/dev/null 2>&1 || true
    fi

    # Intentionally preserve client cert data to avoid auth lockouts.
    # Do not remove:
    #   ~/Library/Application Support/multipass-client-certificate*
    local path
    for path in \
        "$HOME/Library/Caches"/multipass* \
        "$HOME/Library/Logs"/Multipass* \
        "$HOME/Library/Preferences"/*multipass*; do
        run_rm_rf "$path"
    done
}

verify() {
    echo "[6/6] Verification"
    if command -v acfs >/dev/null 2>&1; then
        echo "  acfs: still present at $(command -v acfs)"
    else
        echo "  acfs: not found"
    fi

    if command -v acfs-local >/dev/null 2>&1; then
        echo "  acfs-local: still present at $(command -v acfs-local)"
    else
        echo "  acfs-local: not found"
    fi

    if command -v multipass >/dev/null 2>&1; then
        echo "  multipass instances:"
        multipass list || true
    else
        echo "  multipass: not installed"
    fi
}

main() {
    confirm || {
        echo "Cancelled."
        exit 1
    }

    remove_multipass_vms
    remove_host_acfs_files
    clean_shell_loader_lines
    remove_workspace_and_ssh_key
    remove_multipass_app_data
    verify

    echo "Done."
}

main "$@"
