# Cost-Optimized Agentic Coding Setup

## Research Foundation

This plan is derived from five authoritative sources. Below is a complete inventory of every capability/component identified, with reasoning about what to include and why.

---

## SOURCE 1: Agent-Native Development Guide (every.to/guides/agent-native)

### Architectural Principles Identified

| Principle | Description | Relevance to Our Setup |
|-----------|-------------|------------------------|
| **Parity Principle** | Whatever user can do via UI, agent should achieve via tools | HIGH - Ensures agents aren't artificially limited |
| **Granularity Over Bundling** | Tools should be atomic primitives; features are outcomes from agent loops | HIGH - Affects how we design slash commands |
| **Composability** | New features are prompts composed from primitives | HIGH - Enables rapid feature expansion |
| **Emergent Capability** | Agent solves unplanned tasks; gaps reveal next domain tools | HIGH - Guides tool roadmap and prioritization |
| **Improvement Over Time** | Context/prompt refinement; self-modification needs safety rails | MEDIUM - Requires approval/checkpoints |
| **Decision Logic in Prompts** | Agent makes judgments; tools execute primitives | MEDIUM - Guides prompt engineering |
| **Tool Graduation Path** | Primitives → Domain tools → Optimized hot paths | LOW - More relevant for app development |

### Cost Optimization Strategies Identified

| Strategy | Description | Include? | Reasoning |
|----------|-------------|----------|-----------|
| **Model Tier Selection** | Different intelligence levels per task type | YES | Core of our cost strategy |
| **Context Injection Pattern** | Bounded context with resources/capabilities/recent context | YES | Reduces token usage |
| **Context Consolidation** | Mid-session summarization ("summarize learnings and continue") | YES | Prevents context overflow |
| **Iterative Refinement** | Summary → detail → full (progressive disclosure) | YES | Reduces unnecessary token usage |

### File-Based Architecture Components

| Component | Description | Include? | Reasoning |
|-----------|-------------|----------|-----------|
| **CLAUDE.md / context.md** | Portable working memory without code changes | YES | Already in our plan |
| **Entity-scoped directories** | `{entity_type}/{entity_id}/` pattern | PARTIAL | Adapt for project structure |
| **Conflict model + file locking** | Check-before-write, drafts/, append-only logs, locks | YES | Prevents multi-writer clobbering |
| **File-first + hybrid store** | Files for legibility, DB for structure, sync as needed | PARTIAL | Keep agent-visible source of truth |
| **Agent checkpoints** | Ephemeral session state saves | YES | Already in our plan |
| **Agent logs** | Per-session debugging logs | YES | Add to our plan |

### Workflow Patterns Identified

| Pattern | Description | Include? | Reasoning |
|---------|-------------|----------|-----------|
| **Explicit Completion Signals** | `shouldContinue: bool` vs heuristic detection | MEDIUM | More relevant for building agents |
| **Control Signals (pause/escalate/retry)** | Non-completion control flow states | MEDIUM | Clear handoff + retry semantics |
| **Partial Completion Tracking** | Task status with notes on failures | YES | Already using TodoWrite pattern |
| **Context Refresh** | Refresh context in long sessions; on-demand summaries | YES | Prevents stale context |
| **Shared Workspace Default** | Agents + users operate in same data space | YES | Reduces sync complexity |
| **Dynamic Capability Discovery** | `list_available_types()` pattern | LOW | Over-engineering for our use case |
| **CRUD Completeness Audit** | Verify agent has Create/Read/Update/Delete for every entity | LOW | More relevant for app development |

### Anti-Patterns to Avoid

| Anti-Pattern | Description | How We Avoid It |
|--------------|-------------|-----------------|
| Agent as router only | Using intelligence just to route to functions | Our agents do actual work |
| Build-then-add-agent | Traditional features first, agent as wrapper | Agent-first approach |
| Request/response thinking | Missing the loop | Workflows have explicit phases |
| Context starvation | Agent doesn't know what exists | CLAUDE.md provides full context |
| Heuristic completion | Detecting done-ness from behavior | Explicit checkpoints |
| Bundled tool judgment | Tools encode decision logic | Keep tools atomic + prompt-driven |

---

## SOURCE 2: Awesome Claude Code (github.com/hesreallyhim/awesome-claude-code)

### Cost Monitoring Tools

| Tool | Description | Include? | Reasoning |
|------|-------------|----------|-----------|
| **ccflare/better-ccflare** | Web dashboard for usage metrics, cost tracking | CONSIDER | Useful but requires web hosting |
| **ccusage** | CLI tool analyzing local logs for cost info | YES | Essential for cost tracking |
| **Claude Code Usage Monitor** | Real-time terminal showing live consumption, burn rate | YES | Critical for cost awareness |
| **claudia-statusline** | Rust-based statusline with SQLite persistence | OPTIONAL | Nice-to-have, not critical |

### Token Conservation Strategies

| Strategy | Description | Include? | Reasoning |
|----------|-------------|----------|-----------|
| **CLAUDE.md files** | Project-specific context instead of repeated explanations | YES | Already in plan |
| **Hooks for automation** | Automate repetitive tasks without manual prompting | YES | Critical for efficiency |
| **Context priming commands** | `/prime` or `/context-prime` to load project understanding | YES | Already in plan |
| **Context Engineering Kit** | Minimal token footprint techniques | YES | Adopt lightweight context patterns |

### Session & Context Management

| Tool | Description | Include? | Reasoning |
|------|-------------|----------|-----------|
| **recall** | Full-text search across sessions | YES | Critical for continuity |
| **ccexp** | Interactive CLI for discovering config files | OPTIONAL | Nice-to-have |
| **cchistory** | List all Bash commands from sessions | OPTIONAL | Debugging utility |
| **claude-code-tools** | Avoid compaction, cross-agent handoff, full-text search | YES | Critical for long sessions |
| **Claudex** | Web browser for conversation history | OPTIONAL | Web-based, extra complexity |
| **claudekit** | Auto-save checkpointing + quality hooks | YES | Aligns with checkpoint + QA strategy |
| **Claude CodePro** | TDD enforcement + semantic search | CONSIDER | Heavyweight but feature-rich |
| **RIPER Workflow** | Branch-aware memory bank | YES | Already in plan |

### Workflow Approaches

| Workflow | Description | Include? | Reasoning |
|----------|-------------|----------|-----------|
| **AB Method** | Spec-driven workflow with specialized sub-agents | YES | Already in plan |
| **RIPER Workflow** | Research → Innovate → Plan → Execute → Review phases | YES | Already in plan |
| **Agentic Workflow Patterns** | Pattern catalog for orchestration | CONSIDER | Reference for edge cases |
| **ContextKit** | 4-phase planning methodology | CONSIDER | May overlap with RIPER |
| **TDD Guard** | Real-time monitoring blocking TDD violations | OPTIONAL | Strict, may slow velocity |

### Multi-Agent Orchestration

| Tool | Description | Include? | Reasoning |
|------|-------------|----------|-----------|
| **Ralph Wiggum Technique** | Autonomous task completion until marked complete | YES | Useful pattern |
| **Claude Squad** | Manage multiple Claude Code instances | YES | Critical for parallel work |
| **Happy Coder** | Spawn/control multiple Claude Codes, push notifications | YES | Alternative to Claude Squad |
| **Claude Task Runner** | Context isolation for focused execution | CONSIDER | Helps with long tasks |
| **TSK** | Rust CLI for sandboxed Docker environments | CONSIDER | Adds complexity |

### IDE Integration

| Tool | Description | Include? | Reasoning |
|------|-------------|----------|-----------|
| **Claudix** | VSCode extension | OPTIONAL | User prefers CLI |
| **claude-code.nvim** | Neovim integration | OPTIONAL | If user uses Neovim |
| **claude-code-ide.el** | Emacs integration | OPTIONAL | If user uses Emacs |

### Safety & Sandboxing

