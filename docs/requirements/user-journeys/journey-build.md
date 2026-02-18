# User Journey: Build Phase

## Overview

**Duration:** 30 minutes - 4 hours (depends on project complexity)
**Goal:** Observe and optionally guide AI agents as they build the software
**Entry Point:** User clicks "Begin Build" from architecture confirmation
**Exit Point:** All tasks complete, user proceeds to Review phase

---

## Journey Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Agents    │────►│   Active    │────►│  Monitor    │────►│   Build     │
│   Spawn     │     │   Building  │     │  & Guide    │     │  Complete   │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                           │                   │
                           ▼                   ▼
                    [Intervene if needed]  [Pause/Resume]
```

---

## Step 1: Agents Spawn

**Screen:** Build Initialization

**Duration:** 5-15 seconds

**User Experience:**
1. Sees "Preparing your build team..." message
2. Watches agents appear in the agent panel
3. Sees first tasks get assigned
4. Canvas begins showing activity

**System Behavior:**
1. NTM spawns configured agents (Claude, Codex, Gemini)
2. Beads task queue is initialized with all tasks
3. Agent Mail connections established
4. First tasks assigned to available agents
5. Real-time updates begin

**Visual Feedback:**
```
┌──────────────────────────────────────────────────────────┐
│  Starting Build...                                       │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Assembling your build team...                           │
│                                                          │
│  ✓ Claude Code #1 ready                                  │
│  ✓ Codex #1 ready                                        │
│  🔄 Gemini #1 starting...                                │
│                                                          │
│  Assigning initial tasks...                              │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Step 2: Active Building

**Screen:** Interactive Canvas with Agent Activity (E2-S1, E3-S1)

**User Actions:**
- Observes canvas with components updating
- Watches agent panel showing current work
- Reads activity log for progress updates
- Optionally clicks components for details

**Primary View:**
```
┌──────────────────────────────────────────────────────────────────┐
│  TaskFlow - Building                    45%  ████████░░░░░░░░░░  │
├──────────────────────────────────────────────────────────────────┤
│ ┌────────────┐                                                   │
│ │  Agents    │   ┌────────────────────────────────────────────┐ │
│ │            │   │                                            │ │
│ │ 🧠 Claude  │   │       ┌──────┐         ┌──────┐           │ │
│ │ Working:   │   │       │ Auth │─────────│ API  │           │ │
│ │ API routes │   │       │ ✅🔄 │         │ 🔄   │           │ │
│ │            │   │       └──────┘         └──────┘           │ │
│ │ 💻 Codex   │   │           │                │               │ │
│ │ Working:   │   │           │                │               │ │
│ │ Auth tests │   │           ▼                ▼               │ │
│ │            │   │       ┌──────┐         ┌──────┐           │ │
│ │ 📚 Gemini  │   │       │ UI   │         │  DB  │           │ │
│ │ Idle       │   │       │ ⏳   │         │ ✅   │           │ │
│ │            │   │       └──────┘         └──────┘           │ │
│ ├────────────┤   │                                            │ │
│ │  Tasks     │   │                                            │ │
│ │ ✅ 10/23   │   └────────────────────────────────────────────┘ │
│ │ 🔄 3       │                                                   │
│ │ ⏳ 10      │   Activity:                                       │
│ └────────────┘   • 10:45 Claude created login API endpoint      │
│                  • 10:44 Codex finished auth unit tests         │
│                  • 10:43 Claude reserved API folder             │
│                                                                  │
│  [Pause All]  [+ Add Agent]                                     │
└──────────────────────────────────────────────────────────────────┘
```

**Real-Time Updates:**
- Component nodes pulse when being worked on
- Checkmarks appear as tasks complete
- Progress bar increments smoothly
- Activity log scrolls with new entries

**Component States:**
| Status | Visual | Meaning |
|--------|--------|---------|
| Pending | ⏳ Gray | Not started |
| In Progress | 🔄 Blue pulse | Agent working |
| Complete | ✅ Green | All tasks done |
| Partial | ✅🔄 Mixed | Some complete |
| Error | ❌ Red | Problem occurred |

---

## Step 3: Monitor & Guide

**Screen:** Same as Step 2, with interaction options

**User Actions (Optional):**
1. Click component to see details (E2-S2)
2. View activity log for progress (E3-S2)
3. Pause/resume agents as needed (E3-S3)
4. See agent communication (E3-S4)
5. Toggle code visibility (E5-S1)

