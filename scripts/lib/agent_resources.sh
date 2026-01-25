#!/usr/bin/env bash
# ============================================================
# ACFS Agent Resources - seed/status/diff/apply for .agent bundle
# ============================================================

set -e

AGENT_RESOURCES_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACFS_REPO_ROOT="$(cd "$AGENT_RESOURCES_SCRIPT_DIR/../.." && pwd)"
ACFS_HOME_DEFAULT="${ACFS_HOME:-$HOME/.acfs}"

agent_resources_template_root() {
    local override="${ACFS_AGENT_RESOURCES_TEMPLATES:-}"

    if [[ -n "$override" && -d "$override" ]]; then
        echo "$override"
        return 0
    fi

    if [[ -d "$ACFS_HOME_DEFAULT/templates/agent-resources" ]]; then
        echo "$ACFS_HOME_DEFAULT/templates/agent-resources"
        return 0
    fi

    if [[ -d "$ACFS_REPO_ROOT/acfs/templates/agent-resources" ]]; then
        echo "$ACFS_REPO_ROOT/acfs/templates/agent-resources"
        return 0
    fi

    return 1
}

agent_resources_manifest_file() {
    local root
    root=$(agent_resources_template_root) || return 1
    echo "$root/manifest.txt"
}

agent_resources_manifest_version() {
    local manifest="$1"
    awk -F= '/^version=/{print $2}' "$manifest"
}

agent_resources_manifest_files() {
    local manifest="$1"
    awk 'found {print} /^files:/{found=1;next} /^[[:space:]]*#/ {next} NF==0{next}' "$manifest"
}

agent_resources_read_file() {
    local rel_path="$1"
    local root
    root=$(agent_resources_template_root) || return 1
    cat "$root/$rel_path"
}

agent_resources_lock_file() {
    local project_dir="$1"
    echo "$project_dir/.agent/ACFS_AGENT_RESOURCES.lock"
}

agent_resources_write_lock() {
    local project_dir="$1"
    local version="$2"
    local source="$3"
    local lock_file
    lock_file=$(agent_resources_lock_file "$project_dir")

    mkdir -p "$project_dir/.agent"

    local applied_at
    applied_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat > "$lock_file" << EOF
version=$version
source=$source
applied_at=$applied_at
EOF
}

agent_resources_collect_changes() {
    local project_dir="$1"
    local template_root="$2"
    local manifest="$3"

    local missing_file="$4"
    local changed_file="$5"

    : > "$missing_file"
    : > "$changed_file"

    while IFS= read -r rel_path; do
        [[ -z "$rel_path" ]] && continue
        local src="$template_root/$rel_path"
        local dest="$project_dir/$rel_path"

        if [[ ! -f "$dest" ]]; then
            echo "$rel_path" >> "$missing_file"
            continue
        fi

        if ! cmp -s "$src" "$dest"; then
            echo "$rel_path" >> "$changed_file"
        fi
    done < <(agent_resources_manifest_files "$manifest")
}

agent_resources_seed() {
    local project_dir="$1"

    if [[ -z "$project_dir" ]]; then
        echo "Usage: agent_resources_seed <project_dir>" >&2
        return 1
    fi

    local template_root
    template_root=$(agent_resources_template_root) || {
        echo "Agent resources template not found." >&2
        return 1
    }

    local manifest
    manifest=$(agent_resources_manifest_file) || return 1

    local version
    version=$(agent_resources_manifest_version "$manifest")

    local created=0

    while IFS= read -r rel_path; do
        [[ -z "$rel_path" ]] && continue
        local src="$template_root/$rel_path"
        local dest="$project_dir/$rel_path"

        if [[ -f "$dest" ]]; then
            continue
        fi

        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        created=$((created + 1))
    done < <(agent_resources_manifest_files "$manifest")

    agent_resources_write_lock "$project_dir" "$version" "$template_root"

    if [[ $created -gt 0 ]]; then
        echo "Seeded agent resources: $created file(s) added."
    else
        echo "Agent resources already present; nothing to seed."
    fi
}

agent_resources_status() {
    local project_dir="${1:-$(pwd)}"

    local template_root
    template_root=$(agent_resources_template_root) || {
        echo "Agent resources template not found." >&2
        return 1
    }

    local manifest
    manifest=$(agent_resources_manifest_file) || return 1

    local version
    version=$(agent_resources_manifest_version "$manifest")

    local lock_file
    lock_file=$(agent_resources_lock_file "$project_dir")

    local lock_version=""
    if [[ -f "$lock_file" ]]; then
        lock_version=$(awk -F= '/^version=/{print $2}' "$lock_file")
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local missing_file="$tmp_dir/missing"
    local changed_file="$tmp_dir/changed"

    agent_resources_collect_changes "$project_dir" "$template_root" "$manifest" "$missing_file" "$changed_file"

    local missing_count
    missing_count=$(wc -l < "$missing_file" | tr -d ' ')
    local changed_count
    changed_count=$(wc -l < "$changed_file" | tr -d ' ')

    echo "Agent resources status:"
    echo "  Project: $project_dir"
    echo "  Template version: $version"
    if [[ -n "$lock_version" ]]; then
        echo "  Applied version:  $lock_version"
    else
        echo "  Applied version:  (none)"
    fi
    echo "  Missing files:    $missing_count"
    echo "  Changed files:    $changed_count"

    if [[ $missing_count -gt 0 ]]; then
        echo "  Missing list:"
        sed 's/^/    - /' "$missing_file"
    fi

    if [[ $changed_count -gt 0 ]]; then
        echo "  Changed list:"
        sed 's/^/    - /' "$changed_file"
    fi

    rm -r "$tmp_dir"

    if [[ $missing_count -gt 0 || $changed_count -gt 0 ]]; then
        return 2
    fi

    return 0
}

