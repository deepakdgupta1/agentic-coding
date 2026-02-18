# Epic 6: Testing & Validation

## Overview

**Goal:** Ensure users can verify their software works correctly before deployment through automated testing, live preview, and easy bug reporting.

**User Value:** Users gain confidence that their software is functional and can identify issues early, reducing deployment anxiety and post-launch problems.

---

## Stories

### E6-S1: Automated Test Results Display

**Priority:** P0
**Points:** 5

#### User Story
As a user, I want to see automated tests running and their results so that I know my software is working correctly without manually testing everything.

#### Acceptance Criteria
- [ ] AC1: Given tests exist, when I view the testing panel, then I see a summary: total tests, passed, failed, and running
- [ ] AC2: Given tests are running, when in progress, then I see a live indicator showing which test is currently executing
- [ ] AC3: Given a test fails, when displayed, then I see the test name, expected vs actual result in plain language, and affected component
- [ ] AC4: Given tests complete, when I view results, then I see a pass/fail badge on the overall build status
- [ ] AC5: Given I want to rerun tests, when I click "Run Tests Again", then all tests execute fresh

#### Test Result Display
```
┌──────────────────────────────────────────────────────────┐
│  Test Results                    [Run Tests] [Settings]  │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Summary: ✅ 18 passed  ❌ 2 failed  ⏳ 3 running        │
│                                                          │
│  ─────────────────────────────────────────────────────   │
│                                                          │
│  ❌ FAILED: User can log in with valid credentials       │
│     Expected: Redirect to dashboard                      │
│     Got: Stayed on login page                            │
│     Component: Authentication                            │
│     [View Details] [Ask Agent to Fix]                    │
│                                                          │
│  ❌ FAILED: Password reset sends email                   │
│     Expected: Email sent successfully                    │
│     Got: Email service error                             │
│     Component: Authentication                            │
│     [View Details] [Ask Agent to Fix]                    │
│                                                          │
│  ✅ PASSED: User can register new account                │
│  ✅ PASSED: Dashboard loads data correctly               │
│  ✅ PASSED: Settings can be updated                      │
│  ... 15 more passed                                      │
└──────────────────────────────────────────────────────────┘
```

#### Technical Notes
- **ACFS Integration:** Tests run via Bun/Jest; results parsed and displayed; UBS scans included
- **Dependencies:** E2-S3 (real-time updates)
- **Test Types:** Unit tests, integration tests, UBS quality checks

#### Definition of Done
- [ ] Test summary with counts
- [ ] Live test execution indicator
- [ ] Failed test details with plain-English explanation
- [ ] Rerun tests button
- [ ] Pass/fail badge on build status
- [ ] Unit tests for result rendering

---

### E6-S2: Application Preview Sandbox

**Priority:** P0
**Points:** 8

#### User Story
As a user, I want to preview my application in a sandbox so that I can see it working and interact with it before deploying.

#### Acceptance Criteria
- [ ] AC1: Given my app is buildable, when I click "Preview", then a live preview opens in a new tab or embedded frame
- [ ] AC2: Given the preview is open, when I interact with it, then it functions like the real application (with mock data if needed)
- [ ] AC3: Given I want to test different scenarios, when I use the preview, then I can reset state, switch users, or clear data
- [ ] AC4: Given the preview shows an error, when displayed, then I see a user-friendly error message with "Report Bug" option
- [ ] AC5: Given I make changes during preview, when data is entered, then it doesn't affect production (clearly sandboxed)

#### Preview Controls
| Control | Function |
|---------|----------|
| Reset | Clear all preview data and state |
| Switch User | Toggle between test user accounts |
| Slow Network | Simulate poor network conditions |
| Mobile View | Show mobile-responsive layout |
| Console | View technical logs (optional) |

#### Technical Notes
- **ACFS Integration:** Preview runs via `bun dev` or similar; sandboxed database
- **Dependencies:** E4-S2 (must have enough progress to preview)
- **Implementation:** Embedded iframe with sandbox attributes or new tab with preview URL

#### Wireframe Description
```
┌──────────────────────────────────────────────────────────┐
│  Preview - TaskFlow                    [Reset] [Close]   │
├──────────────────────────────────────────────────────────┤
│  Device: [Desktop ▼]  User: [Test User 1 ▼]  [⚡ Fast]  │
├──────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────┐   │
│  │                                                  │   │
│  │           [Your App Running Here]                │   │
│  │                                                  │   │
│  │    ┌─────────────────────────────────┐          │   │
│  │    │  Welcome to TaskFlow            │          │   │
│  │    │                                 │          │   │
│  │    │  Email: [_______________]       │          │   │
│  │    │  Password: [______________]     │          │   │
│  │    │                                 │          │   │
│  │    │  [Login]                        │          │   │
│  │    └─────────────────────────────────┘          │   │
│  │                                                  │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  ⚠️ This is a preview. Data is not saved.               │
└──────────────────────────────────────────────────────────┘
```

