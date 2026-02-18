# Acceptance Criteria Traceability Matrix

## Overview

This matrix provides a quick reference to all acceptance criteria across epics, enabling tracking of requirement coverage during implementation and testing.

---

## Epic 1: Project Vision & Scoping

### E1-S1: Natural Language Project Description (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E1-S1-AC1 | Continue button enabled when minimum 20 chars entered | Unit |
| E1-S1-AC2 | System processes input and moves to clarification phase | Integration |
| E1-S1-AC3 | Character count and helpful prompts displayed while typing | Unit |
| E1-S1-AC4 | "Add more details" expands input for additional context | Unit |

### E1-S2: AI Clarifying Questions (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E1-S2-AC1 | 3-5 relevant clarifying questions displayed | Integration |
| E1-S2-AC2 | Response recorded, next question appears on selection | Unit |
| E1-S2-AC3 | Multiple choice allows optional additional context | Unit |
| E1-S2-AC4 | "Review Specification" proceeds to summary after all questions | Integration |
| E1-S2-AC5 | Previous answers editable on click | Unit |

### E1-S3: Project Type Selection (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E1-S3-AC1 | Recommended type shown with explanation | Integration |
| E1-S3-AC2 | Hover shows type description | Unit |
| E1-S3-AC3 | Selection recorded for architecture planning | Unit |
| E1-S3-AC4 | Different selection allows optional reason | Unit |

### E1-S4: Auto-Generated Specification Review (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E1-S4-AC1 | Structured summary displayed (name, description, users, features, type, tech) | Integration |
| E1-S4-AC2 | Any section editable inline | Unit |
| E1-S4-AC3 | "Add Feature/Requirement" appends to specification | Unit |
| E1-S4-AC4 | "Start Building" proceeds to architecture/canvas | Integration |
| E1-S4-AC5 | "Start Over" returns to description with text preserved | Unit |

### E1-S5: Complexity and Scope Estimate (P1)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E1-S5-AC1 | Complexity rating displayed (Simple/Moderate/Complex) | Unit |
| E1-S5-AC2 | Hover/click shows contributing factors | Unit |
| E1-S5-AC3 | Estimated components and duration range shown | Integration |
| E1-S5-AC4 | "This seems off" provides feedback mechanism | Unit |

---

## Epic 2: Interactive Canvas

### E2-S1: Visual Project Canvas (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E2-S1-AC1 | Visual representation with nodes for each major component | Integration |
| E2-S1-AC2 | Each node shows name, type icon, and status | Unit |
| E2-S1-AC3 | Auto-fits to show all components on load | Unit |
| E2-S1-AC4 | Complex projects organized in logical layout | Integration |
| E2-S1-AC5 | Performance remains 60fps with 20+ components | Performance |

### E2-S2: Component Detail Panel (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E2-S2-AC1 | Detail panel slides in on component click | Unit |
| E2-S2-AC2 | Panel shows name, description, status, tasks, agents | Unit |
| E2-S2-AC3 | Sub-components listed if present | Unit |
| E2-S2-AC4 | Live activity indicator for working agents | Integration |
| E2-S2-AC5 | Panel closes on click-outside or Escape | Unit |

### E2-S3: Real-Time Agent Updates (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E2-S3-AC1 | Component node updates within 1 second of status change | Integration |
| E2-S3-AC2 | Animation/highlight on file completion | Unit |
| E2-S3-AC3 | Activity indicators (pulsing) on active components | Unit |
| E2-S3-AC4 | Error state (red) with notification on build error | Integration |
| E2-S3-AC5 | Progress bar with percentage in header | Unit |

### E2-S4: Contextual Help Tooltips (P1)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E2-S4-AC1 | Hover on component type shows plain-English explanation | Unit |
| E2-S4-AC2 | Hover on technical terms shows definition | Unit |
| E2-S4-AC3 | "Learn more" opens expanded help | Unit |
| E2-S4-AC4 | Settings can reduce/disable tooltip frequency | Unit |

### E2-S5: Canvas Navigation (P1)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E2-S5-AC1 | Scroll/pinch zooms canvas (25%-200% range) | Unit |
| E2-S5-AC2 | Click and drag pans canvas | Unit |
| E2-S5-AC3 | "Fit All" resets view to show all components | Unit |
| E2-S5-AC4 | Double-click zooms to center component | Unit |
| E2-S5-AC5 | Touch gestures work on mobile | Unit |