agent_resources_diff() {
    local project_dir="${1:-$(pwd)}"

    local template_root
    template_root=$(agent_resources_template_root) || {
        echo "Agent resources template not found." >&2
        return 1
    }

    local manifest
    manifest=$(agent_resources_manifest_file) || return 1

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local missing_file="$tmp_dir/missing"
    local changed_file="$tmp_dir/changed"

    agent_resources_collect_changes "$project_dir" "$template_root" "$manifest" "$missing_file" "$changed_file"

    if [[ ! -s "$missing_file" && ! -s "$changed_file" ]]; then
        echo "No differences found."
        rm -r "$tmp_dir"
        return 0
    fi

    while IFS= read -r rel_path; do
        [[ -z "$rel_path" ]] && continue
        echo "\n--- $rel_path (missing; showing template)"
        diff -u /dev/null "$template_root/$rel_path" || true
    done < "$missing_file"

    while IFS= read -r rel_path; do
        [[ -z "$rel_path" ]] && continue
        echo "\n--- $rel_path"
        diff -u "$project_dir/$rel_path" "$template_root/$rel_path" || true
    done < "$changed_file"

    rm -r "$tmp_dir"
}

agent_resources_apply() {
    local project_dir="${1:-$(pwd)}"

    local template_root
    template_root=$(agent_resources_template_root) || {
        echo "Agent resources template not found." >&2
        return 1
    }

    local manifest
    manifest=$(agent_resources_manifest_file) || return 1

    local version
    version=$(agent_resources_manifest_version "$manifest")

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local missing_file="$tmp_dir/missing"
    local changed_file="$tmp_dir/changed"

    agent_resources_collect_changes "$project_dir" "$template_root" "$manifest" "$missing_file" "$changed_file"

    if [[ ! -s "$missing_file" && ! -s "$changed_file" ]]; then
        echo "Agent resources already up to date."
        rm -r "$tmp_dir"
        return 0
    fi

    agent_resources_diff "$project_dir"

    echo ""
    read -r -p "Apply agent resources updates? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        rm -r "$tmp_dir"
        return 1
    fi

    local updated=0
    while IFS= read -r rel_path; do
        [[ -z "$rel_path" ]] && continue
        local src="$template_root/$rel_path"
        local dest="$project_dir/$rel_path"
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        updated=$((updated + 1))
    done < <(cat "$missing_file" "$changed_file")

    agent_resources_write_lock "$project_dir" "$version" "$template_root"

    rm -r "$tmp_dir"

    echo "Updated agent resources: $updated file(s) written."
}

agent_resources_scan() {
    local root="${1:-/data/projects}"

    if [[ ! -d "$root" ]]; then
        echo "Directory not found: $root" >&2
        return 1
    fi

    local lock
    local found=false

    while IFS= read -r lock; do
        found=true
        local project_dir
        project_dir=$(dirname "$(dirname "$lock")")
        echo ""
        agent_resources_status "$project_dir" || true
    done < <(find "$root" -type f -name "ACFS_AGENT_RESOURCES.lock" 2>/dev/null | sort)

    if [[ "$found" == "false" ]]; then
        echo "No projects with agent resources lock found under $root"
    fi
}

agent_resources_usage() {
    echo "Usage: acfs agent-resources <command> [path]"
    echo ""
    echo "Commands:"
    echo "  seed <path>      Seed agent resources into a project"
    echo "  status <path>    Show status vs latest template"
    echo "  diff <path>      Show diff vs latest template"
    echo "  apply <path>     Apply updates (interactive)"
    echo "  scan [root]      Scan projects under /data/projects (or root)"
}

agent_resources_main() {
    local cmd="${1:-}"
    shift || true

    case "$cmd" in
        seed)
            agent_resources_seed "${1:-}"
            ;;
        status)
            agent_resources_status "${1:-$(pwd)}"
            ;;
        diff)
            agent_resources_diff "${1:-$(pwd)}"
            ;;
        apply)
            agent_resources_apply "${1:-$(pwd)}"
            ;;
        scan)
            agent_resources_scan "${1:-/data/projects}"
            ;;
        -h|--help|help|"")
            agent_resources_usage
            ;;
        *)
            echo "Unknown command: $cmd" >&2
            agent_resources_usage
            return 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    agent_resources_main "$@"
fi
