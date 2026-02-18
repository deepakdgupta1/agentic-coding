# Epic 2: Interactive Canvas

## Overview

**Goal:** Provide a visual, interactive workspace where users can see and navigate their project structure, understand component relationships, and observe real-time build progress.

**User Value:** Users gain spatial understanding of their software architecture without needing to comprehend code structure, making the abstract tangible and navigable.

---

## Stories

### E2-S1: Visual Project Canvas

**Priority:** P0
**Points:** 13

#### User Story
As a user, I want to see my project as a visual canvas with connected components so that I understand the architecture without reading code or technical documentation.

#### Acceptance Criteria
- [ ] AC1: Given my project specification is complete, when I enter the canvas view, then I see a visual representation with nodes for each major component (frontend, backend, database, etc.)
- [ ] AC2: Given I see the canvas, when components are displayed, then each node shows its name, type icon, and current status (pending/building/complete)
- [ ] AC3: Given the canvas is displayed, when I first load it, then it auto-fits to show all components with appropriate zoom level
- [ ] AC4: Given I have a complex project, when there are many components, then they are organized in a logical layout (e.g., frontend left, backend center, database right)
- [ ] AC5: Given the canvas is interactive, when I interact with it, then performance remains smooth (60fps) even with 20+ components

#### Component Node Types
| Type | Icon | Color | Examples |
|------|------|-------|----------|
| Frontend | 🖥️ | Blue | React app, Pages, Components |
| Backend | ⚙️ | Green | API routes, Services, Controllers |
| Database | 🗄️ | Purple | Tables, Schemas, Migrations |
| Auth | 🔐 | Orange | Login, Session, Permissions |
| Integration | 🔌 | Cyan | External APIs, Webhooks |
| Config | ⚙️ | Gray | Environment, Settings |

#### Technical Notes
- **ACFS Integration:** Component structure derived from AI analysis of specification; maps to Beads task categories
- **Dependencies:** E1-S4 (specification must be complete)
- **UI Pattern:** Based on `flywheel-visualization.tsx` - SVG nodes with Framer Motion animations
- **Layout Algorithm:** Force-directed or hierarchical layout (evaluate dagre, elkjs, or custom)

#### Wireframe Description
```
┌─────────────────────────────────────────────────────────────────┐
│  ACFS Canvas - TaskFlow                    [Code] [?] [Avatar] │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────┐                                                     │
│ │ Sidebar │   ┌─────────────────────────────────────────────┐  │
│ │         │   │                                             │  │
│ │ Tasks   │   │    ┌──────┐         ┌──────┐               │  │
│ │ ──────  │   │    │ Auth │─────────│ API  │               │  │
│ │ □ Setup │   │    │  🔐  │         │  ⚙️   │               │  │
│ │ □ Auth  │   │    └──────┘         └──────┘               │  │
│ │ ■ API   │   │        │                │                   │  │
│ │ □ UI    │   │        │                │                   │  │
│ │         │   │        v                v                   │  │
│ │ Agents  │   │    ┌──────┐         ┌──────┐               │  │
│ │ ──────  │   │    │ UI   │         │  DB  │               │  │
│ │ 🤖 CC1  │   │    │  🖥️   │         │  🗄️   │               │  │
│ │ 🤖 CC2  │   │    └──────┘         └──────┘               │  │
│ │         │   │                                             │  │
│ └─────────┘   └─────────────────────────────────────────────┘  │
│                              [−] [○] [+]  Zoom: 100%            │
└─────────────────────────────────────────────────────────────────┘
```

#### Definition of Done
- [ ] SVG-based canvas with component nodes
- [ ] Automatic layout algorithm for positioning
- [ ] Status indicators on each node (color/icon)
- [ ] Smooth animations for state changes
- [ ] Auto-fit on initial load
- [ ] Performance testing with 20+ nodes
- [ ] Unit tests for layout calculations
- [ ] Accessibility: nodes focusable, status announced

---

### E2-S2: Component Detail Panel

**Priority:** P0
**Points:** 8

#### User Story
As a user, I want to click on any component to see its details and current status so that I can track progress and understand what each part does.

