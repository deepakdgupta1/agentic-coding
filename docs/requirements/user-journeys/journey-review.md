# User Journey: Review Phase

## Overview

**Duration:** 15-30 minutes
**Goal:** Verify the built software works correctly and fix any issues
**Entry Point:** Build complete, user clicks "Preview & Test"
**Exit Point:** User satisfied with quality, proceeds to Deployment

---

## Journey Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Preview   │────►│    Test     │────►│  Fix Bugs   │────►│   Ready     │
│    App      │     │  Results    │     │ (if any)    │     │ to Deploy   │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

---

## Step 1: Preview Application

**Screen:** Application Preview Sandbox (E6-S2)

**User Actions:**
1. Views their application running in a preview frame
2. Interacts with features (login, create tasks, etc.)
3. Tests different user flows
4. Notes any issues encountered

**Preview Interface:**
```
┌──────────────────────────────────────────────────────────────────┐
│  Preview - TaskFlow                Device: [Desktop ▼]  [Reset]  │
├──────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                                                          │   │
│  │   ╔══════════════════════════════════════════════════╗  │   │
│  │   ║                   TaskFlow                        ║  │   │
│  │   ║                                                   ║  │   │
│  │   ║   Welcome back, Test User!                       ║  │   │
│  │   ║                                                   ║  │   │
│  │   ║   ┌─────────────────────────────────────────┐   ║  │   │
│  │   ║   │  To Do    │  In Progress  │  Done       │   ║  │   │
│  │   ║   │───────────│───────────────│─────────────│   ║  │   │
│  │   ║   │ ☐ Task 1  │ ☐ Task 3     │ ☑ Task 5   │   ║  │   │
│  │   ║   │ ☐ Task 2  │ ☐ Task 4     │ ☑ Task 6   │   ║  │   │
│  │   ║   │           │               │             │   ║  │   │
│  │   ║   │ [+ Add]   │               │             │   ║  │   │
│  │   ║   └─────────────────────────────────────────┘   ║  │   │
│  │   ║                                                   ║  │   │
│  │   ╚══════════════════════════════════════════════════╝  │   │
│  │                                                          │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ⚠️ Preview mode - data is not saved                           │
│                                                                  │
│  [Report Bug]  [Mobile View]  [Run Tests]  [Proceed to Deploy →]│
└──────────────────────────────────────────────────────────────────┘
```

**Preview Controls:**
| Control | Function |
|---------|----------|
| Device selector | Switch between Desktop/Tablet/Mobile views |
| Reset | Clear all preview data and start fresh |
| Mobile View | Quick switch to mobile dimensions |
| Switch User | Test with different user accounts |

**System Behavior:**
- Runs built application in sandboxed environment
- Pre-populated with test data
- Network requests work against test backend
- State resets don't affect production

---

## Step 2: Review Test Results

**Screen:** Automated Test Results (E6-S1)

**User Actions:**
1. Views summary of automated tests
2. Reviews any failing tests
3. Understands what each test checked
4. Decides if failures need fixing

**Test Results Display:**
```
┌──────────────────────────────────────────────────────────────────┐
│  Test Results                                                    │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Summary: ✅ 21 passed   ❌ 2 failed   ⏭️ 0 skipped             │
│                                                                  │
│  Overall: ████████████████████░░░░  91% passing                 │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│  Failed Tests:                                                   │
│                                                                  │
│  ❌ User can drag tasks between columns                         │
│     What it checks: Kanban drag-and-drop functionality          │
│     What happened: Task didn't move to new column               │
│     Component: Dashboard                                         │
│     [View Details] [Ask Agent to Fix]                           │
│                                                                  │
│  ❌ Email notification sends on assignment                       │
│     What it checks: Email triggers when task is assigned        │
│     What happened: Email service returned error                  │
│     Component: Notifications                                     │
│     [View Details] [Ask Agent to Fix]                           │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│  Passed Tests: ✅ User can create new project                   │
│                ✅ User can add task to project                   │
│                ✅ User can assign task to team member            │
│                ... and 18 more                                   │
│                                                                  │
│  [Run Tests Again]  [Ignore Failures]  [Fix & Continue]         │
└──────────────────────────────────────────────────────────────────┘
```

