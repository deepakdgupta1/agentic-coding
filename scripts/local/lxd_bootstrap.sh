#!/usr/bin/env bash
# ============================================================
# ACFS Local - LXD Bootstrap Script
#
# Prepares the host system for ACFS local desktop installation.
# Run this first if LXD is not already configured.
#
# Usage:
#   ./scripts/local/lxd_bootstrap.sh
#   ./scripts/local/lxd_bootstrap.sh --check
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source sandbox library for init function
# shellcheck source=scripts/lib/sandbox.sh
source "$REPO_ROOT/scripts/lib/sandbox.sh"

# ============================================================
# Colors
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================
# Check Mode
# ============================================================

check_prerequisites() {
    local all_ok=true

    echo ""
    echo "═══ ACFS Local Prerequisites Check ═══"
    echo ""

    # Check OS
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        if [[ "${ID:-}" == "ubuntu" ]]; then
            local version="${VERSION_ID:-0}"
            local major="${version%%.*}"
            if [[ "$major" -ge 22 ]]; then
                echo -e "${GREEN}✓${NC} Ubuntu $VERSION_ID detected"
            else
                echo -e "${YELLOW}⚠${NC} Ubuntu $VERSION_ID detected (22.04+ recommended)"
            fi
        else
            echo -e "${YELLOW}⚠${NC} Non-Ubuntu OS: $ID (may work but not tested)"
        fi
    else
        echo -e "${RED}✖${NC} Cannot detect OS"
        all_ok=false
    fi

    # Check snap
    if command -v snap &>/dev/null; then
        echo -e "${GREEN}✓${NC} snap available"
    else
        echo -e "${RED}✖${NC} snap not installed (required for LXD)"
        echo "    Install: sudo apt install snapd"
        all_ok=false
    fi

    # Check LXD
    if command -v lxc &>/dev/null; then
        if lxc info &>/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} LXD installed and initialized"
        else
            echo -e "${YELLOW}⚠${NC} LXD installed but not initialized"
            echo "    Will be initialized during setup"
        fi
    else
        echo -e "${YELLOW}○${NC} LXD not installed"
        echo "    Will be installed during setup"
    fi

    # Check lxd group membership
    if groups | grep -q '\blxd\b'; then
        echo -e "${GREEN}✓${NC} User in lxd group"
    else
        echo -e "${YELLOW}○${NC} User not in lxd group"
        echo "    Will be added during setup (requires logout/login)"
    fi

    # Check disk space
    local free_gb
    free_gb=$(df -BG "$HOME" | tail -1 | awk '{print $4}' | tr -d 'G')
    if [[ "$free_gb" -ge 10 ]]; then
        echo -e "${GREEN}✓${NC} Disk space: ${free_gb}GB free"
    else
        echo -e "${YELLOW}⚠${NC} Disk space: ${free_gb}GB free (10GB+ recommended)"
    fi

    # Check memory
    local mem_gb
    mem_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [[ "$mem_gb" -ge 4 ]]; then
        echo -e "${GREEN}✓${NC} Memory: ${mem_gb}GB RAM"
    else
        echo -e "${YELLOW}⚠${NC} Memory: ${mem_gb}GB RAM (4GB+ recommended)"
    fi

    echo ""
    if [[ "$all_ok" == "true" ]]; then
        echo -e "${GREEN}All prerequisites met!${NC}"
        return 0
    else
        echo -e "${RED}Some prerequisites missing.${NC}"
        return 1
    fi
}

# ============================================================
# Bootstrap
# ============================================================

bootstrap() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           ACFS Local - LXD Bootstrap                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""

    # Run prerequisites check first
    if ! check_prerequisites; then
        echo ""
        echo "Please fix the prerequisites above before continuing."
        exit 1
    fi

    echo ""
    echo "Proceeding with LXD setup..."
    echo ""

    # Initialize LXD
    acfs_sandbox_init_lxd

    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Bootstrap Complete!                        ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║                                                               ║"
    echo "║  Next step: Create your ACFS sandbox                         ║"
    echo "║                                                               ║"
    echo "║    acfs-local create                                         ║"
    echo "║                                                               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""

    # Check if user needs to re-login for group membership
    if ! groups | grep -q '\blxd\b'; then
        echo -e "${YELLOW}NOTE:${NC} You were added to the 'lxd' group."
        echo "      Log out and back in, OR run: newgrp lxd"
        echo "      Then run: acfs-local create"
        echo ""
    fi
}

# ============================================================
# Main
# ============================================================

main() {
    case "${1:-}" in
        --check|-c)
            check_prerequisites
            ;;
        --help|-h)
            echo "Usage: $0 [--check]"
            echo ""
            echo "Options:"
            echo "  --check, -c   Check prerequisites without installing"
            echo "  --help, -h    Show this help"
            ;;
        *)
            bootstrap
            ;;
    esac
}

main "$@"
