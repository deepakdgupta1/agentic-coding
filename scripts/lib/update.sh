#!/usr/bin/env bash
# ============================================================
# ACFS Update - Update All Components
# Updates system packages, agents, cloud CLIs, and stack tools
# ============================================================

set -euo pipefail

ACFS_VERSION="${ACFS_VERSION:-0.1.0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../../VERSION" ]]; then
    ACFS_VERSION="$(cat "$SCRIPT_DIR/../../VERSION" 2>/dev/null || echo "$ACFS_VERSION")"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Counters
SUCCESS_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0

# Flags
UPDATE_APT=true
UPDATE_AGENTS=true
UPDATE_CLOUD=true
UPDATE_STACK=false
FORCE_MODE=false
DRY_RUN=false
VERBOSE=false
QUIET=false
YES_MODE=false
ABORT_ON_FAILURE=false
REBOOT_REQUIRED=false

# Logging
UPDATE_LOG_DIR="${HOME}/.acfs/logs/updates"
UPDATE_LOG_FILE=""

# Version tracking
declare -A VERSION_BEFORE=()
declare -A VERSION_AFTER=()

# ============================================================
# Logging Infrastructure
# ============================================================

init_logging() {
    mkdir -p "$UPDATE_LOG_DIR"
    UPDATE_LOG_FILE="$UPDATE_LOG_DIR/$(date '+%Y-%m-%d-%H%M%S').log"

    # Write log header
    {
        echo "==============================================="
        echo "ACFS Update Log"
        echo "Started: $(date -Iseconds)"
        echo "User: $(whoami)"
        echo "Version: $ACFS_VERSION"
        echo "==============================================="
        echo ""
    } >> "$UPDATE_LOG_FILE"
}

log_to_file() {
    local msg="$1"
    if [[ -n "$UPDATE_LOG_FILE" ]]; then
        echo "[$(date '+%H:%M:%S')] $msg" >> "$UPDATE_LOG_FILE"
    fi
}

# ============================================================
# Version Detection
# ============================================================

get_version() {
    local tool="$1"
    local version=""

    case "$tool" in
        bun)
            version=$("$HOME/.bun/bin/bun" --version 2>/dev/null || echo "unknown")
            ;;
        rust)
            version=$("$HOME/.cargo/bin/rustc" --version 2>/dev/null | awk '{print $2}' || echo "unknown")
            ;;
        uv)
            version=$("$HOME/.local/bin/uv" --version 2>/dev/null | awk '{print $2}' || echo "unknown")
            ;;
        claude)
            version=$(claude --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        codex)
            version=$(codex --version 2>/dev/null || echo "unknown")
            ;;
        gemini)
            version=$(gemini --version 2>/dev/null || echo "unknown")
            ;;
        wrangler)
            version=$(wrangler --version 2>/dev/null || echo "unknown")
            ;;
        supabase)
            version=$(supabase --version 2>/dev/null || echo "unknown")
            ;;
        vercel)
            version=$(vercel --version 2>/dev/null || echo "unknown")
            ;;
        ntm|ubs|bv|cass|cm|caam|slb)
            version=$("$tool" --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        *)
            version="unknown"
            ;;
    esac

    echo "$version"
}

capture_version_before() {
    local tool="$1"
    VERSION_BEFORE["$tool"]=$(get_version "$tool")
    log_to_file "Version before [$tool]: ${VERSION_BEFORE[$tool]}"
}

capture_version_after() {
    local tool="$1"
    VERSION_AFTER["$tool"]=$(get_version "$tool")
    log_to_file "Version after [$tool]: ${VERSION_AFTER[$tool]}"

    local before="${VERSION_BEFORE[$tool]:-unknown}"
    local after="${VERSION_AFTER[$tool]}"

    if [[ "$before" != "$after" ]]; then
        log_to_file "Updated [$tool]: $before -> $after"
        return 0
    fi
    return 1
}

