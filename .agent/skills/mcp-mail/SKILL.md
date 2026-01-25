---
name: mcp-mail
description: Multi-agent coordination via MCP Agent Mail. Use when coordinating work between multiple agents, file reservations, or agent messaging.
---

# MCP Agent Mail — Multi-Agent Coordination

Agent Mail provides:
- Identities, inbox/outbox, searchable threads
- Advisory file reservations (leases) to avoid agent conflicts
- Persistent artifacts in git (human-auditable)

## Core Patterns

### Register Identity
```
ensure_project
register_agent(project_key="<repo-abs-path>")
```

### Reserve Files Before Editing
```
file_reservation_paths(
  project_key, 
  agent_name, 
  ["src/**"], 
  ttl_seconds=3600, 
  exclusive=true
)
```

### Communicate
```
send_message(..., thread_id="FEAT-123")
fetch_inbox
acknowledge_message
```

### Fast Reads (Resources)
```
resource://inbox/{Agent}?project=<abs-path>&limit=20
resource://thread/{id}?project=<abs-path>&include_bodies=true
```

## Macros vs Granular

Prefer macros when speed matters:
- `macro_start_session`
- `macro_prepare_thread`
- `macro_file_reservation_cycle`
- `macro_contact_handshake`

## Common Pitfalls

| Error | Solution |
|-------|----------|
| "from_agent not registered" | Call `register_agent` with correct `project_key` |
| `FILE_RESERVATION_CONFLICT` | Adjust patterns, wait for expiry, or use non-exclusive |
