---
name: acfs-tools
description: ACFS CLI commands reference. Use when working with ACFS utilities like doctor, newproj, info, update, or dashboard.
---

# ACFS CLI Tools

ACFS provides several CLI commands for managing your agentic coding environment.

## Available Commands

### `acfs doctor`

Health check for installed tools. Run after installation or when troubleshooting.

```bash
acfs doctor              # Terminal output
acfs doctor --json       # JSON output for scripting
```

### `acfs newproj`

Create a new project with ACFS defaults (git init, AGENTS.md, beads, Claude settings).

```bash
acfs newproj myapp                # CLI mode
acfs newproj --interactive        # TUI wizard (recommended)
acfs newproj -i myapp             # Prefill project name
```

### `acfs info`

Lightning-fast system overview (reads cached state).

```bash
acfs info                # Terminal output
acfs info --json         # JSON for scripting
acfs info --minimal      # Just essentials
```

### `acfs update`

Update all installed tools.

```bash
acfs-update              # Update apt, runtimes, shell, agents, cloud
acfs-update --stack      # Include Dicklesworthstone stack
acfs-update --dry-run    # Preview without changes
```

### `acfs cheatsheet`

Discover aliases and shortcuts installed by ACFS.

```bash
acfs cheatsheet
```

### `acfs dashboard generate`

Generate an HTML status page.

```bash
acfs dashboard generate
```

### `acfs services-setup`

Configure agent credentials (Claude, Codex, Gemini).

```bash
acfs services-setup
```

### `acfs continue`

View upgrade progress after reboot (during Ubuntu upgrades).

```bash
acfs continue
```

## Key Aliases

| Alias | Command | Notes |
|-------|---------|-------|
| `cc` | Claude Code | dangerously-skip-permissions |
| `cod` | Codex CLI | dangerously-bypass-approvals |
| `gmi` | Gemini CLI | yolo mode |
| `amp` | Amp CLI | |

## Configuration Files

- `~/.acfs/state.json` — Installation state and checkpoints
- `~/.acfs/zsh/acfs.zshrc` — Shell configuration
- `~/.acfs/logs/` — Update and installation logs
