# ACFS Canvas - MVP Requirements Specification

## Product Overview

**ACFS Canvas** is a self-guided, GUI-based software building experience that enables technical non-developers (product managers, designers, and other tech-savvy professionals) to build complete software applications through an interactive visual interface with transparent multi-agent AI orchestration.

### Target Users

| Persona | Description | Key Needs |
|---------|-------------|-----------|
| **Product Manager** | Understands product requirements, not coding | Translate ideas into working software without writing code |
| **Designer** | Creates UI/UX, wants to see designs come to life | Build functional prototypes from design concepts |
| **Technical Founder** | Has vision, limited engineering resources | Rapidly prototype and validate ideas |
| **Ops/DevOps** | Understands infrastructure, less app development | Build internal tools and automation |

### Core Value Proposition

> "Describe what you want to build, watch AI agents build it transparently, deploy with one click."

---

## Implementation Progress

### ✅ Epic 1: Project Vision & Scoping — COMPLETE (4/4 P0 stories)

All four P0 stories for the Project Vision wizard flow are implemented with full UI, animations, localStorage persistence, and mock AI responses.

| Story | Status | What Was Built |
|-------|--------|----------------|
| E1-S1 | ✅ Done | Natural language description input with char count, "Add more details" expansion, validation |
| E1-S2 | ✅ Done | Dynamic clarifying questions (single/multi select, free text), progress bar, answer history, suggestion chips |
| E1-S3 | ✅ Done | Project type card grid with AI-recommended type, override reason, staggered animations |
| E1-S4 | ✅ Done | Structured spec review with inline editing, add/remove features, Copy as Markdown, Start Over |
| E1-S5 | ⬜ Not started | Complexity and scope estimate (P1 — deferred) |

### ⬜ Remaining Epics — NOT STARTED

| Epic | P0 Stories | P1 Stories | P2 Stories | Status |
|------|-----------|-----------|-----------|--------|
| 2. Interactive Canvas | 3 | 3 | 0 | ⬜ Not started |
| 3. Agent Orchestration | 2 | 2 | 2 | ⬜ Not started |
| 4. Task Management | 2 | 2 | 1 | ⬜ Not started |
| 5. Code Visibility | 1 | 2 | 2 | ⬜ Not started |
| 6. Testing & Validation | 2 | 1 | 2 | ⬜ Not started |
| 7. Deployment | 2 | 1 | 2 | ⬜ Not started |
| 8. Project History | 1 | 1 | 2 | ⬜ Not started |

**Overall progress: 4/17 P0 stories complete (24%)**

---

## Codebase Reference (for continuing agents)

### What Exists Today

All Canvas code lives inside the existing `apps/web/` Next.js 16 App Router application. No new packages or top-level directories were created.

#### Files Created

```
apps/web/
├── app/canvas/
│   ├── page.tsx                          # Server page → renders CanvasNewProject (creates UUID, redirects)
│   └── [projectId]/
│       └── page.tsx                      # Server page → renders CanvasWizard with projectId
│
├── components/canvas/
│   ├── canvas-new-project.tsx            # Client: generates project ID + router.replace
│   ├── canvas-wizard.tsx                 # Client: main orchestrator (step nav, mock AI calls, AnimatePresence)
│   └── steps/
│       ├── description-step.tsx          # E1-S1: textarea, char count, expandable details
│       ├── questions-step.tsx            # E1-S2: dynamic questions, single/multi/freetext, progress
│       ├── type-step.tsx                 # E1-S3: card grid, recommended badge, override reason
│       └── review-step.tsx              # E1-S4: inline-editable spec, add/remove features, copy MD
│
└── lib/canvas/
    ├── index.ts                          # Barrel re-exports
    ├── types.ts                          # CanvasProject, CanvasSpecification, PROJECT_TYPES, etc.
    ├── storage.ts                        # localStorage persistence (getProject, upsertProject, createProject, resetToStep)
    ├── mock-ai.ts                        # Deterministic mock AI (mockGenerateQuestions, mockRecommendType, mockGenerateSpec)
    └── use-canvas-project.ts             # TanStack Query hook (useCanvasProject → { project, isLoading, updateProject })
```

#### Key Files NOT Created by Canvas (existing, but important)

| File | Relevance |
|------|-----------|
| `components/ui/button.tsx` | Button with `loading`, `loadingText`, `variant="gradient"` — used by all steps |
| `components/ui/card.tsx` | Card/CardHeader/CardContent — available but steps use custom card-like sections |
| `components/motion/index.tsx` | `fadeUp`, `fadeScale`, `springs`, `staggerContainer`, `AnimatePresence` — used everywhere |
| `components/motion/motion-provider.tsx` | LazyMotion + MotionConfig wrapper (already in root layout) |
| `lib/utils.ts` | `cn()`, `safeGetJSON`, `safeSetJSON`, `safeRemoveItem` — used by storage layer |
| `app/globals.css` | oklch design tokens, Terminal Noir theme, fluid typography |

