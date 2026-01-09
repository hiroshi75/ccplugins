# Parallel Development README Template

Template for `.parallel-dev/README.md`. Contains overall progress management and overview.

---

## Template

```markdown
# Parallel Development: {Feature Name}

## Overview

{Overview of the features to be implemented in this parallel development}

| Item | Value |
|------|-------|
| Start Date | YYYY-MM-DD |
| Target Completion Date | YYYY-MM-DD |
| Integration Branch | `feature/{integration-branch}` |
| Number of Tasks | {N} |
| Parallelism | Up to {M} tasks in parallel |

---

## Progress Summary

```
Overall Progress: ████████░░░░░░░░ 50% (2/4 tasks complete)

Phase 1: ████████████████ 100% Complete
Phase 2: ████████░░░░░░░░  50% In Progress
```

### Task Status List

| Task | Branch | worktree | Status | Assignee |
|------|--------|----------|--------|----------|
| {Task-A} | feature/{task-a} | `worktree/{task-a}/` | ✅ Merged | Agent-1 |
| {Task-B} | feature/{task-b} | `worktree/{task-b}/` | ✅ Merged | Agent-2 |
| {Task-C} | feature/{task-c} | `worktree/{task-c}/` | 🔄 In Progress | Agent-3 |
| {Task-D} | feature/{task-d} | `worktree/{task-d}/` | ⏳ Waiting | Agent-1 |

**Legend**: ⬚ Not Started / 🔄 In Progress / ✅ Complete/Merged / ⏳ Waiting for Dependencies / ❌ Blocked

---

## Directory Structure

```
project/
├── .parallel-dev/              # Parallel development management
│   ├── README.md               # This file
│   ├── merge-coordinator.md    # Instructions for merge coordinator
│   └── tasks/                  # Task instruction files
│       ├── {task-a}.md
│       ├── {task-b}.md
│       ├── {task-c}.md
│       └── {task-d}.md
├── worktree/                   # worktree directories
│   ├── {task-a}/
│   ├── {task-b}/
│   ├── {task-c}/
│   └── {task-d}/
└── ...
```

---

## Dependency Diagram

```
feature/{task-a}  ──────────────────────┐
                                        ↓
feature/{task-b}  ────────────────► feature/{task-d}
                                        ↑
feature/{task-c}  ──────────────────────┘
```

---

## Merge Order

```
Phase 1: Independent Tasks
  1. feature/{task-a}  ✅ Merged
  2. feature/{task-b}  ✅ Merged
  3. feature/{task-c}  🔄 Waiting for Completion

Phase 2: Dependent Tasks
  4. feature/{task-d}  ⏳ Waiting for Phase 1 Completion
```

See [merge-coordinator.md](merge-coordinator.md) for details.

---

## Instructions for Each Claude

### Worker Claude

1. Check your assigned task instruction file: `.parallel-dev/tasks/{branch-name}.md`
2. Work in the corresponding worktree: `worktree/{branch-name}/`
3. Update the status in the instruction file when complete
4. Also update the progress in this README

### Merge Coordinator

1. Follow the instructions in [merge-coordinator.md](merge-coordinator.md)
2. When a task completion is detected, merge according to the merge order
3. After merging, update this README and each task instruction file

---

## Update History

| Date/Time | Updated By | Content |
|-----------|------------|---------|
| YYYY-MM-DD HH:MM | {Agent/Human} | Initial creation |
| YYYY-MM-DD HH:MM | Agent-1 | {task-a} complete |
| YYYY-MM-DD HH:MM | Merge-Coordinator | {task-a} merge complete |

---

## Issues/Blockers

Record any current issues here:

| Date | Issue | Affected Tasks | Status |
|------|-------|----------------|--------|
| - | - | - | - |

---

## Completion Criteria

- [ ] All tasks merged
- [ ] Integration tests pass
- [ ] PR created and merged: `feature/{integration-branch}` → `main`
- [ ] Worktree cleanup complete
```

---

## Filling Guide

### When to Update Progress

- When starting a task: Change status to "In Progress"
- When task is complete: Change status to "Complete"
- When merge is complete: Change status to "Merged"

### Status Icons

| Icon | Meaning |
|------|---------|
| ⬚ | Not Started |
| 🔄 | In Progress |
| ✅ | Complete/Merged |
| ⏳ | Waiting for Dependencies |
| ❌ | Blocked (Issue Present) |

### Update History Granularity

Record only important events:
- Task completion
- Merge completion
- Blocker occurrence/resolution
- Plan changes
