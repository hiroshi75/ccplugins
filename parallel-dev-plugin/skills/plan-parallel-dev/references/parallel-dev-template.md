# Parallel Development Plan Template

Use this template as a reference to create your plan. Add or remove sections as needed for your project.

---

## Template

```markdown
# [Feature Name] Implementation Plan

## Overview

This document is a work assignment table for parallel development of [target document/feature] by multiple developers.

**Goal**: Maximize parallel development and shorten the development period

---

## Developer Role Definition (N-person Team)

As a result of optimization, **N developers** can work efficiently while minimizing wait time.

| Role | Assigned Branch | Required Skills |
|------|-----------------|-----------------|
| **BE-1** | feature/xxx-api | Python, FastAPI, ... |
| **FE-1** | feature/xxx-ui → yyy-ui | React, TypeScript, ... |

### Rationale for Staff Allocation

```
Critical Path Analysis:
────────────────────
Longest path: [TaskA] → [TaskB] → [TaskC] (X days)

Bottleneck:
- [Description of bottleneck]
- [Resolution method]

Wait Time Occurrence Patterns:
- [Assignee]: [Wait condition and response]
```

---

## Branch Strategy

```
main
├── feature/[integration-branch-name] (integration branch)
│   │
│   ├── feature/xxx-api       [BE-1]
│   ├── feature/yyy-api       [BE-2]
│   │
│   ├── feature/xxx-ui        [FE-1]
│   └── feature/yyy-ui        [FE-1] ← After BE-1 completion
```

---

## Task List (with Task Names and Assignees)

### Backend Tasks

| Branch | Task Name | Assignee | Dependencies | Deliverables |
|--------|-----------|----------|--------------|--------------|
| feature/recommendation-api | Recommendation API Implementation | BE-1 | None | `GET /api/v1/recommendations` |
| feature/notification-api | Notification API Implementation | BE-1 | None | `POST /api/v1/notifications` |

### Frontend Tasks

| Branch | Task Name | Assignee | Dependencies | Deliverables |
|--------|-----------|----------|--------------|--------------|
| feature/project-card-enhance | Card Feature Enhancement | FE-1 | recommendation-api | ProjectCard Extension |
| feature/search-filter | Search Filter | FE-1 | None | SearchFilter |

---

## Parallel Development Timeline (N-person Team, X Days)

```
Day 1                    Day 2                    Day 3
────────────────────────────────────────────────────────────

BE-1  ████████████████████████████████████████████  Review
      recommendation-api                            ↓Complete

FE-1  ████████████████████████████████████████████  ████████████████████████
      search-filter                                 project-card-enhance
                                                    ↑ After recommendation-api completion
```

### Detailed Schedule for Each Assignee

| Assignee | Day 1 | Day 2 | Day 3 |
|----------|-------|-------|-------|
| BE-1 | recommendation-api | Complete | Review |
| FE-1 | search-filter | Complete | project-card-enhance |

---

## Dependency Matrix

### Start Conditions

| Branch | Start Condition | Assignee |
|--------|-----------------|----------|
| recommendation-api, search-filter | **Can start immediately** | BE-1, FE-1 |
| project-card-enhance | After recommendation-api completion | FE-1 |

### Blocking Relationship Diagram

```
                         Day 1           Day 2           Day 3
                         ─────           ─────           ─────
BE-1  ═══════════════════════════════════╗
      recommendation-api                  ║
                                         ╚════════════════════► project-card-enhance (FE-1)

FE-1  ═══════════════════════════════════╗
      search-filter                       ║
                                         ╚════════════════════► project-card-enhance
```

---

## Merge Order

Merge order to integration branch:

### Phase 1: Independent Tasks (Can be merged in parallel)
```
1. feature/recommendation-api [BE-1]
2. feature/search-filter [FE-1]
```

### Phase 2: Dependent Tasks
```
3. feature/project-card-enhance [FE-1] ← After recommendation-api merge
```

---

## Detailed Specifications for Each Task

### recommendation-api

**Endpoint**: `GET /api/v1/xxx`

**Response**:
```typescript
interface XxxResponse {
  items: XxxItem[];
  generated_at: string;
}
```

**Implementation Notes**:
- [Notes for implementation]

---

### project-card-enhance

**Component**: `ProjectCard` (Extension)

**Implementation Notes**:
- Display results from recommendation-api
- [Other notes]

---

## Definition of Done

### Completion Criteria by Feature

| Feature | Completion Criteria |
|---------|---------------------|
| Recommendation Feature | All of recommendation-api, project-card-enhance merged |

### Overall Completion Criteria

- [ ] All PRs reviewed and merged
- [ ] PR created from integration branch → main
- [ ] Integration testing completed

---

## Risk Management

| Risk | Impact | Mitigation |
|------|--------|------------|
| recommendation-api delay | project-card-enhance blocked | Continue FE development with mock API |
| Merge conflict | Integration delay | Regularly merge integration branch |

---

## Communication

### Daily Sync
- 15-minute standup every day
- Early reporting of blockers

### Branch Naming Convention
```
feature/{feature-name}
Example: feature/recommendation-api
```

### Commit Message Convention
```
feat: Add new feature
fix: Bug fix
refactor: Refactoring
docs: Documentation update
test: Add or modify tests
```

---

**Created**: YYYY-MM-DD
**Version**: 1.0
**Status**: Pending Approval
```

---

## Section Selection Guide

Select necessary sections based on project scale:

### Small Scale (2-3 people, within 1 week)
Required:
- Overview
- Developer Role Definition
- Task List
- Dependency Matrix

### Medium Scale (4-6 people, about 2 weeks)
In addition to the above:
- Branch Strategy
- Timeline
- Merge Order
- Definition of Done

### Large Scale (7+ people, 1+ months)
All sections + additionally:
- Detailed Risk Management
- Escalation Path
- Milestone Definition
