# Epic 7: Deployment & Publishing

## Overview

**Goal:** Enable users to deploy their software to staging and production environments with minimal friction, turning their built application into a live, accessible product.

**User Value:** Users experience the satisfaction of seeing their idea become a real, live application accessible via a URL, completing the journey from concept to deployed product.

---

## Stories

### E7-S1: One-Click Staging Deployment

**Priority:** P0
**Points:** 8

#### User Story
As a user, I want to deploy to a staging environment with one click so that I can preview my application in a production-like setting before going live.

#### Acceptance Criteria
- [ ] AC1: Given my app has passed tests, when I click "Deploy to Staging", then the deployment process starts automatically
- [ ] AC2: Given deployment is in progress, when I observe, then I see a progress indicator with current step (building, uploading, starting)
- [ ] AC3: Given deployment succeeds, when complete, then I receive a staging URL I can visit and share
- [ ] AC4: Given deployment fails, when an error occurs, then I see a clear error message with suggested actions
- [ ] AC5: Given I want to redeploy, when I make changes and click deploy again, then the staging environment is updated

#### Deployment Steps Shown
```
Deploying to Staging...

1. ✅ Building application
2. ✅ Running final tests
3. 🔄 Uploading to server
4. ⏳ Starting application
5. ⏳ Verifying health

[Cancel]                    Progress: 60%
```

#### Staging Environment
| Aspect | Description |
|--------|-------------|
| URL | `https://taskflow-staging-abc123.acfs.dev` |
| Data | Sandbox data, safe to experiment |
| Lifespan | 7 days or until next deploy |
| Purpose | Testing and stakeholder review |

#### Technical Notes
- **ACFS Integration:** Deployment via Vercel CLI or similar; environment provisioned automatically
- **Dependencies:** E6-S1 (tests should pass), E6-S2 (preview should work)
- **Infra:** Vercel, Railway, or Cloudflare for hosting

#### Wireframe Description
```
┌──────────────────────────────────────────────────────────┐
│  Deployment                                              │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Your app is ready to deploy!                            │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  🔶 STAGING                                     │    │
│  │                                                 │    │
│  │  Deploy to a test environment to verify        │    │
│  │  everything works before going live.           │    │
│  │                                                 │    │
│  │  [Deploy to Staging]                           │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  🟢 PRODUCTION                                  │    │
│  │                                                 │    │
│  │  Deploy your app for real users.               │    │
│  │  Recommended: Deploy to staging first.         │    │
│  │                                                 │    │
│  │  [Deploy to Production]                        │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

#### Definition of Done
- [ ] Deploy to Staging button
- [ ] Progress indicator with steps
- [ ] Success state with URL display
- [ ] Error handling with actionable messages
- [ ] Redeploy capability
- [ ] Integration tests for deployment flow

---

### E7-S2: One-Click Production Deployment

**Priority:** P0
**Points:** 8

#### User Story
As a user, I want to deploy to production with one click so that my software goes live and is accessible to real users.

#### Acceptance Criteria
- [ ] AC1: Given I click "Deploy to Production", when initiating, then I see a confirmation dialog warning this affects real users
- [ ] AC2: Given I confirm deployment, when the process runs, then I see progress indicators similar to staging
- [ ] AC3: Given deployment succeeds, when complete, then I receive my production URL and a celebration message
- [ ] AC4: Given this is my first production deploy, when setting up, then I'm prompted to configure environment variables if needed
- [ ] AC5: Given I've deployed before, when redeploying, then I see a diff/summary of what changed since last deploy

#### Confirmation Dialog
```
┌──────────────────────────────────────────────────────┐
│  Deploy to Production?                               │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ⚠️ This will make your app live and accessible     │
│  to real users.                                      │
│                                                      │
│  Changes since last deploy:                          │
│  • Added user authentication                         │
│  • Updated dashboard layout                          │
│  • Fixed 3 bugs                                      │
│                                                      │
│  Tests: ✅ All 23 tests passing                      │
│                                                      │
│           [Cancel]    [Deploy to Production]         │
└──────────────────────────────────────────────────────┘
```

#### Technical Notes
- **ACFS Integration:** Production deployment via Vercel/Railway; environment separation
- **Dependencies:** E7-S1 (staging deployment pattern)
- **Security:** Environment variables for secrets, not hardcoded

#### Definition of Done
- [ ] Production deploy button with confirmation
- [ ] Change summary in confirmation dialog
- [ ] Progress tracking during deployment
- [ ] Success celebration with URL
- [ ] Environment variable setup flow
- [ ] Integration tests for production deployment

---

### E7-S3: Deployment Status and Logs

**Priority:** P1
**Points:** 5

#### User Story
As a user, I want to see deployment status and logs so that I know if deployment succeeded and can troubleshoot if it failed.

#### Acceptance Criteria
- [ ] AC1: Given a deployment is running, when I view status, then I see real-time logs of what's happening
- [ ] AC2: Given deployment completes, when I view history, then I see a list of past deployments with timestamps and status
- [ ] AC3: Given a deployment failed, when I view logs, then I see the error with line highlighted and plain-English explanation
- [ ] AC4: Given I need to share deployment info, when I click "Copy Log", then deployment details are copied to clipboard
- [ ] AC5: Given I want to understand timing, when I view deployment, then I see how long each step took

#### Deployment History
```
┌──────────────────────────────────────────────────────────┐
│  Deployment History                                      │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  🟢 Production - Feb 19, 2026 at 3:45 PM                │
│     Duration: 2m 34s • Deployed by: You                  │
│     [View Logs] [Visit Site]                             │
│                                                          │
│  🟢 Staging - Feb 19, 2026 at 3:30 PM                   │
│     Duration: 2m 12s • Deployed by: You                  │
│     [View Logs] [Visit Site]                             │
│                                                          │
│  🔴 Production - Feb 19, 2026 at 2:15 PM   FAILED       │
│     Error: Build failed - missing dependency             │
│     [View Logs] [Retry]                                  │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

