# Epic 3: Transparent Agent Orchestration

## Overview

**Goal:** Make the multi-agent build process visible and controllable, allowing users to observe how AI agents coordinate to build their software and intervene when needed.

**User Value:** Users understand that sophisticated AI coordination is happening, building trust through transparency. They can course-correct when needed without waiting for a failed build.

---

## Stories

### E3-S1: Agent Status Dashboard

**Priority:** P0
**Points:** 8

#### User Story
As a user, I want to see which agents are working on what tasks so that I understand the build process and know multiple AIs are collaborating on my project.

#### Acceptance Criteria
- [ ] AC1: Given agents are active, when I view the agent panel, then I see a card for each spawned agent showing: name, type (Claude/Codex/Gemini), current task, and status
- [ ] AC2: Given an agent is working, when I view its card, then I see a real-time indicator (spinner/animation) and the task it's executing
- [ ] AC3: Given multiple agents exist, when viewing the panel, then I can see all agents at a glance with clear visual distinction between agent types
- [ ] AC4: Given an agent encounters an issue, when detected, then its card shows a warning/error state with brief description
- [ ] AC5: Given I want to know agent capabilities, when I hover over an agent type badge, then I see a tooltip explaining what that agent excels at

#### Agent Display Information
| Field | Example | Update Frequency |
|-------|---------|------------------|
| Name | "Agent 1" or generated name | Static |
| Type | Claude Code / Codex / Gemini | Static |
| Status | Idle / Working / Error / Paused | Real-time |
| Current Task | "Creating user authentication" | Real-time |
| Progress | "3/5 files complete" | Real-time |
| Uptime | "Running for 12 minutes" | Every minute |

#### Agent Type Descriptions
| Type | Specialty | Icon |
|------|-----------|------|
| Claude Code | Complex reasoning, architecture, debugging | 🧠 |
| Codex | Code generation, refactoring, tests | 💻 |
| Gemini | Documentation, research, validation | 📚 |

#### Technical Notes
- **ACFS Integration:** Agent data from NTM session management; status from Agent Mail
- **Dependencies:** None (core infrastructure)
- **UI Pattern:** Card-based layout in sidebar or collapsible panel

#### Wireframe Description
```
┌──────────────────────────────────┐
│  Active Agents (3)               │
├──────────────────────────────────┤
│ ┌──────────────────────────────┐ │
│ │ 🧠 Claude Code #1    WORKING │ │
│ │ ─────────────────────────── │ │
│ │ Task: Building API routes    │ │
│ │ Progress: ████████░░ 80%    │ │
│ │ Files: 4/5 complete          │ │
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │ 💻 Codex #1          WORKING │ │
│ │ ─────────────────────────── │ │
│ │ Task: Writing unit tests     │ │
│ │ Progress: ████░░░░░░ 40%    │ │
│ │ Files: 2/5 complete          │ │
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │ 📚 Gemini #1           IDLE  │ │
│ │ ─────────────────────────── │ │
│ │ Waiting for tasks...         │ │
│ │ Last: Reviewed architecture  │ │
│ └──────────────────────────────┘ │
└──────────────────────────────────┘
```

#### Definition of Done
- [ ] Agent cards render with all required information
- [ ] Real-time status updates via WebSocket
- [ ] Visual distinction between agent types
- [ ] Error/warning states clearly visible
- [ ] Tooltips for agent type descriptions
- [ ] Mobile-responsive layout
- [ ] Unit tests for agent card rendering

---

### E3-S2: Plain-English Activity Logs

**Priority:** P0
**Points:** 8

#### User Story
As a user, I want to see agent activity logs in plain English so that I can follow their progress without understanding code or technical jargon.

#### Acceptance Criteria
- [ ] AC1: Given agents are working, when I open the activity log, then I see a chronological list of actions described in plain language
- [ ] AC2: Given a log entry is created, when displayed, then it includes: timestamp, agent name, action description, and affected component
- [ ] AC3: Given technical actions occur, when logged, then they are translated to user-friendly descriptions (e.g., "Created new file" not "git add src/auth.ts")
- [ ] AC4: Given I want to filter logs, when I select filters, then I can view by agent, component, or action type
- [ ] AC5: Given an action has details, when I click a log entry, then I see expanded information about what happened

