# User Journey: Ideation Phase

## Overview

**Duration:** 5-15 minutes
**Goal:** Transform a vague idea into a clear, buildable project specification
**Entry Point:** User clicks "New Project" on dashboard
**Exit Point:** User clicks "Start Building" with confirmed specification

---

## Journey Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Welcome   │────►│  Describe   │────►│  Clarify    │────►│   Review    │
│   Screen    │     │   Idea      │     │   Details   │     │    Spec     │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                           │                   │                   │
                           ▼                   ▼                   ▼
                    [E1-S1: Natural    [E1-S2: AI         [E1-S4: Auto-
                     Language Input]   Clarifying Qs]     Generated Spec]
```

---

## Step 1: Welcome Screen

**Screen:** Project Dashboard → New Project Button

**User Actions:**
- User arrives at dashboard (may be first visit or returning)
- Clicks "New Project" button

**System Behavior:**
- Displays welcoming message
- Shows brief overview of what ACFS Canvas does
- Presents input area for describing their idea

**Emotional State:** Curious, possibly uncertain about what to expect

---

## Step 2: Describe Your Idea

**Screen:** Natural Language Input (E1-S1)

**User Actions:**
1. Reads prompt: "What do you want to build?"
2. Types description of their software idea
3. Optionally expands to add more details
4. Clicks "Continue"

**Sample User Input:**
> "I want a task management app for my small team. We need to be able to create projects, add tasks, assign them to people, and see what everyone is working on. Something like a simple Trello."

**System Behavior:**
- Shows placeholder with example descriptions
- Displays character count
- Enables Continue button when minimum length reached
- On Continue: Shows loading state, sends to AI for analysis

**Guidance Provided:**
- Example descriptions that rotate
- "Add more details" expansion for comprehensive input
- Tips on what to include (users, features, purpose)

**Error States:**
- Description too short → Prompt to add more detail
- Network error → Retry option

---

## Step 3: Answer Clarifying Questions

**Screen:** AI Clarification Flow (E1-S2)

**User Actions:**
1. Reads AI-generated question
2. Selects from suggested options OR types custom answer
3. Optionally adds context to their answer
4. Repeats for 3-5 questions
5. Clicks "Review Specification"

**Sample Questions:**
1. "Who will use this application?"
   - [x] Internal team members
   - [ ] External customers
   - [ ] Both
   - [ ] Other: ___

2. "What's the most important feature?"
   - Suggestions: [Kanban board] [Task assignment] [Due dates]
   - Custom: "Being able to see who's working on what at a glance"

3. "Do you need user authentication?"
   - [x] Yes, simple email/password
   - [ ] Yes, with social login (Google, etc.)
   - [ ] No, it's for personal use
   - [ ] Not sure

4. "Any specific integrations needed?"
   - [ ] Slack notifications
   - [x] Email notifications
   - [ ] Calendar sync
   - [ ] None needed

**System Behavior:**
- Generates questions based on initial description
- Allows going back to change previous answers
- Shows progress (Question 2 of 4)
- Enables "Review Specification" when all answered

**Guidance Provided:**
- "Not sure" option for uncertain questions
- Brief explanations of technical options
- Ability to skip non-critical questions

---

## Step 4: Select Project Type

**Screen:** Project Type Confirmation (E1-S3)

**User Actions:**
1. Views AI-recommended project type
2. Reviews type options with descriptions
3. Confirms or changes selection
4. Proceeds to specification review

**Options Displayed:**
```
Recommended for your project:

[✓] Full-Stack Web Application
    Complete app with frontend, backend, and database
    Best for: Team collaboration tools, dashboards, SaaS products

[ ] Web Application (Frontend Only)
    Browser-based interface, uses external APIs
    Best for: Simple tools, single-page apps

[ ] REST API
    Backend service with data endpoints
    Best for: Mobile app backends, integrations

[ ] Internal Tool
    Admin-focused functionality
    Best for: Data management, configuration tools
```

**System Behavior:**
- Highlights recommended type with reasoning
- Shows what each type means in plain language
- Records selection for architecture planning

---

## Step 5: Review Specification

**Screen:** Generated Specification View (E1-S4)

**User Actions:**
1. Reviews auto-generated specification
2. Edits any sections that need adjustment
3. Adds missing features or requirements
4. Views complexity estimate (E1-S5)
5. Clicks "Start Building" to proceed

**Specification Displayed:**
```
┌────────────────────────────────────────────────────────────┐
│  TaskFlow - Project Specification                  [Edit] │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  📝 Description                                            │
│  A team task management application where small teams      │
│  can create projects, assign tasks, and track progress     │
│  with a visual kanban board.                              │
│                                                            │
│  👥 Target Users                                           │
│  • Primary: Small team members (5-20 people)              │
│  • Secondary: Team leads managing workload                │
│                                                            │
│  ✨ Core Features                                          │
│  • User authentication with team invites                  │
│  • Project creation and management                        │
│  • Kanban board for task visualization                    │
│  • Task assignment with due dates                         │
│  • Team member status view                                │
│  [+ Add Feature]                                          │
│                                                            │
│  📧 Nice to Have                                           │
│  • Email notifications                                    │
│  [+ Add Feature]                                          │
│                                                            │
│  🔧 Technical Approach                                     │
│  • Frontend: React with TypeScript                        │
│  • Backend: Node.js API                                   │
│  • Database: PostgreSQL                                   │
│  • Deployment: Vercel + Railway                           │
│                                                            │
│  📊 Estimated Complexity: Moderate                        │
│     ~15 components, ~4-6 hours build time                 │
│     [Why this estimate?]                                  │
│                                                            │
│              [Start Over]    [Start Building →]            │
└────────────────────────────────────────────────────────────┘
```

**System Behavior:**
- Generates comprehensive specification from all inputs
- Enables inline editing for all sections
- Shows complexity estimate with factors
- Saves specification and proceeds to Architecture phase

**Decision Points:**
- User satisfied → "Start Building" → Exit to Architecture Phase
- User wants changes → Edit inline → Update specification
- User wants to start over → "Start Over" → Return to Step 2

---

## Error Handling

| Scenario | Handling |
|----------|----------|
| AI fails to generate questions | Show generic questions + retry option |
| Network timeout during save | Auto-retry with saved draft |
| User navigates away | Auto-save progress, can resume |
| Invalid input detected | Inline validation with guidance |

---

## Success Criteria

| Metric | Target |
|--------|--------|
| Completion rate | >85% of users who start reach spec review |
| Time to spec | <10 minutes for average user |
| Edit rate | <30% of specs need manual edits |
| Satisfaction | Users feel specification matches their vision |

---

## Related Stories

- E1-S1: Natural Language Project Description
- E1-S2: AI Clarifying Questions
- E1-S3: Project Type Selection
- E1-S4: Auto-Generated Specification Review
- E1-S5: Complexity and Scope Estimate