# ============================================================
# Helper Functions
# ============================================================

log_section() {
    log_to_file "=== $1 ==="
    if [[ "$QUIET" != "true" ]]; then
        echo ""
        echo -e "${BOLD}${CYAN}$1${NC}"
        echo "------------------------------------------------------------"
    fi
}

log_item() {
    local status="$1"
    local msg="$2"
    local details="${3:-}"

    log_to_file "[$status] $msg${details:+ - $details}"

    case "$status" in
        ok)
            [[ "$QUIET" != "true" ]] && echo -e "  ${GREEN}[ok]${NC} $msg"
            [[ -n "$details" && "$VERBOSE" == "true" && "$QUIET" != "true" ]] && echo -e "       ${DIM}$details${NC}"
            ((SUCCESS_COUNT += 1))
            ;;
        skip)
            [[ "$QUIET" != "true" ]] && echo -e "  ${DIM}[skip]${NC} $msg"
            [[ -n "$details" && "$QUIET" != "true" ]] && echo -e "       ${DIM}$details${NC}"
            ((SKIP_COUNT += 1))
            ;;
        fail)
            # Always show failures even in quiet mode
            echo -e "  ${RED}[fail]${NC} $msg"
            [[ -n "$details" ]] && echo -e "       ${DIM}$details${NC}"
            ((FAIL_COUNT += 1))
            ;;
        run)
            [[ "$QUIET" != "true" ]] && echo -e "  ${YELLOW}[...]${NC} $msg"
            ;;
    esac
}

run_cmd() {
    local desc="$1"
    shift
    local cmd_display=""
    cmd_display=$(printf '%q ' "$@")

    log_to_file "Running: $cmd_display"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_item "skip" "$desc" "dry-run: $cmd_display"
        return 0
    fi

    log_item "run" "$desc"

    local output=""
    local exit_code=0
    output=$("$@" 2>&1) || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        # Move cursor up and overwrite (only if not in quiet mode)
        if [[ "$QUIET" != "true" ]]; then
            echo -e "\033[1A\033[2K  ${GREEN}[ok]${NC} $desc"
        fi
        log_to_file "Success: $desc"
        [[ -n "$output" ]] && log_to_file "Output: $output"
        ((SUCCESS_COUNT += 1))
        return 0
    else
        if [[ "$QUIET" != "true" ]]; then
            echo -e "\033[1A\033[2K  ${RED}[fail]${NC} $desc"
        else
            echo -e "  ${RED}[fail]${NC} $desc"
        fi
        log_to_file "Failed: $desc (exit code: $exit_code)"
        [[ -n "$output" ]] && log_to_file "Output: $output"
        ((FAIL_COUNT += 1))

        # Handle abort-on-failure
        if [[ "$ABORT_ON_FAILURE" == "true" ]]; then
            echo -e "${RED}Aborting due to failure (--abort-on-failure)${NC}"
            log_to_file "ABORT: Stopping due to --abort-on-failure"
            exit 1
        fi
        return 0
    fi
}

# Check if command exists
cmd_exists() {
    command -v "$1" &>/dev/null
}

# Get sudo (empty if already root)
get_sudo() {
    if [[ $EUID -eq 0 ]]; then
        echo ""
    else
        echo "sudo"
    fi
}

run_cmd_sudo() {
    local desc="$1"
    shift

    local sudo_cmd
    sudo_cmd=$(get_sudo)
    if [[ -n "$sudo_cmd" ]]; then
        run_cmd "$desc" "$sudo_cmd" "$@"
        return 0
    fi
    run_cmd "$desc" "$@"
}

# ============================================================
# Upstream installer verification (checksums.yaml)
# ============================================================

