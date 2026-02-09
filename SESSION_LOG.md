# Session Log

## 2026-02-07 — macOS local install resilience
- Objective: Make macOS local installation flow resilient (host Multipass + in-VM local mode).
- Scope: `install.sh` (`bootstrap_macos_vm`), `scripts/local/acfs_container.sh`, `scripts/lib/sandbox.sh`, and a macOS local resilience matrix doc.
- Constraints: No destructive commands; use `bun` for JS/TS; keep context under 60%.
- Status: In progress.
- Notes:
  - Session started after reading Collaboration Knowledge Base.
  - User approved auto-remediation and both host-side + in-VM scope.
  - Created `docs/macos-local-install-research.md` with primary sources.
  - Implemented macOS host-side Multipass readiness checks in `install.sh`.
  - Added workspace writability fallback and extra mount cleanup attempt in `install.sh`.
  - Added idempotency guards for Multipass mounts, LXD profile drift, and in-VM install checks.
  - Added idempotency matrix to `docs/local-desktop-resilient-install.md`.
  - Added dry-run idempotency audit mode and `acfs-local audit`.
  - Fixed shellcheck SC2078 in `scripts/lib/sandbox.sh` and re-ran shellcheck (SC2329 info remains).
  - Hardened in-VM local flow in `scripts/local/acfs_container.sh` and `scripts/lib/sandbox.sh`.
  - Updated `docs/local-desktop-resilient-install.md` with macOS host readiness and failure modes.
  - `shellcheck` not installed locally; lint not run.
- Next session goals:
  - Document SOTA research for Multipass/LXD readiness and recovery.
  - Implement host-side checks + auto-remediation.
  - Implement in-VM flow readiness + retries.

## 2026-02-08 — staged deep code review (correctness/regressions/perf)
- Objective: Risk-based review across installer, sandbox, manifest, and web app (skip generated files).
- Scope: `install.sh`, `scripts/lib/`, `scripts/local/`, `packages/manifest/`, `apps/web/`.
- Automated checks:
  - Installed Bun (system) and ran `bun install`.
  - `bun run lint` now passes after fixes.
  - `bun run type-check` now passes after fixes.
  - `bun run --filter @acfs/manifest test` still failing (stale generated outputs).
  - `shellcheck install.sh scripts/lib/*.sh` ran; only SC2329 info warnings.
- Findings:
  - Syntax errors in `apps/web` (`flywheel-visualization.tsx`, `lesson-components.tsx`, `flywheel.ts`, `tldr-content.ts`) breaking lint/type-check. (fixed)
  - `scripts/generated/manifest_index.sh` appears stale vs `acfs.manifest.yaml` (tests fail); needs regeneration. (pending)
  - Dashboard port fallback parsing in `scripts/lib/sandbox.sh` could skip listen lines. (fixed)
- Status: Review fixes applied; manifest regeneration pending.
- Next session goals:
  - Regenerate manifest outputs (`bun run generate`) and re-run manifest tests.
