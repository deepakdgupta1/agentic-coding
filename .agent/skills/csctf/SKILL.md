---
name: csctf
description: Convert AI chat share links to Markdown/HTML archives. Use when archiving AI conversations or building knowledge bases.
---

# csctf — Chat Shared Conversation to File

Converts **AI chat share links** to Markdown/HTML.

## Usage

```bash
csctf "https://chatgpt.com/share/..."       # ChatGPT
csctf "https://gemini.google.com/share/..." # Gemini
csctf "https://claude.ai/share/..."         # Claude
csctf "..." --md-only                       # Markdown only
csctf "..." --json                          # JSON metadata
csctf "..." --publish-to-gh-pages --yes     # GitHub Pages
```

## Output

- `<slug>.md` — Clean Markdown with code blocks
- `<slug>.html` — Static HTML with syntax highlighting

## Use Cases

- Archive important AI conversations
- Build searchable knowledge base
- Share solutions with team
- Document debugging sessions