UPDATE_SECURITY_READY=false
update_require_security() {
    if [[ "${UPDATE_SECURITY_READY}" == "true" ]]; then
        return 0
    fi

    if [[ ! -f "$SCRIPT_DIR/security.sh" ]]; then
        return 1
    fi

    # shellcheck source=security.sh
    # shellcheck disable=SC1091  # runtime relative source
    source "$SCRIPT_DIR/security.sh"
    load_checksums || return 1

    UPDATE_SECURITY_READY=true
    return 0
}

# shellcheck disable=SC2329  # invoked indirectly via run_cmd()
update_run_verified_installer() {
    local tool="$1"
    shift || true

    if ! update_require_security; then
        echo "Security verification unavailable (missing $SCRIPT_DIR/security.sh or checksums.yaml)" >&2
        return 1
    fi

    local url="${KNOWN_INSTALLERS[$tool]:-}"
    local expected_sha256
    expected_sha256="$(get_checksum "$tool")"

    if [[ -z "$url" ]] || [[ -z "$expected_sha256" ]]; then
        echo "Missing checksum entry for $tool" >&2
        return 1
    fi

    verify_checksum "$url" "$expected_sha256" "$tool" | bash -s -- "$@"
}

# ============================================================
# Update Functions
# ============================================================

update_apt() {
    log_section "System Packages (apt)"

    if [[ "$UPDATE_APT" != "true" ]]; then
        log_item "skip" "apt update" "disabled via --no-apt"
        return 0
    fi

    # Check if apt/dpkg is available (Linux only)
    if ! command -v apt-get &>/dev/null; then
        log_item "skip" "apt" "not available (non-Debian system)"
        return 0
    fi

    # Check for apt lock
    if ! check_apt_lock; then
        return 0
    fi

    # Run apt update
    run_cmd_sudo "apt update" apt-get update -y

    # Get list of upgradable packages before upgrade
    local upgradable_list=""
    local upgrade_count=0
    if upgradable_list=$(apt list --upgradable 2>/dev/null | grep -v "^Listing"); then
        upgrade_count=$(echo "$upgradable_list" | grep -c . || echo 0)
        if [[ $upgrade_count -gt 0 ]]; then
            log_to_file "Upgradable packages ($upgrade_count):"
            log_to_file "$upgradable_list"
        fi
    fi

    if [[ $upgrade_count -eq 0 ]]; then
        log_item "ok" "apt upgrade" "all packages up to date"
    else
        log_to_file "Upgrading $upgrade_count packages..."
        run_cmd_sudo "apt upgrade ($upgrade_count packages)" apt-get upgrade -y
    fi

    run_cmd_sudo "apt autoremove" apt-get autoremove -y

    # Check if reboot is required (kernel updates, etc.)
    check_reboot_required
}

# Check if apt is locked by another process
check_apt_lock() {
    # Check for dpkg lock
    if [[ -f /var/lib/dpkg/lock-frontend ]]; then
        if fuser /var/lib/dpkg/lock-frontend &>/dev/null 2>&1; then
            log_item "fail" "apt locked" "dpkg lock held by another process"
            log_to_file "APT lock detected: /var/lib/dpkg/lock-frontend in use"
            if [[ "$ABORT_ON_FAILURE" == "true" ]]; then
                echo -e "${RED}Aborting: apt is locked by another process${NC}"
                echo "Try: sudo killall apt apt-get dpkg  (use with caution)"
                exit 1
            fi
            return 1
        fi
    fi

    # Check for apt/apt-get processes
    if pgrep -x "apt|apt-get|dpkg" &>/dev/null; then
        log_item "fail" "apt locked" "apt/dpkg process running"
        log_to_file "APT lock detected: apt/dpkg process already running"
        if [[ "$ABORT_ON_FAILURE" == "true" ]]; then
            echo -e "${RED}Aborting: another apt process is running${NC}"
            exit 1
        fi
        return 1
    fi

    # Check for unattended-upgrades
    if pgrep -x "unattended-upgr" &>/dev/null; then
        log_item "skip" "apt" "unattended-upgrades running, will retry later"
        log_to_file "Skipping apt: unattended-upgrades in progress"
        return 1
    fi

    return 0
}

