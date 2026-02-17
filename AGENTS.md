# AGENTS.md — Agentic Coding Flywheel Setup (ACFS)

## RULE 0 - THE FUNDAMENTAL OVERRIDE PEROGATIVE

If I tell you to do something, even if it goes against what follows below, YOU MUST LISTEN TO ME. I AM IN CHARGE, NOT YOU.

---

## RULE 1 – ABSOLUTE (DO NOT EVER VIOLATE THIS)

You may NOT delete any file or directory unless I explicitly give the exact command **in this session**.

- This includes files you just created (tests, tmp files, scripts, etc.).
- You do not get to decide that something is "safe" to remove.
- If you think something should be removed, stop and ask. You must receive clear written approval **before** any deletion command is even proposed.

Treat "never delete files without permission" as a hard invariant.

---

## IRREVERSIBLE GIT & FILESYSTEM ACTIONS

Absolutely forbidden unless I give the **exact command and explicit approval** in the same message:

- `git reset --hard`
- `git clean -fd`
- `rm -rf`
- Any command that can delete or overwrite code/data

Rules:

1. If you are not 100% sure what a command will delete, do not propose or run it. Ask first.
2. Prefer safe tools: `git status`, `git diff`, `git stash`, copying to backups, etc.
3. After approval, restate the command verbatim, list what it will affect, and wait for confirmation.
4. When a destructive command is run, record in your response:
   - The exact user text authorizing it
   - The command run
   - When you ran it

If that audit trail is missing, then you must act as if the operation never happened.

---

## Node / JS Toolchain

- Use **bun** for everything JS/TS.
- ❌ Never use `npm`, `yarn`, or `pnpm`.
- Lockfiles: only `bun.lock`. Do not introduce any other lockfile.
- Target **latest Node.js**. No need to support old Node versions.
- **Note:** `bun install -g <pkg>` is valid syntax (alias for `bun add -g`). Do not "fix" it.

---

## Project Architecture

ACFS is a **multi-component project**:

| Component | Location | Purpose |
|-----------|----------|---------|
| Website Wizard | `apps/web/` | Next.js 16 App Router guiding beginners |
| Installer | `install.sh` + `scripts/` | Bash installer for Ubuntu 25.10 |
| Onboarding TUI | `packages/onboard/` | Interactive tutorial (`onboard` command) |
| Module Manifest | `acfs.manifest.yaml` | Single source of truth for tools |
| ACFS Configs | `acfs/` | Shell, tmux, lessons → installed to `~/.acfs/` |

**Target:** Ubuntu 25.10 (auto-upgrades from 22.04+)

---

## Generated Files — NEVER Edit Manually

All files in `scripts/generated/` are auto-generated from the manifest:
- `install_*.sh` — Category installer scripts
- `doctor_checks.sh` — Doctor verification checks
- `manifest_index.sh` — Bash arrays with module metadata

**To modify:** Edit `packages/manifest/src/generate.ts`, then run `bun run generate`.

---

## Code Editing Discipline

- Do **not** run scripts that bulk-modify code (codemods, giant sed/regex refactors).
- Large mechanical changes: break into smaller, explicit edits.
- Subtle/complex changes: edit by hand, file-by-file.

---

## Backwards Compatibility & File Sprawl

We optimize for a clean architecture now, not backwards compatibility.

- No "compat shims" or "v2" file clones.
- When changing behavior, migrate callers and remove old code.
- New files are only for genuinely new domains.

---

## Website Development (apps/web)

```bash
cd apps/web && bun install && bun run dev
```

Key patterns: App Router, shadcn/ui + Tailwind, URL params + localStorage (no backend).

---

## Installer Testing

```bash
shellcheck install.sh scripts/lib/*.sh
./tests/vm/test_install_ubuntu.sh
```

---

## Defensive Engineering Standard

All long-running workflows (installer, upgrade, migration) MUST follow this standard:

### Stage Contract

Every phase declares preconditions and postconditions in `scripts/lib/stage_contract.sh`.
- Preconditions are checked **before** execution in `_run_phase_with_report()`
- Postconditions are verified **after** execution AND on resume (before skipping)
- Postcondition drift triggers automatic phase re-run via `state_unmark_phase()`

### Observability