### Architecture Decisions Made

1. **Routing:** `/canvas` creates a new project (UUID) and redirects to `/canvas/[projectId]`. All wizard logic lives in the `[projectId]` route. This means "resume" is automatic — visiting `/canvas/<id>` loads from localStorage.

2. **State management:** TanStack Query (`useQuery` with `staleTime: Infinity`) as in-memory state, backed by localStorage. Updates use `queryClient.setQueryData` for instant UI + `upsertProject()` for persistence. No extra state libraries needed.

3. **Mock AI:** All AI responses are deterministic keyword-based mocks (`lib/canvas/mock-ai.ts`) with artificial delays (600–1500ms). These will be replaced with real API calls when a backend exists. The mock functions return the same types the real API will, so swap-in is straightforward.

4. **Animations:** Uses `m` components (not `motion`) from framer-motion's LazyMotion mode. All variants come from `@/components/motion`. Step transitions use `<AnimatePresence mode="wait">`.

5. **Schema versioning:** `CanvasProject` has `version: 1` to allow future migrations.

6. **"Start Building" button:** Currently a no-op placeholder. This is the seam where Epic 2 (Interactive Canvas) connects. When implemented, it should transition the project to a "building" state and render the canvas visualization.

### Conventions to Follow

- **"use client"** on all interactive components; server components for pages only
- **`m.div`** not `motion.div` (LazyMotion strict mode)
- **Import paths:** `@/components/...`, `@/lib/...` (no `src/` directory)
- **Icons:** lucide-react only
- **CSS:** Tailwind utility classes with oklch design tokens from globals.css
- **Fonts:** `font-mono` = JetBrains Mono (headings), `font-sans` = Instrument Sans (body)
- **Button variants:** `default`, `ghost`, `secondary`, `gradient` (for primary CTAs)
- **Build verification:** Always run `bun run type-check && bun run lint` in `apps/web/`

### localStorage Keys

| Key Pattern | Purpose |
|-------------|---------|
| `acfs-canvas:project:<uuid>` | Full `CanvasProject` JSON blob |

No project index exists yet. When implementing E8-S1 (project dashboard/listing), add an `acfs-canvas:projects-index` key that stores an array of `{ id, name, updatedAt }`.

---

## Next Steps (Prioritized)

### Immediate: Epic 2 — Interactive Canvas (P0 stories)

This is the next epic to implement. It depends on E1-S4 being complete (✅).

| Story | Points | What to Build |
|-------|--------|---------------|
| **E2-S1: Visual Project Canvas** | 13 | SVG canvas with component nodes (Frontend, Backend, DB, Auth, etc.), auto-layout, status indicators. Base on `flywheel-visualization.tsx` patterns. Evaluate dagre/elkjs for layout. |
| **E2-S2: Component Detail Panel** | 8 | Slide-in panel on node click showing description, tasks, agent activity, files. Close on Escape/click-outside. |
| **E2-S3: Real-Time Agent Updates** | 8 | WebSocket event → node animation mapping (pulse on start, check on complete, red shake on error). Progress bar in header. Mock with simulated events for now. |

**Implementation approach for E2-S1:**
- Create `components/canvas/project-canvas.tsx` — the SVG-based visualization
- Derive component nodes from `CanvasSpecification` (project type → default component set)
- Reuse SVG patterns from `flywheel-visualization.tsx` (circle positioning, curved paths, gradient colors)
- Wire "Start Building" in `canvas-wizard.tsx` to transition to the canvas view (new step or new route)

### After That: Epics 3 + 4 in Parallel

- **E3-S1 (Agent Status Dashboard)** and **E3-S2 (Activity Logs)** — agent panel sidebar with mock agents
- **E4-S1 (Task Breakdown)** and **E4-S2 (Progress Visualization)** — task list from Beads-like data + progress bar

These are the remaining P0 stories that complete the core build experience.

### Later: Remaining P0 Stories

| Story | Epic | Points | Dependencies |
|-------|------|--------|--------------|
| E5-S1: Code Visibility Toggle | 5 | 5 | E2-S1 |
| E6-S1: Automated Test Results | 6 | 5 | E2-S3 |
| E6-S2: Application Preview Sandbox | 6 | 8 | E4-S2 |
| E7-S1: One-Click Staging | 7 | 8 | E6-S1, E6-S2 |
| E7-S2: One-Click Production | 7 | 8 | E7-S1 |
| E8-S1: Save and Resume | 8 | 8 | None |

### Deferred: P1 Stories

Only after all P0 stories are complete. See individual epic docs for details.

---

## Document Navigation

### Epics (Feature Areas)