| Tool | Description | Include? | Reasoning |
|------|-------------|----------|-----------|
| **Container Use** | Dev environments for multiple agents | CONSIDER | Adds complexity |
| **run-claude-docker** | Isolated Docker container | CONSIDER | For dangerous operations |
| **viwo-cli** | Docker + git worktrees for safer skip-permissions | CONSIDER | Advanced safety |

### Hooks & Automation

| Tool | Description | Include? | Reasoning |
|------|-------------|----------|-----------|
| **cchooks** | Python SDK for hook writing | YES | Clean API for hooks |
| **claude-hooks** | TypeScript-based hook system | ALTERNATIVE | If preferring TS |
| **cc-tools** | High-performance hooks for lint/test/statusline | YES | Low-overhead quality gates |
| **TypeScript Quality Hooks** | Lint/typecheck/prettier hook bundle | OPTIONAL | TS-only repos |
| **Auto-skill selection hooks** | Hook-driven skill routing | CONSIDER | Reduces manual skill selection |

### Slash Commands

| Command | Description | Include? | Reasoning |
|---------|-------------|----------|-----------|
| **/prime** | Standardized context setup | YES | Already in plan |
| **/commit** | Conventional commit format | YES | Already in plan |
| **/tdd** | Red-Green-Refactor discipline | YES | Already in plan |
| **/optimize** | Performance bottleneck identification | CONSIDER | Useful addition |

### Multi-Model Orchestration

| Capability | Description | Include? | Reasoning |
|------------|-------------|----------|-----------|
| **Gemini CLI orchestration** | Use Gemini for specialized tasks | YES | Core of cost strategy |
| **claudekit Oracle subagent** | Use GPT-5 for specific capabilities | CONSIDER | If user has OpenAI sub |
| **Cross-agent handoff** | Claude Code ↔ Codex CLI | YES | Flexibility |

---

## SOURCE 3: Agentic Coding Flywheel Setup (ACFS)

### Core Architecture Components

| Component | Description | Include? | Reasoning |
|-----------|-------------|----------|-----------|
| **Manifest-driven installation** | Single source of truth YAML | ADAPT | Improves tool availability/version pinning |
| **10-phase installation** | Structured setup with resume | ADAPT | Simpler version for our needs |
| **State machine with checkpoints** | `state.json` with atomic writes | YES | Critical for resume capability |
| **Checksum + HTTPS verification** | Fail-closed installer verification | YES | Supply-chain protection |
| **Doctor/health checks** | Post-install verification (`acfs doctor`) | YES | Ensures toolchain validity |
| **Ubuntu auto-upgrade** | Target Ubuntu 25.10 | NO | User already has environment |

### AI Coding Agents (The "Big Three")

| Agent | Alias | Dangerous Flag | Include? | Reasoning |
|-------|-------|----------------|----------|-----------|
| **Claude Code** | `cc` | `--dangerously-skip-permissions` | YES | Primary agent |
| **Codex CLI** | `cod` | `--dangerously-bypass-approvals-and-sandbox` | CONSIDER | If user has ChatGPT Plus |
| **Gemini CLI** | `gmi` | `--yolo` | YES | Free tier for cost savings |

### Shell & Terminal UX

| Tool | Description | Include? | Reasoning |
|------|-------------|----------|-----------|
| **zsh + oh-my-zsh + powerlevel10k** | Modern shell with fast prompt | OPTIONAL | User preference |
| **lsd** | Modern ls with icons | OPTIONAL | Nice-to-have |
| **atuin** | Searchable shell history | CONSIDER | Useful for recall |
| **fzf** | Fuzzy finder | CONSIDER | Productivity boost |
| **zoxide** | Smarter cd | CONSIDER | Productivity boost |
| **direnv** | Directory-specific env vars | YES | Critical for project isolation |

### Development Tools

| Tool | Description | Include? | Reasoning |
|------|-------------|----------|-----------|
| **tmux** | Terminal multiplexer | YES | Critical for multi-agent |
| **ripgrep** | Fast recursive grep | YES | Already using via Claude |
| **ast-grep** | Structural code search | CONSIDER | Advanced searching |
| **lazygit** | Git TUI | OPTIONAL | Nice-to-have |
| **GitHub CLI** | `gh` commands | YES | Already using |

### Dicklesworthstone Stack (CRITICAL - 10 Tools)

| Tool | Description | Include? | Reasoning |
|------|-------------|----------|-----------|
| **NTM (Named Tmux Manager)** | Agent orchestration cockpit | YES | Critical for multi-agent |
| **MCP Agent Mail** | Message-passing + file reservations | YES | Prevents agent conflicts |
| **UBS (Ultimate Bug Scanner)** | Bug scanning with guardrails | CONSIDER | Quality assurance |
| **Beads Viewer (bv)** | Task management TUI with graph analysis | CONSIDER | Visual task tracking |
| **CASS** | Unified agent history search | YES | Critical for context |
| **CASS Memory (cm)** | Procedural memory system | YES | Learning from past sessions |
| **CAAM** | Agent auth switching | OPTIONAL | If using multiple accounts |
| **SLB** | Two-person rule for dangerous commands | OPTIONAL | Extra safety layer |
| **DCG (Destructive Command Guard)** | Sub-ms Rust hook blocking destructive git/fs commands | YES | CRITICAL safety |
| **RU (Repo Updater)** | Multi-repo sync + AI-driven commit automation | CONSIDER | If managing multiple repos |

### DCG Blocked Commands (IMPORTANT)

| Blocked | Why |
|---------|-----|
| `git reset --hard` | Destroys uncommitted work |
| `git checkout -- <files>` | Discards changes |
| `git push --force` | Rewrites remote history |
| `git clean -f` | Deletes untracked files |
| `git branch -D` | Force deletes branch |
| `git stash drop/clear` | Loses stashed work |
| `rm -rf` (except temp dirs) | Destructive file deletion |

### Multi-Agent Coordination Stack

```
Agent Mail (Messaging) + NTM (Sessions) + SLB/DCG (Safety) + Beads (Tasks)
                              ↓
                    File Reservation System
                              ↓
                  No conflicts, parallel progress
```

### File Reservation Pattern (FROM ACFS)

```python
# Agent A reserves auth module
mcp.file_reservation_paths(paths=["src/auth/*"], exclusive=true, ttl=3600)

# Agent B tries same files → CONFLICT
# Agent B reserves different files → GRANTED
mcp.file_reservation_paths(paths=["src/api/*"], exclusive=true, ttl=3600)
```

**THIS IS MISSING FROM OUR CURRENT PLAN** - Critical for preventing agent conflicts.

### VPS Recommendations (FOR REFERENCE)

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| RAM | 32GB (tight) | 48-64GB |
| Storage | 250GB NVMe | 300GB+ NVMe |
| CPU | 12 vCPU | 16 vCPU |
| Why 48-64GB? | Each agent uses ~2GB; 10-20+ agents need 48GB+ |

**User has 32GB RAM** - This limits us to ~10-15 simultaneous agents max.

### Security Model

| Protection | Method |
|------------|--------|
| MITM attacks | HTTPS enforcement |
| Compromised scripts | SHA256 checksum verification |
| Supply-chain drift | Pin installer via `ACFS_REF` (tag/commit) |
| Credential exposure | No secrets in scripts |
| Dangerous commands | DCG hook blocking |
| Vibe mode abuse | Only for throwaway environments |

**Deep Dive Notes (ACFS):**
- `checksums.yaml` + `scripts/lib/security.sh` enforce HTTPS and fail-closed checksum verification for installers.
- `state.json` writes are atomic (temp + rename) to survive interruption and resume cleanly.
- `acfs doctor` provides post-install health checks; use it as a required verification step.

---

## SOURCE 4: Compound Engineering Plugin (EveryInc)

### Core Philosophy

**"Each unit of engineering work should make subsequent units easier—not harder."**

**The 80/20 Split:**
- 80% planning/review
- 20% execution

This inverts traditional development's technical debt accumulation.