#### Acceptance Criteria
- [ ] AC1: Given I click on a component node, when the click is registered, then a detail panel slides in from the right
- [ ] AC2: Given the detail panel is open, when I view it, then I see: component name, description, status, associated tasks, and assigned agent(s)
- [ ] AC3: Given a component has sub-components, when I view details, then I see a list of files/modules within it
- [ ] AC4: Given an agent is working on this component, when I view details, then I see a live activity indicator with recent actions
- [ ] AC5: Given I want to close the panel, when I click outside or press Escape, then the panel closes smoothly

#### Detail Panel Sections
1. **Header:** Name, type icon, status badge
2. **Description:** AI-generated explanation of what this component does
3. **Progress:** Tasks completed / total for this component
4. **Agent Activity:** Which agent(s) are working, what they're doing
5. **Files:** List of files in this component (if code visibility enabled)
6. **Actions:** [Pause work] [Add note] [View code]

#### Technical Notes
- **ACFS Integration:** Component details pulled from Beads task data and Agent Mail status
- **Dependencies:** E2-S1
- **UI Pattern:** Slide-in panel similar to `HelpPanel.tsx` pattern

#### Definition of Done
- [ ] Slide-in panel with smooth animation
- [ ] All detail sections populated from state
- [ ] Real-time updates while panel is open
- [ ] Close on click-outside and Escape key
- [ ] Mobile: panel becomes bottom sheet
- [ ] Unit tests for panel content rendering

---

### E2-S3: Real-Time Agent Updates

**Priority:** P0
**Points:** 8

#### User Story
As a user, I want to see real-time updates as agents work so that I know things are progressing and can observe the build process.

#### Acceptance Criteria
- [ ] AC1: Given agents are working, when a task status changes, then the corresponding component node updates within 1 second
- [ ] AC2: Given an agent completes a file, when I observe the canvas, then I see a brief animation/highlight on the affected component
- [ ] AC3: Given agents are active, when I view the canvas, then I see activity indicators (pulsing, spinning) on components being worked on
- [ ] AC4: Given a build error occurs, when detected, then the affected component shows an error state (red) with notification
- [ ] AC5: Given I want to see overall progress, when I view the canvas header, then I see a progress bar with percentage complete

#### Update Types
| Event | Visual Feedback | Duration |
|-------|-----------------|----------|
| Task started | Pulse animation on node | 500ms |
| File created | Flash + increment counter | 300ms |
| Task completed | Check animation, color change | 800ms |
| Error occurred | Shake + red glow | 1000ms |
| Agent assigned | Agent avatar appears on node | 400ms |

#### Technical Notes
- **ACFS Integration:** WebSocket connection to NTM/Agent Mail for real-time events
- **Dependencies:** E2-S1, E3-S1
- **Performance:** Batch updates to prevent excessive re-renders

#### Definition of Done
- [ ] WebSocket connection established and maintained
- [ ] Event-to-animation mapping implemented
- [ ] Debounced updates for performance
- [ ] Progress bar in header updates in real-time
- [ ] Error states clearly visible
- [ ] Integration tests with mock WebSocket events

---

### E2-S4: Contextual Help Tooltips

**Priority:** P1
**Points:** 5

#### User Story
As a user, I want contextual help tooltips that explain technical concepts so that I can learn as I build without leaving the canvas.

#### Acceptance Criteria
- [ ] AC1: Given I hover over a component type icon, when tooltip triggers, then I see a plain-English explanation of what that component type means
- [ ] AC2: Given I hover over a technical term in the detail panel, when tooltip triggers, then I see a definition appropriate for non-developers
- [ ] AC3: Given I see a tooltip, when I want more info, then I can click "Learn more" to open expanded help
- [ ] AC4: Given tooltips are appearing too frequently, when I access settings, then I can reduce or disable tooltip frequency

#### Tooltip Content Examples
| Term | Explanation |
|------|-------------|
| API | "The communication layer - how your frontend talks to your backend" |
| Database | "Where your data lives - user info, content, settings" |
| Component | "A reusable piece of your user interface" |
| Migration | "A script that updates your database structure" |
| Endpoint | "A specific URL your app can send/receive data from" |

