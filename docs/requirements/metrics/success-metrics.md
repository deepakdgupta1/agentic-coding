# Success Metrics Framework

## Overview

This document defines the key performance indicators (KPIs) for ACFS Canvas, how they are measured, and their target values. These metrics align with the product goals of enabling technical non-developers to build and deploy software successfully.

---

## Primary Success Metrics

### 1. Project Completion Rate

**Definition:** Percentage of started projects that reach successful deployment.

| Metric | Target | Measurement |
|--------|--------|-------------|
| Overall completion rate | >70% | Projects deployed / Projects started |
| MVP completion | >80% | P0 features only |
| Full feature completion | >60% | All planned features |

**Measurement Method:**
```sql
SELECT
  COUNT(CASE WHEN status = 'deployed' THEN 1 END) * 100.0 / COUNT(*)
FROM projects
WHERE created_at > :period_start
```

**Breakdowns:**
- By project complexity (Simple / Moderate / Complex)
- By user experience level (First project / Returning user)
- By project type (Web app / API / Full-stack)

**Dashboard Display:**
```
Completion Rate: 73%  ▲ 5% from last month

[Simple]     ████████████████████ 92%
[Moderate]   ████████████████░░░░ 78%
[Complex]    ██████████████░░░░░░ 55%
```

---

### 2. Time to First Deploy

**Definition:** Time from project creation to first successful deployment.

| Metric | Target | Measurement |
|--------|--------|-------------|
| Median time (simple projects) | <1 hour | 50th percentile |
| Median time (moderate) | <2 hours | 50th percentile |
| Median time (complex) | <4 hours | 50th percentile |

**Measurement Method:**
```sql
SELECT
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY
    EXTRACT(EPOCH FROM (first_deploy_at - created_at)) / 3600
  ) as median_hours
FROM projects
WHERE first_deploy_at IS NOT NULL
```

**Time Breakdown by Phase:**
| Phase | Target % of Total |
|-------|-------------------|
| Ideation | 10-15% |
| Architecture | 5-10% |
| Build | 60-70% |
| Review | 10-15% |
| Deploy | 5-10% |

**Dashboard Display:**
```
Median Time to Deploy: 1h 42m

Phase Breakdown:
[Ideation]     ████░░░░░░  12 min
[Architecture] ██░░░░░░░░  6 min
[Build]        ██████████████████  68 min
[Review]       ██████░░░░  18 min
[Deploy]       ████░░░░░░  8 min
```

---

### 3. User Satisfaction (NPS)

**Definition:** Net Promoter Score based on post-completion survey.

| Metric | Target | Measurement |
|--------|--------|-------------|
| NPS Score | >50 | (Promoters - Detractors) / Total |
| Satisfaction rating | >4.2/5 | Average rating |
| Would recommend | >80% | Yes responses |

**Survey Questions:**
1. "How likely are you to recommend ACFS Canvas to a friend?" (0-10)
2. "Overall, how satisfied are you with your experience?" (1-5)
3. "Would you use ACFS Canvas for your next project?" (Yes/No)

**Survey Timing:**
- Triggered after first successful deployment
- Follow-up survey after 7 days of usage
- Optional feedback throughout journey

**NPS Calculation:**
```
Promoters (9-10):    45%
Passives (7-8):      35%
Detractors (0-6):    20%

NPS = 45 - 20 = +25 (below target, needs improvement)
```

---

### 4. User Intervention Rate

**Definition:** Percentage of builds requiring manual user intervention to complete.

| Metric | Target | Measurement |
|--------|--------|-------------|
| Zero-intervention builds | >80% | Builds with no pauses/fixes |
| Single intervention | <15% | One intervention needed |
| Multiple interventions | <5% | Two or more needed |

**Intervention Types Tracked:**
| Type | Weight | Example |
|------|--------|---------|
| Bug report | 1.0 | User reports issue in preview |
| Manual pause | 0.5 | User pauses to review |
| Task redirect | 1.0 | User reassigns agent task |
| Error recovery | 1.5 | Agent error requires attention |
| Specification change | 2.0 | User modifies spec mid-build |

**Measurement Method:**
```sql
SELECT
  COUNT(CASE WHEN intervention_count = 0 THEN 1 END) * 100.0 / COUNT(*)
FROM builds
WHERE completed_at IS NOT NULL
```

---

## Secondary Metrics

### 5. Agent Efficiency

**Definition:** Productivity of AI agents in completing tasks.

| Metric | Target | Measurement |
|--------|--------|-------------|
| Tasks per agent-hour | TBD (baseline first) | Tasks completed / Agent hours |
| Code quality score | >85% | UBS pass rate |
| Test pass rate | >90% | Tests passing on first run |