### Workflow Architecture

| Phase | Command | Purpose |
|-------|---------|---------|
| **Plan** | `/workflows:plan` | Transform feature ideas into detailed implementation plans |
| **Work** | `/workflows:work` | Execute plans using git worktrees for isolation |
| **Review** | `/workflows:review` | Multi-agent code review before merging |
| **Compound** | `/workflows:compound` | Document learnings to simplify future work |

**Cycle: Plan → Work → Review → Compound → Repeat**

### Key Features Identified

| Feature | Description | Include? | Reasoning |
|---------|-------------|----------|-----------|
| **Multi-agent review** | Multiple specialized agents review code | YES | Catches different issue types |
| **Git worktree integration** | Isolated development branches | YES | Clean separation for parallel work |
| **Knowledge accumulation** | Plans/learnings inform future cycles | YES | Reduces planning time over time |
| **Task tracking** | Built-in progress monitoring | YES | Already have via TodoWrite |
| **Quality gates** | Review phase as mandatory checkpoint | YES | Prevents technical debt |
| **Compound docs** | Auto-capture fixes with YAML frontmatter | YES | Prevents knowledge loss |
| **File-todos** | File-based todo queue with status/priority | CONSIDER | Simplifies task tracking |
| **Parallel plan research** | /plan launches repo + best-practices + docs research | YES | Better plans, less rework |
| **P1 merge blocking** | Critical findings block merges | YES | Enforces quality gates |

### Directory Structure

```
.claude-plugin/          # Plugin configuration
plans/                   # Implementation plans (reference for future)
docs/solutions/          # Compounded fixes with YAML frontmatter
todos/                   # File-based task queue
.worktrees/              # Optional worktree isolation
```

### Compounding Principles

| Principle | Description | How to Apply |
|-----------|-------------|--------------|
| **Plans inform future plans** | Reference previous plans for similar work | Store plans in `plans/` (or `.claude/plans/`) |
| **Reviews catch more over time** | Pattern recognition improves | Document common issues |
| **Patterns become reusable** | Codified solutions prevent duplicate work | Add to CLAUDE.md |
| **Each cycle improves next** | Continuous improvement loop | Append to `progress.txt` |

**Deep Dive Notes (Compound Plugin):**
- `/plan` launches parallel research agents before writing `plans/<issue>.md`.
- `/review` synthesizes findings by severity; P1s block merge.
- `/compound` auto-triggers on "that worked/it's fixed" and writes to `docs/solutions/<category>/`.
- MCP servers (Context7/Playwright) may require manual entry in `.claude/settings.json`.

### Cost Optimization Implications

| Mechanism | Savings |
|-----------|---------|
| Reduced rework | Thorough planning reduces implementation errors |
| Knowledge reuse | Documented patterns reduce research time |
| Better estimation | Accumulated learnings improve accuracy |
| Fewer bugs | Multi-agent review catches issues before production |

---

## SOURCE 5: Ralph - Autonomous Agent Loop (snarktank)

### Core Architecture

**Ralph runs AI agents repeatedly until all PRD items are complete.**

Key innovation: **Fresh instances with clean context on each iteration** - prevents context window exhaustion.

### Memory Persistence Mechanisms

| Mechanism | Purpose |
|-----------|---------|
| **Git history** | Commits from previous iterations |
| **`progress.txt`** | Append-only learnings for future iterations |
| **`prd.json`** | Task list with completion status tracking |
| **`AGENTS.md`** | Learnings that agents auto-read |

**THIS IS CRITICAL:** Memory persists through files, not context. Each iteration starts fresh but reads accumulated knowledge.

### Execution Flow

```
1. Create feature branch from PRD branchName
2. Select highest priority story where passes: false
3. Implement the single story
4. Run quality checks (typecheck, tests)
5. Update AGENTS.md with reusable patterns/gotchas (if any)
6. Commit if checks pass (format: `feat: [Story ID] - [Story Title]`)
7. Update prd.json to mark story as passes: true
8. Append learnings to progress.txt
9. Repeat until all stories pass OR max iterations reached
```

### File Structure

| File | Purpose | Include? |
|------|---------|----------|
| `ralph.sh` | Bash loop that spawns fresh agent instances | YES - adapt pattern |
| `prompt.md` | Instructions given to each agent instance | YES |
| `prd.json` | User stories with completion status | YES |
| `tasks/prd-*.md` | Source PRDs for conversion | YES |
| `progress.txt` | Append-only learnings repository | YES |
| `AGENTS.md` | Auto-read context for future iterations | YES |
| `archive/` | Archived runs per feature | CONSIDER |

### PRD -> prd.json Workflow (Deep Dive)

1. Generate PRD with a dedicated skill (ask 3-5 clarifying questions).
2. Convert PRD to `prd.json` with right-sized stories (one iteration each).
3. Order stories by dependency (schema -> backend -> UI -> aggregates).
4. Enforce verifiable acceptance criteria:
   - Always include **Typecheck passes**
   - Include **Tests pass** when logic is testable
   - For UI stories: **Verify in browser using dev-browser skill**

### Execution Discipline (Deep Dive)
- Commit format: `feat: [Story ID] - [Story Title]`
- Append progress with a consistent template (include thread URL + learnings).
- Maintain a **Codebase Patterns** section at top of `progress.txt` for reusable rules.

### Task Granularity Principle (CRITICAL)

**Right-sized stories** (completable in one context window):
- Add a database column and migration
- Add a UI component to existing page
- Update server action with new logic
- Add filter dropdown to list

**Oversized stories** (need splitting):
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

**Key insight:** "If a task is too big, the LLM runs out of context before finishing and produces poor code."

### AGENTS.md Pattern (CRITICAL)

Ralph updates `AGENTS.md` after each iteration. Content types:

| Content Type | Example |
|--------------|---------|
| **Patterns discovered** | "This codebase uses X pattern for Y" |
| **Gotchas** | "Always update Z before modifying W" |
| **Useful context** | "Components for feature X are in src/Y/" |

**Why critical:** "Amp automatically reads these files, so future iterations (and future human developers) benefit."

### Stop Conditions

| Condition | Meaning |
|-----------|---------|
| All stories have `passes: true` | Work complete |
| Agent outputs `<promise>COMPLETE</promise>` | Explicit completion signal |
| Maximum iterations reached | Safety limit (default: 10) |

### Feedback Loops (REQUIRED)

| Check | Purpose |
|-------|---------|
| Typecheck | Catches type errors |
| Tests | Verifies behavior |
| CI green | Broken code compounds across iterations |
| Browser verification | UI changes validated via dev-browser | Required for frontend stories |

**"Ralph only works if there are feedback loops."** Without automated checks, errors compound across iterations.

### Auto-Handoff Configuration

```json
{
  "experimental.autoHandoff": { "context": 90 }
}
```

Enables automatic handoff when context fills up - allows handling large stories exceeding single context window.

---

## CAPABILITY GAP ANALYSIS (UPDATED WITH ALL 5 SOURCES)

### What Our Original Plan Had

| Capability | Status |
|------------|--------|
| Model routing (free/mid/premium tiers) | ✅ Complete |
| Cost tracking (ccost, ccreport) | ✅ Complete |
| Slash commands (/prime, /commit, /review, /test, /tdd, /checkpoint, /resume) | ✅ Complete |
| CLAUDE.md template | ✅ Complete |
| context.md pattern | ✅ Complete |
| RIPER workflow | ✅ Complete |
| AB Method workflow | ✅ Complete |
| Session continuity | ✅ Complete |
| Git hooks | ✅ Complete |

### What Was MISSING (Now Adding)

