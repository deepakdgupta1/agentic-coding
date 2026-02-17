# Agent-Native Architecture Analysis

> Deep analysis of the Every.to "Agent-Native" framework for building applications where AI agents are first-class citizens. This document is designed to inform the refinement of multi-agent autonomous coding systems.

**Source**: https://every.to/guides/agent-native
**Authors**: Dan Shipper & Claude
**Analysis Date**: 2026-01-17

---

## Executive Summary

The Agent-Native architecture represents a paradigm shift from traditional software design. Instead of hard-coding features as logic, features become **outcomes described in prompts** that agents pursue autonomously. The architecture is directly inspired by Claude Code's success: an LLM with bash and file tools operating in loops can accomplish complex multi-step tasks.

**Core Insight**: "A really good coding agent is actually a really good general-purpose agent."

---

## Part 1: Five Core Architectural Principles

### 1.1 Parity

**Definition**: Whatever the user can do through the UI, the agent must be able to achieve through tools.

**Implications for Multi-Agent Coding Systems**:
- Every IDE action (refactor, format, run tests, git operations) must have agent-accessible equivalents
- Not necessarily 1:1 button-to-tool mapping—focus on achieving same *outcomes*
- Capability mapping is essential for system design

| User Action | Agent Achievement Path |
|------------|------------------------|
| Create file | `write_file` tool |
| Rename symbol | Language server + edit tools |
| Run tests | `bash` with test commands |
| Git commit | `bash` with git commands |
| Search codebase | `grep`/`glob` tools |

**Test for Your System**: Pick any action a developer performs in the IDE—can your agent accomplish it?

---

### 1.2 Granularity

**Definition**: Tools should be atomic primitives. Features are outcomes achieved by an agent operating in a loop.

**The Critical Shift**:
- OLD: Agent executes choreographed sequences
- NEW: Agent pursues outcomes with judgment, adjusting approach as needed

**Example Comparison**:

| Less Granular (Anti-pattern) | More Granular (Correct) |
|-----------------------------|------------------------|
| `classify_and_organize_files(files)` | `read_file`, `write_file`, `move_file`, `bash` + outcome prompt |
| `refactor_function(name, pattern)` | `read_file`, `edit`, `grep`, `glob` + refactoring outcome |
| `fix_all_type_errors()` | `bash` (compiler), `read_file`, `edit` + iterative fix loop |

**Why This Matters**: Bundled tools encode YOUR judgment. Atomic tools let the agent apply ITS judgment—enabling handling of edge cases you never anticipated.

---

### 1.3 Composability

**Definition**: With atomic tools and parity, new features emerge from new prompts—no code changes required.

**Power for Coding Systems**:
```
Prompt: "Review all files modified this week. Identify potential bugs,
        security issues, and style violations. Prioritize by severity."
```

Agent composes: `git log` → `read_file` (changed files) → judgment → structured report

**Key Benefit**: Both system developers AND end users can create new capabilities through prompts.

---

### 1.4 Emergent Capability

**Definition**: The agent accomplishes things you didn't explicitly design for.

**The Flywheel**:
```
1. Build with atomic tools + parity
        ↓
2. Users request unanticipated things
        ↓
3. Agent composes tools (or fails, revealing gaps)
        ↓
4. Observe patterns in requests
        ↓
5. Add domain tools/prompts for efficiency
        ↓
6. Repeat → System grows organically
```

**For Coding Agents**: Instead of guessing what refactoring patterns developers need, observe what they ask the agent to do. The agent becomes a **research instrument** for understanding user needs.

**Example**: User asks "Find all functions that could cause memory leaks and suggest fixes." You never built a memory leak detector, but if the agent can read code and reason about patterns, it can attempt this.

---

### 1.5 Improvement Over Time

**Four Mechanisms**:

| Mechanism | Description | Application to Coding |
|-----------|-------------|----------------------|
| **Accumulated context** | State persists via context files | Project knowledge, coding standards, past decisions |
| **Developer refinement** | Ship updated prompts to all users | Better code review instructions, new patterns |
| **User customization** | Users modify prompts for their workflow | Personal style preferences, team conventions |
| **Self-modification** | Agent edits own prompts/code (with rails) | Learning from corrections, evolving guidelines |

