---
name: warp-grep
description: AI-powered code search with Morph. Use when exploring how something works across the codebase or tracing data flow.
---

# Morph Warp Grep — AI-Powered Code Search

Use `mcp__morph-mcp__warp_grep` for "how does X work?" discovery across the codebase.

## When to Use

- You don't know where something lives
- You want data flow across multiple files (API → service → schema → types)
- You want all touchpoints of a cross-cutting concern

## Example

```
mcp__morph-mcp__warp_grep(
  repoPath: "/data/projects/myproject",
  query: "How is authentication implemented?"
)
```

## How It Works

1. Expands natural-language query to multiple search patterns
2. Runs targeted greps, reads code, follows imports
3. Returns concise snippets with line numbers

## When NOT to Use

| Don't Use Warp Grep For | Use Instead |
|-------------------------|-------------|
| You know the identifier name | `rg` |
| You know the exact file | Just open it |
| Yes/no existence check | `rg` |

## Comparison Table

| Scenario | Tool |
|----------|------|
| "How is auth session validated?" | warp_grep |
| "Where is `handleSubmit` defined?" | `rg` |
| "Replace `var` with `let`" | `ast-grep` |