| Capability | Source | Priority | Why Critical |
|------------|--------|----------|--------------|
| **DCG (Destructive Command Guard)** | ACFS | CRITICAL | Prevents catastrophic git/fs mistakes |
| **Checksum + HTTPS verification** | ACFS | CRITICAL | Supply-chain protection for installs |
| **File reservation system** | ACFS | HIGH | Prevents multi-agent conflicts |
| **NTM (Named Tmux Manager)** | ACFS | HIGH | Orchestrates multiple agents |
| **CASS (Agent History Search)** | ACFS | HIGH | Context across all agent sessions |
| **CASS Memory** | ACFS | MEDIUM | Procedural memory from past work |
| **Agent Mail / MCP** | ACFS | MEDIUM | Inter-agent communication |
| **Context consolidation** | Agent-Native | MEDIUM | Mid-session summarization |
| **Conflict model + file locking** | Agent-Native | HIGH | Prevents multi-writer clobbering |
| **Control signals (pause/escalate/retry)** | Agent-Native | MEDIUM | Clear handoff and retry semantics |
| **Agent logging** | Agent-Native | MEDIUM | Debugging agent behavior |
| **Gemini CLI wrapper** | Our plan | HIGH | Free tier API access |
| **OpenRouter wrapper** | Our plan | HIGH | Free model access |
| **Batching strategy** | Our plan | MEDIUM | Reduce API calls |
| **Compound workflow** | Compound Engineering | HIGH | Knowledge accumulation across cycles |
| **Multi-agent review** | Compound Engineering | HIGH | Quality gates before merging |
| **Git worktree integration** | Compound Engineering | MEDIUM | Isolated parallel development |
| **80/20 planning split** | Compound Engineering | HIGH | Reduced rework through thorough planning |
| **Compound docs** | Compound Engineering | MEDIUM | Auto-captured fixes in docs/solutions |
| **File-todos** | Compound Engineering | MEDIUM | File-based task queue |
| **Ralph autonomous loop** | Ralph | HIGH | Run until all tasks complete |
| **progress.txt pattern** | Ralph | HIGH | Append-only learnings |
| **AGENTS.md pattern** | Ralph | CRITICAL | Auto-read learnings for agents |
| **Task granularity rules** | Ralph | CRITICAL | Right-sized tasks for context windows |
| **Quality feedback loops** | Ralph | CRITICAL | Typecheck + tests must pass |
| **Fresh instance pattern** | Ralph | HIGH | Prevents context exhaustion |
| **prd.json tracking** | Ralph | MEDIUM | Task completion status |

---

## CONSOLIDATED CAPABILITY MATRIX

After analyzing all 5 sources, here is the complete picture:

### Tier 1: CRITICAL (Must Have)

| Capability | Source | Implementation |
|------------|--------|----------------|
| **Model routing** | Agent-Native | Free/Mid/Premium tier selection |
| **DCG** | ACFS | Block destructive commands |
| **Checksum + HTTPS verification** | ACFS | Fail-closed installer checks |
| **AGENTS.md** | Ralph | Auto-read learnings file |
| **Task granularity** | Ralph | Right-sized tasks for context |
| **Quality feedback loops** | Ralph | Typecheck + tests |
| **CLAUDE.md** | Agent-Native | Project context injection |
| **Cost tracking** | Awesome-CC | ccusage, ccreport, alerts |

### Tier 2: HIGH (Should Have)

| Capability | Source | Implementation |
|------------|--------|----------------|
| **NTM** | ACFS | Multi-agent tmux orchestration |
| **File reservations** | ACFS | Prevent agent conflicts |
| **Conflict model + file locking** | Agent-Native | Check-before-write, drafts/, locks |
| **CASS** | ACFS | Unified agent history search |
| **Compound workflow** | Compound Eng | Plan → Work → Review → Compound |
| **Multi-agent review** | Compound Eng | Quality gates before merge |
| **80/20 split** | Compound Eng | More planning, less execution |
| **Ralph loop** | Ralph | Autonomous until complete |
| **progress.txt** | Ralph | Append-only learnings |
| **Fresh instances** | Ralph | Clean context per iteration |
| **Gemini CLI** | Our plan | Free tier access |
| **OpenRouter** | Our plan | Free model access |
| **Checkpoints** | Agent-Native | Resume capability |

### Tier 3: MEDIUM (Nice to Have)

| Capability | Source | Implementation |
|------------|--------|----------------|
| **CASS Memory** | ACFS | Procedural memory |
| **Agent Mail** | ACFS | Inter-agent messaging |
| **Git worktrees** | Compound Eng | Isolated branches |
| **Context consolidation** | Agent-Native | Mid-session summarization |
| **Batching** | Our plan | Reduce API calls |
| **Agent logging** | Agent-Native | Debug agent behavior |
| **prd.json** | Ralph | Task status tracking |
| **Compound docs** | Compound Eng | docs/solutions knowledge base |
| **File-todos** | Compound Eng | File-based task queue |

### Tier 4: OPTIONAL (Context-Dependent)

| Capability | Source | When to Use |
|------------|--------|-------------|
| **UBS** | ACFS | Bug scanning with guardrails |
| **Beads Viewer** | ACFS | Visual task graph |
| **SLB** | ACFS | Two-person rule for danger |
| **RU** | ACFS | Multi-repo management |
| **Codex CLI** | ACFS | If ChatGPT subscription |
| **IDE integrations** | Awesome-CC | If using VSCode/Neovim/Emacs |

---

## ISSUE RESOLUTION UPDATES (DEEP DIVE)

The following resolutions map directly to the gaps/risks identified during review.

- **Supply-chain safety**: adopt ACFS `checksums.yaml` + HTTPS-only fetches; pin installs with `ACFS_REF`; fail closed on checksum mismatch.
- **Tool availability/versioning**: use a manifest-driven install + `acfs doctor`-style verification; maintain a tool availability matrix with fallbacks.
- **Memory sprawl**: enforce a hierarchy (`CLAUDE.md` -> `AGENTS.md` -> `progress.txt` with Codebase Patterns -> `context.md`); use `compound-docs` + `file-todos`.
- **File conflicts**: combine Agent Mail file reservations with an explicit conflict model (check-before-write, drafts/, append-only logs, locks).
- **Backup/sync risk**: replace `rclone sync` with versioned `rclone copy` + `--backup-dir`, encryption, and lock/throttle to avoid deletes.
- **Quality gates**: integrate `cc-tools`/`claudekit` hooks, `TDD Guard`, and TS quality hooks; enforce P1 review blocking + browser verification for UI.
- **Cost drift**: use `ccusage` + statuslines for live budgets; enforce alert thresholds and provider quota checks.
- **Complexity creep**: define an MVP toolset and grow only after measurable ROI.
- **OS pinning**: document supported OS versions; pin tool versions; use containers (run-claude-docker/viwo/TSK) for risky tasks.
- **Secrets/log hygiene**: store keys in Vault or `.env` with 600 perms; redact logs; avoid plaintext in shell rc files.
- **Observability**: require `acfs doctor` checks + session analytics (cclogviewer/vibe-log) in weekly reviews.
- **Resource planning**: cap concurrent agents based on RAM; enforce via NTM session limits.

---

## FIRST PRINCIPLES REASONING (COMPREHENSIVE)

### Why This Setup Is Cost-Optimized

**Principle 1: Task-Model Matching** (Agent-Native)
- Not all tasks require frontier intelligence
- Simple tasks (formatting, commit messages, test boilerplate) can use FREE models
- Complex tasks (architecture, debugging) justify premium cost
- **Savings**: 50-70% of tasks can use free/mid tier

**Principle 2: Context Efficiency** (Agent-Native + Ralph)
- Token costs are proportional to context size
- CLAUDE.md provides structured context injection (vs. repeating every session)
- AGENTS.md provides auto-read learnings (Ralph pattern)
- Fresh instances prevent context exhaustion (Ralph pattern)
- Context consolidation summarizes old context
- **Savings**: 30-50% reduction in tokens per session

**Principle 3: Batching** (Our Analysis)
- Each API call has overhead
- Batching similar tasks reduces call count
- **Savings**: 20-30% fewer API calls

