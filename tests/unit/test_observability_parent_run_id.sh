#!/usr/bin/env bash
# ============================================================
# observability.sh parent_run_id propagation test
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/acfs-observability-test.XXXXXX")"

export ACFS_HOME="$tmp_root/.acfs"
export ACFS_RUN_ID="child-run-123"
export ACFS_PARENT_RUN_ID="host-run-abc"
export ACFS_INSTALL_START="$(date +%s)"

# shellcheck source=scripts/lib/observability.sh
source "$REPO_ROOT/scripts/lib/observability.sh"

_observability_init
_emit_event "stage_start" "test_phase" "mode=test"

log_file="$ACFS_HOME/logs/install/${ACFS_RUN_ID}.jsonl"

if [[ ! -f "$log_file" ]]; then
    echo "✖ expected log file not found: $log_file" >&2
    exit 1
fi

if grep -q '"parent_run_id":"host-run-abc"' "$log_file"; then
    echo "✓ parent_run_id included in emitted events"
else
    echo "✖ parent_run_id missing from emitted event JSON" >&2
    exit 1
fi