### E2-S6: Dependency Visualization (P1)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E2-S6-AC1 | Connecting lines shown between dependent components | Unit |
| E2-S6-AC2 | Hover on line shows relationship tooltip | Unit |
| E2-S6-AC3 | Selection highlights dependencies/dependents | Unit |
| E2-S6-AC4 | Blocking dependencies visually emphasized | Unit |
| E2-S6-AC5 | Connections simplify at low zoom | Unit |

---

## Epic 3: Transparent Agent Orchestration

### E3-S1: Agent Status Dashboard (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E3-S1-AC1 | Card for each agent shows name, type, task, status | Unit |
| E3-S1-AC2 | Real-time indicator and task displayed when working | Integration |
| E3-S1-AC3 | All agents visible at a glance with type distinction | Unit |
| E3-S1-AC4 | Warning/error state shown with description | Unit |
| E3-S1-AC5 | Hover on type badge shows capability tooltip | Unit |

### E3-S2: Plain-English Activity Logs (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E3-S2-AC1 | Chronological list of plain language actions | Unit |
| E3-S2-AC2 | Entry shows timestamp, agent, description, component | Unit |
| E3-S2-AC3 | Technical actions translated to user-friendly descriptions | Integration |
| E3-S2-AC4 | Filter by agent, component, or action type | Unit |
| E3-S2-AC5 | Click entry shows expanded details | Unit |

### E3-S3: Pause/Resume Agent Work (P1)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E3-S3-AC1 | "Pause All" stops all agents | Integration |
| E3-S3-AC2 | Individual pause stops only that agent | Integration |
| E3-S3-AC3 | "Resume" continues from paused state | Integration |
| E3-S3-AC4 | Paused state shows pending resume task | Unit |
| E3-S3-AC5 | Mid-task pause completes interrupted task on resume | Integration |

### E3-S4: Agent-to-Agent Communication (P1)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E3-S4-AC1 | Messages between agents shown in chat format | Unit |
| E3-S4-AC2 | Message shows sender, recipient, subject, summary | Unit |
| E3-S4-AC3 | File reservations visible by agent | Integration |
| E3-S4-AC4 | Conflict warning highlighted | Integration |
| E3-S4-AC5 | Click message shows full content | Unit |

### E3-S5: Redirect Agent to Task (P2)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E3-S5-AC1 | "Change Task" shows available tasks | Unit |
| E3-S5-AC2 | Agent switches to new task on confirm | Integration |
| E3-S5-AC3 | Original task returns to queue | Integration |
| E3-S5-AC4 | Custom instruction input available | Unit |
| E3-S5-AC5 | Warning shown for potentially problematic redirects | Unit |

### E3-S6: Spawn Additional Agents (P2)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E3-S6-AC1 | "Add Agent" shows type options | Unit |
| E3-S6-AC2 | New agent session starts and appears in panel | Integration |
| E3-S6-AC3 | Spawned agent picks up available tasks | Integration |
| E3-S6-AC4 | Multiple same-type agents numbered | Unit |
| E3-S6-AC5 | "Remove" on idle agent terminates it | Integration |

---

## Epic 4: Task Management

### E4-S1: Task Breakdown View (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E4-S1-AC1 | Hierarchical list organized by component | Unit |
| E4-S1-AC2 | Task shows name, status, agent, complexity | Unit |
| E4-S1-AC3 | Dependencies visible on task view | Unit |
| E4-S1-AC4 | Click shows plain-English description | Unit |
| E4-S1-AC5 | Task groups collapsible by component | Unit |

### E4-S2: Progress Visualization (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E4-S2-AC1 | Overall progress bar with percentage in header | Unit |
| E4-S2-AC2 | Per-component progress percentage shown | Unit |
| E4-S2-AC3 | Real-time updates with smooth animation | Unit |
| E4-S2-AC4 | Hover shows completed/in-progress/blocked/pending counts | Unit |
| E4-S2-AC5 | Celebration animation at 100% | Unit |

### E4-S3: Blocked Task Visualization (P1)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E4-S3-AC1 | Blocked status with visual indication | Unit |
| E4-S3-AC2 | Blocking tasks listed with status | Unit |
| E4-S3-AC3 | "Show Blockers" shows visual dependency chain | Unit |
| E4-S3-AC4 | Auto-update to Pending when unblocked | Integration |
| E4-S3-AC5 | High-impact blockers highlighted | Unit |

### E4-S4: Milestone Notifications (P1)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E4-S4-AC1 | Toast notification on component completion | Unit |
| E4-S4-AC2 | Browser notification if permitted | Unit |
| E4-S4-AC3 | Rapid completions batched | Unit |
| E4-S4-AC4 | Notification history in bell menu | Unit |
| E4-S4-AC5 | Settings to disable/customize notifications | Unit |