**Principle 4: Knowledge Compounding** (Compound Engineering)
- 80% planning/review, 20% execution reduces rework
- progress.txt accumulates learnings across iterations
- Plans inform future plans
- **Savings**: Exponential improvement over time - each cycle becomes cheaper

**Principle 5: Quality Gates** (Ralph + Compound Engineering)
- Typecheck + tests catch errors early
- Multi-agent review catches issues before production
- "Ralph only works if there are feedback loops"
- **Savings**: Bugs caught early cost 10-100x less to fix

**Principle 6: Task Granularity** (Ralph)
- Right-sized tasks fit in context window
- Oversized tasks cause poor output requiring rework
- **Savings**: Prevents wasted tokens on incomplete/poor work

### Why This Setup Is Comprehensive

**Coverage Matrix (All 5 Sources)**:

| Category | Components | Sources |
|----------|------------|---------|
| **Model Routing** | Free (OpenRouter, Gemini Flash), Mid (Gemini Pro), Premium (Claude Sonnet/Opus) | Agent-Native |
| **Cost Tracking** | ccusage, ccost, ccreport, daily monitoring, alerts | Awesome-CC |
| **Context Management** | CLAUDE.md, AGENTS.md, context.md, progress.txt, checkpoints | Agent-Native, Ralph |
| **Workflows** | RIPER, AB Method, Compound (Plan→Work→Review→Compound), Ralph Loop | All sources |
| **Multi-Agent** | NTM, Agent Mail, file reservations, fresh instances | ACFS, Ralph |
| **Safety** | DCG (destructive command guard), git hooks, quality gates | ACFS, Ralph |
| **Automation** | Slash commands, git hooks, cron monitoring, Ralph autonomous loop | All sources |
| **Continuity** | Session recall, CASS, checkpoints, progress.txt, AGENTS.md | ACFS, Ralph |
| **Quality** | Typecheck, tests, multi-agent review, 80/20 planning split | Ralph, Compound Eng |

### Synthesis: The Complete Flywheel

```
                    ┌─────────────────────────────────────────┐
                    │         COST-OPTIMIZED FLYWHEEL         │
                    └─────────────────────────────────────────┘
                                        │
        ┌───────────────────────────────┼───────────────────────────────┐
        │                               │                               │
        ▼                               ▼                               ▼
   ┌─────────┐                    ┌─────────┐                    ┌─────────┐
   │  PLAN   │                    │  WORK   │                    │ REVIEW  │
   │  (80%)  │───────────────────▶│  (20%)  │───────────────────▶│ (Gate)  │
   └─────────┘                    └─────────┘                    └─────────┘
        │                               │                               │
        │ • CLAUDE.md context           │ • Model routing               │ • Typecheck
        │ • AGENTS.md learnings         │ • Free tier first             │ • Tests
        │ • Task granularity            │ • DCG protection              │ • Multi-agent
        │ • Previous plans              │ • Fresh instances             │   review
        │                               │ • NTM orchestration           │
        │                               │                               │
        └───────────────────────────────┼───────────────────────────────┘
                                        │
                                        ▼
                                  ┌─────────┐
                                  │COMPOUND │
                                  │(Learn)  │
                                  └─────────┘
                                        │
                                        │ • Update progress.txt
                                        │ • Update AGENTS.md
                                        │ • Store plans for future
                                        │ • Cost report & optimization
                                        │
                                        ▼
                              ┌─────────────────┐
                              │ NEXT ITERATION  │
                              │ (Faster/Cheaper)│
                              └─────────────────┘
```

### Memory Architecture (From All Sources)

