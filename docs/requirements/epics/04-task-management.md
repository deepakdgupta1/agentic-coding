# Epic 4: Task Management & Progress Tracking

## Overview

**Goal:** Provide clear visibility into the work breakdown, progress status, and any blockers, enabling users to understand what has been done and what remains.

**User Value:** Users can track progress without micromanaging, understand why things might be taking time (blocked tasks), and have confidence that work is proceeding systematically.

---

## Stories

### E4-S1: Task Breakdown View

**Priority:** P0
**Points:** 8

#### User Story
As a user, I want to see a task breakdown of my project so that I understand the work involved and can track what's being built.

#### Acceptance Criteria
- [ ] AC1: Given my project has been analyzed, when I view tasks, then I see a hierarchical list organized by component/feature area
- [ ] AC2: Given a task exists, when displayed, then I see: task name, status (pending/in-progress/complete), assigned agent (if any), and estimated complexity
- [ ] AC3: Given tasks have dependencies, when I view a task, then I can see what it depends on and what depends on it
- [ ] AC4: Given I want to understand a task, when I click on it, then I see a plain-English description of what will be built
- [ ] AC5: Given tasks are numerous, when viewing, then I can collapse/expand task groups by component

#### Task Display Structure
```
📁 Authentication (4 tasks)
├── ✅ Set up user database table [Complete]
├── 🔄 Create login/register API endpoints [In Progress - Claude #1]
├── ⏳ Build login page UI [Pending - blocked by API]
└── ⏳ Add session management [Pending]

📁 Dashboard (3 tasks)
├── ⏳ Design dashboard layout [Pending]
├── ⏳ Implement data fetching [Pending - blocked by Auth]
└── ⏳ Create dashboard widgets [Pending]
```

#### Task Status Icons
| Status | Icon | Color |
|--------|------|-------|
| Pending | ⏳ | Gray |
| In Progress | 🔄 | Blue |
| Complete | ✅ | Green |
| Blocked | 🚫 | Orange |
| Error | ❌ | Red |

#### Technical Notes
- **ACFS Integration:** Task data from Beads issue tracker; DAG structure preserved
- **Dependencies:** E1-S4 (specification generates initial tasks)
- **UI Pattern:** Tree view with collapsible sections

#### Wireframe Description
```
┌──────────────────────────────────────────────────────┐
│  Tasks                          [View: List ▼]       │
├──────────────────────────────────────────────────────┤
│  🔍 Search tasks...                                  │
│                                                      │
│  📁 Authentication (2/4 complete)           [−]     │
│  ├── ✅ Database: User table                        │
│  │   └── Completed by Claude #1 • 10:32 AM         │
│  ├── 🔄 API: Login endpoints                        │
│  │   └── Claude #1 working • Started 10:35 AM      │
│  ├── 🚫 UI: Login page                              │
│  │   └── Blocked by: API endpoints                  │
│  └── ⏳ Auth: Session management                    │
│      └── Waiting for: Login page                    │
│                                                      │
│  📁 Dashboard (0/3 complete)                [+]     │
│                                                      │
│  📁 Settings (0/2 complete)                 [+]     │
└──────────────────────────────────────────────────────┘
```

#### Definition of Done
- [ ] Hierarchical task list component
- [ ] Collapsible sections by component
- [ ] Status icons and color coding
- [ ] Agent assignment display
- [ ] Task search functionality
- [ ] Click-to-expand task details
- [ ] Unit tests for task rendering

---

### E4-S2: Progress Visualization

**Priority:** P0
**Points:** 5

#### User Story
As a user, I want to see task completion percentages and progress visualization so that I know overall status at a glance.

#### Acceptance Criteria
- [ ] AC1: Given tasks exist, when I view the header, then I see an overall progress bar with percentage (e.g., "45% complete")
- [ ] AC2: Given tasks are organized by component, when I view the task list, then each component shows its own progress percentage
- [ ] AC3: Given progress changes, when a task completes, then progress indicators update in real-time with smooth animation
- [ ] AC4: Given I want to understand progress breakdown, when I hover over the progress bar, then I see: completed, in-progress, blocked, and pending counts
- [ ] AC5: Given the build is complete, when 100% is reached, then I see a celebration animation and prompt to proceed to testing/deployment

#### Progress Metrics
| Metric | Calculation | Display |
|--------|-------------|---------|
| Overall % | Completed / Total tasks | Main progress bar |
| Component % | Completed in component / Total in component | Section headers |
| Velocity | Tasks completed per hour | Tooltip/detail view |
| ETA | Remaining tasks / Velocity | Tooltip (rough estimate) |

#### Technical Notes
- **ACFS Integration:** Task counts from Beads; real-time updates via WebSocket
- **Dependencies:** E4-S1
- **Animation:** Framer Motion for smooth progress bar transitions

#### Definition of Done
- [ ] Overall progress bar in header
- [ ] Per-component progress indicators
- [ ] Real-time updates with animations
- [ ] Hover tooltip with breakdown
- [ ] 100% completion celebration
- [ ] Unit tests for progress calculation

---

### E4-S3: Blocked Task Visualization