#### Definition of Done
- [ ] Preview launch button
- [ ] Embedded iframe or new tab preview
- [ ] Reset and state controls
- [ ] Mobile/desktop view toggle
- [ ] Clear sandbox indicator
- [ ] Error handling with bug report option
- [ ] Integration tests for preview functionality

---

### E6-S3: Natural Language Bug Reporting

**Priority:** P1
**Points:** 5

#### User Story
As a user, I want to report bugs by describing them in natural language so that agents can understand and fix issues without me writing technical bug reports.

#### Acceptance Criteria
- [ ] AC1: Given I find an issue, when I click "Report Bug", then I see a simple form to describe what went wrong
- [ ] AC2: Given I describe the bug, when I submit, then an agent analyzes the description and creates a fix task
- [ ] AC3: Given I'm in the preview, when I report a bug, then my current state/page is automatically captured as context
- [ ] AC4: Given I've reported a bug, when it's being fixed, then I see its status in the task list
- [ ] AC5: Given the bug is fixed, when I'm notified, then I can verify the fix in the preview

#### Bug Report Flow
```
1. User: "When I click the login button nothing happens"

2. System captures:
   - Current page: /login
   - Last actions: typed email, typed password, clicked login
   - Console errors: "TypeError: undefined is not a function"

3. Agent analyzes and creates task:
   "Fix login button click handler - undefined function error"

4. Agent fixes, user verifies in preview
```

#### Technical Notes
- **ACFS Integration:** Bug becomes Beads task; context from preview state
- **Dependencies:** E6-S2, E4-S1
- **Context Capture:** Screenshot capability, console logs, user action replay

#### Definition of Done
- [ ] Bug report modal with description input
- [ ] Automatic context capture
- [ ] Bug converted to agent task
- [ ] Status tracking in task list
- [ ] Verify fix workflow
- [ ] Unit tests for bug report submission

---

### E6-S4: Test Coverage Display

**Priority:** P2
**Points:** 3

#### User Story
As a user, I want to see test coverage metrics so that I understand how thoroughly my software has been tested.

#### Acceptance Criteria
- [ ] AC1: Given tests have run, when I view coverage, then I see an overall coverage percentage
- [ ] AC2: Given I want more detail, when I expand coverage view, then I see per-component coverage breakdown
- [ ] AC3: Given coverage is low for a component, when displayed, then I see a warning indicator
- [ ] AC4: Given I want better coverage, when I click "Improve Coverage", then an agent generates additional tests

#### Coverage Display
```
Overall Coverage: 78%  ████████░░

Components:
├── Authentication: 92% ██████████ ✓
├── Dashboard:      85% █████████░
├── Settings:       45% █████░░░░░ ⚠️ Low
└── API:            89% █████████░
```

#### Technical Notes
- **ACFS Integration:** Coverage from Jest/Vitest coverage reports
- **Dependencies:** E6-S1
- **Note:** Coverage is a proxy for confidence, not a guarantee

#### Definition of Done
- [ ] Overall coverage percentage display
- [ ] Per-component breakdown
- [ ] Low coverage warnings
- [ ] "Improve Coverage" agent task option
- [ ] Unit tests for coverage parsing

---

### E6-S5: Responsive Testing

**Priority:** P2
**Points:** 5

#### User Story
As a user, I want to test my app on different device sizes so that I can verify it works well on mobile and desktop.

#### Acceptance Criteria
- [ ] AC1: Given I'm in preview, when I select a device size, then the preview resizes to that dimension
- [ ] AC2: Given I select "Mobile", when previewing, then I see the mobile layout (if responsive design exists)
- [ ] AC3: Given I want to compare, when I click "Side by Side", then I see desktop and mobile previews together
- [ ] AC4: Given I notice a responsive issue, when I report it, then the device size is included in the bug context

#### Device Presets
| Device | Dimensions |
|--------|------------|
| Desktop | 1920x1080 |
| Laptop | 1366x768 |
| Tablet | 768x1024 |
| Mobile | 375x812 |

#### Technical Notes
- **ACFS Integration:** Preview container resized; responsive CSS applied
- **Dependencies:** E6-S2
- **Implementation:** CSS resize or iframe dimension adjustment

#### Definition of Done
- [ ] Device size selector
- [ ] Preview resize with smooth transition
- [ ] Side-by-side comparison view
- [ ] Device size included in bug reports
- [ ] Common device presets
- [ ] Unit tests for resize functionality

---

## Epic Summary

| Story | Priority | Points | Dependencies |
|-------|----------|--------|--------------|
| E6-S1 | P0 | 5 | E2-S3 |
| E6-S2 | P0 | 8 | E4-S2 |
| E6-S3 | P1 | 5 | E6-S2, E4-S1 |
| E6-S4 | P2 | 3 | E6-S1 |
| E6-S5 | P2 | 5 | E6-S2 |

**Total Points:** 26
**P0 Points:** 13
