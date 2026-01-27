# brenner_bot (brenner)

Research session manager with hypothesis tracking for AI-driven investigation workflows.

## What It Does

`brenner` (Brenner Bot) helps manage research sessions:
- Track hypotheses and their verification status
- Organize research notes and findings
- Manage multi-agent research workflows
- Search across corpus of collected research

## Installation Verification

```bash
# Check brenner is installed
brenner --version

# Or check help
brenner --help
```

## Basic Usage

### Start a Research Session

```bash
# Start new research session
brenner session new "Investigating auth performance"

# List active sessions
brenner session list
```

### Manage Hypotheses

```bash
# Add a hypothesis
brenner hypothesis add "Redis caching will improve response time by 50%"

# Update hypothesis status
brenner hypothesis update H-1 --status confirmed
brenner hypothesis update H-2 --status rejected

# List hypotheses
brenner hypothesis list
```

### Record Findings

```bash
# Add a finding to current session
brenner note "Found that database queries are the bottleneck"

# Add with evidence link
brenner note "Query plan shows full table scan" --evidence ./query-plan.txt
```

### Search Research Corpus

```bash
# Search across all sessions
brenner search "performance bottleneck"

# Search in specific session
brenner search "redis" --session S-42
```

## Common Workflows

### Structured Investigation

```bash
# 1. Start session
brenner session new "Why are API responses slow?"

# 2. Form hypotheses
brenner hypothesis add "Database connection pooling exhausted"
brenner hypothesis add "Missing index on users table"
brenner hypothesis add "N+1 query in orders endpoint"

# 3. Investigate and record
brenner note "Connection pool shows 100% utilization"
brenner hypothesis update H-1 --status confirmed

# 4. Close session
brenner session close --summary "Fixed connection pool sizing"
```

### Multi-Agent Research

```bash
# Agent 1 starts session
brenner session new "Security audit" --share

# Agent 2 joins
brenner session join S-123

# Both agents can add findings
brenner note "Found XSS vulnerability in /search endpoint"
```

### Review Past Research

```bash
# List all sessions
brenner session list --all

# Show session details
brenner session show S-42

# Export session
brenner session export S-42 --format markdown > research-report.md
```

## Configuration

Configuration is stored in `~/.config/brenner/config.toml`:

```toml
[default]
corpus_path = "~/.brenner/corpus"
session_timeout = "4h"

[search]
engine = "tantivy"
max_results = 50

[export]
default_format = "markdown"
```

## Troubleshooting

### "No active session"

Start or resume a session:

```bash
# Start new
brenner session new "My research"

# Or resume existing
brenner session resume S-42
```

### "Corpus not indexed"

Rebuild the search index:

```bash
brenner index rebuild
```

### "brenner: command not found"

Verify installation:

```bash
# Check installation
which brenner
ls -la ~/.cargo/bin/brenner

# Install if missing
cargo install brenner_bot
```

### Search Returns Stale Results

Update the index after adding notes:

```bash
brenner index update
```

## Integration with AI Agents

Agents can use brenner for:
1. Tracking investigation progress
2. Recording findings systematically
3. Coordinating research across multiple agents
4. Building a searchable knowledge base

Best practices:
- Start a session for each investigation
- Form hypotheses before investigating
- Record evidence with notes
- Close sessions with summaries

## Related Tools

- `cass` - Agent session history search
- `ms` - Skill and knowledge management
- `cm` - Procedural memory for agents