| Epic | Document | Priority Stories |
|------|----------|------------------|
| 1. Project Vision & Scoping | [01-project-vision.md](epics/01-project-vision.md) | 4 P0, 1 P1 |
| 2. Interactive Canvas | [02-interactive-canvas.md](epics/02-interactive-canvas.md) | 3 P0, 3 P1 |
| 3. Agent Orchestration | [03-agent-orchestration.md](epics/03-agent-orchestration.md) | 2 P0, 2 P1, 2 P2 |
| 4. Task Management | [04-task-management.md](epics/04-task-management.md) | 2 P0, 2 P1, 1 P2 |
| 5. Code Visibility | [05-code-visibility.md](epics/05-code-visibility.md) | 1 P0, 2 P1, 2 P2 |
| 6. Testing & Validation | [06-testing-validation.md](epics/06-testing-validation.md) | 2 P0, 1 P1, 2 P2 |
| 7. Deployment | [07-deployment.md](epics/07-deployment.md) | 2 P0, 1 P1, 2 P2 |
| 8. Project History | [08-project-history.md](epics/08-project-history.md) | 1 P0, 1 P1, 2 P2 |

**Total:** 8 Epics, 40 User Stories (17 P0, 13 P1, 10 P2)

### User Journeys

| Journey | Document | Duration |
|---------|----------|----------|
| Ideation | [journey-ideation.md](user-journeys/journey-ideation.md) | 5-15 min |
| Architecture | [journey-architecture.md](user-journeys/journey-architecture.md) | 5-10 min |
| Build | [journey-build.md](user-journeys/journey-build.md) | 30 min - 4 hr |
| Review | [journey-review.md](user-journeys/journey-review.md) | 15-30 min |
| Deploy | [journey-deploy.md](user-journeys/journey-deploy.md) | 5-10 min |

### Supporting Documents

| Document | Purpose |
|----------|---------|
| [ac-matrix.md](acceptance-criteria/ac-matrix.md) | Full acceptance criteria traceability |
| [acfs-integration.md](architecture/acfs-integration.md) | ACFS component integration specification |
| [success-metrics.md](metrics/success-metrics.md) | KPIs and measurement framework |

---

## MVP Scope Summary

### In Scope (P0 Stories)

- Natural language project description and AI clarification
- Interactive canvas visualization of project structure
- Real-time agent status and activity display
- Task breakdown and progress tracking
- Optional code visibility toggle
- Sandbox preview of built application
- One-click staging and production deployment
- Project save and resume

### Out of Scope (Post-MVP)

- Custom domain configuration
- Version rollback
- Multi-user collaboration
- Template marketplace
- Advanced analytics dashboard
- Mobile-native builds

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Project Completion Rate** | >70% | % of started projects reaching deployment |
| **Time to First Deploy** | <2 hours | Median time for simple web apps |
| **User Satisfaction (NPS)** | >50 | Post-completion survey score |
| **User Intervention Rate** | <20% | % of builds requiring manual intervention |

See [success-metrics.md](metrics/success-metrics.md) for detailed measurement framework.

---

## Technical Context

### ACFS Components Used

| Component | Role in Canvas |
|-----------|----------------|
| **NTM** | Spawn and manage AI agent sessions |
| **Agent Mail** | Agent coordination, file reservations, messaging |
| **Beads** | Task DAG creation and progress tracking |
| **CASS** | Session history for learning and continuity |
| **UBS** | Code quality scanning before deployment |

### Technology Stack

- **Frontend:** Next.js 16 App Router, React 19, TanStack Query
- **Visualization:** SVG + Framer Motion (LazyMotion with `m` components, based on flywheel component)
- **Real-time:** WebSocket for agent status updates (planned, not yet implemented)
- **State:** TanStack Query + localStorage persistence (implemented)
- **Styling:** Tailwind CSS 4 with oklch design tokens (Terminal Noir theme)
- **Forms:** Native controlled inputs (TanStack React Form available but not used yet)
- **Icons:** lucide-react
- **Build:** Bun (package manager + bundler)

See [acfs-integration.md](architecture/acfs-integration.md) for detailed integration specification.

---

## Story Card Format

Each epic document uses this standardized format:

```markdown
## [E#-S#]: [Story Title]

**Priority:** P0/P1/P2
**Points:** [1-13]

### User Story
As a [persona], I want to [action] so that [benefit].

### Acceptance Criteria
- [ ] AC1: Given [context], when [action], then [result]
- [ ] AC2: ...

### Technical Notes
- ACFS Integration: [Component]
- Dependencies: [Story IDs]
- Open Questions: [List]

### Definition of Done
- [ ] Implementation complete
- [ ] Tests passing
- [ ] Accessibility verified
- [ ] Documentation updated
```

---

## Document Maintenance

| Activity | Frequency | Owner |
|----------|-----------|-------|
| Story grooming | Weekly | Product |
| Epic review | Bi-weekly | Product + Engineering |
| User validation | Monthly | Product + UX |
| Metrics review | Monthly | Product + Data |