**Interaction: View Component Details**
```
┌──────────────────────────────────────────────────────────┐
│  API Component                                    [×]    │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Status: 🔄 In Progress (60%)                           │
│                                                          │
│  What this does:                                         │
│  Handles all backend communication - receives requests   │
│  from the frontend and interacts with the database.      │
│                                                          │
│  Tasks:                                                  │
│  ✅ Set up API framework                                │
│  ✅ Create project endpoints                            │
│  🔄 Create task endpoints (Claude #1 working)           │
│  ⏳ Create user endpoints                               │
│  ⏳ Add authentication middleware                       │
│                                                          │
│  Files created: 4                                        │
│  • src/api/projects.ts                                  │
│  • src/api/tasks.ts                                     │
│  • ...                                                  │
│                                                          │
│  [View Code] [Pause Work] [Add Note]                    │
└──────────────────────────────────────────────────────────┘
```

**Interaction: Pause Build**
- User clicks "Pause All"
- All agents stop current tasks
- Progress preserved
- User can investigate, add notes, or take a break
- Click "Resume" to continue

**Interaction: View Agent Communication**
```
Agent Communication:

Claude #1 → Codex #1:
"I've completed the API routes for tasks. You can now
write the integration tests for the task endpoints."

Codex #1 → Claude #1:
"Thanks! I'm starting on the task API tests now.
I'll let you know if I find any issues."

Claude #1 reserved: src/api/*, src/routes/*
Codex #1 reserved: src/__tests__/api/*
```

---

## Step 4: Handle Issues (If Any)

**Scenario: Agent Encounters Error**

**User Experience:**
1. Sees error indicator on component (red)
2. Notification appears: "Build paused: Error in Auth component"
3. Clicks component to see details
4. Reviews plain-English error explanation
5. Options: "Ask Agent to Fix" or "Describe Solution"

**Error Display:**
```
┌──────────────────────────────────────────────────────────┐
│  ⚠️ Issue Found                                          │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Component: Authentication                               │
│  Agent: Claude #1                                        │
│                                                          │
│  What happened:                                          │
│  The login function couldn't connect to the database     │
│  because the connection settings are missing.            │
│                                                          │
│  Agent's assessment:                                     │
│  "I need the database connection string to continue.     │
│  This should be in environment configuration."           │
│                                                          │
│  [Ask Agent to Fix] [I'll Provide Info] [Skip for Now]  │
└──────────────────────────────────────────────────────────┘
```

---

## Step 5: Build Complete

**Screen:** Completion Celebration

**User Experience:**
1. Progress reaches 100%
2. All component nodes show green checkmarks
3. Celebration animation plays
4. Summary of what was built displayed
5. Prompt to proceed to Testing/Review

**Completion Display:**
```
┌──────────────────────────────────────────────────────────┐
│  🎉 Build Complete!                                      │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  TaskFlow has been built successfully!                   │
│                                                          │
│  Summary:                                                │
│  • 5 components created                                  │
│  • 23 tasks completed                                    │
│  • 47 files generated                                    │
│  • Build time: 2h 15m                                    │
│                                                          │
│  What's next:                                            │
│  Test your application to make sure everything works     │
│  the way you want before deploying.                      │
│                                                          │
│                     [Preview & Test →]                   │
└──────────────────────────────────────────────────────────┘
```

---

## Background Operation

**If User Leaves:**
- Build continues in background
- Progress saved continuously
- User can return and see current state
- Notification when complete (if browser notifications enabled)

**Session Persistence:**
- All progress saved to Beads and git
- Agent sessions maintained
- User can close browser and return
- State fully recoverable

---

## Error Handling

| Scenario | Handling |
|----------|----------|
| Agent crashes | Auto-restart, reassign task |
| Network disconnect | Pause, auto-resume on reconnect |
| Task fails repeatedly | Flag for human review |
| Rate limit hit | Auto-pause, notify user, resume when able |

---

## Success Criteria

| Metric | Target |
|--------|--------|
| Build completion rate | >90% reach completion |
| Error rate | <10% of builds have errors |
| User intervention | <20% require manual help |
| Time accuracy | Within 50% of estimate |

---

## Related Stories

- E2-S1: Visual Project Canvas
- E2-S2: Component Detail Panel
- E2-S3: Real-Time Agent Updates
- E3-S1: Agent Status Dashboard
- E3-S2: Plain-English Activity Logs
- E3-S3: Pause/Resume Agent Work
- E3-S4: Agent-to-Agent Communication View
- E4-S1: Task Breakdown View
- E4-S2: Progress Visualization