### E4-S5: Manual Task Flagging (P2)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E4-S5-AC1 | Flag icon marks task as "Needs Review" | Unit |
| E4-S5-AC2 | Optional note saved with flag | Unit |
| E4-S5-AC3 | Filter by "Needs Review" shows flagged tasks | Unit |
| E4-S5-AC4 | "Clear Flag" removes flag | Unit |
| E4-S5-AC5 | Notification when flagged task completes | Unit |

---

## Epic 5: Code Visibility

### E5-S1: Code Visibility Toggle (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E5-S1-AC1 | "Code" toggle visible in header | Unit |
| E5-S1-AC2 | Toggle ON shows code panel with component files | Unit |
| E5-S1-AC3 | Toggle OFF hides code panel | Unit |
| E5-S1-AC4 | Preference persisted across sessions | Unit |
| E5-S1-AC5 | Prompt to select component when none selected | Unit |

### E5-S2: Code Change Highlighting (P1)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E5-S2-AC1 | Changed lines highlighted (green/red) | Unit |
| E5-S2-AC2 | Modified file shows change indicator | Unit |
| E5-S2-AC3 | Recent changes (5 min) visually distinguished | Unit |
| E5-S2-AC4 | "Show Changes Only" collapses unchanged code | Unit |
| E5-S2-AC5 | "Clear Highlights" removes highlighting | Unit |

### E5-S3: Plain-English Code Explanations (P1)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E5-S3-AC1 | Hover on function shows plain-English tooltip | Unit |
| E5-S3-AC2 | "Explain This" shows comprehensive explanation | Unit |
| E5-S3-AC3 | Explanations focus on "what" not "how" | Integration |
| E5-S3-AC4 | "Explain Mode" shows inline annotations | Unit |
| E5-S3-AC5 | "Simplify" provides even simpler explanation | Integration |

### E5-S4: Concept-Based Code Search (P2)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E5-S4-AC1 | Concept search finds relevant files/functions | Integration |
| E5-S4-AC2 | Results show file, function, relevance explanation | Unit |
| E5-S4-AC3 | Click navigates to code location | Unit |
| E5-S4-AC4 | Refinement suggestions for ambiguous queries | Integration |
| E5-S4-AC5 | Recent searches accessible | Unit |

### E5-S5: Natural Language Refactoring (P2)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E5-S5-AC1 | "Suggest Change" input available | Unit |
| E5-S5-AC2 | Request creates agent task | Integration |
| E5-S5-AC3 | Request status visible in activity log | Unit |
| E5-S5-AC4 | Review/approve flow for changes | Integration |
| E5-S5-AC5 | Clarification Q&A when needed | Integration |

---

## Epic 6: Testing & Validation

### E6-S1: Automated Test Results (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E6-S1-AC1 | Summary shows total, passed, failed, running | Unit |
| E6-S1-AC2 | Live indicator for currently executing test | Unit |
| E6-S1-AC3 | Failed test shows name, expected, actual, component | Unit |
| E6-S1-AC4 | Pass/fail badge on overall build status | Unit |
| E6-S1-AC5 | "Run Tests Again" executes fresh | Integration |

### E6-S2: Application Preview Sandbox (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E6-S2-AC1 | "Preview" opens live preview | Integration |
| E6-S2-AC2 | Preview functions like real app with mock data | Integration |
| E6-S2-AC3 | Reset, switch user, clear data controls | Unit |
| E6-S2-AC4 | Error shows user-friendly message with "Report Bug" | Unit |
| E6-S2-AC5 | Clearly sandboxed, no production impact | Integration |

### E6-S3: Natural Language Bug Reporting (P1)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E6-S3-AC1 | "Report Bug" shows description form | Unit |
| E6-S3-AC2 | Bug submitted creates agent fix task | Integration |
| E6-S3-AC3 | Context (page, actions) auto-captured | Integration |
| E6-S3-AC4 | Bug status visible in task list | Unit |
| E6-S3-AC5 | Verify fix workflow available | Integration |

### E6-S4: Test Coverage Display (P2)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E6-S4-AC1 | Overall coverage percentage displayed | Unit |
| E6-S4-AC2 | Per-component coverage breakdown | Unit |
| E6-S4-AC3 | Low coverage warning indicator | Unit |
| E6-S4-AC4 | "Improve Coverage" creates agent task | Integration |

