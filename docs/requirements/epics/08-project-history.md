# Epic 8: Project History & Continuity

## Overview

**Goal:** Enable users to save their work, return to projects later, track changes over time, and share or export their project specifications.

**User Value:** Users can work incrementally without losing progress, understand how their project evolved, and maintain continuity across multiple sessions.

---

## Stories

### E8-S1: Save and Resume Projects

**Priority:** P0
**Points:** 8

#### User Story
As a user, I want to save my project and return to it later so that I can work incrementally and don't lose progress if I close my browser.

#### Acceptance Criteria
- [ ] AC1: Given I am working on a project, when I make changes, then progress is automatically saved (no manual save needed)
- [ ] AC2: Given I close my browser, when I return to the app, then I see my project list with last-modified timestamps
- [ ] AC3: Given I have multiple projects, when I view the dashboard, then I can see all projects with their status (building/paused/complete)
- [ ] AC4: Given I click on a project, when it loads, then I see the canvas exactly as I left it with all progress preserved
- [ ] AC5: Given I want to delete a project, when I click delete, then I see a confirmation and the project is removed

#### Project Dashboard
```
┌──────────────────────────────────────────────────────────┐
│  My Projects                              [+ New Project] │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  📦 TaskFlow                                    │    │
│  │  Full-stack task management app                 │    │
│  │  Status: 🟢 Deployed   Progress: 100%          │    │
│  │  Last edited: Today at 3:45 PM                  │    │
│  │  [Open] [View Live] [Settings]                  │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  📦 Budget Tracker                              │    │
│  │  Personal finance web app                       │    │
│  │  Status: 🔄 Building   Progress: 45%           │    │
│  │  Last edited: Yesterday at 10:30 AM             │    │
│  │  [Open] [Pause Build] [Settings]                │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  📦 Landing Page                                │    │
│  │  Marketing website                              │    │
│  │  Status: ⏸️ Paused    Progress: 20%            │    │
│  │  Last edited: 3 days ago                        │    │
│  │  [Open] [Resume Build] [Delete]                 │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

#### Technical Notes
- **ACFS Integration:** Project state saved to localStorage and/or backend database; git repo persists code
- **Dependencies:** None (core infrastructure)
- **Auto-save:** Debounced save on every significant state change

#### Definition of Done
- [ ] Auto-save on state changes
- [ ] Project dashboard with list view
- [ ] Project status indicators
- [ ] Click-to-open with full state restoration
- [ ] Delete with confirmation
- [ ] Unit tests for state persistence

---

### E8-S2: Project Change Timeline

**Priority:** P1
**Points:** 5

#### User Story
As a user, I want to see a timeline of all changes made to my project so that I can understand how it evolved and what was built when.

#### Acceptance Criteria
- [ ] AC1: Given I access project history, when I view it, then I see a chronological timeline of significant events
- [ ] AC2: Given a timeline entry exists, when displayed, then I see: timestamp, event type, description, and actor (agent or user)
- [ ] AC3: Given I want to find specific changes, when I search/filter the timeline, then I can narrow by date range, component, or agent
- [ ] AC4: Given an entry is about code changes, when I click it, then I see a summary of files affected
- [ ] AC5: Given the timeline is long, when scrolling, then items load progressively (infinite scroll)

#### Timeline Events
| Event Type | Icon | Example |
|------------|------|---------|
| Project created | 🎉 | "Project TaskFlow created" |
| Feature added | ✨ | "Authentication feature added" |
| Component complete | ✅ | "Dashboard component completed" |
| Bug fixed | 🐛 | "Fixed login button not working" |
| Deployed | 🚀 | "Deployed to production" |
| User change | 👤 | "You updated the project name" |

#### Timeline View
```
┌──────────────────────────────────────────────────────────┐
│  Project Timeline                    [Filter ▼] [Search] │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Today                                                   │
│  ├── 3:45 PM  🚀 Deployed to production                 │
│  │            by You                                     │
│  │                                                       │
│  ├── 3:30 PM  ✅ Testing complete                       │
│  │            23 tests passing                           │
│  │                                                       │
│  ├── 2:15 PM  ✨ Added user authentication              │
│  │            by Claude #1 • 5 files created            │
│  │                                                       │
│  Yesterday                                               │
│  ├── 4:30 PM  ✅ Dashboard component complete           │
│  │            by Codex #1 • 3 files created             │
│  │                                                       │
│  ├── 2:00 PM  🎉 Project created                        │
│  │            by You                                     │
│                                                          │
│  [Load more...]                                          │
└──────────────────────────────────────────────────────────┘
```

#### Technical Notes
- **ACFS Integration:** Events from Beads task completions, git commits, deployment records
- **Dependencies:** E8-S1
- **Storage:** Timeline entries stored with project metadata

#### Definition of Done
- [ ] Timeline view component
- [ ] Event type icons and styling
- [ ] Date grouping (Today, Yesterday, etc.)
- [ ] Filter and search functionality
- [ ] Infinite scroll loading
- [ ] Unit tests for timeline rendering

---

### E8-S3: Fork Previous Versions

**Priority:** P2
**Points:** 5

#### User Story
As a user, I want to fork a previous version of my project so that I can experiment with alternatives without losing my current progress.

#### Acceptance Criteria
- [ ] AC1: Given I view the timeline, when I see a past state I want to explore, then I can click "Fork from here"
- [ ] AC2: Given I click fork, when creating, then a new project is created based on that point in time
- [ ] AC3: Given I fork a project, when it's created, then it has a clear name indicating it's a fork (e.g., "TaskFlow (Fork)")
- [ ] AC4: Given I have forks, when viewing my projects, then I can see the fork relationship
- [ ] AC5: Given I decide the fork is better, when I want to replace the original, then I can "Promote" the fork

#### Fork Flow
```
┌──────────────────────────────────────────────────────┐
│  Fork Project                                        │
├──────────────────────────────────────────────────────┤
│                                                      │
│  Create a copy of TaskFlow from:                     │
│  Feb 18, 2026 at 4:30 PM                            │
│                                                      │
│  This was before:                                    │
│  • Added email notifications                         │
│  • Changed dashboard layout                          │
│                                                      │
│  New project name:                                   │
│  ┌────────────────────────────────────────────┐     │
│  │ TaskFlow (Alternative Dashboard)            │     │
│  └────────────────────────────────────────────┘     │
│                                                      │
│              [Cancel]    [Create Fork]               │
└──────────────────────────────────────────────────────┘
```

#### Technical Notes
- **ACFS Integration:** Git branch or complete project copy; point-in-time restoration
- **Dependencies:** E8-S1, E8-S2
- **Implementation:** Git checkout to point in time, then new project creation

#### Definition of Done
- [ ] Fork button on timeline entries
- [ ] Fork creation with name customization
- [ ] Fork relationship tracking
- [ ] Promote fork option
- [ ] Integration tests for fork creation

---

### E8-S4: Export Project Specifications

**Priority:** P2
**Points:** 3

#### User Story
As a user, I want to export my project specifications so that I can share them with stakeholders or use them outside of ACFS Canvas.

#### Acceptance Criteria
- [ ] AC1: Given I have a project, when I click "Export", then I see format options (Markdown, PDF, JSON)
- [ ] AC2: Given I select Markdown, when exported, then I receive a well-formatted document with all specifications
- [ ] AC3: Given I select PDF, when exported, then I receive a professional-looking document suitable for sharing
- [ ] AC4: Given I export, when the document is generated, then it includes: project summary, features, architecture diagram description, and current status
- [ ] AC5: Given I want to share, when I click "Copy Link", then I get a shareable read-only link to the specification

#### Export Content Structure
```markdown
# TaskFlow - Project Specification

