# Safety Rules for AI Coding Agents

> These rules apply to all coding agents working on this project. They replicate the protection provided by DCG (Destructive Command Guard) for Claude Code.

## Absolutely Forbidden Commands

The following commands are **never** to be executed without explicit user approval in the same session:

### Git Commands
```bash
git reset --hard           # Destroys uncommitted changes
git checkout -- <files>    # Discards file changes permanently
git restore <files>        # Same as checkout -- (not --staged)
git push --force / -f      # Overwrites remote history
git clean -f               # Deletes untracked files
git branch -D              # Force-deletes without merge check
git stash drop / clear     # Permanently deletes stashes
```

### Filesystem Commands
```bash
rm -rf <non-temp>          # Recursive deletion
rmdir                      # Directory deletion
```

## Always Safe Commands
```bash
git checkout -b <branch>   # Creates branch, doesn't touch files
git restore --staged       # Only unstages, safe
git clean -n               # Dry-run, preview only
rm -rf /tmp/...            # Temp directories are ephemeral
git push --force-with-lease # Safe force push variant
```

## When You Need a Destructive Command

1. **STOP** and explain to the user why it's needed
2. **Suggest safer alternatives** if available
3. **Ask the user to run it manually** if truly required
4. **Never bypass** these protections—they exist for your safety too

## Multi-Agent Awareness

When working alongside other agents:
- Never disturb changes you didn't make
- Treat unfamiliar changes as if you made them yourself
- Use MCP Agent Mail for file reservations when available
