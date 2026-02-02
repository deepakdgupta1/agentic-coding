#!/usr/bin/env bash
# shellcheck disable=SC1091
# ============================================================
# ACFS Status - One-line health summary
# Quick check: runs in <100ms, no network calls by default
#
# Exit codes:
#   0 - Healthy (all core tools present, state valid)
#   1 - Warnings (some optional tools missing, outdated state)
#   2 - Errors (broken state, missing critical tools)
#
# Usage:
#   acfs status                # Human-readable one-liner
#   acfs status --json         # Machine-readable JSON
#   acfs status --short        # Minimal output for shell prompts
#   acfs status --check-updates  # Include network-based update check
# ============================================================

# --- PATH setup (matches doctor.sh) ---
_status_ensure_path() {
    local dir
    for dir in \
        "$HOME/.local/bin" \
        "$HOME/.bun/bin" \
        "$HOME/.cargo/bin" \
        "$HOME/go/bin" \
        "$HOME/.atuin/bin"; do
        [[ -d "$dir" ]] || continue
        case ":$PATH:" in
            *":$dir:"*) ;;
            *) export PATH="$dir:$PATH" ;;
        esac
    done
}
_status_ensure_path

# --- Defaults ---
_STATUS_JSON=false
_STATUS_SHORT=false
_STATUS_CHECK_UPDATES=false
_ACFS_HOME="${ACFS_HOME:-$HOME/.acfs}"

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)           _STATUS_JSON=true; shift ;;
        --short)          _STATUS_SHORT=true; shift ;;
        --check-updates)  _STATUS_CHECK_UPDATES=true; shift ;;
        --help|-h)
            echo "Usage: acfs status [--json] [--short] [--check-updates]"
            echo ""
            echo "Quick one-line health summary."
            echo ""
            echo "Options:"
            echo "  --json            Machine-readable JSON output"
            echo "  --short           Minimal output for shell prompt integration"
            echo "  --check-updates   Include network-based update checks (slower)"
            echo ""
            echo "Exit codes:"
            echo "  0  Healthy"
            echo "  1  Warnings (outdated, minor issues)"
            echo "  2  Errors (broken state, missing critical tools)"
            echo ""
            echo "Examples:"
            echo "  acfs status                     # Quick health check"
            echo "  acfs status --json              # JSON for scripts"
            echo "  acfs status --short             # For shell prompts"
            echo "  acfs status --check-updates     # Check for ACFS updates"
            echo ""
            echo "Shell prompt integration:"
            echo "  PROMPT='\$(acfs status --short 2>/dev/null) \w \$ '"
            exit 0
            ;;
        *) shift ;;
    esac
done

# --- Collect checks ---
_warnings=()
_errors=()
_tool_count=0

# Core tools: missing any of these is a warning
_CORE_TOOLS=(zsh git tmux bun cargo go rg claude)
# Optional tools: counted but not warned about
_OPTIONAL_TOOLS=(codex gemini gh uv fzf zoxide atuin bat lsd ntm bv br cass cm slb ubs dcg)

# 1. ACFS_HOME check
if [[ ! -d "$_ACFS_HOME" ]]; then
    _errors+=("ACFS_HOME missing")
fi

# 2. State file check
_state_file="$_ACFS_HOME/state.json"
if [[ ! -f "$_state_file" ]]; then
    _errors+=("state file missing")
elif [[ ! -s "$_state_file" ]]; then
    _errors+=("state file empty")
fi

# 3. Count tools in PATH
for cmd in "${_CORE_TOOLS[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        ((_tool_count++))
    else
        _warnings+=("missing: $cmd")
    fi
done

for cmd in "${_OPTIONAL_TOOLS[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        ((_tool_count++))
    fi
done

