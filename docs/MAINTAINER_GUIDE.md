# ACFS Maintainer Guide

Internal reference for maintaining the ACFS installer and manifest.

## Manifest-Driven Architecture

ACFS uses a single source of truth pattern:

```
acfs.manifest.yaml
       ↓
packages/manifest/src/generate.ts
       ↓
scripts/generated/
       ↓
install.sh (orchestrator)
```

The manifest defines what gets installed. The generator produces bash functions. The installer orchestrates execution.

### Web Content Generation

The manifest also drives web content (tools, TL;DR, commands, lessons). Modules with a `web` block generate TypeScript data files consumed by the Next.js website.

```
acfs.manifest.yaml (web metadata)
       ↓
packages/manifest/src/generate.ts
       ↓
apps/web/lib/generated/
├── manifest-tools.ts      # Tool cards for flywheel/learn pages
├── manifest-tldr.ts       # TL;DR summaries
├── manifest-commands.ts   # CLI command reference
├── manifest-lessons-index.ts  # Lesson navigation index
└── manifest-web-index.ts  # Re-exports all above
```

**IMPORTANT:** Files in `apps/web/lib/generated/` are auto-generated. Never edit them directly.

## Adding a New Module

### 1. Add to acfs.manifest.yaml

```yaml
modules:
  - id: category.toolname
    name: Tool Name
    category: category  # base, shell, cli, lang, tools, agents, db, cloud, stack, acfs
    phase: 6            # Execution order (0-10)
    enabled_by_default: true  # Include in default install
    
    # Installation
    run_as: target_shell  # root, target, target_shell, current, current_shell
    install:
      - command1
      - command2
    
    # Verification (for acfs doctor)
    installed_check: command -v toolname
    verify:
      - toolname --version
    
    # Optional
    optional: false       # If true, failure doesn't kill install
    dependencies:         # Module IDs that must run first
      - lang.bun
    tags:
      - dev-tools
```

### 2. Add Checksums (for external scripts)

If the module downloads scripts from external URLs, add checksums to `checksums.yaml`:

```yaml
scripts:
  https://example.com/install.sh: sha256:abc123...
```

Generate checksums:
```bash
curl -fsSL "https://example.com/install.sh" | sha256sum
```

### 3. Regenerate

```bash
cd packages/manifest
bun run generate
```

Or with the pre-commit hook:
```bash
./scripts/hooks/install.sh  # One-time hook setup
git add acfs.manifest.yaml
git commit  # Hook auto-regenerates
```

### 4. Add Web Metadata (Optional)

If the tool should appear on the website (flywheel page, TL;DR, learn section), add a `web` block:

```yaml
modules:
  - id: stack.newtool
    # ... install/verify fields ...
    web:
      display_name: "New Tool"
      short_name: "NT"
      tagline: "One-line description of what it does"
      short_desc: "Slightly longer description (1-2 sentences)"
      icon: "terminal"           # Lucide icon name (kebab-case)
      color: "#3B82F6"           # Brand color (6-digit hex)
      category_label: "Stack Tools"
      href: "/learn/tools/newtool"   # Internal link or external URL
      features:
        - "Feature one"
        - "Feature two"
      tech_stack: ["Rust", "SQLite"]
      use_cases:
        - "When to use this tool"
      language: "Rust"
      cli_name: "nt"
      cli_aliases: ["newtool"]
      command_example: "nt status --json"
      lesson_slug: "newtool"     # Links to /learn/tools/newtool
      tldr_snippet: "Quick summary for TL;DR page"
      visible: true              # Set false to hide from web
```

See `docs/MANIFEST_SCHEMA_VNEXT.md` for full field reference.

### 5. Validate

```bash
# Check for drift
cd packages/manifest && bun run generate --diff

# Syntax check all scripts
bash -n scripts/generated/*.sh

# Run selection tests
bash scripts/lib/test_selection.sh

# Full integration test
./tests/vm/test_install_ubuntu.sh
```

