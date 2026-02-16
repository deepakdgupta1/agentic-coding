#!/usr/bin/env bash
# ============================================================
# ACFS Stage Contract — Phase Pre/Postcondition Declarations
#
# Defines what each installation phase requires before running
# (preconditions) and what it must produce after completing
# (postconditions). Called from _run_phase_with_report() and
# run_phase() to fail fast on misconfiguration and detect drift.
#
# Usage:
#   source scripts/lib/stage_contract.sh
#   _run_phase_preconditions "languages"   # returns 0 or 1
#   _run_phase_postconditions "languages"  # returns 0 or 1
#
# NOTE: Do not enable strict mode here. This file is sourced
# by other scripts and must not leak set -euo pipefail.
# ============================================================

# ============================================================
# Phase Precondition Declarations
# ============================================================
# Space-separated list of checker function names per phase.
# Each checker returns 0 (pass) or 1 (fail).

declare -gA PHASE_PRECONDITIONS=(
    [user_setup]="_pre_identity"
    [filesystem]="_pre_identity"
    [shell_setup]="_pre_identity _pre_acfs_home"
    [cli_tools]="_pre_identity _pre_acfs_home _pre_network"
    [languages]="_pre_identity _pre_acfs_home _pre_network _pre_bin_curl _pre_bin_git"
    [agents]="_pre_identity _pre_acfs_home _pre_network _pre_bin_bun"
    [cloud_db]="_pre_identity _pre_acfs_home _pre_network"
    [stack]="_pre_identity _pre_acfs_home _pre_network _pre_bin_bun"
    [finalize]="_pre_identity _pre_acfs_home _pre_onboard_source"
)

# ============================================================
# Phase Postcondition Declarations
# ============================================================
# Postconditions verify that a phase produced its expected outputs.
# Used both after execution and during resume (to verify completed
# phases haven't drifted before skipping).

declare -gA PHASE_POSTCONDITIONS=(
    [user_setup]="_post_user_exists _post_sudo_configured"
    [filesystem]="_post_dir_acfs_home _post_dir_local_bin"
    [shell_setup]="_post_bin_zsh"
    [cli_tools]="_post_bin_rg _post_bin_fd _post_bin_fzf _post_bin_gum"
    [languages]="_post_bin_bun _post_bin_uv _post_bin_cargo _post_bin_go"
    [agents]="_post_bin_claude"
    [cloud_db]="_post_optional"
    [stack]="_post_bin_ntm"
    [finalize]="_post_bin_onboard _post_file_dashboard"
)

# ============================================================
# Phase Timeouts (seconds)
# ============================================================

declare -gA PHASE_TIMEOUTS=(
    [user_setup]=60
    [filesystem]=60
    [shell_setup]=120
    [cli_tools]=300
    [languages]=600
    [agents]=600
    [cloud_db]=600
    [stack]=600
    [finalize]=120
)

# ============================================================
# Precondition Checker Functions
# ============================================================

# Identity: TARGET_USER and TARGET_HOME are set and consistent with passwd
_pre_identity() {
    local failures=0

    if [[ -z "${TARGET_USER:-}" ]]; then
        _contract_fail "TARGET_USER is empty"
        ((failures += 1))
    fi

    if [[ -z "${TARGET_HOME:-}" || "${TARGET_HOME:-}" == "/" ]]; then
        _contract_fail "TARGET_HOME is invalid ('${TARGET_HOME:-<empty>}')"
        ((failures += 1))
    fi

    # Cross-check against passwd entry
    if [[ -n "${TARGET_USER:-}" ]] && command -v getent &>/dev/null; then
        local pw_home
        pw_home="$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)"
        if [[ -n "$pw_home" && "$pw_home" != "${TARGET_HOME:-}" ]]; then
            _contract_fail "TARGET_HOME=${TARGET_HOME} mismatches passwd ($pw_home)"
            ((failures += 1))
        fi
    fi

    [[ $failures -eq 0 ]]
}

# ACFS_HOME directory exists and is writable
_pre_acfs_home() {
    if [[ -z "${ACFS_HOME:-}" ]]; then
        _contract_fail "ACFS_HOME is not set"
        return 1
    fi
    if [[ ! -d "$ACFS_HOME" ]]; then
        _contract_fail "ACFS_HOME=$ACFS_HOME does not exist"
        return 1
    fi
    return 0
}

