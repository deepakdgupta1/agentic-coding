# User Journey: Deploy Phase

## Overview

**Duration:** 5-10 minutes
**Goal:** Deploy the application to a live environment
**Entry Point:** User clicks "Continue to Deploy" from Review phase
**Exit Point:** Application is live with accessible URL

---

## Journey Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Choose    │────►│   Deploy    │────►│   Monitor   │────►│   Live!     │
│Environment  │     │   Process   │     │   Status    │     │   (Success) │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

---

## Step 1: Choose Environment

**Screen:** Deployment Options (E7-S1, E7-S2)

**User Actions:**
1. Views deployment options
2. Reads descriptions of each environment
3. Chooses staging (recommended first) or production
4. Clicks to initiate deployment

**Deployment Options Display:**
```
┌──────────────────────────────────────────────────────────────────┐
│  Deploy TaskFlow                                                 │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Where would you like to deploy?                                 │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  🔶 STAGING (Recommended)                                │   │
│  │                                                          │   │
│  │  A test environment to verify everything works           │   │
│  │  before going live. Safe to experiment.                  │   │
│  │                                                          │   │
│  │  • URL: taskflow-staging-abc123.acfs.dev                │   │
│  │  • Data: Test data, won't affect real users             │   │
│  │  • Lifespan: 7 days or until next deploy                │   │
│  │                                                          │   │
│  │  [Deploy to Staging]                                     │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  🟢 PRODUCTION                                           │   │
│  │                                                          │   │
│  │  Your live application for real users.                   │   │
│  │  Deploy here when you're confident everything works.     │   │
│  │                                                          │   │
│  │  • URL: taskflow.acfs.dev (or custom domain)            │   │
│  │  • Data: Real user data                                  │   │
│  │  • Lifespan: Permanent until you take it down           │   │
│  │                                                          │   │
│  │  ⚠️ Recommended: Deploy to staging first                │   │
│  │                                                          │   │
│  │  [Deploy to Production]                                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**First-Time Guidance:**
- "Staging is like a dress rehearsal - test everything before the real show"
- "You can deploy to staging as many times as you want"
- "Production is permanent - real users will see your app"

---

## Step 2: Confirm Deployment (Production Only)

**Screen:** Production Deployment Confirmation

**User Actions (Production only):**
1. Reviews deployment summary
2. Sees what changed since last deploy (if applicable)
3. Confirms understanding
4. Clicks to proceed

**Confirmation Dialog:**
```
┌──────────────────────────────────────────────────────────────────┐
│  Deploy to Production?                                           │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ⚠️ This will make TaskFlow live and accessible to real users.  │
│                                                                  │
│  Pre-deploy checklist:                                           │
│  ✅ All tests passing (23/23)                                   │
│  ✅ Preview tested successfully                                  │
│  ✅ No critical bugs found                                      │
│                                                                  │
│  This is your first production deploy.                           │
│                                                                  │
│  Your app will be available at:                                  │
│  https://taskflow.acfs.dev                                      │
│                                                                  │
│  ☐ I understand this will be publicly accessible                │
│                                                                  │
│               [Cancel]    [Deploy to Production]                 │
└──────────────────────────────────────────────────────────────────┘
```

---

## Step 3: Deployment Process

**Screen:** Deployment Progress (E7-S3)

**User Experience:**
1. Watches progress through deployment steps
2. Sees estimated time remaining
3. Can view detailed logs if curious
4. Waits for completion

**Progress Display:**
```
┌──────────────────────────────────────────────────────────────────┐
│  Deploying to Staging...                                         │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Progress: ████████████████░░░░░░░░  65%                        │
│  Estimated: ~1 minute remaining                                  │
│                                                                  │
│  Steps:                                                          │
│  ✅ Preparing build                                              │
│  ✅ Compiling application                                        │
│  ✅ Running final checks                                         │
│  🔄 Uploading to server                                          │
│  ⏳ Starting application                                         │
│  ⏳ Verifying health                                             │
│                                                                  │
│  [View Detailed Logs]                                            │
│                                                                  │
│  💡 Tip: Staging deploys usually take 1-3 minutes               │
│                                                                  │
│  [Cancel Deployment]                                             │
└──────────────────────────────────────────────────────────────────┘
```

**Step Explanations (on hover/click):**
| Step | What it does |
|------|--------------|
| Preparing build | Packages your code for deployment |
| Compiling | Converts code to optimized production version |
| Running checks | Final security and quality scans |
| Uploading | Sends your app to the hosting server |
| Starting | Boots up your application |
| Verifying | Confirms the app is responding correctly |

---

## Step 4: Deployment Success

**Screen:** Success Celebration

**User Experience:**
1. Sees success message with celebration
2. Receives live URL
3. Can open app in new tab
4. Options to share or configure further

**Success Display:**
```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│                           🎉                                     │
│                                                                  │
│            TaskFlow is now live!                                 │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Your staging URL:                                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  https://taskflow-staging-abc123.acfs.dev         [Copy] │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  [Open in New Tab]                                               │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│  What's next?                                                    │
│                                                                  │
│  ┌────────────────────┐  ┌────────────────────┐                 │
│  │ Test your live app │  │ Deploy to Prod     │                 │
│  │ Click to verify    │  │ When ready to go   │                 │
│  │ everything works   │  │ fully live         │                 │
│  │                    │  │                    │                 │
│  │ [Visit Staging]    │  │ [Go to Production] │                 │
│  └────────────────────┘  └────────────────────┘                 │
│                                                                  │
│  ┌────────────────────┐  ┌────────────────────┐                 │
│  │ Share your app     │  │ Custom domain      │                 │
│  │ Send the link to   │  │ Use your own       │                 │
│  │ stakeholders       │  │ domain name        │                 │
│  │                    │  │                    │                 │
│  │ [Copy Link]        │  │ [Configure]        │                 │
│  └────────────────────┘  └────────────────────┘                 │
│                                                                  │
│  [Return to Project Dashboard]                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Alternative: Deployment Failure

