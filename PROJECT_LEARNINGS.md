# Project Learnings

## 2026-02-07
- macOS local install uses Multipass VM bootstrapping in `install.sh` (`bootstrap_macos_vm`).
- In-VM local mode relies on LXD sandbox helpers in `scripts/lib/sandbox.sh` and the `acfs-local` wrapper in `scripts/local/acfs_container.sh`.
- Multipass provides `wait-ready`, and state-aware `start`/`restart`/`stop` semantics that can be used for safe automation (see `docs/macos-local-install-research.md`).
- Adding `acfs_sandbox_wait_ready` and retryable repo transfer improves resilience without changing install semantics.
- `acfs-local create` now checks for an already-healthy install and skips reinstall, re-running only when drift is detected.
- Dry-run idempotency audit uses read-only checks; `acfs-local audit` is the recommended entry point on Ubuntu hosts.

## 2026-02-08
- `apps/web` currently fails lint/type-check due to syntax errors from duplicated or truncated blocks (e.g., `flywheel-visualization.tsx`, `lesson-components.tsx`, `flywheel.ts`, `tldr-content.ts`).
- `packages/manifest` tests fail when `scripts/generated/*` are stale; rerun `bun run generate` after manifest edits.
- Dashboard port parsing fallback in `scripts/lib/sandbox.sh` is sensitive to LXD output shape; keep the parsing robust when backfilling `profile device get`.

## 2026-02-08 — macOS ACFS Installation RCA

### Summary
Successfully installed ACFS on macOS (Apple Silicon, macOS 15.7.3) via the Multipass VM → LXD container path. 9/9 installation phases completed. 7/8 smoke test checks passed. Three classes of bugs were found and fixed in `scripts/lib/sandbox.sh` and `scripts/local/acfs_container.sh`.

### Bugs Found and Fixed

#### Bug 1: LXD CLI `-c` column flag not supported (LXD 5.21)
- **Symptom**: `lxc storage list --format csv -c n` fails with `unknown shorthand flag: 'c'`. This caused `_acfs_sandbox_default_storage_pool()` to return empty, hitting `log_fatal`.
- **Root cause**: LXD 5.21.4 (snap) does not support the `-c`/column selector for `storage list` or `remote list`. Only `--format csv` is supported.
- **Fix**: Changed all `--format csv -c n` to `--format csv | cut -d, -f1` (3 occurrences in `sandbox.sh`).
- **Idempotency impact**: None; read-only detection.

#### Bug 2: `lxc profile device show <profile> <device>` syntax invalid
- **Symptom**: `lxc profile device show default root` prints usage and exits with error. Same for `lxc config device show <instance> <device>`.
- **Root cause**: LXD 5.21 `device show` only accepts a profile/instance name, not a device name argument. The code assumed two-argument form.
- **Fix**: Added `_lxc_profile_has_device()` and `_lxc_config_has_device()` helpers that use `grep -q '^<device>:'` on the full device listing. Replaced all 10+ occurrences across both files.
- **Idempotency impact**: None; detection-only.

#### Bug 3: LXD CLI write operations hang when stdin is piped
- **Symptom**: `lxc profile create`, `lxc storage create`, and other write commands hang indefinitely when executed via `multipass exec` (non-interactive, piped stdin).
- **Root cause**: LXD CLI reads from stdin for interactive confirmation or preseed data. When stdin is a pipe from `multipass exec`, the read blocks forever.
- **Fix**: Modified `acfs_lxc()` to redirect stdin from `/dev/null` for all non-`exec` commands. Added `_acfs_sudo_lxc()` wrapper for direct `acfs_sudo lxc` calls. Replaced all 20+ direct `acfs_sudo lxc` calls with `_acfs_sudo_lxc`.
- **Idempotency impact**: None; behavioral fix.