# Network connectivity (warn-only — some installs work from cache)
_pre_network() {
    if timeout 5 bash -c 'exec 3<>/dev/tcp/1.1.1.1/443' 2>/dev/null; then
        return 0
    fi
    if timeout 5 bash -c 'exec 3<>/dev/tcp/8.8.8.8/53' 2>/dev/null; then
        return 0
    fi
    _contract_warn "No network connectivity detected (install may fail if not cached)"
    return 0  # Warning only, don't block
}

# Binary exists: check in PATH and TARGET_HOME/.local/bin
_pre_check_bin() {
    local bin_name="$1"
    # Check PATH first
    if command -v "$bin_name" &>/dev/null; then
        return 0
    fi
    # Check TARGET_HOME bins
    if [[ -x "${TARGET_HOME:-}/.local/bin/$bin_name" ]]; then
        return 0
    fi
    # Check common install locations
    if [[ -x "${TARGET_HOME:-}/.bun/bin/$bin_name" ]]; then
        return 0
    fi
    if [[ -x "${TARGET_HOME:-}/.cargo/bin/$bin_name" ]]; then
        return 0
    fi
    _contract_fail "Required binary '$bin_name' not found"
    return 1
}

# Named binary preconditions (dispatched from declarations)
_pre_bin_curl() { _pre_check_bin "curl"; }
_pre_bin_git()  { _pre_check_bin "git"; }
_pre_bin_bun()  { _pre_check_bin "bun"; }

# Onboard source script is reachable
_pre_onboard_source() {
    if [[ -n "${ACFS_BOOTSTRAP_DIR:-}" && -f "$ACFS_BOOTSTRAP_DIR/packages/onboard/onboard.sh" ]]; then
        return 0
    fi
    if [[ -n "${SCRIPT_DIR:-}" && -f "$SCRIPT_DIR/packages/onboard/onboard.sh" ]]; then
        return 0
    fi
    _contract_warn "onboard.sh source not found locally (will try download)"
    return 0  # Warning only
}

# ============================================================
# Postcondition Checker Functions
# ============================================================

# User exists in the system
_post_user_exists() {
    if ! id "$TARGET_USER" &>/dev/null; then
        _contract_fail "User '$TARGET_USER' does not exist after user_setup phase"
        return 1
    fi
    return 0
}

# Sudo is configured for TARGET_USER
_post_sudo_configured() {
    # Check if user is root (no sudo needed) or in sudo/admin group
    if [[ "$TARGET_USER" == "root" ]]; then
        return 0
    fi
    if id -nG "$TARGET_USER" 2>/dev/null | grep -qw "sudo"; then
        return 0
    fi
    if id -nG "$TARGET_USER" 2>/dev/null | grep -qw "admin"; then
        return 0
    fi
    # Check sudoers file
    if [[ -f "/etc/sudoers.d/$TARGET_USER" ]] || [[ -f "/etc/sudoers.d/90-$TARGET_USER" ]]; then
        return 0
    fi
    _contract_warn "Sudo configuration for '$TARGET_USER' could not be verified"
    return 0  # Warn only — sudoers can be configured many ways
}

# Directory postconditions
_post_dir_acfs_home() {
    if [[ ! -d "${ACFS_HOME:-}" ]]; then
        _contract_fail "ACFS_HOME=$ACFS_HOME not created after filesystem phase"
        return 1
    fi
    return 0
}

_post_dir_local_bin() {
    if [[ ! -d "${TARGET_HOME:-}/.local/bin" ]]; then
        _contract_fail "$TARGET_HOME/.local/bin not created after filesystem phase"
        return 1
    fi
    return 0
}

