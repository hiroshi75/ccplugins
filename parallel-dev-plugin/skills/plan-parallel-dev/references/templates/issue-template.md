# Issue Template

Template to use when a problem occurs during work and you cannot continue.

Filename: `.parallel-dev-issues/{branch-name}.md`

---

## Template

```markdown
# Issue: {branch-name}

## Basic Information

| Item | Content |
|------|---------|
| Date/Time | YYYY-MM-DD HH:MM |
| Task | {branch-name} |
| worktree | `worktree/{branch-name}/` |
| Reporter | {agent-name} |
| Assignee | (Assigned by merge coordinator) |
| Status | Unresolved / In Progress / Resolved |

---

## Situation

(Select applicable items below)

- [ ] Build error
- [ ] Test failure
- [ ] Dependent task issue
- [ ] Unable to resolve conflict
- [ ] Unclear specification
- [ ] Environment issue (secrets, connections, etc.)
- [ ] Other

---

## Error Details

```
(Paste error messages, stack traces, etc. here)
```

---

## Impact Scope

### This Task

- {branch-name}: {Current state, how much is completed}

### Tasks This Depends On

| Task | Impact |
|------|--------|
| {dependent-task} | {Impact from this issue} |

### Tasks Depending on This

| Task | Impact |
|------|--------|
| {blocking-task} | {Impact from this task not being completed} |

---

## Attempted Solutions

1. {Attempted solution 1}
   - Result: {Success/Failure/Partially resolved}

2. {Attempted solution 2}
   - Result: {Success/Failure/Partially resolved}

---

## Required Actions

- [ ] Coordination with other tasks needed
- [ ] New branch/worktree needed
- [ ] Specification confirmation/change needed
- [ ] Human escalation needed
- [ ] Other: {Details}

### Proposed Solution

{If possible, describe the proposed solution}

---

## Merge Coordinator's Response Record

### Assignment

- Assignment date/time:
- Assigned to:

### Response Details

{Merge coordinator records response details}

### New Task Creation (if applicable)

- [ ] Update `.parallel-dev/README.md`
- [ ] Update `.parallel-dev/merge-coordinator.md`
- [ ] Create `.parallel-dev/tasks/{new-task}.md`
- [ ] Create `worktree/{new-task}/`

### Resolution

- Resolution date/time:
- Resolution method:
```

---

## Examples by Situation

### Build Error Example

```markdown
## Situation
- [x] Build error

## Error Details
```
src/services/recommendation.py:45: error: Module "external_api" has no attribute "RecommendationClient"
```

## Attempted Solutions
1. Checked external_api package version
   - Result: Version is correct (1.2.0)
2. Checked type definition files
   - Result: RecommendationClient was added in v1.3.0

## Required Actions
- [x] Coordination with other tasks needed

### Proposed Solution
Need to upgrade external_api to 1.3.0.
Want to perform the upgrade after confirming impact on other tasks.
```

### Dependent Task Issue Example

```markdown
## Situation
- [x] Dependent task issue

## Error Details
```
recommendation-api's API response format differs from the design document.
Expected: { "items": [...] }
Actual: { "recommendations": [...] }
```

## Impact Scope
### Tasks Depending on This
| Task | Impact |
|------|--------|
| project-card-enhance | Uses recommendation-api's response |

## Attempted Solutions
1. Checked recommendation-api's .done file
   - Result: No specification change noted

## Required Actions
- [x] Specification confirmation/change needed

### Proposed Solution
1. Fix response format on the recommendation-api side
2. Or adapt project-card-enhance to the new format

Awaiting merge coordinator's decision.
```

### Unable to Resolve Conflict Example

```markdown
## Situation
- [x] Unable to resolve conflict

## Error Details
```
CONFLICT (content): Merge conflict in src/components/shared/Card.tsx
Auto-merging failed; fix conflicts and then commit the result.
```

Conflict location:
- `src/components/shared/Card.tsx` lines 45-78
- Both notification-api and project-card-enhance significantly modified the Card component

## Attempted Solutions
1. Tried to incorporate both changes
   - Result: Simple merge not possible due to conflicting logic

## Required Actions
- [x] Coordination with other tasks needed

### Proposed Solution
1. Separate Card component (NotificationCard, ProjectCard)
2. Or redesign common abstraction

Coordination with both task owners needed.
```

---

## Merge Coordinator's Response Flow

1. **Detection**: Check if there are new files in `.parallel-dev-issues/`
2. **Evaluation**: Review issue content and determine priority
3. **Assignment**: Decide assignee (existing task owner or new)
4. **Tracking**: Create new task/worktree as needed
5. **Update**: Update files in `.parallel-dev/`
6. **Notification**: Add information to related task instructions
7. **Resolution Confirmation**: Update issue status to "Resolved"