# Check if system reboot is required after updates
check_reboot_required() {
    if [[ -f /var/run/reboot-required ]]; then
        log_item "warn" "Reboot required" "kernel or critical package updated"
        log_to_file "REBOOT REQUIRED: /var/run/reboot-required exists"

        if [[ -f /var/run/reboot-required.pkgs ]]; then
            local pkgs
            pkgs=$(cat /var/run/reboot-required.pkgs 2>/dev/null || echo "unknown")
            log_to_file "Packages requiring reboot: $pkgs"
            if [[ "$QUIET" != "true" ]]; then
                echo -e "       ${DIM}Packages: $pkgs${NC}"
            fi
        fi

        # Set a global flag for summary
        REBOOT_REQUIRED=true
    fi
}

update_bun() {
    log_section "Bun Runtime"

    local bun_bin="$HOME/.bun/bin/bun"

    if [[ ! -x "$bun_bin" ]]; then
        log_item "skip" "Bun" "not installed"
        return 0
    fi

    run_cmd "Bun self-upgrade" "$bun_bin" upgrade
}

update_agents() {
    log_section "Coding Agents"

    if [[ "$UPDATE_AGENTS" != "true" ]]; then
        log_item "skip" "agents update" "disabled via --no-agents"
        return 0
    fi

    local bun_bin="$HOME/.bun/bin/bun"

    if [[ ! -x "$bun_bin" ]]; then
        log_item "fail" "Bun not installed" "required for agent updates"
        return 0
    fi

    # Claude Code has its own update command
    if cmd_exists claude; then
        run_cmd "Claude Code" claude update
    else
        log_item "skip" "Claude Code" "not installed"
    fi

    # Codex CLI via bun
    if cmd_exists codex || [[ "$FORCE_MODE" == "true" ]]; then
        run_cmd "Codex CLI" "$bun_bin" install -g @openai/codex@latest
    else
        log_item "skip" "Codex CLI" "not installed (use --force to install)"
    fi

    # Gemini CLI via bun
    if cmd_exists gemini || [[ "$FORCE_MODE" == "true" ]]; then
        run_cmd "Gemini CLI" "$bun_bin" install -g @google/gemini-cli@latest
    else
        log_item "skip" "Gemini CLI" "not installed (use --force to install)"
    fi
}

update_cloud() {
    log_section "Cloud CLIs"

    if [[ "$UPDATE_CLOUD" != "true" ]]; then
        log_item "skip" "cloud CLIs update" "disabled via --no-cloud"
        return 0
    fi

    local bun_bin="$HOME/.bun/bin/bun"

    if [[ ! -x "$bun_bin" ]]; then
        log_item "fail" "Bun not installed" "required for cloud CLI updates"
        return 0
    fi

    # Wrangler
    if cmd_exists wrangler || [[ "$FORCE_MODE" == "true" ]]; then
        run_cmd "Wrangler (Cloudflare)" "$bun_bin" install -g wrangler@latest
    else
        log_item "skip" "Wrangler" "not installed"
    fi

    # Supabase
    if cmd_exists supabase || [[ "$FORCE_MODE" == "true" ]]; then
        run_cmd "Supabase CLI" "$bun_bin" install -g supabase@latest
    else
        log_item "skip" "Supabase CLI" "not installed"
    fi

    # Vercel
    if cmd_exists vercel || [[ "$FORCE_MODE" == "true" ]]; then
        run_cmd "Vercel CLI" "$bun_bin" install -g vercel@latest
    else
        log_item "skip" "Vercel CLI" "not installed"
    fi
}

update_rust() {
    log_section "Rust Toolchain"

    local rustup_bin="$HOME/.cargo/bin/rustup"

    if [[ ! -x "$rustup_bin" ]]; then
        log_item "skip" "Rust" "not installed"
        return 0
    fi

    run_cmd "Rust stable" "$rustup_bin" update stable
}