---

## Part 2: Tool Design Philosophy

### 2.1 Evolution from Primitives to Domain Tools

**Recommended Progression**:

```
Stage 1: Pure Primitives
├── bash
├── read_file
├── write_file
├── edit
├── glob
└── grep

        ↓ (Prove architecture, reveal needs)

Stage 2: Add Domain Tools Deliberately
├── create_test (vocabulary: what "test" means in this context)
├── run_linter (guardrails: ensure valid config)
└── git_commit (efficiency: bundle common operations)

        ↓ (Hot paths identified)

Stage 3: Optimized Code Paths
└── Frequently-used operations implemented as fast, deterministic code
    (Agent can still fall back to primitives for edge cases)
```

### 2.2 Rules for Domain Tools

1. **Represent one conceptual action** from the user's perspective
2. **Include mechanical validation** but keep judgment in prompts
3. **Never gate primitives** unless specific security/integrity reason
4. Domain tools are **shortcuts, not gates**—underlying primitives remain available

### 2.3 CRUD Completeness Check

For every entity your system manages, verify:

| Entity | Create | Read | Update | Delete |
|--------|--------|------|--------|--------|
| Files | ✓ write_file | ✓ read_file | ✓ edit | ✓ bash rm |
| Git branches | ✓ git branch | ✓ git branch -l | ✓ git branch -m | ✓ git branch -d |
| Tests | ✓ write test file | ✓ read test | ✓ edit test | ✓ delete test |
| Dependencies | ✓ npm install | ✓ npm list | ✓ npm update | ✓ npm uninstall |

**Common Failure**: Building `create_*` and `read_*` but forgetting `update_*` and `delete_*`.

---

## Part 3: Files as Universal Interface

### 3.1 Why Files Work for Agents

| Property | Benefit |
|----------|---------|
| **Already Known** | Agents fluent with `cat`, `grep`, `mv`, `mkdir` |
| **Inspectable** | Users see agent work, can edit/override |
| **Portable** | Trivial export and backup |
| **Syncs** | Cloud storage makes agent work appear everywhere |
| **Self-Documenting** | `/src/components/` more intuitive than database queries |

**Design Principle**: "Design for what agents can reason about. The best proxy is what would make sense to a human."

### 3.2 Recommended File Conventions

**Entity-Scoped Directories**:
```
{entity_type}/{entity_id}/
├── primary content
├── metadata
└── related materials
```

**For Coding Projects**:
```
projects/{project_name}/
├── src/                    # Primary source
├── tests/                  # Test files
├── docs/                   # Documentation
├── .agent/                 # Agent-specific state
│   ├── context.md          # Project understanding
│   ├── decisions.md        # Architectural decisions log
│   └── task_history.md     # Completed tasks
└── CLAUDE.md               # Agent instructions (project-specific)
```

### 3.3 The context.md Pattern

**Purpose**: Portable working memory without code changes

**Structure for Coding Agents**:
```markdown
# Context

## Project Understanding
- Tech stack: React, TypeScript, Node.js
- Architecture: Microservices with REST APIs
- Test framework: Jest with React Testing Library

## Coding Standards
- Use functional components with hooks
- Prefer named exports
- Error boundaries at route level

## Recent Activity
- Implemented user authentication (yesterday)
- Fixed pagination bug in /users endpoint (2 hours ago)

## Current State
- 3 failing tests in auth module
- Open PR #42 awaiting review
- Next task: Add rate limiting to API

## Known Issues
- Legacy code in /src/legacy - don't modify without discussion
- Database migrations require manual approval
```

Agent reads at session start, updates as state changes.

### 3.4 Files vs. Database Decision Matrix

| Use Files For | Use Database For |
|---------------|------------------|
| Content users should read/edit | High-volume structured data |
| Configuration benefiting from VCS | Complex relational queries |
| Agent-generated content | Ephemeral state (sessions, caches) |
| Transparency-valued content | Data needing indexing |
| Large text (code, docs) | Concurrent access patterns |

**Principle**: "Files for legibility, databases for structure. When in doubt, files."

---

## Part 4: Agent Execution Patterns

### 4.1 Completion Signals

