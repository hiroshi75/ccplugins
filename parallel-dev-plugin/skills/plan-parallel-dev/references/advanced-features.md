# Advanced Features

Guide for optional features and advanced techniques in parallel development.

---

## Phased Task Design

**Normal Flow**: Dependent tasks start after dependency is merged. Phase separation is not needed in this case.

**When to Use Phase Separation**: When you want to maximize parallelism by starting dependent tasks from the beginning.

### Phase Separation Patterns

**Example: Frontend depends on backend API but wants to start early**

```markdown
## Phase 1: UI Implementation (Before API Complete)

- [ ] Complete UI with mock API
- [ ] Create .done file ({branch-name}-phase1.done)

## Phase 2: API Integration (After Dependent API Complete)

- [ ] Start when dependency is merged
- [ ] Replace mock API with production API
- [ ] Create .done file ({branch-name}.done)
```

### Criteria for Phase Separation

Consider phase separation only when **all** of the following are met:

- Waiting for dependent task completion significantly reduces parallelism
- Early development with mock/stub is possible
- Phase 1 and Phase 2 work can be clearly separated

**Normally, starting after dependency merge is simpler than using phase separation.**

---

## Dependency Task Launch

Merge coordinator launches dependent task in tmux after merging dependency task:

```bash
# Launch dependent task since dependency is merged
# Pass PROJECT_ROOT to communicate .done file creation location
tmux split-window -h "cd worktree/{dependent-branch} && PROJECT_ROOT=$PROJECT_ROOT claude 'Please read ../../.parallel-dev/tasks/{dependent-branch}.md and implement. Dependency task {dependency-branch} is already merged. Create .done file when complete.'"
# Set task name to pane (easier to identify which pane is which task)
tmux select-pane -T "{dependent-branch}"
```

---

## Timeline Visualization

When communicating timeline to user, show visually in ASCII art format:

```
Day 1                Day 2                Day 3
────────────────────────────────────────────────
BE-1  ████████████████████████████  Review
      BE-01: API impl (2 days)       ↓Complete

FE-1  ████████████████  ████████████████████████
      FE-01: UI (1 day)  FE-02: Integration (1 day)
                         ↑ After BE-01 complete
```

---

## Output Template

### Plan Document (Communicate to User + Save File)

Communicate plan content directly to user while also saving to `.parallel-dev/PLAN.md`.
Structure reference: [templates/parallel-dev-template.md](templates/parallel-dev-template.md)

### Main Sections

1. Overview and Goals
2. Claude/Role Definition
3. Branch Strategy
4. Task List (with task names and assignees)
5. Parallel Development Timeline
6. Dependency Matrix
7. Merge Order
8. Each Task Detailed Specification
9. Definition of Done
10. Risk Management

### Claude Instruction Documents (Create as Files)

Separate from plan document, create instruction documents for each Claude as files in `.parallel-dev/`:

| Template | Output Destination | Purpose |
|-------------|--------|------|
| [parallel-dev-readme.md](templates/parallel-dev-readme.md) | `.parallel-dev/README.md` | Overall progress management |
| [merge-coordinator.md](templates/merge-coordinator.md) | `.parallel-dev/merge-coordinator.md` | For merge coordinator |
| [task-instruction.md](templates/task-instruction.md) | `.parallel-dev/tasks/*.md` | For each task |

---

## Claude Code Launch Procedure

After plan creation, tell user to execute following tmux command:

```bash
# Launch merge coordinator at project root (execute within tmux session)
export PROJECT_ROOT=$(pwd)
tmux split-window -h "cd $PROJECT_ROOT && claude 'Read .parallel-dev/merge-coordinator.md and start parallel development'"
```

**Note**: Worker Claude is launched by merge coordinator with `tmux split-window`. Humans don't need to launch individually.

---

## Asking Clarifying Questions

Items to confirm before creating plan:

1. **Development Target**: What features/improvements to implement
2. **Tech Stack**: Technology selection for BE/FE/Infrastructure
3. **Number of Developers**: Maximum how many can develop
4. **Existing Materials**: Presence of PRD, design docs, improvement proposals, etc.
5. **Constraints**: Deadlines, external dependency factors, etc.
6. **Test Commands**: Test commands to run after merge (e.g., `uv run pytest tests/ -v`)
7. **Test Environment**: Environment for external API/DB connection (dev/staging)
