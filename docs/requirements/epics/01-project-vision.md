# Epic 1: Project Vision & Scoping

## Overview

**Goal:** Transform a vague idea into a clear, buildable project specification through guided natural language interaction.

**User Value:** Users can start with just an idea and end up with a comprehensive specification that AI agents can execute, without needing technical knowledge to define requirements.

---

## Stories

### E1-S1: Natural Language Project Description

**Priority:** P0
**Points:** 5

#### User Story
As a product manager, I want to describe my software idea in natural language so that the system understands what I want to build without requiring technical specifications.

#### Acceptance Criteria
- [ ] AC1: Given I am on the new project page, when I type a description of my idea (minimum 20 characters), then the "Continue" button becomes enabled
- [ ] AC2: Given I have entered a description, when I click Continue, then the system processes my input and moves to the clarification phase
- [ ] AC3: Given I am entering a description, when I type, then I see a character count and helpful prompts for what to include
- [ ] AC4: Given I want to provide more context, when I click "Add more details", then I can expand the input to include additional information like target users, key features, or examples

#### Technical Notes
- **ACFS Integration:** Initial prompt sent to Claude Code for understanding
- **Dependencies:** None (entry point)
- **UI Pattern:** Large text area with placeholder examples, similar to ChatGPT input

#### Wireframe Description
```
┌─────────────────────────────────────────────────────────┐
│  ACFS Canvas                              [User Avatar] │
├─────────────────────────────────────────────────────────┤
│                                                         │
│         What do you want to build?                      │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │                                                 │   │
│  │  Describe your idea here...                     │   │
│  │                                                 │   │
│  │  Example: "A task management app where teams    │   │
│  │  can create projects, assign tasks, and track   │   │
│  │  progress with a kanban board view"             │   │
│  │                                                 │   │
│  └─────────────────────────────────────────────────┘   │
│                                          142 characters │
│                                                         │
│  [+ Add more details]                                   │
│                                                         │
│                                    [Continue →]         │
└─────────────────────────────────────────────────────────┘
```

#### Definition of Done
- [ ] Text input component implemented with validation
- [ ] Character counting and minimum length enforcement
- [ ] Placeholder examples rotate or are contextual
- [ ] Loading state while processing
- [ ] Unit tests for input validation
- [ ] Accessibility: proper labels, focus management

---

### E1-S2: AI Clarifying Questions

**Priority:** P0
**Points:** 8

#### User Story
As a designer, I want to answer clarifying questions about my idea so that I can refine my requirements and ensure the system fully understands my vision.

#### Acceptance Criteria
- [ ] AC1: Given I have submitted my description, when the AI processes it, then I see 3-5 clarifying questions relevant to my specific idea
- [ ] AC2: Given I see a clarifying question, when I select a suggested answer or type my own, then my response is recorded and the next question appears
- [ ] AC3: Given a question has multiple choice options, when I select an option, then I can optionally add additional context
- [ ] AC4: Given I have answered all questions, when I click "Review Specification", then I proceed to the summary view
- [ ] AC5: Given I want to change a previous answer, when I click on that question, then I can edit my response

#### Technical Notes
- **ACFS Integration:** Claude Code generates questions based on initial description; follow-up prompts refine understanding
- **Dependencies:** E1-S1
- **AI Prompt Strategy:** Questions should cover: target users, core features, technical preferences (if any), deployment target, integrations needed

#### Sample Questions (Generated Dynamically)
1. "Who will use this application?" → [Internal team / Customers / Both / Other]
2. "What's the most important feature?" → [Free text with suggestions]
3. "Do you need user authentication?" → [Yes, email/password / Yes, social login / No / Not sure]
4. "Where should this be deployed?" → [Web only / Web + Mobile / Internal tool]
5. "Any specific integrations needed?" → [Multi-select: Stripe, Google, Slack, etc.]

#### Wireframe Description
```
┌─────────────────────────────────────────────────────────┐
│  ACFS Canvas                              [User Avatar] │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Let me understand your idea better...                  │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Q1: Who will use this application?              │   │
│  │                                                 │   │
│  │ [Internal team]  [Customers]  [Both]  [Other]  │   │
│  │                                                 │   │
│  │ + Add context (optional)                        │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Q2: What's the most important feature?          │   │
│  │                                                 │   │
│  │ ┌─────────────────────────────────────────┐    │   │
│  │ │ Type your answer...                      │    │   │
│  │ └─────────────────────────────────────────┘    │   │
│  │                                                 │   │
│  │ Suggestions: [Real-time updates] [Dashboard]   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  Question 2 of 4                    [Review Spec →]     │
└─────────────────────────────────────────────────────────┘
```

#### Definition of Done
- [ ] Dynamic question generation from AI response
- [ ] Multiple choice and free-text question types
- [ ] Progress indicator showing questions answered
- [ ] Edit capability for previous answers
- [ ] Smooth transitions between questions
- [ ] Unit tests for question flow logic
- [ ] Accessibility: keyboard navigation, screen reader support

---

### E1-S3: Project Type Selection

**Priority:** P0
**Points:** 3

#### User Story
As a user, I want to select or confirm the project type (web app, API, full-stack, etc.) so that the system knows the technical scope and can suggest appropriate architecture.

