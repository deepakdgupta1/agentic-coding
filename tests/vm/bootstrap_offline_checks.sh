#!/usr/bin/env bash
# ============================================================
# ACFS Bootstrap - Offline Simulation Test
#
# Validates the curl|bash bootstrap path without network by
# serving a local archive via a stubbed curl binary.
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

log() {
  echo "[bootstrap-offline] $*" >&2
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $1" >&2
    exit 1
  fi
}

require_cmd tar
require_cmd bash
require_cmd grep
require_cmd cp
require_cmd mktemp

create_archive() {
  local archive_path="$1"
  log "Creating archive: $archive_path"
  tar -czf "$archive_path" -C "$REPO_ROOT" \
    --transform 's,^,acfs-offline/,' \
    scripts/lib \
    scripts/generated \
    scripts/preflight.sh \
    acfs \
    checksums.yaml \
    acfs.manifest.yaml
}

create_bad_archive() {
  local good_archive="$1"
  local bad_archive="$2"
  local bad_dir
  bad_dir="$(mktemp -d /tmp/acfs-offline-bad.XXXXXX)"

  log "Creating bad archive: $bad_archive"
  tar -xzf "$good_archive" -C "$bad_dir"
  printf '\n# bootstrap mismatch\n' >> "$bad_dir/acfs-offline/acfs.manifest.yaml"
  tar -czf "$bad_archive" -C "$bad_dir" acfs-offline
}

create_stub_curl() {
  local stub_dir
  stub_dir="$(mktemp -d /tmp/acfs-curl-stub.XXXXXX)"

  cat > "$stub_dir/curl" <<'CURL'
#!/usr/bin/env bash
set -euo pipefail

for arg in "$@"; do
  if [[ "$arg" == "--help" ]]; then
    echo "--proto"
    exit 0
  fi
  if [[ "$arg" == "--help"* ]]; then
    echo "--proto"
    exit 0
  fi
done

out=""
prev=""
for arg in "$@"; do
  if [[ "$prev" == "-o" ]]; then
    out="$arg"
    break
  fi
  prev="$arg"
done

if [[ -z "$out" ]]; then
  echo "stub curl: missing -o" >&2
  exit 1
fi

if [[ -z "${ACFS_TEST_ARCHIVE:-}" ]]; then
  echo "stub curl: ACFS_TEST_ARCHIVE not set" >&2
  exit 1
fi

cp "$ACFS_TEST_ARCHIVE" "$out"
CURL

  chmod +x "$stub_dir/curl"
  echo "$stub_dir"
}

run_bootstrap() {
  local archive_path="$1"
  local label="$2"
  local expect_failure="${3:-false}"

  log "$label: running bootstrap (archive=$archive_path)"
  local stub_dir
  stub_dir="$(create_stub_curl)"

  if [[ "$expect_failure" == "true" ]]; then
    set +e
    local output
    output="$(ACFS_TEST_ARCHIVE="$archive_path" PATH="$stub_dir:$PATH" bash -lc "cat '$REPO_ROOT/install.sh' | bash -s -- --list-modules" 2>&1)"
    local status=$?
    set -e

    if [[ $status -eq 0 ]]; then
      echo "$output" >&2
      echo "ERROR: expected bootstrap failure for $label" >&2
      exit 1
    fi

    echo "$output" | grep -q "Bootstrap mismatch" || {
      echo "$output" >&2
      echo "ERROR: expected bootstrap mismatch message for $label" >&2
      exit 1
    }

    log "$label: bootstrap failure detected as expected"
    return 0
  fi

  local output
  output="$(ACFS_TEST_ARCHIVE="$archive_path" PATH="$stub_dir:$PATH" bash -lc "cat '$REPO_ROOT/install.sh' | bash -s -- --list-modules" 2>&1)"

  echo "$output" | grep -q "Bootstrap archive ready" || {
    echo "$output" >&2
    echo "ERROR: bootstrap archive not reported ready for $label" >&2
    exit 1
  }

  echo "$output" | grep -q "Available ACFS Modules" || {
    echo "$output" >&2
    echo "ERROR: list-modules output missing for $label" >&2
    exit 1
  }

  log "$label: bootstrap success"
}

main() {
  local good_archive
  local bad_archive

  good_archive="$(mktemp /tmp/acfs-offline-archive.XXXXXX.tar.gz)"
  bad_archive="$(mktemp /tmp/acfs-offline-archive-bad.XXXXXX.tar.gz)"

  create_archive "$good_archive"
  run_bootstrap "$good_archive" "happy-path"

  create_bad_archive "$good_archive" "$bad_archive"
  run_bootstrap "$bad_archive" "mismatch-path" "true"

  log "offline bootstrap checks complete"
}

main "$@"
