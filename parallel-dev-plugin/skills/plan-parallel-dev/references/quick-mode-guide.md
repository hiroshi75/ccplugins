# Quick Task Mode (Mode B) Operations Guide

In quick task mode, immediately create git worktree and start tasks without a plan document.
Main differences from initial parallel development mode (Mode A):

## Differences Between Mode A and Mode B

| Aspect            | Initial Parallel Dev (A) | Quick Task (B)                             |
| ----------------- | ------------------------ | ------------------------------------------ |
| Starting Point    | Start from plan creation | Start immediately on request               |
| Coordinator File  | `.parallel-dev/merge-coordinator.md` (fixed) | `.parallel-dev/quick-session-{timestamp}.md` (unique) |
| Multiple Concurrent Sessions | Not possible | Possible (identified by timestamp) |
| Worktree Creation | Create multiple at once  | Create on-demand                           |
| Integration Branch | Required                | Not required but create work branch (merge directly to main) |
| Plan Document     | Create PLAN.md           | Don't create                               |
| Merge Target      | Integration branch → main | Directly to main (or specified branch)    |
| Cleanup           | Batch after all tasks    | Immediately after each task                |

## Create Session File

When starting quick session, create unique session file.

Detailed template: [templates/quick-session-template.md](templates/quick-session-template.md)

**Important**: Session files are uniquely identified by timestamp to avoid conflicts even when multiple quick sessions run in parallel.

## Create Worktree for Quick Task

Use `scripts/setup-worktree.sh`:

```bash
# Bug fix (fix/ prefix)
./scripts/setup-worktree.sh fix-login-validation "" "" fix

# Feature addition (feature/ prefix, default)
./scripts/setup-worktree.sh add-logout-button

# Specify ports
./scripts/setup-worktree.sh fix-login-validation 3001 5174 fix
```

**Note**: On first execution, `.parallel-dev/`, `.parallel-dev-signals/`, `.parallel-dev-issues/` directories and `.gitignore` entries are automatically created.

## Quick Task Directory Structure

```
project/
├── .parallel-dev/                    # Task management (added on first creation)
│   ├── quick-session-20250105143022.md  # Session file (unique)
│   └── tasks/
│       └── fix-login-validation.md   # Simple task instructions
├── .parallel-dev-signals/            # Completion notifications (.gitignore)
│   └── fix-login-validation.done
├── .parallel-dev-issues/             # Issue reports (.gitignore)
│   └── fix-login-validation.md
└── worktree/                         # Worktrees (.gitignore)
    └── fix-login-validation/         # fix/fix-login-validation branch
```

## Launch Worker Claude

Use `scripts/start-worker.sh`:

```bash
./scripts/start-worker.sh fix-login-validation
```

**Prerequisite**: Execute within tmux session.

## Merge and Cleanup After Completion

In quick task mode, merge and cleanup immediately after each task:

1. **Commit, merge, push in worktree**
   ```bash
   cd worktree/fix-login-validation
   git add . && git commit -m "fix: fix-login-validation"
   git fetch origin && git merge origin/main --no-ff
   # Run tests
   git push origin fix/fix-login-validation
   ```

2. **Merge to base branch**
   ```bash
   cd ../..
   git checkout main && git pull origin main
   git merge origin/fix/fix-login-validation --no-ff
   git push origin main
   ```

3. **Cleanup**
   ```bash
   ./scripts/stop-worker.sh fix-login-validation
   ./scripts/cleanup-parallel-dev.sh --force  # Or individually remove worktree
   ```

4. **Update session file** - Change task status to "merged"

## Parallel Execution of Multiple Quick Tasks

When requested multiple tasks simultaneously, execute each script in sequence:

```bash
# 1. Setup worktree for each task
./scripts/setup-worktree.sh fix-login-validation "" "" fix
./scripts/setup-worktree.sh add-logout-button
./scripts/setup-worktree.sh update-header-style

# 2. Create instructions for each task (see templates)
# → templates/quick-task-template.md

# 3. Launch worker Claude
./scripts/start-worker.sh fix-login-validation
./scripts/start-worker.sh add-logout-button
./scripts/start-worker.sh update-header-style

# 4. Adjust layout
tmux select-layout tiled
```

Instruction template: [templates/quick-task-template.md](templates/quick-task-template.md)

## Port Assignment for Quick Tasks

`scripts/setup-worktree.sh` auto-assigns ports. To manually specify:

```bash
./scripts/setup-worktree.sh fix-login-validation 3001 5174 fix
```

Port assignment rules → [worktree-guide.md "Port Number Assignment"](worktree-guide.md#port-number-assignment)

## Templates

Templates for quick task mode:

- [templates/quick-session-template.md](templates/quick-session-template.md) - Session file (required)
- [templates/quick-task-template.md](templates/quick-task-template.md) - Simple task instructions
- [templates/quick-task-coordinator.md](templates/quick-task-coordinator.md) - Task reception and merge coordinator