## run_as Modes

| Mode | Description | Use When |
|------|-------------|----------|
| `root` | Runs as root user | System packages, apt installs |
| `target` | Runs as target user | User config, no shell needed |
| `target_shell` | Target user with login shell | Most tools (needs PATH) |
| `current` | Current user context | Bootstrap scripts |
| `current_shell` | Current user with shell | Debugging |

## Verified Installers

For security, external install scripts must be:
1. HTTPS only
2. SHA256 checksummed in `checksums.yaml`
3. Listed in `KNOWN_INSTALLERS` (scripts/lib/security.sh)

The installer verifies checksums before execution.

## Testing Changes

### Local Testing

```bash
# Quick syntax check
bash -n install.sh scripts/lib/*.sh scripts/generated/*.sh

# Unit tests
bash scripts/lib/test_selection.sh
bash scripts/lib/test_contract.sh
bash scripts/lib/test_security.sh
bash scripts/lib/test_install_helpers.sh

# Bootstrap simulation
bash tests/vm/bootstrap_offline_checks.sh
```

### Docker Integration

```bash
# Single Ubuntu version
./tests/vm/test_install_ubuntu.sh

# All supported versions
./tests/vm/test_install_ubuntu.sh --all

# Specific version
./tests/vm/test_install_ubuntu.sh --ubuntu 25.04
```

### CI Checks

As of **2026-02-18**, ACFS has **13 GitHub Actions workflows** under `.github/workflows/`.

#### Branch and Release Model

| Surface | Branch/Ref | Workflows |
|------|------|------|
| Upstream mirror branch | `main` | `upstream-sync.yml` updates this branch to track upstream |
| Local integration branch | `local-desktop-installation-support` | `installer.yml` runs installer CI on pushes/PRs |
| Manual-only quality workflows | `workflow_dispatch` | `website.yml`, `playwright.yml`, `production-smoke.yml`, `toon-integration-tests.yml` |
| Security/checksum automation | `local-desktop-installation-support` + schedules/dispatch | `checksum-monitor.yml`, `manifest-drift.yml`, `installer-notification-receiver.yml` |
| Release refs | `v*` tags | `release-checksums.yml` |

#### Workflow Inventory

| Workflow | File | Trigger summary | Main purpose |
|------|------|------|------|
| Installer CI | `.github/workflows/installer.yml` | Push/PR to `local-desktop-installation-support` on installer/script/manifest/workflow/test changes | Full installer validation (lint, drift, checksum verify, matrix install, E2E) |
| Installer Canary (Docker) | `.github/workflows/installer-canary.yml` | Daily schedule + manual dispatch | Fast scheduled canary install run in Docker |
| Installer Canary (Strict) | `.github/workflows/installer-canary-strict.yml` | Nightly schedule + manual dispatch | Strict canary with checksum mismatch detection and issue creation |
| Installer Notification Receiver | `.github/workflows/installer-notification-receiver.yml` | `repository_dispatch` (`installer-updated`, `installer-removed`, `installer-added`) + manual dispatch | Receives installer update events, validates, scans, updates `checksums.yaml`, opens PRs targeting integration branch |
| Auto-Update Upstream Checksums | `.github/workflows/checksum-monitor.yml` | Every 2 hours + manual + push on `local-desktop-installation-support` to `scripts/lib/security.sh` + `repository_dispatch` (`upstream-changed`) | Auto-detect checksum drift, auto-commit `checksums.yaml` to integration branch, raise review issues for external tools |
| Checksum System E2E Tests | `.github/workflows/checksum-system-tests.yml` | Push/PR on `local-desktop-installation-support` for checksum workflow/security changes | Tests checksum workflows and `security.sh` behavior end-to-end |
| Release Gate - Checksums | `.github/workflows/release-checksums.yml` | Tag push `v*` + manual dispatch | Blocks releases when checksum verification fails |
| Internal Checksums Drift Check | `.github/workflows/manifest-drift.yml` | Push/PR on `local-desktop-installation-support` | Ensures internal script checksums and manifest drift state are clean |
| Sync Flywheel Upstream | `.github/workflows/upstream-sync.yml` | Daily schedule + manual dispatch | Mirrors fork `main` to upstream and merges into integration branch |
| Website CI | `.github/workflows/website.yml` | Manual dispatch only | Website lint/typecheck/build and Playwright matrix |
| Playwright Tests | `.github/workflows/playwright.yml` | Manual dispatch only | Chromium-focused Playwright workflow |
| Production Smoke Tests | `.github/workflows/production-smoke.yml` | Manual dispatch only | Runs smoke tests against deployed production URL |
| TOON Integration Tests | `.github/workflows/toon-integration-tests.yml` | Manual dispatch only | Validates `tru` behavior, script lint, optional full integration |

