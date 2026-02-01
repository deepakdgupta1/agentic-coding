---
name: giil
description: Download cloud-hosted images for visual debugging. Use when user shares iCloud, Dropbox, or Google Photos links.
---

# giil — Get Image from Internet Link

Downloads **cloud-hosted images** to the terminal for visual debugging.

## Usage

```bash
giil "https://share.icloud.com/..."   # iCloud
giil "https://www.dropbox.com/s/..."  # Dropbox
giil "https://photos.google.com/..."  # Google Photos
giil "..." --output ~/screenshots     # Custom output
giil "..." --json                     # JSON metadata
giil "..." --all                      # Download album
```

## Supported Platforms

- iCloud (share.icloud.com)
- Dropbox (dropbox.com/s/, dl.dropbox.com)
- Google Photos/Drive

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 10 | Network error |
| 11 | Auth required |
| 12 | Not found/expired |
| 13 | Unsupported type |

## Workflow

1. User screenshots bug on phone
2. Shares cloud link
3. `giil "<url>"` downloads locally
4. Agent analyzes image
