# Agent Parity Report: Multi-Agent Configuration Status

**Last Updated:** January 25, 2026

## Executive Summary

This report documents the current state of multi-agent configuration parity in the ACFS repository. Following the AGENTS.md refactoring, all agents now share a common configuration foundation.

| Metric | Status |
|--------|--------|
| **AGENTS.md** | 229 lines (refactored from 906) |
| **Skills extracted** | 8 |
| **Agents supported** | Claude, Gemini, Antigravity, Codex, AMP |

---

## Part 1: Current Configuration Structure

### 1.1 Directory Layout

```
Repository Root
├── AGENTS.md                    ← Universal instructions (229 lines)
├── GEMINI.md → AGENTS.md        ← Symlink for Gemini/Antigravity
│
├── .agent/                      ← Shared agent resources
│   ├── rules/
│   │   ├── ubs.md              ← Canonical UBS reference
│   │   └── safety.md           ← DCG-equivalent rules
│   ├── skills/                 ← On-demand tool documentation
│   │   ├── beads/SKILL.md
│   │   ├── mcp-mail/SKILL.md
│   │   ├── cass/SKILL.md
│   │   ├── cm/SKILL.md
│   │   ├── warp-grep/SKILL.md
│   │   ├── ru/SKILL.md
│   │   ├── giil/SKILL.md
│   │   └── csctf/SKILL.md
│   └── workflows/
│
├── .claude/hooks/               ← Claude-only hooks
│   └── on-file-write.sh        ← UBS integration
│
├── .gemini/rules                ← Gemini CLI rules
├── .codex/rules/ubs.md         ← Codex CLI rules
├── .cursor/rules               ← Cursor rules
├── .cline/rules                ← Cline rules
├── .continue/config.json       ← Continue slash commands
│
└── .githooks/pre-commit         ← Universal UBS pre-commit
```

### 1.2 How Each Agent Accesses Configuration

| Agent | Instructions | Skills | Hooks | Rules |
|-------|-------------|--------|-------|-------|
| **Claude Code** | `AGENTS.md` | Manual `@` reference | ✅ `.claude/hooks/` | Via instructions |
| **Gemini CLI** | `GEMINI.md` → `AGENTS.md` | ✅ `~/.gemini/skills/` | ❌ | `.gemini/rules` |
| **Antigravity** | `GEMINI.md` → `AGENTS.md` | ✅ `.agent/skills/` | ❌ | `.agent/rules/` |
| **Codex CLI** | `AGENTS.md` | ✅ Via config | ❌ | `.codex/rules/` |
| **AMP** | `AGENTS.md` | ✅ Native | ❌ | Via instructions |

---

## Part 2: Feature Parity Matrix

### 2.1 Current Status

| Feature | Claude | Gemini | Antigravity | Codex | AMP |
|---------|--------|--------|-------------|-------|-----|
| **Installation (manifest)** | ✅ | ✅ | N/A (IDE) | ✅ | ✅ |
| **Shell alias** | ✅ `cc` | ✅ `gmi` | N/A | ✅ `cod` | ✅ `amp` |
| **Shared instructions** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **UBS inline (AGENTS.md)** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **DCG inline (AGENTS.md)** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Skills system** | Manual | ✅ `~/.gemini/skills/` | ✅ Native | ✅ Config | ✅ Native |
| **File-write hooks** | ✅ UBS | ❌ | ❌ | ❌ | ❌ |
| **Pre-commit hook** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **DCG protection** | ✅ Native | ⚠️ Via rules | ⚠️ Via rules | ⚠️ Via rules | ⚠️ Via rules |
| **MCP support** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **CASS session indexing** | ✅ | ✅ | ✅ | ✅ | ⚠️ Unknown |

### 2.2 Parity Achieved

