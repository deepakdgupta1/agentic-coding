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

- **Frontend:** Next.js 16 App Router, React, TanStack Query
- **Visualization:** SVG + Framer Motion (based on flywheel component)
- **Real-time:** WebSocket for agent status updates
- **State:** TanStack Query + localStorage persistence

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