**Per-Agent Type:**
| Agent | Metric | Target |
|-------|--------|--------|
| Claude Code | Complex tasks/hour | >3 |
| Codex | Code gen tasks/hour | >5 |
| Gemini | Review tasks/hour | >8 |

---

### 6. Build Success Rate

**Definition:** Percentage of builds that complete without errors.

| Metric | Target | Measurement |
|--------|--------|-------------|
| First-try success | >85% | No retries needed |
| With retry success | >95% | Including auto-retries |
| Fatal failure rate | <2% | Unrecoverable errors |

**Error Categories:**
| Category | Target % | Description |
|----------|----------|-------------|
| Agent errors | <5% | Agent crashes or timeouts |
| Task failures | <8% | Individual task failures |
| Resource errors | <2% | Memory, disk, network issues |
| User errors | <3% | Invalid input/configuration |

---

### 7. Feature Adoption

**Definition:** Usage of optional features beyond core flow.

| Feature | Target Adoption |
|---------|-----------------|
| Code visibility toggle | >30% enable |
| Agent communication view | >50% view |
| Custom domain setup | >10% configure |
| Project export | >20% use |

---

## Funnel Metrics

### User Journey Conversion Funnel

```
Stage               Users    Conversion    Target
─────────────────────────────────────────────────
Visit landing page  10,000   -             -
Start wizard        6,000    60%           >60%
Complete spec       5,100    85%           >85%
Begin build         4,800    94%           >90%
Complete build      4,080    85%           >80%
Pass review         3,672    90%           >85%
Deploy (staging)    3,305    90%           >90%
Deploy (production) 2,644    80%           >75%

Overall:            2,644    26.4%         >25%
```

### Drop-off Analysis

| Stage | Drop-off Rate | Primary Reasons |
|-------|---------------|-----------------|
| Spec completion | 15% | Unclear what to write, too many questions |
| Build start | 6% | Overwhelmed by architecture view |
| Build completion | 15% | Build took too long, errors occurred |
| Review pass | 10% | Too many failing tests, bugs found |
| Production deploy | 20% | Stayed on staging, didn't need production |

---

## Operational Metrics

### System Performance

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Canvas load time | <2s | >5s |
| WebSocket latency | <100ms | >500ms |
| API response time | <200ms | >1s |
| Build queue time | <30s | >2m |
| Deploy time (staging) | <3m | >10m |

### Reliability

| Metric | Target | Measurement |
|--------|--------|-------------|
| System uptime | >99.5% | Monthly availability |
| Build success rate | >95% | Excluding user errors |
| Deploy success rate | >98% | All deployments |
| Data loss events | 0 | Never lose user work |

---

## Measurement Implementation

### Data Collection Points

```typescript
// Track user events
analytics.track('project_created', {
  userId,
  projectId,
  complexity,
  techStack,
  timestamp
});

analytics.track('build_started', {
  userId,
  projectId,
  agentConfig,
  taskCount,
  timestamp
});

analytics.track('build_completed', {
  userId,
  projectId,
  duration,
  interventionCount,
  errorCount,
  timestamp
});

analytics.track('deployment_completed', {
  userId,
  projectId,
  environment,
  duration,
  success,
  timestamp
});
```

### Dashboard Requirements

**Executive Dashboard:**
- Overall completion rate (trend)
- Average time to deploy (trend)
- NPS score (monthly)
- Active users (daily/weekly/monthly)

**Operations Dashboard:**
- Real-time build status
- Agent utilization
- Error rates by type
- Queue depths

**Product Dashboard:**
- Funnel conversion rates
- Feature adoption rates
- User journey heatmaps
- Cohort retention

---

## Review Cadence

| Review Type | Frequency | Participants |
|-------------|-----------|--------------|
| Metrics standup | Weekly | Product + Engineering |
| NPS review | Monthly | Product + Leadership |
| Funnel analysis | Bi-weekly | Product + Growth |
| Operational review | Daily | Engineering |
| Quarterly business review | Quarterly | All stakeholders |

---

## Baseline Establishment

Before launch, establish baselines for:
1. Similar products (competitive benchmarks)
2. ACFS CLI usage patterns
3. User research expectations
4. Technical performance baseline

**First 30 days post-launch:**
- Focus on data collection, not optimization
- Set realistic targets based on observed data
- Identify top 3 improvement opportunities

**Post-baseline targets:**
- Adjust targets based on actual performance
- Set quarterly improvement goals
- Document any target changes with rationale