**Screen:** Deployment Error

**User Experience:**
1. Sees deployment failed at specific step
2. Reads plain-English explanation
3. Given options to retry or get help

**Error Display:**
```
┌──────────────────────────────────────────────────────────────────┐
│  Deployment Failed                                               │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ❌ TaskFlow couldn't be deployed                               │
│                                                                  │
│  What happened:                                                  │
│  The application failed to start on the server.                  │
│  This usually means there's a configuration issue.               │
│                                                                  │
│  Technical details:                                              │
│  └── Error: Missing environment variable DATABASE_URL            │
│                                                                  │
│  How to fix:                                                     │
│  We need to set up your database connection. This is a           │
│  one-time setup step.                                            │
│                                                                  │
│  [Set Up Database]  [Try Again]  [Get Help]                     │
│                                                                  │
│  [View Full Logs]                                                │
└──────────────────────────────────────────────────────────────────┘
```

**Error Recovery Options:**
| Option | Action |
|--------|--------|
| Set Up [X] | Guided setup for missing configuration |
| Try Again | Retry deployment |
| Get Help | Open support/documentation |
| View Logs | See detailed technical logs |

---

## Post-Deployment: Optional Configuration

**Screen:** Custom Domain Setup (E7-S4)

**User Actions (if selected):**
1. Enters custom domain
2. Receives DNS instructions
3. Configures DNS at their registrar
4. Verifies configuration

**Domain Setup:**
```
┌──────────────────────────────────────────────────────────────────┐
│  Set Up Custom Domain                                            │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Step 1: Enter your domain                                       │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ taskflow.yourcompany.com                                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  Step 2: Add these DNS records at your domain provider           │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Type   │ Name     │ Value                               │    │
│  │────────│──────────│─────────────────────────────────────│    │
│  │ CNAME  │ taskflow │ cname.acfs.dev                      │    │
│  │ TXT    │ _verify  │ acfs-verify=abc123xyz               │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  📋 [Copy DNS Records]                                           │
│                                                                  │
│  Step 3: Verify (after DNS propagates, up to 48 hours)           │
│                                                                  │
│  [Verify Domain]  Status: ⏳ Not yet verified                    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Error Handling

| Scenario | Handling |
|----------|----------|
| Build fails | Show step that failed, offer retry |
| Upload timeout | Retry automatically, then alert user |
| Health check fails | Suggest common fixes, offer rollback |
| Domain verification fails | Show specific DNS issue |

---

## Success Criteria

| Metric | Target |
|--------|--------|
| Deploy success rate | >95% deploys succeed |
| Time to deploy | <5 minutes staging, <10 minutes production |
| First-deploy success | >90% first attempts succeed |
| User understanding | Users know where their app is live |

---

## Related Stories

- E7-S1: One-Click Staging Deployment
- E7-S2: One-Click Production Deployment
- E7-S3: Deployment Status and Logs
- E7-S4: Custom Domain Configuration
- E7-S5: Deployment Rollback