### E6-S5: Responsive Testing (P2)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E6-S5-AC1 | Device size selector changes preview | Unit |
| E6-S5-AC2 | Mobile shows mobile layout | Unit |
| E6-S5-AC3 | "Side by Side" shows desktop and mobile | Unit |
| E6-S5-AC4 | Device size included in bug context | Unit |

---

## Epic 7: Deployment

### E7-S1: One-Click Staging (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E7-S1-AC1 | "Deploy to Staging" starts deployment | Integration |
| E7-S1-AC2 | Progress indicator shows current step | Unit |
| E7-S1-AC3 | Success provides staging URL | Integration |
| E7-S1-AC4 | Failure shows error with suggestions | Unit |
| E7-S1-AC5 | Redeploy updates staging environment | Integration |

### E7-S2: One-Click Production (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E7-S2-AC1 | Confirmation dialog warns about real users | Unit |
| E7-S2-AC2 | Progress indicators shown during deploy | Unit |
| E7-S2-AC3 | Success provides production URL with celebration | Integration |
| E7-S2-AC4 | First deploy prompts for env var setup if needed | Integration |
| E7-S2-AC5 | Redeploy shows changes since last deploy | Unit |

### E7-S3: Deployment Logs (P1)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E7-S3-AC1 | Real-time logs during deployment | Integration |
| E7-S3-AC2 | Past deployments listed with timestamps | Unit |
| E7-S3-AC3 | Failed deployment shows error with explanation | Unit |
| E7-S3-AC4 | "Copy Log" copies details to clipboard | Unit |
| E7-S3-AC5 | Step timing displayed | Unit |

### E7-S4: Custom Domain (P2)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E7-S4-AC1 | Domain settings show instructions | Unit |
| E7-S4-AC2 | DNS records displayed for configuration | Unit |
| E7-S4-AC3 | "Verify" checks DNS configuration | Integration |
| E7-S4-AC4 | Success enables custom domain with HTTPS | Integration |
| E7-S4-AC5 | Failure shows specific misconfiguration guidance | Unit |

### E7-S5: Deployment Rollback (P2)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E7-S5-AC1 | "Rollback to This" button on past deployments | Unit |
| E7-S5-AC2 | Confirmation warns about replacing current | Unit |
| E7-S5-AC3 | Rollback restores previous version | Integration |
| E7-S5-AC4 | Rollback appears as new entry in history | Unit |
| E7-S5-AC5 | Rollback completes quickly (no rebuild) | Performance |

---

## Epic 8: Project History

### E8-S1: Save and Resume (P0)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E8-S1-AC1 | Progress auto-saved on changes | Unit |
| E8-S1-AC2 | Project list shown with last-modified times | Unit |
| E8-S1-AC3 | All projects visible with status | Unit |
| E8-S1-AC4 | Click loads project with state preserved | Integration |
| E8-S1-AC5 | Delete with confirmation removes project | Unit |

### E8-S2: Project Change Timeline (P1)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E8-S2-AC1 | Chronological timeline of significant events | Unit |
| E8-S2-AC2 | Entry shows timestamp, type, description, actor | Unit |
| E8-S2-AC3 | Search/filter by date, component, agent | Unit |
| E8-S2-AC4 | Code change entries show files affected | Unit |
| E8-S2-AC5 | Infinite scroll for long timelines | Unit |

### E8-S3: Fork Previous Versions (P2)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E8-S3-AC1 | "Fork from here" on timeline entries | Unit |
| E8-S3-AC2 | Fork creates new project from that point | Integration |
| E8-S3-AC3 | Fork name indicates relationship | Unit |
| E8-S3-AC4 | Fork relationship visible in project list | Unit |
| E8-S3-AC5 | "Promote" replaces original with fork | Integration |

### E8-S4: Export Specifications (P2)
| AC ID | Acceptance Criteria | Test Type |
|-------|---------------------|-----------|
| E8-S4-AC1 | Export format options (Markdown, PDF, JSON) | Unit |
| E8-S4-AC2 | Markdown export well-formatted | Unit |
| E8-S4-AC3 | PDF export professional-looking | Unit |
| E8-S4-AC4 | Export includes summary, features, architecture, status | Unit |
| E8-S4-AC5 | Shareable read-only link generated | Integration |

---

## Summary Statistics

| Priority | Stories | Acceptance Criteria |
|----------|---------|---------------------|
| P0 | 17 | 73 |
| P1 | 13 | 54 |
| P2 | 10 | 43 |
| **Total** | **40** | **170** |