#### Bug 4: `shift=true` fails on Multipass-mounted filesystems
- **Symptom**: `lxc launch` fails with `idmapping abilities are required but aren't supported on system` when the workspace disk device has `shift=true`.
- **Root cause**: Multipass mounts the host workspace via SSHFS (fuse.sshfs), which doesn't support LXD's idmapped mounts (shiftfs/idmap). The `shift=true` parameter is accepted at profile creation time but fails at container launch.
- **Fix**: (a) Added proactive filesystem detection in `_acfs_create_profile()` that checks if workspace is on `fuse*`, `9p`, `virtiofs`, or `sshfs` mount and uses `security.privileged=true` instead of `shift=true`. (b) Added launch failure fallback in `acfs_sandbox_create()` that catches the error, switches to privileged mode, and retries launch.
- **Idempotency impact**: Containers launched via fallback work correctly.

#### Bug 5 (NEW): `uid`/`gid` disk device options not supported in LXD 5.21
- **Symptom**: `lxc profile device add ... uid=1000 gid=1000` fails with `Error: Device validation failed for "workspace": Invalid device option "gid"`. The workspace device is NOT added; container launches without shared workspace.
- **Root cause**: LXD 5.21 (Canonical) does not support `uid` and `gid` as disk device options — those are Incus-specific extensions. Additionally, `raw.idmap` config breaks FUSE bind mounts in unprivileged containers (mount fails with EPERM).
- **Fix**: Replaced all `uid=1000 gid=1000` device options and `raw.idmap` fallbacks with `security.privileged=true` on the profile/container. Privileged containers can bind-mount FUSE filesystems without UID mapping issues.
- **Idempotency impact**: None; the profile/container config is set idempotently.

#### Bug 6: Gemini CLI node-gyp build hangs (pre-existing)
- **Symptom**: `bun install -g @google/gemini-cli@latest` hangs during `node-pty` native module compilation via node-gyp. CPU drops to 0% and the process sleeps indefinitely.
- **Root cause**: Unknown (likely node-gyp or bun interaction on ARM64 in nested container). The `node-gyp rebuild` subprocess sleeps without making progress.
- **Fix**: Not fixed (pre-existing issue in upstream Gemini CLI). The installer gracefully handles the failure and marks Gemini CLI as failed in the coding agents phase. Killing the node-gyp process allows the installer to continue.
- **Idempotency impact**: Gemini CLI remains uninstalled; installer skips it on re-run.

### Architecture Notes
- **macOS install path**: macOS host → Multipass VM (`acfs-host`, Ubuntu 24.04) → LXD container (`acfs-local`, Ubuntu 24.04) → ACFS tools
- **Workspace sharing**: macOS host `~/acfs-workspace` → Multipass SSHFS mount → LXD disk device (privileged container, no shift/uid/gid)
- **LXD version in Multipass VM**: 5.21.4 LTS (snap, latest/stable)
- **Multipass version**: 1.16.1+mac

### Idempotency Verification
- The core installer (inside the LXD container) is idempotent: re-running detects already-installed tools and skips them
- The `acfs-local audit` command should check for either `shift=true` or `security.privileged=true` when verifying workspace config
- The LXD preflight and storage pool creation are idempotent after fixes
- Profile creation is idempotent (checks existence before creating)
- Container launch is idempotent (detects existing container and starts it)

### Developer Mindset Reflection

#### 1. The "Compatible Enough" Trap: LXD vs Incus Conflation (Bugs 1, 2, 5)

Bugs 1, 2, and 5 share a single root cause: the code was written against the *mental model* of Incus (or a newer LXD) while targeting LXD 5.21. The `-c` column flag, the two-argument `device show`, and the `uid`/`gid` disk options all exist in Incus but not in LXD 5.21. This is not a documentation problem — it is a **target identity problem**. The developer likely tested commands interactively on one system and transcribed them into a script intended for another.

**Prevention principle**: When writing automation that targets a specific tool version, the first development artifact should be a **version contract** — a comment block or config declaring "this script targets LXD 5.21.x (snap, Canonical)" — and a **capability probe** that runs at the top of execution. The probe does not test whether the tool is installed; it tests whether *the specific features the script relies on* actually work. For example, a single `lxc storage list --format csv -c n 2>/dev/null` at startup would have surfaced bug 1 before any real logic ran. The cost of a 5-line capability probe is near zero; the cost of discovering incompatibilities at step 7 of 9 is enormous.

More broadly: when two projects fork (LXD/Incus), their CLIs diverge in **flag-level details**, not just major features. Treat fork divergence like a breaking API version, not a patch release. If you search "lxc disk device uid" and find an answer, check whether the answer is about LXD or Incus — the commands look identical but the runtime rejects them.

