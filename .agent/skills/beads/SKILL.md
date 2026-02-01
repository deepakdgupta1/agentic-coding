---
name: beads
description: Issue tracking with Beads (br/bv). Use when working with tasks, bugs, issues, or needing to triage work priorities.
---

# Issue Tracking with br (Beads)

All issue tracking goes through **Beads**. No other TODO systems.

**Note:** `br` is a convenience alias for the real Beads CLI: `bd`.

## Key Invariants

- `.beads/` is authoritative state and **must always be committed** with code changes.
- Do not edit `.beads/*.jsonl` directly; only via `br` / `bd`.

## Basic Commands

```bash
br ready --json                    # Check ready work
br create "Title" -t bug -p 1      # Create issue (types: bug|feature|task|epic|chore)
br update br-42 --status in_progress
br close br-42 --reason "Done"
br sync --flush-only               # Export without git ops
```

**Priorities:** `0` critical | `1` high | `2` medium | `3` low | `4` backlog

## Agent Workflow

1. `br ready` → find unblocked work
2. `br update <id> --status in_progress` → claim
3. Implement + test
4. If new work found → `br create ... --deps discovered-from:<id>`
5. `br close <id>` → complete
6. Commit `.beads/` with code changes

---

# bv — Beads Viewer (AI Sidecar)

Graph-aware triage engine with precomputed metrics (PageRank, betweenness, critical path).

**⚠️ CRITICAL: Use ONLY `--robot-*` flags. Bare `bv` launches TUI that blocks your session.**

## Core Commands

```bash
bv --robot-triage        # THE MEGA-COMMAND: start here
bv --robot-next          # Single top pick + claim command
bv --robot-plan          # Parallel execution tracks
bv --robot-priority      # Priority misalignment detection
```

## Triage Output

Returns: `quick_ref`, `recommendations`, `quick_wins`, `blockers_to_clear`, `project_health`, `commands`

## Graph Analysis

| Command | Returns |
|---------|---------|
| `--robot-insights` | PageRank, betweenness, HITS, cycles, critical path |
| `--robot-label-health` | Per-label health levels |
| `--robot-label-flow` | Cross-label dependencies |
| `--robot-alerts` | Stale issues, blocking cascades |

## Filtering

```bash
bv --robot-plan --label backend
bv --recipe actionable --robot-triage
bv --robot-triage --robot-triage-by-label
```

## jq Examples

```bash
bv --robot-triage | jq '.quick_ref'
bv --robot-triage | jq '.recommendations[0]'
bv --robot-insights | jq '.Cycles'
```

**Note:** Phase 1 (degree, topo sort) is instant. Phase 2 (PageRank, betweenness) has 500ms timeout.