#### Detailed Context by Workflow

##### 1) Installer CI (`installer.yml`)
- **Trigger scope:** Push/PR only on `local-desktop-installation-support`, with path filters for installer/manifests/scripts/workflows/tests.
- **Jobs:**
  - `yaml-lint`: validates workflow YAML syntax for all workflow files.
  - `shellcheck`: lint all tracked `.sh` files + custom lint scripts + unit-style shell tests + macOS bootstrap mock test.
  - `manifest-drift`: runs manifest diff generation checks and validates generated script syntax + shellcheck.
  - `checksum-verification`: verifies upstream checksums with `scripts/lib/security.sh --verify --json`.
  - `pinned-ref-smoke`: containerized Ubuntu 24.04 install using `ACFS_CHECKSUMS_REF=local-desktop-installation-support`.
  - `selection-tests`: runs selection/contract/security/install-helper/RU tests.
  - `test-installer`: matrix (`24.04 vibe`, `25.10 vibe`, `24.04 safe`) full installer + `acfs doctor` + tool presence checks.
  - `e2e-curlbash-bootstrap`: runs `tests/e2e/test_curlbash_bootstrap.sh`.
  - `e2e-resume-after-failure`: runs `tests/e2e/test_resume_after_failure.sh`.
- **Notable behavior:** CI intentionally skips preflight and Ubuntu upgrades inside GitHub Actions containers.

##### 2) Installer Canary (Docker) (`installer-canary.yml`)
- **Trigger scope:** daily `07:30 UTC` and manual.
- **Inputs:** `ubuntu` (`24.04`, `25.04`, `all`), `mode` (`vibe`, `safe`).
- **Execution:** runs `tests/vm/test_install_ubuntu.sh`; sets `ACFS_CHECKSUMS_REF=local-desktop-installation-support`.

##### 3) Installer Canary (Strict) (`installer-canary-strict.yml`)
- **Trigger scope:** nightly `04:15 UTC` and manual.
- **Execution mode:** always strict (`--strict`), captures `canary.log`, keeps going to parse failures.
- **Failure handling:**
  - Detects checksum-specific failures via log grep.
  - Uploads log artifact.
  - Opens or comments on issue `Installer checksum mismatch detected (strict canary)` with actionable steps.
  - Fails job at end if canary exit code non-zero.

##### 4) Installer Notification Receiver (`installer-notification-receiver.yml`)
- **Dispatch contract:**
  - Event types: `installer-updated`, `installer-removed`, `installer-added`.
  - Expected payload fields for dispatch path: `tool`, `new_sha256`, `old_sha256`, `repo`, `commit`, and `url` (for added installers).
  - Manual dispatch supports `tool_name` and `dry_run` input (note: `dry_run` is defined but not enforced in later jobs).
- **Validation stage (`validate-dispatch`):**
  - Validates tool name format.
  - Validates tool presence in `checksums.yaml` for non-add events.
  - Restricts installer URLs to trusted domains.
  - Writes audit JSONL line to `.github/audit/installer-updates.jsonl`.
