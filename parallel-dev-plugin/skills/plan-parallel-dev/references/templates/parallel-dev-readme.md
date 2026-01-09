# Parallel Development README Template

Template for `.parallel-dev/README.md` - overall progress tracking and overview.

## Template Content

```markdown
# Parallel Development: {Feature Name}

## Overview
{Brief description of features being implemented}

| Item | Value |
|------|-------|
| Start Date | YYYY-MM-DD |
| Target Date | YYYY-MM-DD |
| Integration Branch | `feature/{integration-branch}` |
| Tasks | {N} tasks |
| Max Parallelism | {M} concurrent |

## Progress Summary
Overall: ████████░░░░░░░░ 50% (2/4 complete)

### Task Status
| Task | Branch | Status | Assignee |
|------|--------|--------|----------|
| {Task-A} | feature/{task-a} | ✅ Merged | Agent-1 |
| {Task-B} | feature/{task-b} | 🔄 In Progress | Agent-2 |

Legend: ⬚ Not Started / 🔄 In Progress / ✅ Merged / ⏳ Waiting / ❌ Blocked

## Dependency Diagram
```
feature/{task-a} ──→ feature/{task-b}
```

## Merge Order
1. feature/{task-a} ✅ Merged
2. feature/{task-b} 🔄 Waiting

## Completion Criteria
- [ ] All tasks merged
- [ ] Integration tests pass
- [ ] PR merged to main
- [ ] Worktrees cleaned up
```