#### Technical Notes
- **ACFS Integration:** Logs from deployment provider API; stored for history
- **Dependencies:** E7-S1, E7-S2
- **Log Translation:** Technical errors translated to user-friendly messages

#### Definition of Done
- [ ] Real-time log streaming
- [ ] Deployment history list
- [ ] Error highlighting with explanations
- [ ] Copy log functionality
- [ ] Step timing display
- [ ] Unit tests for log rendering

---

### E7-S4: Custom Domain Configuration

**Priority:** P2
**Points:** 5

#### User Story
As a user, I want to configure a custom domain so that my app has a professional URL instead of a generated one.

#### Acceptance Criteria
- [ ] AC1: Given I want a custom domain, when I access domain settings, then I see instructions for connecting my domain
- [ ] AC2: Given I enter my domain, when I save, then I see DNS records I need to configure
- [ ] AC3: Given I've configured DNS, when I click "Verify", then the system checks if DNS is properly configured
- [ ] AC4: Given verification succeeds, when complete, then my app is accessible at my custom domain with HTTPS
- [ ] AC5: Given verification fails, when displaying error, then I see specific guidance on what's misconfigured

#### Domain Setup Flow
```
Step 1: Enter your domain
┌────────────────────────────────────┐
│ taskflow.yourcompany.com           │
└────────────────────────────────────┘

Step 2: Add these DNS records at your domain provider

Type    Name            Value
CNAME   taskflow        cname.acfs.dev
TXT     _acfs-verify    abc123xyz789

Step 3: Click verify once DNS has propagated (may take up to 48h)

[Verify Domain]  Status: ⏳ Pending verification
```

#### Technical Notes
- **ACFS Integration:** Domain configuration via Vercel/Cloudflare API
- **Dependencies:** E7-S2 (must have production deployment)
- **SSL:** Automatic HTTPS via Let's Encrypt

#### Definition of Done
- [ ] Domain input and instructions
- [ ] DNS record display for user
- [ ] Verification check functionality
- [ ] Success state with custom domain active
- [ ] Troubleshooting guidance for failures
- [ ] Integration tests for domain verification

---

### E7-S5: Deployment Rollback

**Priority:** P2
**Points:** 5

#### User Story
As a user, I want to rollback to a previous deployment so that I can recover quickly if something goes wrong with a new release.

#### Acceptance Criteria
- [ ] AC1: Given I have deployment history, when I view a past deployment, then I see a "Rollback to This" button
- [ ] AC2: Given I click rollback, when confirming, then I see a warning that this will replace the current deployment
- [ ] AC3: Given I confirm rollback, when it completes, then the previous version is now live
- [ ] AC4: Given I've rolled back, when viewing history, then I see the rollback as a new deployment entry
- [ ] AC5: Given the current deployment is broken, when I need to rollback, then it completes quickly (no rebuild needed)

#### Rollback Confirmation
```
┌──────────────────────────────────────────────────────┐
│  Rollback to Previous Version?                       │
├──────────────────────────────────────────────────────┤
│                                                      │
│  This will restore the deployment from:              │
│  Feb 18, 2026 at 4:30 PM                            │
│                                                      │
│  Current version will be replaced.                   │
│  You can always deploy again to go forward.          │
│                                                      │
│              [Cancel]    [Rollback]                  │
└──────────────────────────────────────────────────────┘
```

#### Technical Notes
- **ACFS Integration:** Rollback via deployment provider's rollback feature
- **Dependencies:** E7-S3 (must have deployment history)
- **Performance:** Rollback should be near-instant (artifact already exists)

#### Definition of Done
- [ ] Rollback button on past deployments
- [ ] Confirmation dialog with details
- [ ] Fast rollback execution
- [ ] Rollback recorded in history
- [ ] Success notification
- [ ] Integration tests for rollback flow

---

## Epic Summary

| Story | Priority | Points | Dependencies |
|-------|----------|--------|--------------|
| E7-S1 | P0 | 8 | E6-S1, E6-S2 |
| E7-S2 | P0 | 8 | E7-S1 |
| E7-S3 | P1 | 5 | E7-S1, E7-S2 |
| E7-S4 | P2 | 5 | E7-S2 |
| E7-S5 | P2 | 5 | E7-S3 |

**Total Points:** 31
**P0 Points:** 16