**Critical Requirement**: Agents must explicitly signal completion.

```
Tool Result Structure:
├── success: Bool      # Did the operation succeed?
├── output: String     # What happened?
└── shouldContinue: Bool  # Should the loop continue?
```

**Key Insight**: Completion is separate from success/failure:
- Tool can **succeed and stop** (task complete)
- Tool can **fail and continue** (retry with different approach)
- Tool can **succeed and continue** (partial progress, more to do)

**Anti-pattern**: Detecting completion through heuristics (consecutive iterations without tool calls, checking for output files) is fragile.

### 4.2 Control Flow Signals

| Signal | Meaning | Action |
|--------|---------|--------|
| `continue` | Keep operating | Next iteration |
| `complete` | Outcome achieved | Stop loop |
| `pause` | Needs user input | Wait for response |
| `escalate` | Needs human decision | Alert user |
| `retry` | Transient failure | Orchestrator retries |

### 4.3 Model Tier Selection

| Task Type | Recommended Tier | Reasoning |
|-----------|-----------------|-----------|
| Code exploration | Balanced | Good reasoning, tool loops |
| Simple edits | Fast | High volume, simple task |
| Architecture decisions | Powerful | Complex multi-factor analysis |
| Code review | Balanced | Judgment + thoroughness |
| Debugging | Powerful | Deep reasoning required |

**Discipline**: Explicitly choose tier based on task complexity when adding new agent types.

### 4.4 Partial Completion Handling

**Task Structure**:
```
status: pending | in_progress | completed | failed | skipped
notes: String (why it failed, what was done)
```

**Progress Display**:
```
Progress: 3/5 tasks complete (60%)

✓ [1] Analyze failing tests
✓ [2] Identify root cause
✓ [3] Implement fix
✗ [4] Run test suite - Error: timeout
○ [5] Update documentation
```

**Scenarios**:
- **Max iterations reached**: Checkpoint saved, resume continues later
- **Task failure**: Task marked failed with notes, other tasks may continue
- **Unrecoverable error**: Session marked failed, checkpoint preserves state

### 4.5 Context Limits

**Design Principles**:
1. Tools support iterative refinement (summary → detail → full)
2. Give agents way to consolidate learnings mid-session
3. **Assume context will fill up**—design from start for this

---

## Part 5: Multi-Agent Coordination Patterns

### 5.1 Shared Workspace (Recommended Default)

```
Workspace/
├── src/                 ← All agents read/write here
├── tests/               ← Test agent writes, code agent reads
├── docs/                ← Doc agent writes, all agents read
└── .agent/
    ├── context.md       ← Shared understanding
    ├── tasks.json       ← Task queue
    └── handoffs.md      ← Inter-agent communication
```

**Benefits**:
- Agents inspect/build on each other's work
- No synchronization layer needed
- Complete transparency
- Users can intervene at any point

### 5.2 Context Injection

**System Prompt Must Include**:

```markdown
## Available Resources
- 47 source files in /src
- 23 test files in /tests
- 12 open issues in project tracker
- Last modified: src/auth/login.ts (10 min ago)

## Your Capabilities
- Read and edit any file in workspace
- Run tests via bash
- Query git history
- Search codebase with grep/glob

## Recent Context
- Agent-1 just fixed authentication bug
- 3 tests still failing in /tests/api/
- PR #42 merged 2 hours ago
```

### 5.3 Agent-to-Agent Communication

**File-Based Handoffs**:
```markdown
# .agent/handoffs.md

## From: CodeAgent → TestAgent
- Fixed null pointer in parseConfig()
- Need tests for edge cases: empty input, malformed JSON

## From: TestAgent → CodeAgent
- Test discovered bug: timeout not handled in fetchUser()
- Failing test at tests/api/user.test.ts:47
```

### 5.4 Conflict Resolution

| Model | Characteristics | Best For |
|-------|----------------|----------|
| **Last write wins** | Simple, changes can be lost | Non-critical files |
| **Check before writing** | Skip if modified since read | Collaborative editing |
| **Separate spaces** | Agent → drafts/, user promotes | High-stakes changes |
| **Append-only logs** | Additive, never overwrites | Audit trails, decisions |

---

## Part 6: Product Design Implications

