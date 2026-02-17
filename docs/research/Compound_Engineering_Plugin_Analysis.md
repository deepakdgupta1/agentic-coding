# Compound Engineering Plugin: Architecture & Design Analysis

> **Purpose**: This document provides a comprehensive analysis of the [EveryInc Compound Engineering Plugin](https://github.com/EveryInc/compound-engineering-plugin) to inform the design of multi-agent autonomous coding systems.

---

## Executive Summary

The Compound Engineering Plugin is a Claude Code plugin implementing a **compounding methodology** where each unit of engineering work makes subsequent work easier. The system features:

- **27 specialized agents** organized by function (review, research, design, workflow, docs)
- **21 commands** orchestrating multi-agent workflows
- **14 skills** providing reusable capabilities
- **1 MCP server** (Context7) for framework documentation lookup

**Core Philosophy**: "Each unit of engineering work should make subsequent units easier—not harder."

**Resource Allocation**: 80% planning and review, 20% execution

---

## Architectural Overview

### High-Level Workflow Cycle

```
Plan → Work → Review → Compound → Repeat
```

This cycle ensures that:
1. **Plan**: Features are thoroughly researched and designed before implementation
2. **Work**: Execution follows structured plans with continuous testing
3. **Review**: Multi-agent analysis catches issues before merge
4. **Compound**: Learnings are documented for future reuse

### Plugin Structure

```
plugins/compound-engineering/
├── .claude-plugin/
│   └── plugin.json           # Plugin metadata and MCP server config
├── agents/
│   ├── design/               # 3 agents for UI/design work
│   ├── docs/                 # 1 agent for documentation
│   ├── research/             # 4 agents for codebase research
│   ├── review/               # 14 agents for code review
│   └── workflow/             # 5 agents for task orchestration
├── commands/
│   ├── workflows/            # Core workflow commands
│   └── *.md                  # Utility commands
└── skills/
    └── */                    # 14 skill directories with SKILL.md
```

---

## Core Workflow Commands

### 1. `/workflows:plan` — Planning Phase

**Purpose**: Transform feature ideas into detailed implementation plans.

**Multi-Agent Orchestration**:
```
[Parallel Research Phase]
├── repo-research-analyst      → Analyzes repository structure
├── best-practices-researcher  → Gathers industry best practices
├── framework-docs-researcher  → Retrieves framework documentation
└── spec-flow-analyzer         → Validates specifications
```

**Key Features**:
- Three detail levels: Minimal / More / A Lot
- Plans stored in `plans/<type>-<descriptive-name>.md`
- Conventional prefixes: `feat:`, `fix:`, `refactor:`
- ERD diagrams for model changes
- Cross-references to issues/PRs

**Output Integration**:
- Opens plan in editor
- Chains to `/deepen-plan` for research enhancement
- Chains to `/plan_review` for reviewer feedback
- Chains to `/workflows:work` for implementation
- Creates GitHub/Linear issues

### 2. `/workflows:work` — Execution Phase

**Purpose**: Execute plans systematically to ship complete features.

**Four-Phase Execution Model**:

| Phase | Activities |
|-------|------------|
| **Quick Start** | Read plan, ask clarifying questions, choose environment (worktree recommended), create TodoWrite task list |
| **Execute** | Mark in_progress → implement → test → mark completed; match existing patterns; continuous testing |
| **Quality Check** | Full test suite, linting agent, optional reviewers for complex changes |
| **Ship It** | Conventional commit, capture screenshots, push and create PR |

**Key Principles**:
- "Start Fast, Execute Faster" — clarify once, then execute
- Follow plan references and existing patterns
- Test continuously, not at the end
- Ship complete features, not 80% solutions
- Use reviewer agents sparingly (only for complex/risky changes)

**Worktree Integration**:
- Uses `git-worktree` skill for isolated parallel development
- Enables working on multiple features simultaneously

### 3. `/workflows:review` — Review Phase

**Purpose**: Exhaustive multi-agent code review using parallel analysis.

**Parallel Agent Deployment** (13+ agents simultaneously):
```
[Standard Review Agents]
├── kieran-rails-reviewer     → Rails-specific conventions
├── dhh-rails-reviewer        → DHH-style Rails patterns
├── rails-turbo-expert        → Turbo integration (conditional)
├── git-history-analyzer      → Historical context
├── dependency-detective      → Dependency analysis
├── pattern-recognition-specialist
├── architecture-strategist   → System design evaluation
├── code-philosopher          → High-level code quality
├── security-sentinel         → Security vulnerabilities
├── performance-oracle        → Performance implications
├── devops-harmony-analyst    → Deployment considerations
├── data-integrity-guardian   → Data consistency
└── agent-native-reviewer     → Agent-native patterns
```

**Conditional Agents** (for database migrations):
- `data-migration-expert`: Validates ID mappings, rollback safety
- `deployment-verification-agent`: Go/No-Go checklists with SQL verification

**Ultra-Thinking Analysis**:

1. **Stakeholder Perspectives**:
   - Developer (ease of modification, testing)
   - Operations (deployment, monitoring)
   - End User (intuitiveness, performance)
   - Security Team (attack surface, compliance)
   - Business (ROI, legal risks)

2. **Scenario Exploration**:
   - Happy paths, invalid inputs, boundary conditions
   - Concurrent access, scale testing
   - Network issues, resource exhaustion
   - Security attacks, data corruption, cascading failures

**Severity-Based Findings**:

| Level | Name | Description | Action |
|-------|------|-------------|--------|
| 🔴 | P1 CRITICAL | Security vulnerabilities, data corruption, breaking changes | Blocks merge |
| 🟡 | P2 IMPORTANT | Performance issues, architectural concerns | Should fix |
| 🔵 | P3 NICE-TO-HAVE | Minor improvements, cleanup | Optional |

**Todo File Structure**:
```
todos/{issue_id}-{status}-{priority}-{description}.md
```
Includes: YAML frontmatter, Problem Statement, Findings, Proposed Solutions (2-3 with pros/cons/effort/risk), Acceptance Criteria, Work Log

### 4. `/workflows:compound` — Knowledge Capture Phase

**Purpose**: Document solved problems for future reuse.

**Parallel Subagent Architecture** (6 agents simultaneously):
```
[Documentation Assembly]
├── Context Analyzer          → Extracts conversation history, generates YAML frontmatter
├── Solution Extractor        → Analyzes investigation, extracts working solution
├── Related Docs Finder       → Searches existing solutions, cross-references
├── Prevention Strategist     → Develops prevention strategies, best practices
├── Category Classifier       → Determines optimal category path, filename
└── Documentation Writer      → Assembles complete markdown, creates file
```

**Post-Documentation Enhancement**:
Automatically invokes specialized agents based on problem type:
- `performance_issue` → performance-oracle
- `security_issue` → security-sentinel
- `database_issue` → data-integrity-guardian
- Code-heavy issues → kieran-rails-reviewer + code-simplicity-reviewer

**Output Categories**:
```
docs/solutions/
├── build-errors/
├── test-failures/
├── runtime-errors/
├── performance-issues/
├── database-issues/
├── security-issues/
├── ui-bugs/
├── integration-issues/
└── logic-errors/
```

**Knowledge Compounding Value**: "The first time you solve a problem takes research. Documentation transforms 30-minute researches into 2-minute lookups."

---

## Agent Architecture

### Agent Categories

| Category | Count | Purpose |
|----------|-------|---------|
| **Review** | 14 | Code quality, security, performance, language-specific conventions |
| **Research** | 4 | Codebase understanding, best practices, documentation |
| **Design** | 3 | UI/UX validation, Figma sync |
| **Workflow** | 5 | Bug reproduction, linting, PR comment resolution |
| **Docs** | 1 | README generation |

### Agent Design Patterns

#### 1. Specialized Review Agents

**Example: `kieran-rails-reviewer`**

Core Philosophy:
- **Existing Code Modifications**: Strict scrutiny — added complexity requires strong justification
- **New Code**: Pragmatic approach — isolated working code is acceptable

Key Conventions:
- 5-Second Rule: Names should communicate purpose within 5 seconds
- Turbo Streams: Inline arrays in controllers, not separate `.turbo_stream.erb` files
- Namespacing: Always use `class Module::ClassName` pattern
- Testing as Quality Indicator: Hard-to-test code indicates poor structure

Principles:
- **Duplication > Complexity**: Prefer simple duplicated code over complex DRY abstractions
- More simple controllers beats fewer complex controllers
- Consider performance at scale, but avoid premature optimization

#### 2. Research Agents

**Example: `repo-research-analyst`**

Core Responsibilities:
1. Architecture and Structure Analysis (README, ARCHITECTURE.md, CONTRIBUTING.md)
2. GitHub Issue Pattern Analysis (formatting, labels, automation)
3. Documentation and Guidelines Review
4. Template Discovery (`.github/ISSUE_TEMPLATE/`)
5. Codebase Pattern Search (ast-grep for syntax-aware matching)

Methodology:
- Start high-level, progressively drill down
- Cross-reference discoveries across sources
- Prioritize official documentation over inferred patterns
- Note inconsistencies or documentation gaps

**Example: `best-practices-researcher`**

Three-Phase Research:
1. **Check Local Skills First**: Glob for SKILL.md files, match topics to skills
2. **Online Research**: Context7 MCP, web search for recent guides
3. **Synthesize Findings**: Prioritize skill-based guidance, organize by Must Have/Recommended/Optional

#### 3. Architecture Agents

**Example: `architecture-strategist`**

Four-Step Analysis:
1. Understand System Architecture
2. Analyze Change Context
3. Identify Violations and Improvements
4. Consider Long-term Implications

Concerns Monitored:
- Component intimacy issues
- Leaky abstractions
- Dependency rule violations
- Pattern inconsistencies
- Missing architectural boundaries

---

## Skills System

### Available Skills (14)

| Skill | Purpose |
|-------|---------|
| `agent-browser` | Browser automation via Playwright MCP |
| `agent-native-architecture` | Agent-native design patterns |
| `andrew-kane-gem-writer` | Ruby gem creation in Andrew Kane style |
| `compound-docs` | Documentation generation for Compound system |
| `create-agent-skills` | Meta-skill for creating new skills |
| `dhh-rails-style` | DHH Rails conventions |
| `dspy-ruby` | Ruby implementation of DSPy patterns |
| `every-style-editor` | Every publication style guidelines |
| `file-todos` | File-based TODO management |
| `frontend-design` | Frontend design capabilities |
| `gemini-imagegen` | Image generation via Gemini API |
| `git-worktree` | Git worktree management for parallel work |
| `rclone` | Cloud storage synchronization |
| `skill-creator` | Meta-skill for creating new skills |

### Skill Discovery Pattern

Skills are discovered from multiple locations:
```
Project-local:     .claude/skills/
User global:       ~/.claude/skills/
Plugin cache:      ~/.claude/plugins/cache/*/skills/
```

The `/deepen-plan` command spawns one subagent per matched skill in parallel.

---

## MCP Server Integration

### Context7

**Purpose**: Framework documentation lookup supporting 100+ frameworks

**Configuration**:
```json
{
  "mcpServers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp"
    }
  }
}
```

**Tools Provided**:
- Library ID resolution
- Documentation retrieval

---

## Parallel Execution Patterns

### Key Design Decisions

1. **Maximize Parallelism**: Independent agents run simultaneously
2. **Dependency-Aware Sequencing**: Related tasks execute in order
3. **No Filtering by Relevance**: Run ALL discovered agents (40+ is acceptable)
4. **Subagent Model**: Each agent runs as a separate subprocess

### Parallel Resolution Commands

**`/resolve_parallel`** — Resolve TODO comments through parallel processing:
1. Analyze: Gather all TODO items
2. Plan: Identify dependencies, create mermaid diagram
3. Implement (PARALLEL): Spawn `pr-comment-resolver` per TODO
4. Commit & Resolve: Push changes

**`/resolve_pr_parallel`** — Parallel PR comment resolution

**`/resolve_todo_parallel`** — Parallel TODO item resolution

---

## Knowledge Compounding Mechanics

### How Learnings Feed Forward

1. **Capture**: `/workflows:compound` creates structured solution docs
2. **Store**: Documents saved in `docs/solutions/` with YAML frontmatter
3. **Index**: YAML includes tags, category, module, symptom, root_cause
4. **Retrieve**: `/deepen-plan` searches solutions for relevant learnings
5. **Apply**: Subagents check if learnings apply and quote key insights

### Example Frontmatter

```yaml
---
title: "Fix N+1 Query in Dashboard"
tags: [performance, rails, activerecord]
category: performance-issues
module: dashboard
symptom: "Slow page load with many database queries"
root_cause: "Missing includes on association"
created: 2025-01-15
---
```

### Compounding Benefits

From the methodology article:
> "Changed variable naming to match pattern from PR #234, removed excessive test coverage per feedback on PR #219, added error handling similar to approved approach in PR #241."

The system learns from every PR, code review, and bug fix.

---

## Key Design Principles

### 1. Plan Thoroughly Before Coding

- 80% planning and review, 20% execution
- Multi-agent research before implementation
- Detail levels scale with complexity

### 2. Parallel Multi-Agent Analysis

- Maximum coverage through simultaneous agent execution
- No filtering — spawn all relevant agents
- Synthesis after collection

### 3. Continuous Quality Integration

- Test continuously during work phase
- Reviewers run in parallel at end
- Severity-based prioritization (P1 blocks merge)

### 4. Knowledge Preservation

- Every solved problem becomes a documented solution
- Solutions include prevention strategies
- Learnings automatically inform future plans

### 5. File-Based State Management

- Plans in `plans/` directory
- Solutions in `docs/solutions/`
- TODOs in `todos/` with structured naming
- All state is grep-able and version-controlled

---

## Implementation Recommendations for Multi-Agent Systems

### Agent Design

1. **Single Responsibility**: Each agent has one clear purpose
2. **Structured Output**: Defined output formats for synthesis
3. **Model Inheritance**: Agents inherit model from parent (configurable)
4. **Self-Contained Instructions**: Full context in agent definition

### Orchestration Patterns

1. **Parallel-First**: Default to parallel execution when no dependencies
2. **Dependency Graphs**: Visualize with mermaid diagrams
3. **Subagent Spawning**: Use Task tool for isolated execution
4. **Result Synthesis**: Collect and merge outputs from parallel agents

### Knowledge Management

1. **YAML Frontmatter**: Enable structured search and filtering
2. **Category Hierarchy**: Organize by problem type
3. **Solution Templates**: Standardize documentation format
4. **Auto-Detection**: Trigger compounding on success phrases

### Skill Architecture

1. **Multi-Source Discovery**: Project, user, plugin locations
2. **SKILL.md Standard**: Single documentation file per skill
3. **No Filtering**: Match broadly, let agents determine relevance
4. **Composability**: Skills can reference other skills

---

## Configuration Reference

### plugin.json

```json
{
  "name": "compound-engineering",
  "version": "2.26.4",
  "description": "AI-powered development tools. 27 agents, 21 commands, 14 skills, 1 MCP server",
  "author": {
    "name": "Kieran Klaassen",
    "email": "kieran@every.to"
  },
  "license": "MIT",
  "keywords": [
    "ai-powered",
    "compound-engineering",
    "workflow-automation",
    "code-review",
    "rails", "ruby", "python", "typescript"
  ],
  "mcpServers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp"
    }
  }
}
```

### Installation

```bash
# Add marketplace
/plugin marketplace add https://github.com/EveryInc/compound-engineering-plugin

# Install plugin
/plugin install compound-engineering
```

---

## Summary: Key Takeaways for Multi-Agent System Design

| Principle | Implementation |
|-----------|----------------|
| **Compounding Knowledge** | Document every solution; feed learnings into future planning |
| **Parallel Multi-Agent** | Spawn 10-40+ agents simultaneously; synthesize results |
| **Workflow Phases** | Plan → Work → Review → Compound cycle |
| **Severity Prioritization** | P1 Critical / P2 Important / P3 Nice-to-Have |
| **File-Based State** | Plans, solutions, todos in version-controlled directories |
| **Skill Reuse** | SKILL.md files discovered from multiple locations |
| **MCP Integration** | External services via MCP servers (Context7 for docs) |
| **Research-First** | 80% planning/review, 20% execution |
| **Stakeholder Perspectives** | Developer, Operations, End User, Security, Business |
| **Continuous Testing** | Test after each change, not at the end |

---

*Document generated for use by AI agents in designing multi-agent autonomous coding systems.*