#### 2. Execution Context is Not a Detail — It is Architecture (Bug 3)

Bug 3 (stdin hang) reveals a class of error that no amount of unit testing catches: the script's **execution envelope** changed its semantics. The same `lxc profile create` command works in a terminal and hangs when piped through `multipass exec`. The developer tested the commands interactively (where stdin is a TTY) and assumed the script would behave identically when orchestrated (where stdin is a pipe).

**Prevention principle**: For every script that will be invoked by another tool (not directly by a human), write down the **stdin/stdout/stderr contract** explicitly. Ask: "What is stdin connected to when this runs in production?" If the answer is "a pipe from an orchestrator," then every subprocess that *might* read stdin must be audited. The `< /dev/null` pattern is not a hack — it is the correct explicit declaration that "this command does not consume input." The default should be closed stdin for non-interactive subcommands, opened only for those that need it (like `lxc exec` for shells).

This generalizes beyond stdin: environment variables, working directory, TTY detection, locale, and signal handling all constitute the execution envelope. When you change *how* a script is invoked (cron, systemd, SSH, `multipass exec`, Docker exec), you change this envelope. A checklist of "what changes when invoked non-interactively" should precede any orchestrated deployment.

#### 3. Late-Binding Failures and the Fallback Cascade Problem (Bugs 4 and 5)

Bug 4 (`shift=true` on SSHFS) is a **late-binding failure**: the invalid configuration was accepted at profile creation time and only rejected at container launch time. The fix for bug 4 introduced bug 5 (`uid`/`gid` options rejected) — a second late-binding failure, this time at device addition. This created a cascade where each "fix" discovered the next incompatibility one layer deeper.

**Prevention principle**: When designing fallback chains for platform-dependent configuration, **validate the fallback before you need it**. The code tried `shift=true` first, and when it failed, fell back to `uid=1000 gid=1000`. But neither fallback was tested proactively — both were only discovered to be broken when the previous option failed at runtime. A correct approach: at preflight time, create a throwaway test profile, attempt each configuration variant, and record which one succeeds. Then use only the validated path for the real container. This transforms a runtime cascade into a preflight decision.

More generally, if your fallback chain is A -> B -> C, and you only test A at deploy time, you are not fault-tolerant — you are fault-deferred. True resilience means testing B and C before you need them, so the decision is made calmly during preflight rather than reactively during failure recovery.

#### 4. The Missing Test: A Real VM, Not a Simulation

No mocking framework would have caught these bugs. Bugs 1, 2, and 5 require the actual LXD 5.21 binary. Bug 3 requires actual piped stdin from `multipass exec`. Bug 4 requires an actual SSHFS mount. The testing strategy that was missing is not "more unit tests" — it is a **single integration test running the script end-to-end in the target environment**.

**Prevention principle**: For infrastructure bootstrapping scripts, the minimum viable test is `vagrant up` (or equivalent) executing the script from scratch in a clean environment matching the target. This is not CI/CD — it is a pre-merge gate. The cost is ~10 minutes of wall time per run. The alternative — discovering 6 bugs serially during manual installation — cost significantly more. For this specific project, a Multipass VM snapshot with LXD 5.21 pre-installed, restored before each test run, would serve as the canonical test fixture.

#### 5. Documentation Literacy vs. Trial-and-Error

Five of the six bugs would have been prevented by reading 2-3 specific man pages: `lxc storage list --help` (no `-c` flag), `lxc profile device --help` (single-argument show), and the LXD disk device documentation (no `uid`/`gid`). The developer instead relied on pattern-matching from Incus documentation or blog posts. This is the "Stack Overflow copy-paste" failure mode applied to CLI flags.

**Prevention principle**: For every external CLI command in a script, run `<command> --help` **on the target system** and verify that every flag and argument you use appears in the output. This takes 30 seconds per command and eliminates an entire class of "this flag does not exist" errors. Bookmark the canonical reference for the exact version (e.g., `https://documentation.ubuntu.com/lxd/en/latest/` for LXD, not the Incus docs at `linuxcontainers.org`). When two forks share a name, wrong-fork documentation is worse than no documentation.
