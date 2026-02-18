# Epic 5: Code Visibility (Optional)

## Overview

**Goal:** Allow users to optionally view the generated code, providing transparency for those who want it while keeping the experience simple for those who don't.

**User Value:** Technical-curious users can peek under the hood to understand or verify what's being built, while non-technical users can ignore code entirely without losing functionality.

---

## Stories

### E5-S1: Code Visibility Toggle

**Priority:** P0
**Points:** 5

#### User Story
As a user, I want to toggle code visibility on/off so that I can choose whether to see the underlying code based on my comfort level and interest.

#### Acceptance Criteria
- [ ] AC1: Given I am viewing the canvas, when I look at the header, then I see a "Code" toggle button that indicates current state (on/off)
- [ ] AC2: Given code visibility is off (default), when I click the toggle, then a code panel appears showing files related to the selected component
- [ ] AC3: Given code visibility is on, when I click the toggle, then the code panel hides and more space is available for the canvas
- [ ] AC4: Given I toggle code visibility, when the state changes, then my preference is saved and persists across sessions
- [ ] AC5: Given code visibility is on, when no component is selected, then I see a prompt to select a component to view its code

#### Toggle States
| State | Icon | Panel |
|-------|------|-------|
| Off | `</>` outline | No code panel |
| On | `</>` filled | Code panel visible |

#### Technical Notes
- **ACFS Integration:** Code files retrieved from git working directory or agent session
- **Dependencies:** E2-S1 (canvas must exist)
- **Persistence:** localStorage for preference

#### Wireframe Description
```
Code OFF:
┌─────────────────────────────────────────────────────────┐
│  ACFS Canvas - TaskFlow           [</>] [?] [Avatar]   │
│                                    ↑ Code toggle        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│         [Full width canvas]                             │
│                                                         │
└─────────────────────────────────────────────────────────┘

Code ON:
┌─────────────────────────────────────────────────────────┐
│  ACFS Canvas - TaskFlow           [</>] [?] [Avatar]   │
├───────────────────────────┬─────────────────────────────┤
│                           │  📁 src/auth/              │
│    [Canvas - 60%]         │  ├── login.tsx             │
│                           │  ├── register.tsx          │
│                           │  └── session.ts            │
│                           │                             │
│                           │  // login.tsx               │
│                           │  export function Login() {  │
│                           │    ...                      │
│                           │  }                          │
└───────────────────────────┴─────────────────────────────┘
```

#### Definition of Done
- [ ] Toggle button in header
- [ ] Code panel slides in/out smoothly
- [ ] Preference persisted to localStorage
- [ ] Responsive layout adjustment
- [ ] Empty state when no component selected
- [ ] Unit tests for toggle behavior

---

### E5-S2: Code Change Highlighting

**Priority:** P1
**Points:** 5

#### User Story
As a user, I want to see code changes highlighted when they happen so that I can follow agent work and understand what's being modified.

#### Acceptance Criteria
- [ ] AC1: Given code visibility is on, when an agent modifies a file, then the changed lines are highlighted (e.g., green for additions, red for deletions)
- [ ] AC2: Given a file is modified, when viewing the file list, then the modified file shows a change indicator (dot or badge)
- [ ] AC3: Given changes have occurred, when I view a file, then recent changes (last 5 minutes) are visually distinguished from older code
- [ ] AC4: Given I want to see only changes, when I click "Show Changes Only", then unchanged code is collapsed/hidden
- [ ] AC5: Given changes highlight is distracting, when I click "Clear Highlights", then highlighting is removed until new changes occur

#### Highlight Colors
| Change Type | Color | Duration |
|-------------|-------|----------|
| Added line | Light green background | Fade after 5 min |
| Modified line | Light yellow background | Fade after 5 min |
| Deleted line | Light red strikethrough | Show then remove |

#### Technical Notes
- **ACFS Integration:** File change events from Agent Mail; diff calculation on update
- **Dependencies:** E5-S1
- **Implementation:** Monaco Editor or CodeMirror with custom highlighting

#### Definition of Done
- [ ] Line-level change highlighting
- [ ] File modification indicators
- [ ] Highlight fade-out over time
- [ ] "Show Changes Only" mode
- [ ] Clear highlights action
- [ ] Unit tests for diff highlighting

---

### E5-S3: Plain-English Code Explanations

**Priority:** P1
**Points:** 8

#### User Story
As a user, I want plain-English explanations of code sections so that I can understand what's happening without needing to read code.

#### Acceptance Criteria
- [ ] AC1: Given I view a code file, when I hover over a function or block, then I see a tooltip with a plain-English explanation
- [ ] AC2: Given I want more detail, when I click "Explain This", then I see a panel with a comprehensive explanation of what the code does
- [ ] AC3: Given the code is complex, when explanations are generated, then they focus on "what it does" not "how it works"
- [ ] AC4: Given a file is displayed, when I toggle "Explain Mode", then I see inline annotations explaining each major section
- [ ] AC5: Given I don't understand an explanation, when I click "Simplify", then I get an even simpler explanation