#### Activity Translation Examples
| Technical Action | Plain English |
|-----------------|---------------|
| `git commit -m "Add auth routes"` | "Saved progress on authentication" |
| `npm install bcrypt` | "Added password encryption capability" |
| `CREATE TABLE users` | "Set up user database storage" |
| `jest src/auth.test.ts` | "Ran tests on authentication" |
| `Reserved files: src/api/*` | "Agent 1 is now working on the API folder" |

#### Technical Notes
- **ACFS Integration:** Events from NTM/Agent Mail translated via predefined mappings; complex actions may use Claude for translation
- **Dependencies:** E3-S1
- **Performance:** Virtual scrolling for large log lists

#### Wireframe Description
```
┌──────────────────────────────────────────────────────────┐
│  Activity Log                    [Filter ▼] [Clear]      │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  10:45:23  🧠 Claude #1                                  │
│  ► Created the user login page                           │
│    Component: Authentication                             │
│                                                          │
│  10:44:58  💻 Codex #1                                   │
│  ► Added password validation rules                       │
│    Component: Authentication                             │
│                                                          │
│  10:44:12  🧠 Claude #1                                  │
│  ► Set up the database connection                        │
│    Component: Database                                   │
│                                                          │
│  10:43:30  📚 Gemini #1                                  │
│  ► Reviewed the project architecture                     │
│    Component: Planning                                   │
│                                                          │
│  [Load more...]                                          │
└──────────────────────────────────────────────────────────┘
```

#### Definition of Done
- [ ] Activity log component with virtual scrolling
- [ ] Technical-to-plain-English translation layer
- [ ] Filtering by agent, component, action type
- [ ] Expandable entries for details
- [ ] Auto-scroll to newest (with option to pause)
- [ ] Unit tests for activity translation

---

### E3-S3: Pause/Resume Agent Work

**Priority:** P1
**Points:** 5

#### User Story
As a user, I want to pause and resume agent work so that I can intervene when I notice something going wrong or need to provide additional input.

#### Acceptance Criteria
- [ ] AC1: Given agents are working, when I click "Pause All", then all agents stop their current tasks and enter paused state
- [ ] AC2: Given an individual agent is working, when I click pause on its card, then only that agent pauses while others continue
- [ ] AC3: Given agents are paused, when I click "Resume", then agents continue from where they stopped
- [ ] AC4: Given I pause agents, when paused, then I see what task each agent will resume with
- [ ] AC5: Given an agent is mid-task when paused, when resumed, then it completes the interrupted task before moving on

#### Pause States
| State | Icon | Behavior |
|-------|------|----------|
| Working | 🟢 | Actively executing tasks |
| Paused | 🟡 | Stopped, waiting for resume |
| Error | 🔴 | Stopped due to error, needs attention |
| Idle | ⚪ | No tasks assigned |

#### Technical Notes
- **ACFS Integration:** Pause/resume commands sent to NTM; Agent Mail notifies other agents of paused state
- **Dependencies:** E3-S1
- **Consideration:** Graceful pause (complete current atomic operation) vs immediate pause

#### Definition of Done
- [ ] Pause All button in header
- [ ] Individual pause buttons on agent cards
- [ ] Resume functionality restores previous state
- [ ] Paused state clearly visible
- [ ] Integration with NTM pause/resume commands
- [ ] Unit tests for state transitions

---

### E3-S4: Agent-to-Agent Communication View

**Priority:** P1
**Points:** 8

#### User Story
As a user, I want to see agent-to-agent communication so that I understand how they coordinate and can observe sophisticated collaboration.

#### Acceptance Criteria
- [ ] AC1: Given agents are coordinating, when I open the communication view, then I see messages between agents in a chat-like format
- [ ] AC2: Given an agent sends a message, when displayed, then I see: sender, recipient(s), subject, and plain-English summary of the content
- [ ] AC3: Given agents reserve files, when a reservation is made, then I see which agent has locked what files
- [ ] AC4: Given a coordination conflict occurs, when detected, then I see a highlighted warning about the conflict
- [ ] AC5: Given I want to understand a message, when I click it, then I see the full content (may include technical details)

#### Message Types
| Type | Icon | Description |
|------|------|-------------|
| Task handoff | 🤝 | "Agent 1 asked Agent 2 to handle testing" |
| File reservation | 🔒 | "Agent 1 reserved the auth folder" |
| Question | ❓ | "Agent 2 asked for clarification on the API design" |
| Update | 📢 | "Agent 1 announced completion of the database schema" |
| Conflict | ⚠️ | "Both agents tried to edit the same file" |