### 6.1 Progressive Disclosure

**Principle**: "Simple to start but endlessly powerful."

| User Level | Experience |
|------------|------------|
| Beginner | "Fix this bug" → agent handles everything |
| Intermediate | "Fix this bug using the repository pattern" → agent follows guidance |
| Expert | Custom prompts, tool configurations, agent orchestration |

### 6.2 Approval and User Agency

**Decision Matrix**:

| Stakes | Reversibility | Pattern | Examples |
|--------|--------------|---------|----------|
| Low | Easy | Auto-apply | Format code, organize imports |
| Low | Hard | Quick confirm | Publish to package registry |
| High | Easy | Suggest + apply | Refactor function, add tests |
| High | Hard | Explicit approval | Delete files, push to main, send notifications |

### 6.3 Latent Demand Discovery

**Traditional Approach**:
```
Imagine features → Build them → See if users want them
```

**Agent-Native Approach**:
```
Build capable foundation → Observe what users ask → Formalize emerging patterns
```

**Evolution Over Time**:
- Add domain tools for common patterns (faster, more reliable)
- Create dedicated prompts for frequent requests (more discoverable)
- Remove unused tools (simplifies system)

---

## Part 7: Anti-Patterns to Avoid

### 7.1 Architectural Anti-Patterns

| Anti-Pattern | Description | Fix |
|--------------|-------------|-----|
| **Agent as Router** | Agent just figures out which function to call | Let agent operate in loops with judgment |
| **Build App, Add Agent** | Traditional app with agent bolted on | Design agent-first from start |
| **Request/Response** | Single input → single output | Agent loops until outcome achieved |
| **Defensive Tool Design** | Over-constrain with strict enums/validation | Trust agent judgment, validate at boundaries |
| **Happy Path in Code** | Code handles edge cases, agent just executes | Let agent handle edge cases |

### 7.2 Specific Anti-Patterns

**Agent Executes Your Workflow** (Wrong):
```python
def process_code(input):
    category = categorize(input)      # YOUR code decides
    priority = score(input)           # YOUR code decides
    if priority > 3: notify()         # YOUR code decides
```

**Agent Pursues Outcome** (Correct):
```
tools: read_file, edit, bash, notify
prompt: "Analyze code quality, fix critical issues,
        notify if security vulnerabilities found"
```

**Other Specific Anti-Patterns**:

| Anti-Pattern | Description | Fix |
|--------------|-------------|-----|
| **Workflow-shaped tools** | `analyze_and_organize` bundles judgment | Break into primitives |
| **Orphan UI actions** | User can do X through UI, agent cannot | Maintain parity |
| **Context starvation** | Agent doesn't know what exists | Inject resources into system prompt |
| **Gates without reason** | Domain tool is only way, no underlying access | Keep primitives available |
| **Static mapping** | 50 tools for 50 endpoints | Use discover + access pattern |
| **Heuristic completion** | Detect done via consecutive no-tool iterations | Require explicit completion signal |

---

## Part 8: Implementation Checklist

### 8.1 Architecture Checklist

- [ ] Agent achieves anything users achieve through UI (parity)
- [ ] Tools are atomic primitives (granularity)
- [ ] Domain tools are shortcuts, not gates
- [ ] New features added by writing prompts (composability)
- [ ] Agent accomplishes unanticipated tasks (emergent capability)
- [ ] Changing behavior = editing prompts, not refactoring code

### 8.2 Implementation Checklist

- [ ] System prompt includes available resources and capabilities
- [ ] Agent and user work in same data space
- [ ] Agent actions reflect immediately in UI/filesystem
- [ ] Every entity has full CRUD capability
- [ ] Agents explicitly signal completion
- [ ] Context files persist state across sessions

### 8.3 Multi-Agent Checklist

- [ ] Clear handoff mechanisms between agents
- [ ] Shared context accessible to all agents
- [ ] Conflict resolution strategy defined
- [ ] Task queue with status tracking
- [ ] Checkpoint/resume for interrupted sessions

### 8.4 The Ultimate Test

> "Describe an outcome to the agent that's within your application's domain but that you didn't build a specific feature for. Can it figure out how to accomplish it, operating in a loop until it succeeds?"