## Overview
TaskFlow is a full-stack task management application for small teams...

## Target Users
- Primary: Small team members (5-20 people)
- Secondary: Team leads and managers

## Features
### Core Features
- User authentication with team invites
- Project creation and management
- Kanban board for task visualization
- Task assignment and due dates

### Additional Features
- Email notifications
- Calendar integration

## Technical Architecture
- Frontend: React with TypeScript
- Backend: Node.js API
- Database: PostgreSQL
- Deployment: Vercel + Railway

## Current Status
- Progress: 100% complete
- Last deployed: Feb 19, 2026
- Tests: 23/23 passing

---
Generated by ACFS Canvas on Feb 19, 2026
```

#### Technical Notes
- **ACFS Integration:** Specification from project state; architecture from canvas visualization
- **Dependencies:** E8-S1, E1-S4
- **PDF Generation:** Use headless browser or PDF library for rendering

#### Definition of Done
- [ ] Export button with format selection
- [ ] Markdown export generation
- [ ] PDF export generation
- [ ] Shareable link generation
- [ ] Professional formatting
- [ ] Unit tests for export generation

---

## Epic Summary

| Story | Priority | Points | Dependencies |
|-------|----------|--------|--------------|
| E8-S1 | P0 | 8 | None |
| E8-S2 | P1 | 5 | E8-S1 |
| E8-S3 | P2 | 5 | E8-S1, E8-S2 |
| E8-S4 | P2 | 3 | E8-S1, E1-S4 |

**Total Points:** 21
**P0 Points:** 8