#### Technical Notes
- **ACFS Integration:** Messages from Agent Mail inbox/outbox; file reservations from MCP
- **Dependencies:** E3-S1, E3-S2
- **UI Pattern:** Chat-style message list with threading capability

#### Definition of Done
- [ ] Message list component with agent avatars
- [ ] Message type icons and styling
- [ ] File reservation display
- [ ] Conflict highlighting
- [ ] Expandable message details
- [ ] Unit tests for message rendering

---

### E3-S5: Redirect Agent to Different Task

**Priority:** P2
**Points:** 5

#### User Story
As a user, I want to redirect an agent to a different task so that I can course-correct when I see an agent working on something that isn't a priority.

#### Acceptance Criteria
- [ ] AC1: Given an agent is working on a task, when I click "Change Task" on its card, then I see a list of available tasks
- [ ] AC2: Given I select a different task, when I confirm, then the agent stops current work and switches to the new task
- [ ] AC3: Given I redirect an agent, when the original task is abandoned, then it returns to the task queue for another agent
- [ ] AC4: Given I want to suggest a task, when I type a custom instruction, then the agent receives and acts on it
- [ ] AC5: Given a redirect might cause issues, when I attempt it, then I see a warning about potential implications

#### Technical Notes
- **ACFS Integration:** Task reassignment via Beads; custom instructions via NTM prompt sending
- **Dependencies:** E3-S1, E4-S1
- **Consideration:** Some tasks may not be interruptible; need graceful handling

#### Definition of Done
- [ ] Task list modal for redirection
- [ ] Confirmation dialog with implications
- [ ] Original task returns to queue
- [ ] Custom instruction input option
- [ ] Warning for potentially problematic redirects
- [ ] Integration tests with task queue

---

### E3-S6: Spawn Additional Agents

**Priority:** P2
**Points:** 5

#### User Story
As a user, I want to spawn additional agents so that I can accelerate the build when I have available capacity.

#### Acceptance Criteria
- [ ] AC1: Given I want more agents, when I click "Add Agent", then I see options for which type of agent to spawn
- [ ] AC2: Given I select an agent type, when I confirm, then a new agent session starts and appears in the agent panel
- [ ] AC3: Given I spawn an agent, when it starts, then it automatically picks up available tasks from the queue
- [ ] AC4: Given I have multiple agents of the same type, when displayed, then they are numbered (Claude #1, Claude #2)
- [ ] AC5: Given I want to reduce agents, when I click "Remove" on an idle agent, then it is gracefully terminated

#### Agent Spawning Interface
```
┌───────────────────────────────────────┐
│  Add Agent                            │
├───────────────────────────────────────┤
│                                       │
│  Select agent type:                   │
│                                       │
│  [🧠 Claude Code]  Best for complex   │
│                    reasoning          │
│                                       │
│  [💻 Codex]        Best for code      │
│                    generation         │
│                                       │
│  [📚 Gemini]       Best for docs      │
│                    and validation     │
│                                       │
│         [Cancel]  [Add Agent]         │
└───────────────────────────────────────┘
```

#### Technical Notes
- **ACFS Integration:** NTM spawn command with agent type parameter
- **Dependencies:** E3-S1
- **Consideration:** Rate limits and cost implications should be communicated

#### Definition of Done
- [ ] Add Agent modal with type selection
- [ ] New agent appears in panel on spawn
- [ ] Agent auto-assigns to available tasks
- [ ] Remove agent option for idle agents
- [ ] Rate limit/cost warning if applicable
- [ ] Integration tests with NTM spawn

---

## Epic Summary

| Story | Priority | Points | Dependencies |
|-------|----------|--------|--------------|
| E3-S1 | P0 | 8 | None |
| E3-S2 | P0 | 8 | E3-S1 |
| E3-S3 | P1 | 5 | E3-S1 |
| E3-S4 | P1 | 8 | E3-S1, E3-S2 |
| E3-S5 | P2 | 5 | E3-S1, E4-S1 |
| E3-S6 | P2 | 5 | E3-S1 |

**Total Points:** 39
**P0 Points:** 16