# Binary postconditions — check that a binary is executable
_post_check_bin() {
    local bin_name="$1"
    if command -v "$bin_name" &>/dev/null; then
        return 0
    fi
    if [[ -x "${TARGET_HOME:-}/.local/bin/$bin_name" ]]; then
        return 0
    fi
    if [[ -x "${TARGET_HOME:-}/.bun/bin/$bin_name" ]]; then
        return 0
    fi
    if [[ -x "${TARGET_HOME:-}/.cargo/bin/$bin_name" ]]; then
        return 0
    fi
    if [[ -x "/usr/local/go/bin/$bin_name" ]]; then
        return 0
    fi
    if [[ -x "${TARGET_HOME:-}/go/bin/$bin_name" ]]; then
        return 0
    fi
    _contract_fail "Binary '$bin_name' not found after phase completion"
    return 1
}

# Named binary postconditions
_post_bin_zsh()     { _post_check_bin "zsh"; }
_post_bin_rg()      { _post_check_bin "rg"; }
_post_bin_fd()      { _post_check_bin "fd"; }
_post_bin_fzf()     { _post_check_bin "fzf"; }
_post_bin_gum()     { _post_check_bin "gum"; }
_post_bin_bun()     { _post_check_bin "bun"; }
_post_bin_uv()      { _post_check_bin "uv"; }
_post_bin_cargo()   { _post_check_bin "cargo"; }
_post_bin_go()      { _post_check_bin "go"; }
_post_bin_claude()  { _post_check_bin "claude"; }
_post_bin_ntm()     { _post_check_bin "ntm"; }
_post_bin_onboard() { _post_check_bin "onboard"; }

# File postconditions
_post_file_dashboard() {
    if [[ -f "${ACFS_HOME:-}/scripts/lib/dashboard.sh" ]]; then
        return 0
    fi
    _contract_fail "dashboard.sh not found at $ACFS_HOME/scripts/lib/dashboard.sh"
    return 1
}

# Optional phase (always passes)
_post_optional() {
    return 0
}

# ============================================================
# Runner Functions (called from install.sh orchestration)
# ============================================================

# Run all preconditions for a phase
# Usage: _run_phase_preconditions "phase_id"
# Returns: 0 if all pass, 1 if any fail
_run_phase_preconditions() {
    local phase_id="$1"
    local checks="${PHASE_PRECONDITIONS[$phase_id]:-}"

    if [[ -z "$checks" ]]; then
        return 0  # No preconditions defined
    fi

    local failures=0
    for check in $checks; do
        if declare -f "$check" &>/dev/null; then
            if ! "$check"; then
                ((failures += 1))
            fi
        else
            _contract_warn "Precondition checker '$check' not found (skipping)"
        fi
    done

    if [[ $failures -gt 0 ]]; then
        _contract_fail "Precondition check failed for phase '$phase_id' ($failures failure(s))"
        return 1
    fi
    return 0
}

# Run all postconditions for a phase
# Usage: _run_phase_postconditions "phase_id"
# Returns: 0 if all pass, 1 if any fail
_run_phase_postconditions() {
    local phase_id="$1"
    local checks="${PHASE_POSTCONDITIONS[$phase_id]:-}"

    if [[ -z "$checks" ]]; then
        return 0  # No postconditions defined
    fi

    local failures=0
    for check in $checks; do
        if declare -f "$check" &>/dev/null; then
            if ! "$check"; then
                ((failures += 1))
            fi
        else
            _contract_warn "Postcondition checker '$check' not found (skipping)"
        fi
    done

    if [[ $failures -gt 0 ]]; then
        _contract_fail "Postcondition check failed for phase '$phase_id' ($failures failure(s))"
        return 1
    fi
    return 0
}

# Get timeout for a phase (in seconds)
# Usage: _get_phase_timeout "phase_id"
# Outputs: timeout in seconds
_get_phase_timeout() {
    local phase_id="$1"
    echo "${PHASE_TIMEOUTS[$phase_id]:-600}"
}

# ============================================================
# Output Helpers
# ============================================================

_contract_fail() {
    local msg="$1"
    if declare -f log_error &>/dev/null; then
        log_error "Stage contract: $msg"
    else
        echo "ERROR: Stage contract: $msg" >&2
    fi
}

_contract_warn() {
    local msg="$1"
    if declare -f log_warn &>/dev/null; then
        log_warn "Stage contract: $msg"
    else
        echo "WARNING: Stage contract: $msg" >&2
    fi
}