- **Checksum stage (`verify-checksum`):**
  - Downloads installer with timeout and size cap.
  - Computes SHA256 and compares with current `checksums.yaml`.
- **Security stage (`security-scan`):**
  - Advisory grep-based scan for risky patterns (curl|bash, wget|shell, eval, chmod 777, rm -rf vars, etc.).
  - Produces warnings but always sets `passed=true`.
- **Update and PR stages:**
  - `update-checksums` creates branch `auto/update-<tool>-checksum-<shortsha>`, updates YAML, commits, pushes.
  - `create-pr` opens PR to `local-desktop-installation-support` with review checklist and labels.
  - `handle-removal` creates branch/PR removing installer checksum entries for removal events.

##### 5) Auto-Update Upstream Checksums (`checksum-monitor.yml`)
- **Trigger scope:** every 2 hours, manual dispatch, push on `local-desktop-installation-support` for `scripts/lib/security.sh`, and `repository_dispatch` type `upstream-changed`.
- **Concurrency:** serialized group `checksum-monitor` (queues, does not cancel in-flight).
- **Core flow:**
  - Runs `security.sh --verify --json`.
  - Splits changes into trusted (`Dicklesworthstone`) vs external.
  - Regenerates `checksums.yaml` when mismatches exist.
  - Commits and pushes update to `local-desktop-installation-support`, with rebase attempt to handle concurrent changes.
- **Issue automation:** if external installers changed and commit succeeded, opens or appends to a security review issue.
- **Summary:** writes metrics and status to `GITHUB_STEP_SUMMARY`.

##### 6) Checksum System E2E Tests (`checksum-system-tests.yml`)
- **Trigger scope:** Push/PR on `local-desktop-installation-support` for checksum-related files and checksum workflows.
- **Jobs:**
  - `yaml-lint`: validates workflow YAML syntax.
  - `security-unit-tests`: runs `scripts/lib/test_security.sh`.
  - `checksum-verification-e2e`: validates `--verify --json` shape/count logic and `--update-checksums` output shape.
  - `checksum-monitor-dry-run`: reproduces monitor logic and validates step outputs parse correctly.
  - `checksum-freshness`: advisory (`continue-on-error`) check that committed checksums match upstream now.
- **Artifacts:** uploads E2E and dry-run outputs for debugging.

##### 7) Release Gate - Checksums (`release-checksums.yml`)
- **Trigger scope:** tag pushes `v*` and manual dispatch.
- **Behavior:** runs `security.sh --verify --json`, summarizes mismatch/error counts, and hard-fails release/tag workflow if exit code non-zero.

##### 8) Internal Checksums Drift Check (`manifest-drift.yml`)
- **Trigger scope:** Push/PR on branch `[local-desktop-installation-support]`.
- **Behavior:** runs `scripts/check-manifest-drift.sh --json`, summarizes checked/drifted counts and manifest hash parity, fails if drift detected.

##### 9) Sync Flywheel Upstream (`upstream-sync.yml`)
- **Trigger scope:** daily `00:00 UTC` and manual dispatch.
- **Permissions:** write access for contents, PRs, issues.
- **Flow:**
  - Fetches upstream.
  - Hard-resets fork `main` to `upstream/main`.
  - Force-pushes `main`.
  - Merges `main` into integration branch `local-desktop-installation-support` via temp branch `upstream-sync`.
  - If clean merge: pushes directly to integration branch.
  - If conflict: commits conflict markers, pushes sync branch, creates/updates conflict PR, applies labels.
  - Optional conflict analysis via `scripts/analyze-conflicts.ts` when `OPENAI_API_KEY` is set.

##### 10) Website CI (`website.yml`)
- **Trigger scope:** manual dispatch only.
- **Job graph:** `verify-generated` -> `lint-and-typecheck` -> `build` -> `e2e-tests`.
- **Behavior:**
  - Verifies generated manifest outputs are in sync.
  - Runs ESLint + TypeScript checks.
  - Builds Next.js app.
  - Runs Playwright matrix across desktop/mobile projects (`chromium`, `firefox`, `webkit`, `Mobile Chrome`, `Mobile Safari`).
  - Uploads Playwright artifacts on all outcomes.