update_uv() {
    log_section "Python Tools (uv)"

    local uv_bin="$HOME/.local/bin/uv"

    if [[ ! -x "$uv_bin" ]]; then
        log_item "skip" "uv" "not installed"
        return 0
    fi

    run_cmd "uv self-update" "$uv_bin" self update
}

update_stack() {
    log_section "Dicklesworthstone Stack"

    if [[ "$UPDATE_STACK" != "true" ]]; then
        log_item "skip" "stack update" "disabled (use --stack to enable)"
        return 0
    fi

    if ! update_require_security; then
        log_item "fail" "stack updates" "security verification unavailable (missing security.sh/checksums.yaml)"
        return 0
    fi

    # NTM
    if cmd_exists ntm; then
        run_cmd "NTM" update_run_verified_installer ntm
    fi

    # MCP Agent Mail
    if [[ -d "$HOME/mcp_agent_mail" ]] || cmd_exists am; then
        run_cmd "MCP Agent Mail" update_run_verified_installer mcp_agent_mail --yes
    fi

    # UBS
    if cmd_exists ubs; then
        run_cmd "Ultimate Bug Scanner" update_run_verified_installer ubs --easy-mode
    fi

    # Beads Viewer
    if cmd_exists bv; then
        run_cmd "Beads Viewer" update_run_verified_installer bv
    fi

    # CASS
    if cmd_exists cass; then
        run_cmd "CASS" update_run_verified_installer cass --easy-mode --verify
    fi

    # CASS Memory
    if cmd_exists cm; then
        run_cmd "CASS Memory" update_run_verified_installer cm --easy-mode --verify
    fi

    # CAAM
    if cmd_exists caam; then
        run_cmd "CAAM" update_run_verified_installer caam
    fi

    # SLB
    if cmd_exists slb; then
        run_cmd "SLB" update_run_verified_installer slb
    fi
}

# ============================================================
# Summary
# ============================================================

print_summary() {
    # Log footer to file
    if [[ -n "$UPDATE_LOG_FILE" ]]; then
        {
            echo ""
            echo "==============================================="
            echo "Summary"
            echo "==============================================="
            echo "Updated: $SUCCESS_COUNT"
            echo "Skipped: $SKIP_COUNT"
            echo "Failed:  $FAIL_COUNT"
            if [[ "$REBOOT_REQUIRED" == "true" ]]; then
                echo "Reboot:  REQUIRED"
            fi
            echo ""
            echo "Completed: $(date -Iseconds)"
            echo "==============================================="
        } >> "$UPDATE_LOG_FILE"
    fi

    # Console output (respects quiet mode for success, always shows failures)
    if [[ "$QUIET" != "true" ]]; then
        echo ""
        echo "============================================================"
        echo -e "Summary: ${GREEN}$SUCCESS_COUNT updated${NC}, ${DIM}$SKIP_COUNT skipped${NC}, ${RED}$FAIL_COUNT failed${NC}"
        echo ""

        if [[ $FAIL_COUNT -eq 0 ]]; then
            echo -e "${GREEN}All updates completed successfully!${NC}"
        else
            echo -e "${YELLOW}Some updates failed. Check output above.${NC}"
        fi

        # Reboot warning
        if [[ "$REBOOT_REQUIRED" == "true" ]]; then
            echo ""
            echo -e "${YELLOW}${BOLD}⚠ System reboot required${NC}"
            echo -e "${DIM}Run: sudo reboot${NC}"
        fi

        if [[ "$DRY_RUN" == "true" ]]; then
            echo ""
            echo -e "${DIM}(dry-run mode - no changes were made)${NC}"
        fi

        # Show log location
        if [[ -n "$UPDATE_LOG_FILE" ]]; then
            echo ""
            echo -e "${DIM}Log: $UPDATE_LOG_FILE${NC}"
        fi
    elif [[ $FAIL_COUNT -gt 0 ]]; then
        # In quiet mode, still report failures
        echo ""
        echo -e "${RED}Update failed: $FAIL_COUNT error(s)${NC}"
        if [[ -n "$UPDATE_LOG_FILE" ]]; then
            echo -e "${DIM}See: $UPDATE_LOG_FILE${NC}"
        fi
    fi
}

