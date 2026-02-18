#!/usr/bin/env bash
# ============================================================
# ACFS Local - PR Pre-Merge Review Helper
#
# Syncs base/head branches, runs pre-merge checks, and opens VS
# Code diffs for all changed files so local review is faster.
# ============================================================

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  ./scripts/local/pr_premerge_review.sh [options]

Options:
  --base <branch>       Base branch to merge into
                        (default: local-desktop-installation-support)
  --head <branch>       Head branch to review
                        (default: current branch)
  --max-diffs <n>       Max files to open in VS Code diff tabs (default: 200)
  --no-open-diff        Skip opening VS Code diffs
  --full                Run full quality gates (shellcheck + apps/web checks)
  --allow-dirty         Allow running with uncommitted local changes
  -h, --help            Show this help

Examples:
  ./scripts/local/pr_premerge_review.sh
  ./scripts/local/pr_premerge_review.sh --base local-desktop-installation-support --head feature/my-pr
  ./scripts/local/pr_premerge_review.sh --full --max-diffs 40
EOF
}

log() {
    printf '[pre-merge] %s\n' "$*"
}

warn() {
    printf '[pre-merge][warn] %s\n' "$*" >&2
}

die() {
    printf '[pre-merge][error] %s\n' "$*" >&2
    exit 1
}

require_command() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1 || die "Missing required command: $cmd"
}