#### Technical Notes
- **Dependencies:** E2-S1
- **UI Pattern:** Floating tooltips with arrow pointing to trigger element
- **Content:** Stored in JSON/translations file for easy updates

#### Definition of Done
- [ ] Tooltip component with positioning logic
- [ ] Content file with 20+ technical terms explained
- [ ] "Learn more" expansion capability
- [ ] Setting to adjust tooltip frequency
- [ ] Tooltips don't block interactions
- [ ] Accessibility: tooltips accessible via keyboard

---

### E2-S5: Canvas Navigation (Pan/Zoom)

**Priority:** P1
**Points:** 5

#### User Story
As a user, I want to pan, zoom, and navigate the canvas so that I can focus on specific areas or see the full picture.

#### Acceptance Criteria
- [ ] AC1: Given I am viewing the canvas, when I scroll/pinch, then the canvas zooms in/out (25%-200% range)
- [ ] AC2: Given I am viewing the canvas, when I click and drag on empty space, then the canvas pans
- [ ] AC3: Given I have zoomed/panned, when I click "Fit All", then the canvas resets to show all components
- [ ] AC4: Given I want to focus on a component, when I double-click a node, then the canvas zooms to center that component
- [ ] AC5: Given I am on mobile, when I use touch gestures, then pinch-zoom and two-finger pan work smoothly

#### Zoom Controls
- Mouse wheel: Zoom in/out (with cursor as center)
- Pinch gesture: Zoom on mobile
- Zoom buttons: [−] [○] [+] in corner
- Fit All button: Reset view

#### Technical Notes
- **Dependencies:** E2-S1
- **Implementation:** CSS transform with smooth transitions, requestAnimationFrame for performance
- **Mobile:** @use-gesture/react for touch handling

#### Definition of Done
- [ ] Mouse wheel zoom implemented
- [ ] Click-drag pan implemented
- [ ] Touch gestures working on mobile
- [ ] Zoom buttons and fit-all button
- [ ] Zoom level indicator
- [ ] Smooth animations for all interactions
- [ ] Performance maintained during zoom/pan

---

### E2-S6: Dependency Visualization

**Priority:** P1
**Points:** 5

#### User Story
As a user, I want to see dependency lines between components so that I understand the build order and relationships.

#### Acceptance Criteria
- [ ] AC1: Given components have dependencies, when canvas renders, then I see connecting lines between related components
- [ ] AC2: Given a dependency exists, when I hover over a line, then I see a tooltip explaining the relationship
- [ ] AC3: Given I select a component, when highlighted, then its dependencies and dependents are also highlighted (different colors for upstream/downstream)
- [ ] AC4: Given a component is blocked by dependencies, when I view it, then the blocking dependencies are visually emphasized
- [ ] AC5: Given there are many connections, when viewed at low zoom, then connections simplify to prevent visual clutter

#### Connection Types
| Type | Line Style | Color | Meaning |
|------|------------|-------|---------|
| Depends on | Solid → | Gray | Must complete before |
| Provides data | Dashed → | Blue | Sends data to |
| Blocked by | Solid red → | Red | Cannot start until |
| Complete | Dotted ✓ | Green | Dependency satisfied |

#### Technical Notes
- **ACFS Integration:** Dependency graph from Beads task DAG
- **Dependencies:** E2-S1
- **UI Pattern:** SVG paths with quadratic bezier curves (from flywheel visualization)

#### Definition of Done
- [ ] SVG connection lines between nodes
- [ ] Different line styles for connection types
- [ ] Hover tooltips on connections
- [ ] Highlight connected nodes on selection
- [ ] Simplification at low zoom levels
- [ ] Unit tests for dependency line rendering

---

## Epic Summary

| Story | Priority | Points | Dependencies |
|-------|----------|--------|--------------|
| E2-S1 | P0 | 13 | E1-S4 |
| E2-S2 | P0 | 8 | E2-S1 |
| E2-S3 | P0 | 8 | E2-S1, E3-S1 |
| E2-S4 | P1 | 5 | E2-S1 |
| E2-S5 | P1 | 5 | E2-S1 |
| E2-S6 | P1 | 5 | E2-S1 |

**Total Points:** 44
**P0 Points:** 29
