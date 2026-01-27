# meta_skill (ms)

Local-first knowledge management with hybrid semantic search for AI coding agents.

## What It Does

`ms` (meta_skill) provides:
- Skill file management and organization
- Hybrid search (semantic + lexical) over skill content
- Doctor diagnostics for health checks
- Integration with AI agent workflows

Skills are reusable prompts, instructions, and knowledge that agents can invoke during coding sessions.

## Installation Verification

```bash
# Check ms is installed
ms --version

# Run health diagnostics
ms doctor --json
```

Expected: version number and JSON diagnostic report.

## Basic Usage

### List Skills

```bash
# List all available skills
ms list

# List with details
ms list --verbose
```

### Search Skills

```bash
# Semantic search for relevant skills
ms search "git commit workflow"

# Lexical search
ms search "docker" --mode lexical
```

### Show Skill Details

```bash
# Show a specific skill
ms show skill-name

# Show skill content
ms cat skill-name
```

### Health Check

```bash
# Run diagnostics
ms doctor

# JSON output for automation
ms doctor --json
```

## Common Workflows

### Finding Relevant Skills

When starting a task, search for existing skills:

```bash
# Find skills for TypeScript work
ms search "typescript testing"

# Find deployment skills
ms search "vercel deploy"
```

### Using Skills in Claude Code

Skills can be invoked with slash commands:

```
/commit     # Use the commit skill
/review-pr  # Use the PR review skill
```

### Creating New Skills

Skills are stored in skill directories. Create a new skill:

```bash
# Skills typically live in ~/.claude/skills/ or project-local
mkdir -p ~/.claude/skills/my-skill
cat > ~/.claude/skills/my-skill/SKILL.md << 'EOF'
# My Custom Skill

Description of what this skill does.

## Usage

Instructions for the agent...
EOF
```

## Troubleshooting

### "ms: command not found"

Verify installation:

```bash
# Check if ms binary exists
which ms
ls -la ~/.local/bin/ms

# Add to PATH if needed
export PATH="$HOME/.local/bin:$PATH"
```

### "Database not initialized"

Initialize the skill index:

```bash
ms init
# or
ms doctor --fix
```

### Search Returns No Results

Check that skills are indexed:

```bash
# Re-index skills
ms index --rebuild

# Verify skill directories
ms config show
```

## Integration with AI Agents

Agents should:
1. Search for relevant skills before implementing solutions
2. Use existing skills to maintain consistency
3. Create new skills for reusable patterns
4. Run `ms doctor` to verify health after installation

## Related Tools

- Claude Code `/skill` command for invoking skills
- `jfp` (JeffreysPrompts) for curated prompt library
- `cass` for agent session history search
