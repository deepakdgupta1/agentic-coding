# Project Learnings

## 2026-02-07
- macOS local install uses Multipass VM bootstrapping in `install.sh` (`bootstrap_macos_vm`).
- In-VM local mode relies on LXD sandbox helpers in `scripts/lib/sandbox.sh` and the `acfs-local` wrapper in `scripts/local/acfs_container.sh`.
- Multipass provides `wait-ready`, and state-aware `start`/`restart`/`stop` semantics that can be used for safe automation (see `docs/macos-local-install-research.md`).
- Adding `acfs_sandbox_wait_ready` and retryable repo transfer improves resilience without changing install semantics.
- `acfs-local create` now checks for an already-healthy install and skips reinstall, re-running only when drift is detected.
- Dry-run idempotency audit uses read-only checks; `acfs-local audit` is the recommended entry point on Ubuntu hosts.