- **If yes**: You've built something agent-native
- **If no**: Your architecture is too constrained

---

## Part 9: Application to Multi-Agent Coding Systems

### 9.1 Recommended Agent Specializations

| Agent Type | Responsibility | Tools |
|------------|---------------|-------|
| **Explore Agent** | Codebase understanding, search | read, grep, glob, git log |
| **Code Agent** | Implementation, refactoring | read, edit, write, bash |
| **Test Agent** | Test creation, execution | read, write, bash (test runner) |
| **Review Agent** | Code review, quality checks | read, grep, bash (linters) |
| **Plan Agent** | Architecture, task breakdown | read, glob, web search |
| **Debug Agent** | Bug investigation, fixes | read, edit, bash, grep |

### 9.2 Agent Collaboration Flow

```
User Request
    ↓
Plan Agent: Break into tasks, identify files
    ↓
Explore Agent: Gather context, understand patterns
    ↓
Code Agent: Implement changes
    ↓
Test Agent: Write/run tests
    ↓
Review Agent: Check quality, suggest improvements
    ↓
Code Agent: Address feedback
    ↓
Complete (explicit signal)
```

### 9.3 Context Sharing Strategy

```
/.agent/
├── project_context.md      # Overall project understanding
├── current_task.md         # Active task details
├── decisions.md            # Architectural decisions log
├── patterns.md             # Discovered code patterns
├── handoffs/
│   ├── plan_to_code.md     # Plan agent → Code agent
│   ├── code_to_test.md     # Code agent → Test agent
│   └── review_to_code.md   # Review agent → Code agent
└── checkpoints/
    ├── explore_state.json  # Explore agent checkpoint
    ├── code_state.json     # Code agent checkpoint
    └── test_state.json     # Test agent checkpoint
```

### 9.4 Key Design Decisions for Coding Systems

1. **File-based coordination** over message queues for transparency
2. **Explicit task completion signals** over heuristic detection
3. **Shared workspace** over sandboxed agent spaces
4. **Context injection** at session start for all agents
5. **Checkpoint after every tool result** for robustness
6. **Primitives always available** alongside domain tools

---

## Part 10: Key Takeaways

### For System Designers

1. **Start with primitives**: bash, read, write, edit, grep, glob
2. **Ensure parity**: Every user action has an agent path
3. **Keep tools atomic**: Let agents compose and apply judgment
4. **Inject context**: Agents need to know what exists
5. **Signal explicitly**: No heuristic completion detection
6. **Design for loops**: Agents operate until outcome achieved

### For Implementation

1. **Files as interface**: Agents reason about files naturally
2. **context.md pattern**: Portable working memory
3. **Checkpoint frequently**: After every tool result
4. **Shared workspace**: Transparency and collaboration
5. **CRUD completeness**: Every entity needs all four operations

### For Product

1. **Progressive disclosure**: Simple entry, endless depth
2. **Observe users**: Let agent reveal what users actually need
3. **Match approval to stakes**: Auto-apply low-risk, confirm high-risk
4. **Emergent capability**: Build for unanticipated uses

---

## Appendix: Quick Reference

### Tool Design Checklist

```
□ Is this tool atomic (one operation)?
□ Does it enable outcomes, not encode workflows?
□ Can the agent still access underlying primitives?
□ Does it represent one conceptual action to the user?
□ Are related CRUD operations available?
```

### System Prompt Template

```markdown
# Agent Instructions

## Your Role
[What this agent does]

## Available Resources
- [List files, directories, external systems]
- [Recent activity summary]

## Your Capabilities
- [List available tools and what they do]

## Current Context
- [Active task]
- [Relevant recent history]
- [Any blockers or pending items]

## Guidelines
- [Coding standards]
- [Error handling expectations]
- [When to escalate vs. proceed]
```

### Completion Signal Format

```json
{
  "success": true,
  "output": "Description of what was accomplished",
  "shouldContinue": false,
  "artifacts": ["path/to/created/file"],
  "notes": "Optional context for future agents"
}
```

---

*This analysis is intended to inform the design of autonomous multi-agent coding systems. The patterns described here represent a fundamental shift in how we think about software architecture—from features as code to features as outcomes that agents pursue autonomously.*