#### Explanation Examples
| Code | Explanation |
|------|-------------|
| `async function login(email, password)` | "This handles user login - it checks their email and password" |
| `const token = jwt.sign(user, secret)` | "Creates a secure pass that proves the user is logged in" |
| `await db.users.findOne({email})` | "Looks up the user's account by their email address" |
| `if (!user) throw new Error()` | "If no account is found, it stops and shows an error" |

#### Technical Notes
- **ACFS Integration:** Explanations generated by Claude on-demand; cached for performance
- **Dependencies:** E5-S1
- **Caching:** Cache explanations to avoid repeated AI calls for same code

#### Definition of Done
- [ ] Hover tooltips with basic explanations
- [ ] "Explain This" detailed explanation panel
- [ ] "Explain Mode" with inline annotations
- [ ] "Simplify" option for complex explanations
- [ ] Explanation caching
- [ ] Unit tests for explanation rendering

---

### E5-S4: Concept-Based Code Search

**Priority:** P2
**Points:** 5

#### User Story
As a user, I want to search the codebase by concept (not keyword) so that I can find relevant sections without knowing exact function names.

#### Acceptance Criteria
- [ ] AC1: Given code visibility is on, when I type a concept in search (e.g., "where users log in"), then I see relevant files/functions
- [ ] AC2: Given I search, when results appear, then they show file name, function/section name, and a relevance explanation
- [ ] AC3: Given I click a search result, when selected, then the code panel navigates to that location with the relevant code highlighted
- [ ] AC4: Given my search is ambiguous, when multiple interpretations exist, then I see suggestions to refine my search
- [ ] AC5: Given I search frequently, when I access search, then I see my recent searches for quick re-access

#### Search Examples
| User Query | Results |
|------------|---------|
| "where users sign up" | `src/auth/register.tsx` - Register function |
| "how data is saved" | `src/db/repository.ts` - save(), update() |
| "error handling" | Multiple files with try/catch blocks |
| "the main page" | `src/pages/index.tsx` - Home component |

#### Technical Notes
- **ACFS Integration:** Semantic search powered by Claude understanding of codebase; uses CASS patterns
- **Dependencies:** E5-S1
- **Implementation:** Embed code files, semantic search via AI

#### Definition of Done
- [ ] Natural language search input
- [ ] Semantic matching to code locations
- [ ] Result list with relevance explanations
- [ ] Click-to-navigate to code
- [ ] Recent searches history
- [ ] Unit tests for search functionality

---

### E5-S5: Natural Language Refactoring Requests

**Priority:** P2
**Points:** 8

#### User Story
As a user, I want to request code changes in natural language so that I can suggest improvements without writing code myself.

#### Acceptance Criteria
- [ ] AC1: Given I'm viewing code, when I click "Suggest Change", then I see an input for describing what I want changed
- [ ] AC2: Given I describe a change (e.g., "add email validation here"), when I submit, then an agent picks up the request and implements it
- [ ] AC3: Given I've requested a change, when the agent works on it, then I see the request in the activity log with status
- [ ] AC4: Given the change is complete, when I review it, then I can approve or request further modifications
- [ ] AC5: Given my request is ambiguous, when the agent needs clarification, then I receive a question before implementation proceeds

#### Request Flow
```
1. User: "Add password strength checking when users register"
2. System: "I'll add password validation. Should I require:
   a) Minimum 8 characters
   b) Letters + numbers
   c) Complex (letters, numbers, symbols)?"
3. User: Selects option b
4. Agent: Implements password validation
5. User: Reviews and approves
```

#### Technical Notes
- **ACFS Integration:** Request becomes a Beads task assigned to available agent
- **Dependencies:** E5-S1, E3-S1
- **Consideration:** Changes should be scoped to prevent large unintended modifications

#### Definition of Done
- [ ] "Suggest Change" UI with text input
- [ ] Request converted to agent task
- [ ] Progress tracking in activity log
- [ ] Review/approval flow
- [ ] Clarification Q&A when needed
- [ ] Integration tests with agent task flow

---

## Epic Summary

| Story | Priority | Points | Dependencies |
|-------|----------|--------|--------------|
| E5-S1 | P0 | 5 | E2-S1 |
| E5-S2 | P1 | 5 | E5-S1 |
| E5-S3 | P1 | 8 | E5-S1 |
| E5-S4 | P2 | 5 | E5-S1 |
| E5-S5 | P2 | 8 | E5-S1, E3-S1 |

**Total Points:** 31
**P0 Points:** 5
