---
name: ru
description: Multi-repo sync tool with AI-driven commit automation. Use when managing multiple repositories or automating commits.
---

# RU (Repo Updater) — Multi-Repo Sync

Multi-repo sync tool with **AI-driven commit automation**.

## Common Commands

```bash
ru sync                        # Clone missing + pull updates
ru sync --parallel 4           # Parallel sync
ru status                      # Check status without changes
ru status --fetch              # Show ahead/behind
ru list --paths                # List all repo paths
```

## Agent Sweep (Commit Automation)

```bash
ru agent-sweep --dry-run       # Preview dirty repos
ru agent-sweep --parallel 4    # AI-driven commits in parallel
ru agent-sweep --with-release  # Include version tag + release
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Partial failure |
| 2 | Conflicts (manual resolution) |
| 5 | Interrupted (use `--resume`) |

## Best Practices

- `ru status` before `ru sync`
- `ru agent-sweep --dry-run` before full automation
- Scope with `--repos=pattern`
