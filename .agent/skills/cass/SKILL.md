---
name: cass
description: Cross-agent session search. Use when looking for solutions from previous agent sessions or searching conversation history.
---

# cass — Cross-Agent Session Search

`cass` indexes prior agent conversations (Claude Code, Codex, Cursor, Gemini, ChatGPT, etc.) so we can reuse solved problems.

**Rule:** Never run bare `cass` (TUI). Always use `--robot` or `--json`.

## Commands

```bash
cass health                                    # Check index status
cass search "authentication error" --robot --limit 5
cass view /path/to/session.jsonl -n 42 --json
cass expand /path/to/session.jsonl -n 42 -C 3 --json
cass capabilities --json
cass robot-docs guide
```

## Tips

- Use `--fields minimal` for lean output
- Filter by agent with `--agent`
- Use `--days N` to limit to recent history

**stdout** is data-only, **stderr** is diagnostics; exit code 0 = success.

Use cass to avoid re-solving problems other agents already handled.