#### Acceptance Criteria
- [ ] AC1: Given the AI has analyzed my description, when I reach type selection, then I see a recommended type with explanation
- [ ] AC2: Given I see project type options, when I hover over each, then I see a description of what that type means
- [ ] AC3: Given I select a project type, when I confirm, then the system records this for architecture planning
- [ ] AC4: Given the AI recommendation doesn't match my intent, when I select a different type, then I can provide a reason (optional)

#### Project Type Options
| Type | Description | Example |
|------|-------------|---------|
| Web Application | Browser-based app with UI | Dashboard, SaaS product |
| REST API | Backend service with endpoints | Data service, integration layer |
| Full-Stack | Frontend + Backend + Database | Complete product |
| Static Site | Content-focused, minimal interactivity | Landing page, docs site |
| Internal Tool | Admin/ops focused functionality | Data viewer, config manager |

#### Technical Notes
- **ACFS Integration:** Type selection influences AGENTS.md generation and tech stack suggestions
- **Dependencies:** E1-S2
- **UI Pattern:** Card selection similar to ACFS OS selection page

#### Definition of Done
- [ ] Card-based selection UI with hover states
- [ ] AI recommendation highlighted with reasoning
- [ ] Tooltips/descriptions for each type
- [ ] Selection persisted to project state
- [ ] Unit tests for selection logic

---

### E1-S4: Auto-Generated Specification Review

**Priority:** P0
**Points:** 5

#### User Story
As a user, I want to view an auto-generated project summary so that I can confirm the system understood my requirements before building begins.

#### Acceptance Criteria
- [ ] AC1: Given I have completed the clarification phase, when I view the specification, then I see a structured summary including: project name (suggested), description, target users, key features, project type, and technical approach
- [ ] AC2: Given I see the specification, when I click on any section, then I can edit it inline
- [ ] AC3: Given I want to add something missed, when I click "Add Feature" or "Add Requirement", then I can append to the specification
- [ ] AC4: Given I am satisfied with the specification, when I click "Start Building", then the system proceeds to architecture/canvas phase
- [ ] AC5: Given I want to start over, when I click "Start Over", then I return to the description input with my original text preserved

#### Specification Structure
```yaml
project:
  name: "TaskFlow"  # AI-suggested, editable
  description: "A team task management application..."
  type: "Full-Stack Web Application"

users:
  primary: "Small team members (5-20 people)"
  secondary: "Team leads and managers"

features:
  core:
    - "User authentication with team invites"
    - "Project creation and management"
    - "Kanban board for task visualization"
    - "Task assignment and due dates"
  nice_to_have:
    - "Email notifications"
    - "Calendar integration"

technical:
  frontend: "React with TypeScript"
  backend: "Node.js API"
  database: "PostgreSQL"
  deployment: "Vercel + Railway"
```

#### Technical Notes
- **ACFS Integration:** This specification becomes the basis for AGENTS.md and Beads task creation
- **Dependencies:** E1-S2, E1-S3
- **Persistence:** Save to localStorage and optionally to user account

#### Definition of Done
- [ ] Specification rendered in readable, scannable format
- [ ] Inline editing for all fields
- [ ] Add/remove capability for list items
- [ ] "Start Building" triggers canvas initialization
- [ ] Specification exportable as markdown
- [ ] Unit tests for specification generation and editing

---

### E1-S5: Complexity and Scope Estimate

**Priority:** P1
**Points:** 5

#### User Story
As a user, I want to see an estimated complexity and scope so that I can set realistic expectations for the build process.

#### Acceptance Criteria
- [ ] AC1: Given I view the specification, when the estimate is calculated, then I see a complexity rating (Simple / Moderate / Complex)
- [ ] AC2: Given I see the complexity rating, when I hover or click for details, then I see factors contributing to the rating
- [ ] AC3: Given I see the estimate, when displayed, then I see estimated number of components/files and approximate build duration range
- [ ] AC4: Given the estimate seems wrong, when I click "This seems off", then I can provide feedback that improves future estimates

#### Complexity Factors
| Factor | Simple | Moderate | Complex |
|--------|--------|----------|---------|
| Features | 1-3 | 4-7 | 8+ |
| Authentication | None | Basic | OAuth/SSO |
| Database | None/Simple | Relational | Multi-table relations |
| Integrations | None | 1-2 | 3+ |
| Real-time | No | Notifications | Live sync |

#### Technical Notes
- **ACFS Integration:** Estimate based on similar past projects via CASS if available
- **Dependencies:** E1-S4
- **Note:** Estimates should be ranges, not precise times, to set appropriate expectations

#### Definition of Done
- [ ] Complexity calculation algorithm implemented
- [ ] Visual indicator (badge/meter) for complexity
- [ ] Expandable detail view showing factors
- [ ] Feedback mechanism for incorrect estimates
- [ ] Unit tests for complexity calculation

---

## Epic Summary

| Story | Priority | Points | Dependencies |
|-------|----------|--------|--------------|
| E1-S1 | P0 | 5 | None |
| E1-S2 | P0 | 8 | E1-S1 |
| E1-S3 | P0 | 3 | E1-S2 |
| E1-S4 | P0 | 5 | E1-S2, E1-S3 |
| E1-S5 | P1 | 5 | E1-S4 |

**Total Points:** 26
**P0 Points:** 21