# 4. Last update timestamp
_last_update_ts=""
_last_update_human=""
if [[ -f "$_state_file" ]]; then
    if command -v jq &>/dev/null; then
        _last_update_ts=$(jq -r '
            .last_completed_phase_ts //
            .updated_at //
            empty
        ' "$_state_file" 2>/dev/null) || true
    fi
    if [[ -z "$_last_update_ts" ]]; then
        _last_update_ts=$(sed -n 's/.*"updated_at"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
            "$_state_file" 2>/dev/null | head -n1)
    fi
fi

if [[ -n "$_last_update_ts" ]]; then
    _last_epoch=$(date -d "$_last_update_ts" +%s 2>/dev/null) || _last_epoch=0
    _now_epoch=$(date +%s)
    if [[ "$_last_epoch" -gt 0 ]]; then
        _age_secs=$((_now_epoch - _last_epoch))
        if [[ $_age_secs -lt 3600 ]]; then
            _last_update_human="$((_age_secs / 60))m ago"
        elif [[ $_age_secs -lt 86400 ]]; then
            _last_update_human="$((_age_secs / 3600))h ago"
        else
            _last_update_human="$((_age_secs / 86400))d ago"
        fi
    fi
fi

# 5. Optional: network-based update check
_update_available=""
if [[ "$_STATUS_CHECK_UPDATES" == "true" ]]; then
    if [[ -f "$_ACFS_HOME/VERSION" ]]; then
        _local_version=$(cat "$_ACFS_HOME/VERSION" 2>/dev/null) || _local_version=""
        _remote_version=$(timeout 5 curl -fsSL \
            "https://raw.githubusercontent.com/deepakdgupta1/agentic-coding/main/VERSION" \
            2>/dev/null) || _remote_version=""
        if [[ -n "$_remote_version" ]] && [[ -n "$_local_version" ]] \
           && [[ "$_remote_version" != "$_local_version" ]]; then
            _update_available="${_local_version} -> ${_remote_version}"
            _warnings+=("update available: $_update_available")
        fi
    fi
fi

# --- Determine overall status ---
_exit_code=0
_status_word="OK"

if [[ ${#_errors[@]} -gt 0 ]]; then
    _exit_code=2
    _status_word="ERROR"
elif [[ ${#_warnings[@]} -gt 0 ]]; then
    _exit_code=1
    _status_word="WARN"
fi

# --- JSON escape helper (no jq dependency) ---
_json_escape() {
    local s="$1"
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
    s=${s//$'\n'/\\n}
    s=${s//$'\r'/\\r}
    s=${s//$'\t'/\\t}
    printf '%s' "$s"
}

# --- Output ---
if [[ "$_STATUS_JSON" == "true" ]]; then
    # Build JSON arrays without requiring jq
    _warn_items=""
    for w in "${_warnings[@]+"${_warnings[@]}"}"; do
        [[ -z "$w" ]] && continue
        [[ -n "$_warn_items" ]] && _warn_items+=","
        _warn_items+="\"$(_json_escape "$w")\""
    done

    _err_items=""
    for e in "${_errors[@]+"${_errors[@]}"}"; do
        [[ -z "$e" ]] && continue
        [[ -n "$_err_items" ]] && _err_items+=","
        _err_items+="\"$(_json_escape "$e")\""
    done

    _last_update_json="null"
    if [[ -n "$_last_update_ts" ]]; then
        _last_update_json="\"$(_json_escape "$_last_update_ts")\""
    fi

    _update_json=""
    if [[ -n "$_update_available" ]]; then
        _update_json=",\"update_available\":\"$(_json_escape "$_update_available")\""
    fi

    printf '{"status":"%s","tools":%d,"last_update":%s,"warnings":[%s],"errors":[%s]%s}\n' \
        "${_status_word,,}" "$_tool_count" "$_last_update_json" \
        "$_warn_items" "$_err_items" "$_update_json"

elif [[ "$_STATUS_SHORT" == "true" ]]; then
    # Minimal output for shell prompts
    case $_exit_code in
        0) echo "OK" ;;
        1) echo "WARN" ;;
        2) echo "ERR" ;;
    esac

else
    # Human-readable one-liner
    _msg="ACFS $_status_word: $_tool_count tools"
    [[ -n "$_last_update_human" ]] && _msg="$_msg, last update $_last_update_human"

    if [[ ${#_errors[@]} -gt 0 ]]; then
        _msg="$_msg, ${#_errors[@]} error(s)"
    fi

    if [[ ${#_warnings[@]} -gt 0 ]]; then
        _missing_count=0
        for w in "${_warnings[@]}"; do
            [[ "$w" == missing:* ]] && ((_missing_count++))
        done
        [[ $_missing_count -gt 0 ]] && _msg="$_msg, $_missing_count missing tool(s)"
        [[ -n "$_update_available" ]] && _msg="$_msg, update available"
    fi

    case $_exit_code in
        0) printf '\033[0;32m%s\033[0m\n' "$_msg" ;;
        1) printf '\033[0;33m%s\033[0m\n' "$_msg" ;;
        2) printf '\033[0;31m%s\033[0m\n' "$_msg" ;;
    esac
fi

exit $_exit_code
