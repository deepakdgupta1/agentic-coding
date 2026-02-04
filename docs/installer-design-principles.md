# Long-Duration Installer Design Principles

Research notes from RCA of ACFS installation issues in LXD containers.

## Problem Context

Long-running installers (like ACFS's multi-phase bash installer) have unique reliability challenges:
- Network transience
- Mid-execution failures
- User context switching (root ↔ target user)
- Resumability requirements
- Silent failures masking root causes

This document captures design principles for building robust installers.

---

## 1. Fail-Fast with Explicit Precondition Checks

Every phase should validate its preconditions *before* executing any actions, not discover failures mid-execution.

```bash
# Good: Explicit precondition check
install_phase_finalize() {
    # Preconditions
    [[ -d "$ACFS_HOME" ]] || { log_error "ACFS_HOME does not exist"; return 1; }
    [[ -w "$ACFS_HOME" ]] || { log_error "ACFS_HOME not writable"; return 1; }
    
    # Actions only after preconditions pass
    ...
}
```

**Why**: Catching issues early produces clearer error messages and avoids partial state.

---

## 2. Postcondition Assertions

After each phase completes, assert that the expected artifacts exist. Don't trust that commands succeeded—verify the outputs.

```bash
# After installing scripts
assert_file_exists() { 
    [[ -f "$1" ]] || { log_error "Missing expected file: $1"; return 1; }
}

# Postcondition check at end of finalize phase
assert_file_exists "$ACFS_HOME/scripts/lib/dashboard.sh"
assert_file_exists "$ACFS_HOME/scripts/lib/info.sh"
assert_file_exists "/usr/local/bin/acfs"
```

**Why**: Commands can succeed (exit 0) but produce no output due to edge cases. Verification catches these.

---

## 3. Idempotent Operations

Every step should be safe to re-run:
- Use `mkdir -p` (doesn't fail if exists)
- Check existence before creating
- Use `cp -f` (overwrites safely)
- Use `ln -sf` (replaces symlinks)

**Why**: Enables reliable resume after failures without manual cleanup.

---

## 4. Consistent User Context

Never mix root operations with user operations in the same logical step. Be explicit about which context you're in.

```bash
# Bad: Mixed contexts
$SUDO mkdir -p "$USER_DIR"           # Creates as root
chown "$USER:$USER" "$USER_DIR"      # Fix ownership after

# Good: Consistent user context from the start
run_as_target mkdir -p "$USER_DIR"   # Created with correct ownership
```

**Why**: Mixed contexts lead to ownership issues and race conditions.

---

## 5. Atomic Multi-Step Transactions

When multiple files must all succeed together, use a staging area and atomic move.

```bash
# Stage files to temp, then move all atomically
stage_dir=$(mktemp -d)
cp script1.sh "$stage_dir/"
cp script2.sh "$stage_dir/"
# All copies succeeded, now move atomically
mv "$stage_dir"/* "$ACFS_HOME/scripts/lib/"
rmdir "$stage_dir"
```

**Why**: Prevents partial installations where some files exist but not others.

---

## 6. Explicit Error Propagation (No Silent Failures)

Never use `|| true` for operations that *must* succeed. Reserve it only for truly optional operations.

```bash
# Bad: Silently swallows critical failure
$SUDO chown "$TARGET_USER:$TARGET_USER" "$ACFS_STATE_FILE" || true

# Good: Explicit error handling with degraded mode
if ! $SUDO chown "$TARGET_USER:$TARGET_USER" "$ACFS_STATE_FILE"; then
    log_warn "Could not fix state.json ownership—some features may require sudo"
fi
```

**Why**: Silent failures cascade into mysterious downstream errors.

---

## 7. Structured Phase Orchestration

Use a single orchestrator pattern for all phases, never inline phase logic in `main()`.

```bash
# Single pattern for all phases
for phase_id in "${ACFS_PHASE_IDS[@]}"; do
    run_phase "$phase_id" "phase_${phase_id}" || exit 1
done
```

**Why**: Consistent orchestration enables consistent error handling, timing, and resumability.

---

## Application to ACFS

ACFS already implements many of these principles:
- `state.sh`: Atomic writes, phase tracking, resume capability
- `error_tracking.sh`: `try_step`, error context, output capture
- `run_as_target`: Proper user context switching

The RCA revealed these patterns were **inconsistently applied** in the `finalize()` phase, leading to:
- Directories created as root instead of target user
- Silent ownership failures (`|| true`)
- No postcondition verification
- No bootstrap verification for container deployment

---

## Related Files

- [install.sh](file:///home/deeog/Desktop/agentic-coding/install.sh) - Main installer
- [scripts/lib/state.sh](file:///home/deeog/Desktop/agentic-coding/scripts/lib/state.sh) - State management
- [scripts/lib/error_tracking.sh](file:///home/deeog/Desktop/agentic-coding/scripts/lib/error_tracking.sh) - Error tracking