**Priority:** P1
**Points:** 5

#### User Story
As a user, I want to see blocked tasks and their dependencies so that I understand why certain work hasn't started and what's holding it up.

#### Acceptance Criteria
- [ ] AC1: Given a task is blocked, when displayed, then it shows a "Blocked" status with visual indication (orange/red styling)
- [ ] AC2: Given a task is blocked, when I view its details, then I see a list of blocking tasks with their current status
- [ ] AC3: Given I want to understand the critical path, when I click "Show Blockers", then I see a visual chain of dependencies leading to the blocked task
- [ ] AC4: Given a blocking task completes, when unblocked, then the previously blocked task automatically updates to "Pending" and becomes available
- [ ] AC5: Given multiple tasks are blocked by the same dependency, when displayed, then the blocking task is highlighted as high-impact

#### Blocker Visualization
```
Task: "Build login page UI"
Status: 🚫 Blocked

Blocked by:
┌─────────────────────────────────┐
│ 🔄 Create login API endpoints   │──► This task
│    Currently: 60% complete      │
│    Assigned: Claude #1          │
└─────────────────────────────────┘

Also blocking:
• Add password reset flow
• Implement remember me
```

#### Technical Notes
- **ACFS Integration:** Dependency graph from Beads; critical path analysis via `bv --robot-triage`
- **Dependencies:** E4-S1
- **UI Pattern:** Inline expansion or modal for blocker details

#### Definition of Done
- [ ] Blocked status clearly indicated
- [ ] Blocker list in task details
- [ ] Visual dependency chain
- [ ] Auto-update when unblocked
- [ ] High-impact blocker highlighting
- [ ] Unit tests for blocker detection

---

### E4-S4: Milestone Notifications

**Priority:** P1
**Points:** 5

#### User Story
As a user, I want to receive notifications when milestones complete so that I stay informed of significant progress without constantly monitoring.

#### Acceptance Criteria
- [ ] AC1: Given a component is complete, when it finishes, then I see a toast notification with the component name and completion message
- [ ] AC2: Given I'm not actively viewing the app, when a milestone completes, then I receive a browser notification (if permitted)
- [ ] AC3: Given multiple tasks complete rapidly, when notifications are generated, then they are batched to avoid overwhelming the user
- [ ] AC4: Given I want to review past notifications, when I click the notification bell, then I see a history of milestone completions
- [ ] AC5: Given I don't want notifications, when I access settings, then I can disable or customize notification frequency

#### Notification Types
| Event | Priority | Message Example |
|-------|----------|-----------------|
| Component complete | High | "Authentication is now complete! ✅" |
| Major task complete | Medium | "Login API is ready for testing" |
| All tasks complete | Critical | "Your app is ready! Time to test. 🎉" |
| Error/attention needed | Critical | "Build paused: Agent encountered an error" |

#### Technical Notes
- **ACFS Integration:** Milestone detection from Beads task completion events
- **Dependencies:** E4-S1, E4-S2
- **Implementation:** Web Notifications API with permission request

#### Definition of Done
- [ ] Toast notification component
- [ ] Browser notification integration
- [ ] Notification batching logic
- [ ] Notification history panel
- [ ] Settings for notification preferences
- [ ] Unit tests for notification triggers

---

### E4-S5: Manual Task Flagging

**Priority:** P2
**Points:** 3

#### User Story
As a user, I want to mark tasks as "needs review" so that I can flag areas requiring my attention or special consideration.

#### Acceptance Criteria
- [ ] AC1: Given I see a task, when I click the flag icon, then the task is marked as "Needs Review" with a visual indicator
- [ ] AC2: Given I flag a task, when I optionally add a note, then my note is saved with the flag
- [ ] AC3: Given tasks are flagged, when I filter by "Needs Review", then I see only flagged tasks
- [ ] AC4: Given I've reviewed a task, when I click "Clear Flag", then the flag is removed
- [ ] AC5: Given I flag a task, when an agent completes it, then I'm specifically notified that a flagged task needs my review

#### Flag States
| State | Icon | Meaning |
|-------|------|---------|
| Flagged | 🚩 | User wants to review this |
| Under review | 👁️ | User is currently reviewing |
| Approved | ✓ | User has reviewed and approved |

#### Technical Notes
- **ACFS Integration:** Flags stored as metadata in Beads tasks
- **Dependencies:** E4-S1
- **Consideration:** Flagged tasks might warrant agent pause pending review

#### Definition of Done
- [ ] Flag toggle on task items
- [ ] Note input when flagging
- [ ] Filter by flagged status
- [ ] Clear flag functionality
- [ ] Notification on flagged task completion
- [ ] Unit tests for flag operations

---

## Epic Summary

| Story | Priority | Points | Dependencies |
|-------|----------|--------|--------------|
| E4-S1 | P0 | 8 | E1-S4 |
| E4-S2 | P0 | 5 | E4-S1 |
| E4-S3 | P1 | 5 | E4-S1 |
| E4-S4 | P1 | 5 | E4-S1, E4-S2 |
| E4-S5 | P2 | 3 | E4-S1 |

**Total Points:** 26
**P0 Points:** 13