##### 11) Playwright Tests (`playwright.yml`)
- **Trigger scope:** manual dispatch only.
- **Job graph:** `verify-generated` -> `test`.
- **Behavior:** installs dependencies and Playwright Chromium only; runs Chromium project tests; uploads report artifacts.

##### 12) Production Smoke Tests (`production-smoke.yml`)
- **Trigger scope:** manual dispatch only.
- **Job graph:** `wait-for-deploy` (push-only compatibility step; skipped in manual mode) -> `smoke-tests`.
- **Behavior:** runs Playwright against live production URL `https://agent-flywheel.com`; uploads artifacts only on failure.

##### 13) TOON Integration Tests (`toon-integration-tests.yml`)
- **Trigger scope:** manual dispatch only.
- **Concurrency:** one run per ref, cancel in-progress on new events.
- **Jobs:**
  - `toon-core`: installs Rust + `tru`, validates encode/decode, format env var, key folding, tabular arrays.
  - `lint-scripts`: shellcheck on `scripts/test_*.sh`, `verify_*.sh`, `check_*.sh`.
  - `full-integration`: manual-only note-driven job for heavier local-style integration coverage.

#### Shared Operational Context

| Concern | Current behavior |
|------|------|
| Token/secrets usage | `UPSTREAM_SYNC_TOKEN` and optional `OPENAI_API_KEY` in `upstream-sync.yml`; default `GITHUB_TOKEN` used broadly for checkout, push, PR, issue operations |
| Repo-writing workflows | `upstream-sync.yml`, `checksum-monitor.yml`, `installer-notification-receiver.yml` |
| Artifact-heavy workflows | `installer.yml`, `website.yml`, `playwright.yml`, `production-smoke.yml`, `checksum-system-tests.yml`, `installer-canary-strict.yml` |
| Dispatch-based automation | `installer-notification-receiver.yml` and `checksum-monitor.yml` |
| Schedule-based automation | `upstream-sync.yml`, `checksum-monitor.yml`, `installer-canary.yml`, `installer-canary-strict.yml` |

#### Current Caveats to Track

1. `installer-notification-receiver.yml` includes a `dry_run` input that is currently not used to gate commit/PR creation.
2. `installer-notification-receiver.yml` runs `npm test` conditionally in one step, which diverges from repo-wide Bun-first conventions.
3. `website.yml`, `playwright.yml`, `production-smoke.yml`, and `toon-integration-tests.yml` are manual-only in this fork strategy; run them on demand.
4. `upstream-sync.yml` intentionally uses destructive Git operations (`reset --hard`, force push) as part of fork mirroring; treat this workflow as high-impact infrastructure.

## Common Tasks

### Updating a Tool Version

1. Edit `acfs.manifest.yaml` with new version
2. Update checksum if external script changed
3. Regenerate and test

### Adding a Skip Flag

Legacy skip flags are mapped in `scripts/lib/install_helpers.sh`:

```bash
if [[ "${SKIP_NEWTOOL:-false}" == "true" ]]; then
    SKIP_MODULES+=("category.newtool")
fi
```

### Debugging Selection

```bash
# Preview execution plan
./install.sh --print-plan

# List available modules
./install.sh --list-modules

# Test specific selection
./install.sh --only category.tool --print-plan
```

## Files Overview

| File | Purpose |
|------|---------|
| `acfs.manifest.yaml` | Module definitions (source of truth) |
| `checksums.yaml` | SHA256 hashes for external scripts |
| `packages/manifest/` | TypeScript generator |
| `scripts/generated/` | Generated bash functions (don't edit) |
| `scripts/lib/` | Installer libraries |
| `install.sh` | Orchestrator (thin wrapper) |