✅ **Shared Instructions** — All agents read same `AGENTS.md` content  
✅ **UBS/DCG Inline** — Critical safety info available to all agents  
✅ **Skills Structure** — `.agent/skills/` created for supporting agents  
✅ **Pre-commit Hook** — Universal UBS check available via `.githooks/`  
✅ **Rules Files** — UBS reference deployed to agent-specific directories  

### 2.3 Remaining Gaps

| Gap | Impact | Mitigation |
|-----|--------|------------|
| No file-write hooks for non-Claude | UBS runs at commit, not save | Pre-commit hook covers this |
| DCG Claude-only | Other agents unguarded | Safety rules in AGENTS.md + `.agent/rules/safety.md` |

---

## Part 3: Skills Reference

Skills extracted from AGENTS.md to `.agent/skills/`:

| Skill | Purpose | Auto-loads In |
|-------|---------|---------------|
| `beads` | Issue tracking (br + bv) | Gemini, Antigravity, Codex, AMP |
| `mcp-mail` | Multi-agent coordination | Gemini, Antigravity, Codex, AMP |
| `cass` | Cross-agent session search | Gemini, Antigravity, Codex, AMP |
| `cm` | Agent memory system | Gemini, Antigravity, Codex, AMP |
| `warp-grep` | AI-powered code search | Gemini, Antigravity, Codex, AMP |
| `ru` | Multi-repo sync | Gemini, Antigravity, Codex, AMP |
| `giil` | Cloud image download | Gemini, Antigravity, Codex, AMP |
| `csctf` | Chat-to-file converter | Gemini, Antigravity, Codex, AMP |

For Claude: Use `@.agent/skills/<name>/SKILL.md` to load manually.

---

## Part 4: Remaining Action Items

### Priority 0 (High Impact, Low Effort) — ✅ COMPLETE

- [x] Add Amp to `acfs.manifest.yaml`
- [x] Add `amp` shell alias to `acfs/zsh/acfs.zshrc`
- [x] Add Amp doctor checks

### Priority 1 (Medium Effort) — ✅ COMPLETE

- [x] Update `acfs newproj` to create configs for ALL agents:
  - Claude settings (`.claude/settings.toml`)
  - Gemini rules (`.gemini/rules`)
  - Codex rules (`.codex/rules/ubs.md`)
  - GEMINI.md symlink → AGENTS.md
- [x] Rule files now symlinked to `.agent/rules/ubs.md`

### Priority 2 (Research) — ✅ COMPLETE

| Agent | Hook System | DCG Compatible? |
|-------|-------------|-----------------|
| **Claude Code** | `PreToolUse` in settings.json | ✅ Yes |
| **Gemini CLI** | None documented | ❌ No |
| **Codex CLI** | None documented | ❌ No |
| **AMP** | None documented | ❌ No |

**Conclusion:** DCG cannot be extended to other agents — they lack hook APIs.

**Mitigation:** Safety rules in AGENTS.md + pre-commit hook + agent-specific rules files provide equivalent protection through instruction-based safety.

---

## Appendix A: File Locations

### Global (User Home)

| Agent | Config | Auth |
|-------|--------|------|
| Claude | `~/.claude/settings.json` | `~/.claude/config.json` |
| Gemini | `~/.gemini/settings.json` | OAuth via browser |
| Codex | `~/.codex/config.toml` | `~/.codex/auth.json` |
| AMP | `~/.config/amp/` | OAuth via browser |

### Project-Level

| Agent | Instructions | Hooks |
|-------|-------------|-------|
| Claude | `AGENTS.md` | `.claude/hooks/` |
| Gemini | `GEMINI.md` → `AGENTS.md` | N/A |
| Antigravity | `GEMINI.md` + `.agent/skills/` | N/A |
| Codex | `AGENTS.md` + `.codex/rules/` | N/A |
| AMP | `AGENTS.md` | N/A |

---

## Appendix B: Enabling Pre-commit Hook

```bash
ln -sf ../../.githooks/pre-commit .git/hooks/pre-commit
```

This enables UBS scanning before commits for ALL agents.