```
┌─────────────────────────────────────────────────────────────────┐
│                    PERSISTENT MEMORY LAYER                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  CLAUDE.md   │  │  AGENTS.md   │  │ progress.txt │          │
│  │              │  │              │  │              │          │
│  │ • Stack      │  │ • Patterns   │  │ • Learnings  │          │
│  │ • Conventions│  │ • Gotchas    │  │ • Append-only│          │
│  │ • Structure  │  │ • Context    │  │ • Per-session│          │
│  │              │  │ • Auto-read  │  │              │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ checkpoints/ │  │   plans/     │  │   CASS DB    │          │
│  │              │  │              │  │              │          │
│  │ • Resume     │  │ • Past work  │  │ • All agents │          │
│  │ • State save │  │ • Reference  │  │ • Searchable │          │
│  │ • Atomic     │  │ • Compound   │  │ • History    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                    EPHEMERAL CONTEXT LAYER                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  context.md  │  │  prd.json    │  │ Git History  │          │
│  │              │  │              │  │              │          │
│  │ • Session    │  │ • Tasks      │  │ • Commits    │          │
│  │ • Bounded    │  │ • Status     │  │ • Diffs      │          │
│  │ • 500 lines  │  │ • Priority   │  │ • Branches   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Agent Orchestration Architecture (From ACFS + Ralph)

```
┌─────────────────────────────────────────────────────────────────┐
│                    MULTI-AGENT ORCHESTRATION                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    NTM (Tmux Manager)                    │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐        │   │
│  │  │Agent 1  │ │Agent 2  │ │Agent 3  │ │Agent N  │        │   │
│  │  │(Claude) │ │(Gemini) │ │(Claude) │ │  ...    │        │   │
│  │  │Auth     │ │Research │ │API      │ │         │        │   │
│  │  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘        │   │
│  └───────┼───────────┼───────────┼───────────┼─────────────┘   │
│          │           │           │           │                  │
│          ▼           ▼           ▼           ▼                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              File Reservation System (MCP)               │   │
│  │  src/auth/* → Agent 1 (exclusive, 1hr TTL)              │   │
│  │  src/api/*  → Agent 3 (exclusive, 1hr TTL)              │   │
│  │  docs/*     → Agent 2 (shared, no TTL)                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Safety Layer (DCG)                     │   │
│  │  ✗ git reset --hard    ✗ rm -rf    ✗ git push --force   │   │
│  │  ✓ git reset --soft    ✓ rm file   ✓ git push --force-with-lease │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Overview (REVISED)

A comprehensive, cost-optimized agentic coding environment for full-stack web development that:

1. **Leverages FREE APIs** via OpenRouter and Gemini Flash for 50%+ of tasks
2. **Routes intelligently** to premium models only when complexity demands it
3. **Prevents conflicts** with file reservations for multi-agent work
4. **Blocks catastrophic mistakes** with DCG (Destructive Command Guard)
5. **Maintains context** across sessions with CASS and checkpoints
6. **Tracks costs** in real-time with alerts

**Expected savings**: ~60-70% compared to using only premium models (~$50-70/month vs ~$200+/month)

---

## USER-SPECIFIC CONFIGURATION

### Hardware & Environment

| Attribute | Current | Planned |
|-----------|---------|---------|
| **Location** | 100% Local | 100% Local |
| **CPU** | Current CPU | Current CPU |
| **RAM** | 32GB DDR5 | Upgrade planned |
| **GPU** | None (CPU-only) | GPU upgrade planned |
| **Max Simultaneous Agents** | ~10-15 (with 32GB) | More with RAM upgrade |

### Subscriptions & Access

| Service | Access Type | Cost Model | Primary Use |
|---------|-------------|------------|-------------|
| **Claude Code** | API Credits | Pay-per-token | Complex reasoning, architecture |
| **Gemini Advanced** | Subscription | Flat rate | Research, review, Antigravity IDE |
| **ChatGPT Plus/Pro** | Subscription | Flat rate | Codex CLI |
| **OpenRouter** | Free tier | Free | Simple tasks |

**CRITICAL COST INSIGHT**: Claude uses pay-per-token API credits. Every token costs money. This makes aggressive model routing essential - use Gemini/Codex (flat-rate subscriptions) for as much work as possible, reserve Claude for complex reasoning only.

### Dev Tools Ecosystem

| Tool | Provider | Model Access | Coordination Method |
|------|----------|--------------|---------------------|
| **Claude Code** | Anthropic | Claude API | File-based (AGENTS.md, etc.) |
| **Gemini CLI** | Google | Gemini (subscription) | File-based |
| **Codex CLI** | OpenAI | GPT (subscription) | File-based |
| **Google Antigravity IDE** | Google DeepMind | Gemini (subscription) | File-based |
| **VS Code** | Microsoft | Extensions | IDE integration |

### Backup Strategy

| What | Where | Sync Method |
|------|-------|-------------|
| **Software/Scripts** | GitHub | Git push |
| **Agent context files** | Google Drive | rclone/sync |
| **Session history** | Google Drive | rclone/sync |
| **Checkpoints/state** | Google Drive | rclone/sync |
| **Tooling/scripts** | GitHub | Git push |

**Goal**: Complete replicability on another machine.

---

## CROSS-TOOL AGENT COORDINATION ARCHITECTURE

### The Challenge

Agents from different tools (Claude Code, Gemini CLI, Codex CLI, Antigravity, VS Code) must coordinate seamlessly. Unlike single-tool multi-agent setups, these tools don't share a common runtime.

### Solution: File-Based Coordination Bus

**The filesystem becomes the shared coordination layer.**

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CROSS-TOOL COORDINATION BUS                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │ Claude   │  │ Gemini   │  │ Codex    │  │Antigrav- │            │
│  │ Code     │  │ CLI      │  │ CLI      │  │  ity     │            │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘            │
│       │             │             │             │                   │
│       └─────────────┴──────┬──────┴─────────────┘                   │
│                            │                                        │
│                            ▼                                        │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              SHARED PROJECT DIRECTORY                        │   │
│  │                                                              │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐             │   │
│  │  │ AGENTS.md  │  │progress.txt│  │ prd.json   │             │   │
│  │  │            │  │            │  │            │             │   │
│  │  │ • Patterns │  │ • Learnings│  │ • Tasks    │             │   │
│  │  │ • Gotchas  │  │ • Append   │  │ • Status   │             │   │
│  │  │ • Auto-read│  │ • History  │  │ • Priority │             │   │
│  │  └────────────┘  └────────────┘  └────────────┘             │   │
│  │                                                              │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐             │   │
│  │  │ CLAUDE.md  │  │.locks/     │  │ .claude/   │             │   │
│  │  │            │  │            │  │            │             │   │
│  │  │ • Context  │  │ • File     │  │ • Hooks    │             │   │
│  │  │ • Stack    │  │   locks    │  │ • Settings │             │   │
│  │  │ • Rules    │  │ • TTL      │  │ • State    │             │   │
│  │  └────────────┘  └────────────┘  └────────────┘             │   │
│  │                                                              │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                            │                                        │
│                            ▼                                        │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    GIT (Source of Truth)                     │   │
│  │  • Commits from any agent visible to all                     │   │
│  │  • Branch-based isolation for parallel work                  │   │
│  │  • History provides context for all tools                    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Coordination Mechanisms

#### 1. AGENTS.md (Cross-Tool Learnings)

All tools can read and append to AGENTS.md:

```markdown
# AGENTS.md - Cross-Tool Coordination

## Tool-Specific Sections

### Claude Code Learnings
- [Pattern] Use X approach for Y in this codebase
- [Gotcha] Always run Z before modifying W

### Gemini CLI Learnings
- [Research] Found documentation for X at Y
- [Pattern] API follows Z convention

### Codex CLI Learnings
- [Pattern] Tests use X framework with Y config
- [Gotcha] Mock Z service in tests

### Antigravity Learnings
- [Pattern] Component structure follows X
- [Context] Feature X depends on Y module

## Shared Learnings (All Tools)
- [Critical] Never modify X without updating Y
- [Pattern] Error handling uses Z approach
```

#### 2. File Locking (Prevent Conflicts)

Simple file-based locking that all tools can respect:

```
.locks/
├── src_auth.lock          # Contains: {"agent": "claude", "tool": "claude-code", "expires": "2024-01-15T10:30:00Z"}
├── src_api.lock           # Contains: {"agent": "gemini", "tool": "gemini-cli", "expires": "2024-01-15T10:45:00Z"}
└── README.md              # Lock file conventions
```

**Lock Protocol**:
1. Before editing files, check for `.locks/<path_underscore_separated>.lock`
2. If lock exists and not expired, skip those files
3. Create lock file before editing
4. Delete lock file after commit

**Conflict Model (Agent-Native addendum)**:
- Check-before-write (skip if file changed since read)
- Write agent output to `drafts/`, user promotes to final
- Prefer append-only logs for shared state

#### 3. Task Handoff Protocol

```markdown
## .claude/handoff.md

### Current Task Owner
**Tool**: gemini-cli
**Task**: Research authentication patterns
**Status**: in_progress
**Files Reserved**: docs/auth-research.md

### Pending Handoffs
1. **To**: claude-code
   **Task**: Implement auth based on research
   **Blocked On**: Research completion
   **Files Needed**: src/auth/*

2. **To**: codex-cli
   **Task**: Write tests for auth module
   **Blocked On**: Implementation completion
   **Files Needed**: tests/auth/*
```

#### 4. Hub-and-Spoke with Fluid Primary

Any tool can act as the hub for a given task:

```
Task: "Add user authentication"

Phase 1 (Research) - Gemini CLI is Hub:
├── Gemini CLI: Research auth patterns (PRIMARY)
├── Output: docs/auth-research.md
└── Handoff: Update AGENTS.md, create handoff.md

Phase 2 (Architecture) - Claude Code is Hub:
├── Claude Code: Design auth system (PRIMARY)
├── Input: Read research from Phase 1
├── Output: Architecture in AGENTS.md
└── Handoff: Update prd.json with implementation tasks

Phase 3 (Implementation) - Antigravity is Hub:
├── Antigravity: Implement auth (PRIMARY)
├── Codex CLI: Write tests in parallel
├── Input: Architecture from Phase 2
└── Output: Code + tests

Phase 4 (Review) - Any tool:
├── Multi-agent review
└── Compound: Update progress.txt, AGENTS.md
```

---

## COST OPTIMIZATION STRATEGY (API Credits Focus)

### Model Routing Decision Tree

Since Claude uses **pay-per-token API credits**, aggressive routing is essential:

```
┌─────────────────────────────────────────────────────────────────┐
│                    MODEL ROUTING DECISION TREE                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  START: New Task                                                 │
│    │                                                             │
│    ▼                                                             │
│  Is this security/architecture CRITICAL?                         │
│    │                                                             │
│    ├─YES──▶ Claude Code (Opus) [$$$]                            │
│    │                                                             │
│    ▼                                                             │
│  Does it require cross-file reasoning or complex debugging?      │
│    │                                                             │
│    ├─YES──▶ Claude Code (Sonnet) [$$]                           │
│    │                                                             │
│    ▼                                                             │
│  Is it research, documentation, or code review?                  │
│    │                                                             │
│    ├─YES──▶ Gemini CLI or Antigravity [FLAT RATE - FREE*]       │
│    │                                                             │
│    ▼                                                             │
│  Is it test generation or simple refactoring?                    │
│    │                                                             │
│    ├─YES──▶ Codex CLI [FLAT RATE - FREE*]                       │
│    │                                                             │
│    ▼                                                             │
│  Is it formatting, linting, or commit messages?                  │
│    │                                                             │
│    ├─YES──▶ OpenRouter Free Tier [FREE]                         │
│    │                                                             │
│    ▼                                                             │
│  DEFAULT: Gemini CLI [FLAT RATE - FREE*]                        │
│                                                                  │
│  *FREE relative to Claude API costs - already paying subscription│
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Cost Priority Matrix

| Task Type | Primary Tool | Fallback | Why |
|-----------|--------------|----------|-----|
| **Architecture design** | Claude (Opus) | - | Needs best reasoning |
| **Complex debugging** | Claude (Sonnet) | Gemini Pro | Cross-file reasoning |
| **Feature implementation** | Antigravity/Gemini | Claude Sonnet | Flat rate first |
| **Code review** | Gemini CLI | Codex CLI | Flat rate |
| **Research** | Gemini CLI | - | Best for research |
| **Test generation** | Codex CLI | Gemini CLI | Flat rate |
| **Documentation** | Gemini CLI | OpenRouter | Flat rate |
| **Simple edits** | OpenRouter Free | Gemini Flash | Free |
| **Commit messages** | OpenRouter Free | - | Free |

### Subscription Utilization Strategy

**Goal**: Maximize flat-rate subscriptions, minimize Claude API spend.

| Subscription | Monthly Cost | Strategy |
|--------------|--------------|----------|
| **Gemini Advanced** | ~$20 | Use heavily for research, review, Antigravity |
| **ChatGPT Plus/Pro** | ~$20-200 | Use Codex CLI for tests, simple implementation |
| **Claude API** | Pay-per-use | Reserve for complex reasoning ONLY |
| **OpenRouter Free** | $0 | Use for all trivial tasks |

**Target allocation**:
- 50% of work: Gemini (flat rate)
- 30% of work: Codex (flat rate)
- 15% of work: OpenRouter (free)
- 5% of work: Claude (API credits) ← MINIMIZE THIS

---

## 1. Model Routing Strategy

| Tier | Models | Use Cases | Cost |
|------|--------|-----------|------|
| **FREE** | `google/gemini-flash-1.5:free`, `meta-llama/llama-3.1-8b-instruct:free` via OpenRouter | Test generation, docs, commit messages, simple refactoring, formatting | $0 |
| **MID** | `gemini-2.0-flash-exp`, `gemini-1.5-pro` via Gemini Advanced | Code review, research, debugging, API design, security audits | ~$0.50/day |
| **PREMIUM** | `claude-sonnet-4-5` | Implementation, complex debugging, refactoring, business logic | ~$2/day |
| **ULTRA** | `claude-opus-4-5` | Architecture design, critical security code, complex algorithms | ~$1/day |

**Decision Tree**:
```
Security/Architecture critical? → Claude Opus
Cross-file reasoning needed? → Claude Sonnet
Research/Review/Analysis? → Gemini Pro
Simple/Repetitive task? → Free Tier
Default fallback → Gemini Pro
```

---

## 2. Directory Structure

```
/home/deeog/
├── .local/bin/                    # Custom CLI tools
│   ├── model-router               # Model selection helper
│   ├── ccost                      # Cost tracking
│   ├── ccreport                   # Cost reporting
│   ├── gemini-cli                 # Gemini API wrapper
│   ├── openrouter-query           # OpenRouter free tier wrapper
│   ├── claude-slash               # Slash commands (/prime, /commit, /review, /test)
│   ├── riper                      # RIPER workflow manager
│   ├── ab-method                  # AB Method workflow manager
│   ├── agent-squad                # Multi-agent orchestration
│   ├── session-recall             # Session continuity
│   ├── setup-hooks                # Git hooks installer
│   └── setup-agentic-env          # Master setup script
├── .claude/
│   ├── templates/
│   │   ├── CLAUDE.md              # Project context template
│   │   ├── context.md             # Session context template
│   │   └── new-project.sh         # Project scaffolding
│   ├── costs/                     # Cost logs
│   ├── sessions/                  # Session saves
│   ├── batches/                   # Task batching queue
│   └── model-rules.json           # Task→Model routing rules
└── projects/[project-name]/
    └── .claude/
        ├── CLAUDE.md              # Project-specific context
        ├── context.md             # Current session state
        ├── checkpoints/           # Checkpoint saves
        ├── agents/                # Multi-agent configs
        ├── workflows/             # RIPER/AB Method state
        └── research/              # Research outputs
```

---

## 3. Implementation Steps

### Phase 1: Core Setup
1. Create directory structure
2. Install dependencies: `jq`, `bc`, `google-generativeai` (Python), `httpie`
3. Configure environment variables in `~/.bashrc`:
   - `ANTHROPIC_API_KEY`
   - `GEMINI_API_KEY`
   - `OPENROUTER_API_KEY`
   - Model defaults and aliases

### Phase 2: CLI Tools
Create these scripts in `/home/deeog/.local/bin/`:

1. **model-router** - Routes task types to appropriate model tier
2. **ccost** - Logs API costs to JSONL file
3. **ccreport** - Generates cost reports (daily/weekly/by-model)
4. **gemini-cli** - Python wrapper for Gemini API
5. **openrouter-query** - Bash wrapper for OpenRouter free models
6. **claude-slash** - Slash command handler:
   - `/prime` - Load project context
   - `/commit` - Auto-generate commit (free tier)
   - `/review` - Code review (Gemini Pro)
   - `/test` - Generate tests (free tier)
   - `/tdd` - TDD workflow (free + Sonnet)
   - `/checkpoint` - Save session state
   - `/resume` - Resume from checkpoint
   - `/cost` - Show cost report

### Phase 3: Workflow Tools
1. **riper** - RIPER workflow (Research→Implement→Plan→Execute→Review)
2. **ab-method** - AB Method (Architect with Opus → Build with Sonnet)
3. **agent-squad** - Multi-agent orchestration for parallel work
4. **session-recall** - Session save/load/list for continuity
5. **compound** - Compound workflow (Plan→Work→Review→Compound)

### Phase 4: Cross-Tool Coordination
1. **File-based coordination bus setup**:
   - Create `.locks/` directory structure
   - Create `AGENTS.md` template (cross-tool learnings)
   - Create `progress.txt` (append-only learnings)
   - Create `handoff.md` template (task handoffs)
   - Create `prd.json` template (task tracking)
   - Define conflict model: check-before-write, drafts/, append-only logs

2. **Lock management scripts**:
   - `acquire-lock` - Create lock file with TTL
   - `release-lock` - Remove lock file
   - `check-locks` - List active locks

3. **Tool-specific configurations**:
   - Claude Code: `.claude/settings.json` with DCG hook
   - Gemini CLI: Configuration for AGENTS.md reading
   - Codex CLI: Configuration for coordination
   - VS Code: Extensions for file watching

### Phase 5: Safety Layer
1. **Installer verification policy (ACFS-style)**:
   - Enforce HTTPS-only downloads (`curl --proto '=https' --proto-redir '=https'`).
   - Pin installers to tags/commits and verify against `checksums.yaml`.

2. **DCG (Destructive Command Guard)** installation (pinned):
   ```bash
   DCG_REF="<tag-or-commit>"
   curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/destructive_command_guard/${DCG_REF}/install.sh" | bash
   dcg install
   ```

3. **Git hooks** via `setup-hooks`:
   - `prepare-commit-msg`: Auto-generate commit messages (free tier)
   - `pre-push`: Security audit on main branch (Gemini Pro)
   - `post-commit`: Update progress.txt, trigger sync

### Phase 6: Backup & Sync (Real-Time)
1. **Install rclone**:
   ```bash
   curl https://rclone.org/install.sh | sudo bash
   rclone config  # Configure Google Drive remote
   ```
   - Prefer an `rclone crypt` remote for encrypted backups.

2. **Create sync directories**:
   ```
   ~/agentic-backup/
   ├── context/           # AGENTS.md, CLAUDE.md, progress.txt
   ├── sessions/          # Session history
   ├── checkpoints/       # State files
   └── sync.log           # Sync log
   ```

3. **Real-time sync script** (`~/.local/bin/agentic-sync`):
   ```bash
   #!/usr/bin/env bash
   # Versioned, non-destructive sync to Google Drive

   BACKUP_DIR="$HOME/agentic-backup"
   REMOTE="gdrive:agentic-coding-backup"
   REMOTE_ARCHIVE="gdrive:agentic-coding-backup-archive"
   STAMP="$(date +%Y%m%d-%H%M%S)"

   # Avoid overlapping runs; copy (no deletes) + versioned backups
   LOCKFILE="$BACKUP_DIR/sync.lock"
   flock -n "$LOCKFILE" rclone copy "$BACKUP_DIR" "$REMOTE" \
     --checksum \
     --backup-dir "${REMOTE_ARCHIVE}/${STAMP}" \
     --suffix ".${STAMP}" \
     --log-file="$BACKUP_DIR/sync.log"
   ```

4. **File watcher for real-time sync** (using `inotifywait`):
   ```bash
   # Install: sudo apt install inotify-tools
   # Watch for changes and trigger sync
   inotifywait -m -r -e modify,create,delete ~/projects/.claude ~/agentic-backup |
   while read; do
     agentic-sync
   done
   ```

5. **Git hook integration** (post-commit triggers sync):
   ```bash
   # In .git/hooks/post-commit
   agentic-sync &
   ```

### Phase 7: Templates & Configuration
1. **CLAUDE.md template** - Project context
2. **AGENTS.md template** - Cross-tool learnings (with sections per tool)
3. **context.md template** - Bounded session context
4. **progress.txt template** - Append-only learnings
5. **prd.json template** - Task tracking
6. **handoff.md template** - Task handoffs between tools
7. **model-rules.json** - Task→Model routing rules

### Phase 8: Verification
1. Test model routing: `model-router simple` → should output free tier
2. Test cost tracking: `ccost test 100 50 test && ccreport`
3. Test Gemini CLI: `gemini-cli "Hello"`
4. Test OpenRouter: `openrouter-query "Hello"`
5. Test DCG: `dcg doctor`
6. Test file locking: `acquire-lock src/auth && check-locks`
7. Test sync: Modify AGENTS.md, verify appears in Google Drive
8. Create test project and run full workflow

---

## 4. Critical Files to Create

### Core Scripts (in `/home/deeog/.local/bin/`)

| Script | Purpose | Priority |
|--------|---------|----------|
| `model-router` | Route tasks to appropriate model tier | CRITICAL |
| `ccost` | Log API costs to JSONL | CRITICAL |
| `ccreport` | Generate cost reports | CRITICAL |
| `gemini-cli` | Gemini API wrapper (Python) | HIGH |
| `openrouter-query` | OpenRouter free tier wrapper | HIGH |
| `claude-slash` | Slash command handler | HIGH |
| `acquire-lock` | Create file lock with TTL | HIGH |
| `release-lock` | Remove file lock | HIGH |
| `check-locks` | List active locks | HIGH |
| `agentic-sync` | Sync to Google Drive | HIGH |
| `setup-agentic-env` | Master setup script | HIGH |
| `riper` | RIPER workflow manager | MEDIUM |
| `ab-method` | AB Method workflow | MEDIUM |
| `compound` | Compound workflow | MEDIUM |
| `agent-squad` | Multi-agent orchestration | MEDIUM |
| `session-recall` | Session continuity | MEDIUM |
| `setup-hooks` | Git hooks installer | MEDIUM |

### Templates (in `/home/deeog/.claude/templates/`)

| Template | Purpose | Priority |
|----------|---------|----------|
| `CLAUDE.md` | Project context (stack, conventions, structure) | CRITICAL |
| `AGENTS.md` | Cross-tool learnings (patterns, gotchas) | CRITICAL |
| `progress.txt` | Append-only learnings per session | CRITICAL |
| `context.md` | Bounded session context (500 lines max) | HIGH |
| `prd.json` | Task tracking with completion status | HIGH |
| `handoff.md` | Task handoffs between tools | HIGH |
| `new-project.sh` | Project scaffolding script | MEDIUM |

### Configuration Files

| File | Location | Purpose |
|------|----------|---------|
| `settings.json` | `~/.claude/settings.json` | Claude Code config with DCG hook |
| `model-rules.json` | `~/.claude/model-rules.json` | Task→Model routing rules |
| `rclone.conf` | `~/.config/rclone/rclone.conf` | Google Drive sync config |
| `.bashrc` additions | `~/.bashrc` | Env vars, aliases, PATH |

---

## 5. Daily Workflow Example

### Morning Startup

```bash
# 1. Check sync status
cat ~/agentic-backup/sync.log | tail -5

# 2. Check costs from yesterday
ccreport

# 3. Load project context (any tool)
# In Claude Code:
/prime

# In Gemini CLI:
cat AGENTS.md CLAUDE.md | gemini-cli "Summarize project context"
```

### Feature Development (Hub-and-Spoke)

```bash
# Phase 1: Research (Gemini as Hub) - FLAT RATE
gemini-cli "Research best practices for JWT authentication in Node.js"
# Output saved to docs/auth-research.md
# Update AGENTS.md with findings

# Phase 2: Architecture (Claude as Hub) - API CREDITS (minimize)
# In Claude Code:
# "Design JWT auth architecture based on research in docs/auth-research.md"
# Output: Architecture decision in AGENTS.md
# Create tasks in prd.json

# Phase 3: Implementation (Antigravity as Hub) - FLAT RATE
# In Antigravity:
# Implement based on architecture
# Codex CLI writes tests in parallel

# Phase 4: Review (Any tool) - FLAT RATE
gemini-cli "Review src/auth/* for security issues"

# Phase 5: Compound (Update learnings)
echo "[$(date)] Auth: Used passport-jwt pattern" >> progress.txt
# Update AGENTS.md with patterns discovered
```

### End of Session

```bash
# 1. Checkpoint
claude-slash /checkpoint

# 2. Verify sync
agentic-sync
cat ~/agentic-backup/sync.log | tail -3

# 3. Cost check
ccreport
```

---

## 6. Verification Checklist

| Check | Command | Expected Result |
|-------|---------|-----------------|
| Model routing works | `model-router simple` | Outputs free tier model |
| Cost tracking works | `ccost test 100 50 test && ccreport` | Shows logged cost |
| Gemini CLI works | `gemini-cli "Hello"` | Response from Gemini |
| OpenRouter works | `openrouter-query "Hello"` | Response from free model |
| DCG installed | `dcg doctor` | Health check passes |
| Installer verification | `acfs doctor` (or custom verify script) | Checksums/health checks pass |
| File locking works | `acquire-lock test && check-locks` | Shows active lock |
| Sync works | Touch AGENTS.md, check Drive | File appears in Drive |
| Full workflow | Create test project, run feature cycle | All phases complete |

---

## 7. Cost Monitoring

### Daily Targets (API Credits Focus)

| Source | Daily Budget | Alert Threshold |
|--------|--------------|-----------------|
| **Claude API** | $2-5/day | $5/day |
| **Gemini** | Flat rate | N/A |
| **Codex** | Flat rate | N/A |
| **OpenRouter** | Free | N/A |

### Monthly Estimate

| Item | Cost |
|------|------|
| Claude API (5% of work) | ~$30-50/month |
| Gemini Advanced | ~$20/month |
| ChatGPT Plus/Pro | ~$20-200/month |
| **Total** | **~$70-270/month** |

**Compared to**: Using Claude for everything (~$200-500+/month)

**Savings**: 50-70% by aggressive model routing

---

## END OF PLAN

**Total Research Sources**: 5
**Total Capabilities Identified**: 60+
**Implementation Phases**: 8
**Critical Scripts**: 17
**Critical Templates**: 7

**Ready for implementation approval.**


# Learning Resources

**Web Links**:

- https://every.to/guides/agent-native
- https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup
- https://github.com/EveryInc/compound-engineering-plugin
- https://github.com/snarktank/ralph
- https://github.com/hesreallyhim/awesome-claude-code

**Daily targets**:

- Free tier: 50+ requests/day ($0)
- Mid tier (Gemini): 30 requests/day (~$0.50)
- Premium (Sonnet): 10 requests/day (~$2)
- Ultra (Opus): 2 requests/day (~$1)

**Alert threshold**: $10/day (configurable via `COST_ALERT_THRESHOLD`)

**Monthly estimate**: ~$70 for full-time development (vs ~$200+ without optimization)