# ============================================================
# CLI
# ============================================================

usage() {
    cat << 'EOF'
acfs update - Update all ACFS components

Usage:
  acfs update [options]

Options:
  --apt-only         Only update system packages
  --agents-only      Only update coding agents
  --cloud-only       Only update cloud CLIs
  --stack            Include Dicklesworthstone stack updates
  --no-apt           Skip apt updates
  --no-agents        Skip agent updates
  --no-cloud         Skip cloud CLI updates
  --force            Install missing tools
  --dry-run          Show what would be updated without making changes
  --yes, -y          Non-interactive mode (skip all prompts)
  --quiet, -q        Minimal output (only show errors)
  --verbose, -v      Show more details
  --abort-on-failure Stop immediately on first failure
  --continue         Continue after failures (default)
  --help, -h         Show this help

Examples:
  acfs update                  # Update apt, agents, and cloud CLIs
  acfs update --stack          # Include stack tools
  acfs update --agents-only    # Only update coding agents
  acfs update --dry-run        # Preview changes
  acfs update --yes --quiet    # Automated mode with minimal output
  acfs update --abort-on-failure --stack  # Stop on first error

What gets updated:
  - System packages (apt update/upgrade)
  - Bun runtime
  - Coding agents (Claude, Codex, Gemini)
  - Cloud CLIs (Wrangler, Supabase, Vercel)
  - Rust toolchain
  - uv (Python tools)
  - Dicklesworthstone stack (with --stack flag)

Logs:
  Update logs are saved to ~/.acfs/logs/updates/
EOF
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --apt-only)
                UPDATE_APT=true
                UPDATE_AGENTS=false
                UPDATE_CLOUD=false
                UPDATE_STACK=false
                shift
                ;;
            --agents-only)
                UPDATE_APT=false
                UPDATE_AGENTS=true
                UPDATE_CLOUD=false
                UPDATE_STACK=false
                shift
                ;;
            --cloud-only)
                UPDATE_APT=false
                UPDATE_AGENTS=false
                UPDATE_CLOUD=true
                UPDATE_STACK=false
                shift
                ;;
            --stack)
                UPDATE_STACK=true
                shift
                ;;
            --no-apt)
                UPDATE_APT=false
                shift
                ;;
            --no-agents)
                UPDATE_AGENTS=false
                shift
                ;;
            --no-cloud)
                UPDATE_CLOUD=false
                shift
                ;;
            --force)
                FORCE_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --quiet|-q)
                QUIET=true
                shift
                ;;
            --yes|-y)
                YES_MODE=true
                shift
                ;;
            --abort-on-failure)
                ABORT_ON_FAILURE=true
                shift
                ;;
            --continue)
                ABORT_ON_FAILURE=false
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                echo "Try: acfs update --help" >&2
                exit 1
                ;;
        esac
    done

    # Initialize logging
    init_logging

    # Header
    if [[ "$QUIET" != "true" ]]; then
        echo ""
        echo -e "${BOLD}ACFS Update v$ACFS_VERSION${NC}"
        echo -e "User: $(whoami)"
        echo -e "Date: $(date '+%Y-%m-%d %H:%M')"

        if [[ "$DRY_RUN" == "true" ]]; then
            echo -e "${YELLOW}Mode: dry-run${NC}"
        fi
    fi

    # Run updates
    update_apt
    update_bun
    update_agents
    update_cloud
    update_rust
    update_uv
    update_stack

    # Summary
    print_summary

    # Exit code
    if [[ $FAIL_COUNT -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

main "$@"
