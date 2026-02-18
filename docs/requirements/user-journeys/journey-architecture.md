# User Journey: Architecture Phase

## Overview

**Duration:** 5-10 minutes
**Goal:** Visualize and optionally refine the project structure before building begins
**Entry Point:** User clicks "Start Building" from specification review
**Exit Point:** User clicks "Begin Build" to start agent work

---

## Journey Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Canvas    │────►│  Component  │────►│  Refine     │────►│   Begin     │
│   Init      │     │  Overview   │     │  Structure  │     │   Build     │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

---

## Step 1: Canvas Initialization

**Screen:** Loading state while canvas prepares

**User Actions:**
- Waits briefly while system analyzes specification
- Sees progress messages explaining what's happening

**System Behavior:**
1. Analyzes specification to identify components
2. Creates initial task breakdown (Beads)
3. Determines component relationships
4. Generates visual layout
5. Prepares canvas view

**Loading Messages (rotating):**
- "Analyzing your requirements..."
- "Designing the architecture..."
- "Planning the component structure..."
- "Preparing your project canvas..."

**Duration:** 3-8 seconds

---

## Step 2: Component Overview

**Screen:** Interactive Canvas with Components (E2-S1)

**User Actions:**
1. Views the visual representation of their project
2. Sees components laid out with connections
3. Reads component names and understands structure
4. Optionally hovers over components for details

**Canvas Display:**
```
┌──────────────────────────────────────────────────────────────────┐
│  TaskFlow - Architecture                    [Refine] [Begin Build]│
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│     Your project has been organized into 5 main components:      │
│                                                                  │
│          ┌──────────┐                                            │
│          │  Auth    │                                            │
│          │   🔐     │                                            │
│          └────┬─────┘                                            │
│               │                                                  │
│      ┌────────┼────────┐                                         │
│      │        │        │                                         │
│      ▼        ▼        ▼                                         │
│  ┌──────┐ ┌──────┐ ┌──────┐                                     │
│  │ UI   │ │ API  │ │  DB  │                                     │
│  │  🖥️  │ │  ⚙️  │ │  🗄️  │                                     │
│  └──────┘ └──────┘ └──────┘                                     │
│      │        │        │                                         │
│      └────────┼────────┘                                         │
│               │                                                  │
│               ▼                                                  │
│          ┌──────────┐                                            │
│          │Dashboard │                                            │
│          │   📊    │                                            │
│          └──────────┘                                            │
│                                                                  │
│  Components: Auth (login, register) • API (endpoints) •          │
│              UI (pages, components) • DB (tables) • Dashboard    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**Component Legend:**
| Component | Contents | Dependencies |
|-----------|----------|--------------|
| Auth | Login, register, session management | None |
| API | REST endpoints for all features | Auth |
| DB | Database tables and migrations | None |
| UI | React pages and components | Auth, API |
| Dashboard | Main app view with kanban | UI, API |

**System Behavior:**
- Displays components with clear visual hierarchy
- Shows dependency connections (lines)
- Animates smoothly on load
- Provides hover tooltips with component details

---

## Step 3: Refine Structure (Optional)

**Screen:** Architecture Refinement Panel

**User Actions:**
1. Clicks "Refine" if they want to adjust
2. Reviews AI suggestions for additional components
3. Adds or removes components as needed
4. Adjusts component groupings
5. Confirms changes

**Refinement Options:**
```
┌──────────────────────────────────────────────────────────┐
│  Refine Architecture                           [Done]    │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Current Components:                                     │
│  ├── ✓ Auth - Login, registration, sessions             │
│  ├── ✓ API - Backend endpoints                          │
│  ├── ✓ Database - Data storage                          │
│  ├── ✓ UI - Frontend pages                              │
│  └── ✓ Dashboard - Main application view                │
│                                                          │
│  Suggested Additions:                                    │
│  ├── ○ Notifications - Email alerts for tasks           │
│  │     [Add]  [Skip]                                    │
│  └── ○ Settings - User preferences page                 │
│        [Add]  [Skip]                                    │
│                                                          │
│  Or describe what you want:                              │
│  ┌────────────────────────────────────────────────┐     │
│  │ Add a feature for...                            │     │
│  └────────────────────────────────────────────────┘     │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

**System Behavior:**
- Suggests additional components based on specification
- Allows free-form component requests
- Updates canvas in real-time as changes are made
- Validates that changes maintain coherent architecture

---

## Step 4: Begin Build

**Screen:** Build Confirmation

**User Actions:**
1. Reviews final architecture summary
2. Sees agent assignment preview
3. Clicks "Begin Build" to start
4. Transitions to Build phase

**Confirmation Display:**
```
┌──────────────────────────────────────────────────────────┐
│  Ready to Build TaskFlow                                 │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  📦 5 components to build                                │
│  📋 23 tasks identified                                  │
│  ⏱️  Estimated build time: 2-4 hours                     │
│                                                          │
│  Agents will work on:                                    │
│  ├── 🧠 Claude Code - Complex logic, API design         │
│  ├── 💻 Codex - Code generation, tests                  │
│  └── 📚 Gemini - Documentation, validation              │
│                                                          │
│  You can:                                                │
│  • Watch progress on the canvas                          │
│  • Pause or intervene at any time                        │
│  • Preview your app as it's built                        │
│                                                          │
│            [Back to Refine]    [Begin Build →]           │
└──────────────────────────────────────────────────────────┘
```

**System Behavior:**
- Shows build summary with estimates
- Explains what will happen during build
- On "Begin Build": Spawns agents, creates tasks, starts work
- Transitions to Build phase (canvas with active agents)

---

## Guidance Throughout

**First-Time User Hints:**
- "Components are the building blocks of your app"
- "Lines show which parts depend on each other"
- "You can adjust this structure, or trust our suggestion"

**Contextual Help:**
- Hover tooltips explaining each component type
- "Why this structure?" link showing reasoning
- "Learn more" for architecture concepts

---

## Error Handling

| Scenario | Handling |
|----------|----------|
| Analysis fails | Retry with fallback generic structure |
| User requests invalid structure | Explain why and suggest alternatives |
| Component name conflict | Suggest unique name |
| Too many components | Warn about complexity, suggest consolidation |

---

## Success Criteria

| Metric | Target |
|--------|--------|
| Completion rate | >95% proceed to Build |
| Refinement rate | <20% make manual changes |
| Time in phase | <5 minutes average |
| Understanding | Users can explain their architecture |

---

## Related Stories

- E2-S1: Visual Project Canvas
- E2-S6: Dependency Visualization
- E4-S1: Task Breakdown View