- Every install run gets an `ACFS_RUN_ID` (generated in `observability.sh`)
- JSONL events are written to `~/.acfs/logs/install/<run_id>.jsonl`
- Event types: `install_start`, `stage_start`, `stage_end`, `check_failed`, `cmd_failed`, `resume`
- On failure, a structured summary box is printed with run ID, error class, and remediation

### Error Taxonomy

Errors are classified by `classify_error()` in `error_tracking.sh`:

| Class | Examples | Action |
|-------|----------|--------|
| `transient_network` | DNS, timeout, connection refused | Retry with backoff |
| `permission` | Permission denied, EACCES | Stop, print fix command |
| `dependency_conflict` | APT lock, broken packages | Stop, print dpkg fix |
| `corrupt_state` | Invalid JSON, interrupted dpkg | Stop, suggest --force-reinstall |
| `unsupported_env` | Wrong arch, unsupported OS | Stop, run preflight |
| `unknown` | Unclassified | Stop, point to logs |

### Resumability

- `--resume` (default when state exists)
- `--resume-from <stage>` — skip all phases before the target
- `--stop-after <stage>` — exit cleanly after the target completes
- `--force-reinstall` — start fresh

### Fault Injection Tests

Run with `./tests/vm/fault_injection.sh`. Tests cover network loss, apt lock, low disk, permission errors, interrupted runs, and postcondition drift.

---

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   br sync --flush-only
   git add .beads/
   git commit -m "Update beads"
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing
- If push fails, resolve and retry until it succeeds

---

## UBS Quick Reference for AI Agents

UBS (Ultimate Bug Scanner): **The AI Coding Agent's Secret Weapon**

**Golden Rule:** `ubs <changed-files>` before every commit. Exit 0 = safe. Exit >0 = fix & re-run.

**Commands:**
```bash
ubs file.ts file2.py                    # Specific files (< 1s) — USE THIS
ubs $(git diff --name-only --cached)    # Staged files — before commit
ubs --ci --fail-on-warning .            # CI mode — before PR
```

**Fix Workflow:** Read finding → Navigate `file:line:col` → Verify real issue → Fix root cause → Re-run → Commit

**Bug Severity:**
- **Critical** (always fix): Null safety, XSS/injection, async/await, memory leaks
- **Important**: Type narrowing, division-by-zero, resource leaks
- **Contextual**: TODO/FIXME, console logs

---

## DCG Quick Reference for AI Agents

DCG (Destructive Command Guard) is a Claude Code hook that **blocks dangerous git and filesystem commands** before execution.

**Golden Rule:** DCG works automatically. When blocked, use safer alternatives or ask the user to run it manually.

**Auto-Blocked Commands:**
```bash
git reset --hard               # Destroys uncommitted changes
git push --force / -f          # Overwrites remote history
git clean -f                   # Deletes untracked files
rm -rf <non-temp>              # Recursive deletion
```

**Always Safe:**
```bash
git checkout -b <branch>       # Creates branch, safe
git restore --staged           # Only unstages
git push --force-with-lease    # Safe force push variant
```

**When Blocked:** Ask user to run manually, suggest safer alternatives, never try to bypass.

**Commands:**
```bash
dcg test "<cmd>" --explain     # Test if blocked
dcg install                    # Register hook
dcg doctor                     # Health check
dcg allow-once <code>          # One-time bypass
```

---

## Tool Skills Reference

Detailed documentation for specialized tools is available in `.agent/skills/`:

| Skill | Purpose | Trigger |
|-------|---------|---------|
| `beads` | Issue tracking with br/bv | Working with tasks, bugs, issues |
| `mcp-mail` | Multi-agent coordination | Agent-to-agent communication, file reservations |
| `cass` | Cross-agent session search | Looking for previous solutions |
| `cm` | Agent memory system | Retrieving lessons, building memory |
| `warp-grep` | AI-powered code search | "How does X work?" exploration |
| `ru` | Multi-repo sync | Managing multiple repositories |
| `giil` | Cloud image download | Visual debugging with shared images |
| `csctf` | Chat-to-file converter | Archiving AI conversations |

These skills are loaded **on-demand** based on semantic matching.

---

## Note for Codex/GPT-5.2

When you see unexpected changes in working tree from other agents: NEVER stash, revert, overwrite, or disturb their work. Treat those changes identically to changes you made yourself.

---

## Note on Built-in TODO Functionality

If asked to use built-in TODO functionality, comply without insisting on beads.
