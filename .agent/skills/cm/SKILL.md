---
name: cm
description: Cass Memory System for agent learning. Use when retrieving past lessons, extracting rules from sessions, or building procedural memory.
---

# cass-memory (cm) — Agent Memory System

The Cass Memory System gives agents procedural memory by analyzing historical sessions and extracting valuable lessons.

## Quick Start

```bash
cm onboard status                              # Check status
cm onboard sample --fill-gaps                  # Get sessions to analyze
cm onboard read /path/to/session.jsonl --template
cm playbook add "Rule content" --category "debugging"
cm onboard mark-done /path/to/session.jsonl
```

## Before Complex Tasks

```bash
cm context "<task description>" --json
```

Returns:
- **relevantBullets**: Rules that may help
- **antiPatterns**: Pitfalls to avoid
- **historySnippets**: Past sessions with similar problems
- **suggestedCassQueries**: Searches for deeper investigation

## Protocol

1. **START**: `cm context "<task>" --json` before non-trivial work
2. **WORK**: Reference rule IDs (e.g., "Following b-8f3a2c...")
3. **FEEDBACK**: `// [cass: helpful b-xyz] - reason` or `// [cass: harmful b-xyz]`
4. **END**: Just finish. Learning happens automatically.

## Key Flags

| Flag | Purpose |
|------|---------|
| `--json` | Machine-readable output (required!) |
| `--limit N` | Cap rules returned |
| `--no-history` | Faster response |