**Test Explanation (Plain English):**
- Tests are described by what they check, not technical names
- Failures explain what went wrong in user terms
- Users can click for technical details if curious

---

## Step 3: Fix Bugs (If Any)

**Screen:** Bug Fixing Flow (E6-S3)

**Scenario A: User Reports Bug from Preview**

**User Actions:**
1. Encounters issue while testing
2. Clicks "Report Bug"
3. Describes issue in plain language
4. Submits for agent to fix

**Bug Report Interface:**
```
┌──────────────────────────────────────────────────────────────────┐
│  Report a Bug                                              [×]   │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  What went wrong?                                                │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ When I drag a task from "To Do" to "In Progress", it     │   │
│  │ jumps back to where it started instead of staying in     │   │
│  │ the new column.                                          │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  📍 Context captured:                                            │
│  • Page: /dashboard                                              │
│  • Last action: Drag task "Task 1"                               │
│  • Browser: Chrome 120                                           │
│                                                                  │
│  [Cancel]  [Submit Bug Report]                                   │
└──────────────────────────────────────────────────────────────────┘
```

**Scenario B: User Asks Agent to Fix Test Failure**

**User Actions:**
1. Reviews failed test
2. Clicks "Ask Agent to Fix"
3. Confirms the fix request
4. Waits while agent works

**Fix Progress:**
```
┌──────────────────────────────────────────────────────────────────┐
│  Fixing: User can drag tasks between columns                     │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  🧠 Claude #1 is working on this...                             │
│                                                                  │
│  Progress:                                                       │
│  ✅ Analyzed the bug                                            │
│  ✅ Found the issue in drag-drop handler                        │
│  🔄 Writing the fix                                             │
│  ⏳ Testing the fix                                             │
│                                                                  │
│  Agent says:                                                     │
│  "Found the issue - the state wasn't updating after drag.        │
│  Fixing now, should take about 2 minutes."                       │
│                                                                  │
│  [Cancel Fix]                                                    │
└──────────────────────────────────────────────────────────────────┘
```

**After Fix:**
- Agent completes fix
- Tests automatically re-run
- User sees updated results
- Can preview again to verify

---

## Step 4: Ready to Deploy

**Screen:** Deployment Ready Confirmation

**User Actions:**
1. All tests pass (or failures acknowledged)
2. User has previewed and is satisfied
3. Clicks "Proceed to Deploy"
4. Transitions to Deployment phase

**Ready State:**
```
┌──────────────────────────────────────────────────────────────────┐
│  Ready to Deploy!                                                │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ✅ All 23 tests passing                                        │
│  ✅ Preview tested successfully                                  │
│  ✅ No critical issues found                                    │
│                                                                  │
│  Quality Summary:                                                │
│  • Test coverage: 85%                                            │
│  • Code quality: Good (UBS scan passed)                          │
│  • Performance: Acceptable                                       │
│                                                                  │
│  Your app is ready to go live!                                   │
│                                                                  │
│  [Back to Preview]  [Continue to Deploy →]                       │
└──────────────────────────────────────────────────────────────────┘
```

---

## Optional: Iterative Improvements

**User can loop through Review multiple times:**
1. Preview → Find issue → Report bug → Agent fixes → Preview again
2. Run tests → Failures → Fix → Run tests again
3. Repeat until satisfied

**Exit Conditions:**
- All tests pass AND user satisfied with preview
- User chooses to proceed despite minor issues
- User explicitly marks issues as "acceptable for now"

---

## Error Handling

| Scenario | Handling |
|----------|----------|
| Preview won't load | Show error with retry, offer to rebuild |
| Test environment fails | Restart test environment, notify user |
| Agent can't fix bug | Suggest manual intervention or workaround |
| Fix introduces new bug | Detect regression, rollback fix, alert user |

---

## Success Criteria

| Metric | Target |
|--------|--------|
| Preview success rate | >95% can preview their app |
| Bug fix success rate | >80% of reported bugs fixed by agents |
| Time in review phase | <30 minutes average |
| User satisfaction | Users confident app works as expected |

---

## Related Stories

- E6-S1: Automated Test Results Display
- E6-S2: Application Preview Sandbox
- E6-S3: Natural Language Bug Reporting
- E6-S4: Test Coverage Display
- E6-S5: Responsive Testing