BASE_BRANCH="local-desktop-installation-support"
HEAD_BRANCH=""
MAX_DIFFS=200
OPEN_DIFF="true"
RUN_FULL="false"
ALLOW_DIRTY="false"
YAMLLINT_BIN=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --base)
            [[ $# -ge 2 ]] || die "--base requires a value"
            BASE_BRANCH="$2"
            shift 2
            ;;
        --head)
            [[ $# -ge 2 ]] || die "--head requires a value"
            HEAD_BRANCH="$2"
            shift 2
            ;;
        --max-diffs)
            [[ $# -ge 2 ]] || die "--max-diffs requires a value"
            MAX_DIFFS="$2"
            shift 2
            ;;
        --no-open-diff)
            OPEN_DIFF="false"
            shift
            ;;
        --full)
            RUN_FULL="true"
            shift
            ;;
        --allow-dirty)
            ALLOW_DIRTY="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
done

require_command git

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO_ROOT" ]] || die "Run this script inside a git repository."
cd "$REPO_ROOT"

if [[ -z "$HEAD_BRANCH" ]]; then
    HEAD_BRANCH="$(git branch --show-current)"
fi
[[ -n "$HEAD_BRANCH" ]] || die "Could not determine head branch. Pass --head <branch>."
[[ "$MAX_DIFFS" =~ ^[0-9]+$ ]] || die "--max-diffs must be a non-negative integer."

if [[ "$ALLOW_DIRTY" != "true" ]]; then
    if ! git diff --quiet || ! git diff --cached --quiet; then
        die "Working tree is not clean. Commit/stash first or rerun with --allow-dirty."
    fi
fi

if ! git ls-remote --exit-code --heads origin "$BASE_BRANCH" >/dev/null 2>&1; then
    die "Branch origin/$BASE_BRANCH does not exist."
fi

if ! git ls-remote --exit-code --heads origin "$HEAD_BRANCH" >/dev/null 2>&1; then
    die "Branch origin/$HEAD_BRANCH does not exist."
fi

ensure_local_branch() {
    local branch="$1"
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        git switch "$branch" >/dev/null
    else
        git switch -c "$branch" --track "origin/$branch" >/dev/null
    fi
    git pull --ff-only origin "$branch"
}

ensure_yamllint() {
    if command -v yamllint >/dev/null 2>&1; then
        YAMLLINT_BIN="yamllint"
        return 0
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        return 1
    fi

    local venv_dir="$REPO_ROOT/.tmp-yamllint-venv"
    if [[ ! -d "$venv_dir" ]]; then
        log "Creating temporary yamllint virtualenv: $venv_dir"
        python3 -m venv "$venv_dir"
    fi

    # shellcheck disable=SC1091
    source "$venv_dir/bin/activate"
    pip install -q yamllint
    YAMLLINT_BIN="$venv_dir/bin/yamllint"
}

run_shellcheck_on_changed_shell_files() {
    local changed_files=("$@")
    local shell_files=()
    local file=""

    for file in "${changed_files[@]}"; do
        [[ "$file" == *.sh ]] || continue
        [[ -f "$file" ]] || continue
        shell_files+=("$file")
    done

    if [[ ${#shell_files[@]} -eq 0 ]]; then
        log "No changed shell scripts to lint."
        return
    fi

    if ! command -v shellcheck >/dev/null 2>&1; then
        warn "shellcheck not found. Skipping changed-shell lint."
        return
    fi

    log "Running shellcheck on changed shell scripts..."
    shellcheck -x "${shell_files[@]}"
}

run_yamllint_on_changed_workflows() {
    local changed_files=("$@")
    local workflow_files=()
    local file=""

    for file in "${changed_files[@]}"; do
        [[ "$file" == .github/workflows/*.yml ]] || continue
        [[ -f "$file" ]] || continue
        workflow_files+=("$file")
    done

    if [[ ${#workflow_files[@]} -eq 0 ]]; then
        log "No changed workflow YAML files to lint."
        return
    fi

    if ! ensure_yamllint; then
        warn "Could not set up yamllint. Skipping workflow YAML lint."
        return
    fi

    log "Running yamllint on changed workflow YAML files..."
    "$YAMLLINT_BIN" -c /dev/stdin "${workflow_files[@]}" <<'EOF'
extends: default
rules:
  line-length:
    max: 200
  key-ordering: disable
  comments:
    min-spaces-from-content: 1
  document-start: disable
  document-end: disable
  indentation:
    spaces: 2
    indent-sequences: whatever
  truthy:
    allowed-values: ['true', 'false', 'on', 'off']
EOF
}

run_full_quality_gates() {
    if [[ "$RUN_FULL" != "true" ]]; then
        return
    fi

    if command -v shellcheck >/dev/null 2>&1; then
        log "Running full shellcheck gate..."
        shopt -s globstar nullglob
        # shellcheck disable=SC2207
        local files=(install.sh scripts/**/*.sh)
        shellcheck "${files[@]}"
        shopt -u globstar nullglob
    else
        warn "shellcheck not found. Skipping full shellcheck gate."
    fi

    if command -v bun >/dev/null 2>&1; then
        log "Running apps/web gates: type-check, lint, build..."
        (
            cd apps/web
            bun run type-check
            bun run lint
            bun run build
        )
    else
        warn "bun not found. Skipping apps/web gates."
    fi
}

open_vscode_diffs() {
    local changed_files=("$@")

    if [[ "$OPEN_DIFF" != "true" ]]; then
        return
    fi

    if ! command -v code >/dev/null 2>&1; then
        warn "VS Code CLI 'code' not found. Skipping automatic diff open."
        return
    fi

    local safe_base="${BASE_BRANCH//\//_}"
    local safe_head="${HEAD_BRANCH//\//_}"
    local diff_root
    diff_root="$(mktemp -d "${TMPDIR:-/tmp}/acfs-pr-review.${safe_base}-vs-${safe_head}.XXXXXX")"
    local file=""
    local opened=0

    log "Preparing VS Code diff files in: $diff_root"
    for file in "${changed_files[@]}"; do
        if [[ "$opened" -ge "$MAX_DIFFS" ]]; then
            warn "Reached --max-diffs limit ($MAX_DIFFS)."
            break
        fi

        local left_path="$diff_root/$safe_base/$file"
        local right_path="$diff_root/$safe_head/$file"
        mkdir -p "$(dirname "$left_path")" "$(dirname "$right_path")"

        if git cat-file -e "${BASE_BRANCH}:${file}" 2>/dev/null; then
            git show "${BASE_BRANCH}:${file}" > "$left_path"
        else
            : > "$left_path"
        fi

        if git cat-file -e "${HEAD_BRANCH}:${file}" 2>/dev/null; then
            git show "${HEAD_BRANCH}:${file}" > "$right_path"
        else
            : > "$right_path"
        fi

        if ! code --reuse-window --diff "$left_path" "$right_path" >/dev/null 2>&1; then
            warn "Failed to open VS Code diff for: $file"
        fi

        opened=$((opened + 1))
    done

    log "Opened $opened VS Code diff tabs."
    log "Diff orientation: left=$BASE_BRANCH right=$HEAD_BRANCH"
    log "Temporary diff files are in: $diff_root"
}

log "Fetching latest refs from origin..."
git fetch origin

log "Syncing base branch: $BASE_BRANCH"
ensure_local_branch "$BASE_BRANCH"

log "Syncing head branch: $HEAD_BRANCH"
ensure_local_branch "$HEAD_BRANCH"

log "Reviewing commits in $HEAD_BRANCH not in $BASE_BRANCH:"
git log --oneline --decorate "$BASE_BRANCH..$HEAD_BRANCH" || true

mapfile -d '' -t CHANGED_FILES < <(git diff --name-only -z "$BASE_BRANCH...$HEAD_BRANCH")
if [[ ${#CHANGED_FILES[@]} -eq 0 ]]; then
    log "No file differences found between $BASE_BRANCH and $HEAD_BRANCH."
    exit 0
fi

log "Changed files (${#CHANGED_FILES[@]}):"
for file in "${CHANGED_FILES[@]}"; do
    printf '  - %s\n' "$file"
done

log "Running whitespace sanity check..."
git diff --check "$BASE_BRANCH...$HEAD_BRANCH"

run_shellcheck_on_changed_shell_files "${CHANGED_FILES[@]}"
run_yamllint_on_changed_workflows "${CHANGED_FILES[@]}"
run_full_quality_gates
open_vscode_diffs "${CHANGED_FILES[@]}"

cat <<EOF

Pre-merge checklist complete.

Next merge steps:
  git switch $BASE_BRANCH
  git merge --no-ff $HEAD_BRANCH
  git push origin $BASE_BRANCH
EOF
