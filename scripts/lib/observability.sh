#!/usr/bin/env bash
# ============================================================
# ACFS Observability — Structured Event Logging
#
# Emits JSONL events for install lifecycle, failures, and
# resume operations. Each event includes a run_id for
# correlation across logs and support bundles.
#
# Events are written to: ~/.acfs/logs/install/<run_id>.jsonl
#
# Event types:
#   stage_start   — Phase execution begins
#   stage_end     — Phase execution completed (success or failure)
#   check_failed  — Pre/postcondition assertion failed
#   cmd_failed    — Individual command failed (from try_step)
#   resume        — Installation resumed from checkpoint
#   install_start — Installation run started
#   install_end   — Installation run finished
#
# NOTE: Do not enable strict mode here. This file is sourced
# by other scripts and must not leak set -euo pipefail.
# ============================================================

# Generate unique run ID if not already set
ACFS_RUN_ID="${ACFS_RUN_ID:-$(date +%Y%m%d_%H%M%S)_$$}"
export ACFS_RUN_ID

# Install start timestamp (epoch seconds)
ACFS_INSTALL_START="${ACFS_INSTALL_START:-$(date +%s)}"
export ACFS_INSTALL_START

# Event log path (set after ACFS_HOME is known)
ACFS_EVENT_LOG="${ACFS_EVENT_LOG:-}"

# Initialize the event log file
# Call this after ACFS_HOME is set
_observability_init() {
    if [[ -z "${ACFS_HOME:-}" ]]; then
        return 0
    fi

    local log_dir="$ACFS_HOME/logs/install"
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" 2>/dev/null || true
        if [[ $EUID -eq 0 ]] && [[ -n "${TARGET_USER:-}" ]] && [[ "$TARGET_USER" != "root" ]]; then
            chown "$TARGET_USER:$TARGET_USER" "$log_dir" 2>/dev/null || true
        fi
    fi

    ACFS_EVENT_LOG="$log_dir/${ACFS_RUN_ID}.jsonl"
    export ACFS_EVENT_LOG
}

# ============================================================
# Event Emitter
# ============================================================

# Emit a structured JSONL event
#
# Usage: _emit_event <event_type> <stage_id> [key=value ...]
#
# Examples:
#   _emit_event "stage_start" "languages"
#   _emit_event "stage_end" "languages" "exit_code=0" "duration=42"
#   _emit_event "cmd_failed" "languages" "cmd=bun install" "exit_code=1" "stderr=ENOMEM"
#   _emit_event "check_failed" "agents" "type=precondition"
#
_emit_event() {
    local event_type="${1:-unknown}"
    local stage_id="${2:-}"
    shift 2 2>/dev/null || true

    # Skip if no log file configured
    if [[ -z "${ACFS_EVENT_LOG:-}" ]]; then
        # Try to initialize if ACFS_HOME is available
        if [[ -n "${ACFS_HOME:-}" ]]; then
            _observability_init
        fi
        # Still no log file? Silently skip.
        if [[ -z "${ACFS_EVENT_LOG:-}" ]]; then
            return 0
        fi
    fi

    local now elapsed_s
    now="$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)"
    elapsed_s=$(( $(date +%s) - ${ACFS_INSTALL_START:-$(date +%s)} ))

    # Build JSON using jq if available, otherwise fall back to printf
    local json=""
    if command -v jq &>/dev/null; then
        json=$(jq -n -c \
            --arg run_id "$ACFS_RUN_ID" \
            --arg event "$event_type" \
            --arg stage "$stage_id" \
            --arg ts "$now" \
            --argjson elapsed "$elapsed_s" \
            '{run_id:$run_id, event:$event, stage:$stage, ts:$ts, elapsed_s:$elapsed}' 2>/dev/null)

        # Append extra key=value pairs
        for kv in "$@"; do
            local k="${kv%%=*}"
            local v="${kv#*=}"
            json=$(echo "$json" | jq -c --arg k "$k" --arg v "$v" '.[$k]=$v' 2>/dev/null) || true
        done
    else
        # Fallback: manual JSON construction (no special char escaping)
        json="{\"run_id\":\"$ACFS_RUN_ID\",\"event\":\"$event_type\",\"stage\":\"$stage_id\",\"ts\":\"$now\",\"elapsed_s\":$elapsed_s"
        for kv in "$@"; do
            local k="${kv%%=*}"
            local v="${kv#*=}"
            json="$json,\"$k\":\"$v\""
        done
        json="$json}"
    fi

    # Append to log file (non-blocking, best-effort)
    echo "$json" >> "$ACFS_EVENT_LOG" 2>/dev/null || true
}

# ============================================================
# Failure Summary
# ============================================================

# Print a human-readable failure summary box
# Called after all phases when there are critical failures
#
# Usage: _print_failure_summary <phase_id> <phase_name> <exit_code> <stderr_snippet>
#
_print_failure_summary() {
    local phase_id="${1:-unknown}"
    local phase_name="${2:-$phase_id}"
    local exit_code="${3:-1}"
    local stderr_snippet="${4:-}"

    # Classify the error
    local error_class="unknown"
    if type -t classify_error &>/dev/null; then
        error_class="$(classify_error "$exit_code" "$stderr_snippet")"
    fi

    # Get remediation hint
    local remediation="Review logs and retry"
    if type -t get_remediation &>/dev/null; then
        remediation="$(get_remediation "$error_class")"
    fi

    echo "" >&2
    echo "┌─ Failure Summary ──────────────────────────────────────────┐" >&2
    echo "│ Run ID:      $ACFS_RUN_ID" >&2
    echo "│ Failed at:   Phase $phase_id ($phase_name)" >&2
    echo "│ Exit code:   $exit_code" >&2
    echo "│ Error class: $error_class" >&2
    echo "│ Next step:   $remediation" >&2
    if [[ -n "${ACFS_EVENT_LOG:-}" ]]; then
        echo "│ Full log:    $ACFS_EVENT_LOG" >&2
    fi
    echo "└─────────────────────────────────────────────────────────────┘" >&2
    echo "" >&2

    # Emit structured event
    _emit_event "install_end" "$phase_id" \
        "status=failed" \
        "exit_code=$exit_code" \
        "error_class=$error_class" \
        "remediation=$remediation"
}
