# Parallel Development Guide with Git Worktree

Git worktree allows checking out multiple branches simultaneously from a single repository for parallel development.

## Basic Commands

### Creating worktree

```bash
# Check out existing branch to new directory
git worktree add <path> <branch>

# Create and check out new branch
git worktree add <path> -b <new-branch>

# Example: Check out feature/api-a branch to worktree/api-a
git worktree add worktree/api-a -b feature/api-a
```

### List worktrees

```bash
git worktree list
```

### Remove worktree

```bash
# Delete directory first
rm -rf <path>

# Clean up worktree
git worktree prune
```

## Parallel Development Setup Example

### 1. Create Integration Branch

```bash
# Create integration branch from main
git checkout -b feature/ui-improvements main
git push -u origin feature/ui-improvements
```

### 2. Create Worktrees for Each Feature Branch

```bash
# Execute at project root
cd /path/to/project

# Add worktree directory to .gitignore
echo "worktree/" >> .gitignore

# Create worktree for each feature branch
# Directory name = branch name (without feature/ prefix)
git worktree add worktree/recommendation-api -b feature/recommendation-api
git worktree add worktree/notification-api -b feature/notification-api
git worktree add worktree/project-card-enhance -b feature/project-card-enhance
git worktree add worktree/search-filter -b feature/search-filter
```

### 3. Directory Structure

```
project/                              # Project root (main or integration branch)
├── src/
├── ...
├── .gitignore                        # Exclude worktree/, .parallel-dev/
├── .parallel-dev/                    # Parallel dev instructions (see below)
│   ├── README.md
│   ├── merge-coordinator.md
│   └── tasks/
│       ├── recommendation-api.md
│       └── ...
└── worktree/                         # Worktree directory
    ├── recommendation-api/           # feature/recommendation-api branch
    ├── notification-api/             # feature/notification-api branch
    ├── project-card-enhance/         # feature/project-card-enhance branch
    └── search-filter/                # feature/search-filter branch
```

### 4. Place Claude Instruction Documents

For parallel development with Claude, place instruction documents for each Claude in `.parallel-dev/`.

```
.parallel-dev/
├── README.md                 # Overall overview and progress summary
├── merge-coordinator.md      # Instructions for merge coordinator
└── tasks/                    # Instructions for each task
    ├── recommendation-api.md # Work instructions for worktree/recommendation-api/
    ├── notification-api.md
    ├── project-card-enhance.md
    └── search-filter.md
```

**File Correspondence**:

| Instruction Document                        | Worktree                       | Branch                       |
| ------------------------------------------- | ------------------------------ | ---------------------------- |
| `.parallel-dev/tasks/recommendation-api.md` | `worktree/recommendation-api/` | `feature/recommendation-api` |
| `.parallel-dev/tasks/notification-api.md`   | `worktree/notification-api/`   | `feature/notification-api`   |

**Each File's Role**:

| File                   | Target              | Content                                 |
| ---------------------- | ------------------- | --------------------------------------- |
| `README.md`            | All Claude & Humans | Overall progress, task list, dependencies |
| `merge-coordinator.md` | Merge Coordinator   | Merge order, conflict resolution policy |
| `tasks/*.md`           | Worker Claude       | Implementation spec, dependencies, completion criteria |

See templates:

- [templates/parallel-dev-readme.md](templates/parallel-dev-readme.md)
- [templates/merge-coordinator.md](templates/merge-coordinator.md)
- [templates/task-instruction.md](templates/task-instruction.md)

### 5. Environment Setup for Worktree

After creating worktree, prepare development environment in each directory.

#### Install Dependencies

```bash
# For Python (uv)
cd worktree/recommendation-api
uv sync

# For Node.js (pnpm)
cd worktree/project-card-enhance
pnpm install

# For Node.js (npm)
npm install
```

#### Setup Environment Variables

Copy `.env` (secrets like API keys) from project root to each worktree,
and override non-secrets like port numbers with `.env.local`.

```bash
# Copy .env (secrets)
cp .env worktree/recommendation-api/.env

# Create .env.local (port numbers, etc.)
cat > worktree/recommendation-api/.env.local << 'EOF'
PORT=3001
VITE_PORT=5174
EOF
```

#### Port Number Assignment

Assign different ports to each worktree to avoid dev server conflicts:

| Worktree             | Backend Port | Frontend Port |
| -------------------- | ------------ | ------------- |
| (Project Root)       | 3000         | 5173          |
| recommendation-api   | 3001         | 5174          |
| notification-api     | 3002         | 5175          |
| project-card-enhance | 3003         | 5176          |
| search-filter        | 3004         | 5177          |

#### Automate Setup

Use `scripts/setup-worktree.sh`:

```bash
# Basic usage (auto port assignment)
./scripts/setup-worktree.sh recommendation-api

# Specify ports
./scripts/setup-worktree.sh recommendation-api 3001 5174

# Create branch with fix/ prefix
./scripts/setup-worktree.sh login-bug 3001 5174 fix
```

**Important**: `PROJECT_ROOT` is needed to reference parent project root from worktree.
Used for path resolution to `.parallel-dev-signals/` and `.parallel-dev-issues/`.

## Workflow

### Role Division

| Role                                | Worker Claude | Merge Coordinator |
| ----------------------------------- | ------------- | ----------------- |
| Code implementation                 | ✅            | -                 |
| Create .done file                   | ✅            | -                 |
| git commit                          | -             | ✅                |
| git fetch/merge (integration branch)| -             | ✅                |
| Run tests                           | -             | ✅                |
| git push                            | -             | ✅                |
| Merge to integration branch         | -             | ✅                |

**Design Philosophy**: Worker Claude focuses on writing code. Only merge coordinator manages merge order.

### Work in Each Worktree

```bash
# Navigate to target worktree directory
cd worktree/recommendation-api

# Implement code (don't git commit / git push)
# ... implementation work ...

# Verify locally
# uv run pytest / pnpm test, etc.
```

**Important**: Do NOT git commit / git push. Focus on writing code.

### Completion Notification (.done File)

After implementation, create completion notification file in project root's `.parallel-dev-signals/`.
**No commit needed**.

Use `scripts/create-done-file.sh`:

```bash
# Execute within worktree
cd worktree/recommendation-api
../../scripts/create-done-file.sh recommendation-api "API endpoint implementation complete"
```

Merge coordinator detects this file and performs:

1. Navigate to worktree and commit
2. Merge integration branch
3. Run tests
4. Push
5. Merge to integration branch

### Error/Blocked Handling

When issues arise preventing work continuation, record in project root's `.parallel-dev-issues/`.

Use `scripts/create-issue-file.sh`:

```bash
# Execute within worktree
cd worktree/recommendation-api
../../scripts/create-issue-file.sh recommendation-api "Build error"
# → Edit details in editor
```

**Merge Coordinator Response:**

1. Monitor `.parallel-dev-issues/`
2. Review issue content and assign responsibility
3. Create new worktree/branch if needed

### Merge to Integration Branch

```bash
# Return to project root
cd ../..

# Check out integration branch
git checkout feature/ui-improvements

# Merge feature branches (pay attention to order, see below)
git merge feature/recommendation-api
git merge feature/notification-api
```

### Determining Merge Order

Order matters when merging multiple branches to integration branch.

**Criteria for Merge Order:**

| Priority | Criteria               | Description                              |
| -------- | ---------------------- | ---------------------------------------- |
| 1        | **Dependencies**       | Merge branches that others depend on first |
| 2        | **Change Scope**       | Merge wide-ranging changes first, adjust with smaller changes |
| 3        | **Conflict Risk**      | Consider order between branches changing same files |
| 4        | **Completion Order**   | If none of above apply, use completion order |

**Dependency Example:**

```
feature/recommendation-api  ← Merge first (provides API)
       ↓
feature/project-card-enhance  ← Merge later (UI using the API)
```

**Merge Order Plan Example:**

```
Integration branch: feature/ui-improvements

Merge order:
1. feature/recommendation-api   # Others depend on this
2. feature/notification-api     # Independent, can merge anytime
3. feature/project-card-enhance # Depends on recommendation-api
4. feature/search-filter        # Independent, OK to be last
```

**When Dependency Branch Not Yet Merged:**

Don't start dependent task until dependency task is merged to integration branch.

**Important**: Don't directly pull dependency branch. Always pull through integration branch.

### Pull Integration Branch Changes

Merge coordinator pulls integration branch.
Worker Claude waits for dependency task completion notification, then starts Phase 2 implementation.

**Merge Coordinator Steps:**

```bash
# In target worktree
cd worktree/project-card-enhance

# Commit changes (if not committed)
git add .
git commit -m "feat: project-card-enhance implementation"

# Merge integration branch
git fetch origin
git merge origin/feature/ui-improvements --no-ff
```

## Rules

→ **See [SKILL.md Rules section](../SKILL.md#rules-common-to-all-claude)**

## Notes

### Same Branch Cannot Be Checked Out in Multiple Worktrees

```bash
# This will error
git worktree add worktree/api-a-copy feature/api-a
# fatal: 'feature/api-a' is already checked out at 'worktree/api-a'
```

### Handling .git Directory

Worktree directory has `.git` file (not directory) referencing original repository.

```bash
cat worktree/recommendation-api/.git
# gitdir: /path/to/project/.git/worktrees/recommendation-api
```

### IDE/Editor Settings

Open each worktree directory as separate project. For VSCode:

```bash
code worktree/recommendation-api
```

## Troubleshooting

### If Worktree Is Broken

```bash
# Force remove
git worktree remove --force <path>

# Or
rm -rf <path>
git worktree prune
```

### If Locked

```bash
# Unlock
git worktree unlock <path>
```

### If Worktree List Is Stale

```bash
# Clean up
git worktree prune
```

## Parallel Development in Claude Code

For parallel development with multiple worktrees in Claude Code:

1. **Execute within tmux session** (required to launch worker Claude in separate pane)
2. **Human starts only merge coordinator with `scripts/start-coordinator.sh`**
3. **Merge coordinator launches/manages worker Claude with `scripts/start-worker.sh`**
4. **Don't use Task tool (sub-agent)**

```bash
# Launch merge coordinator (execute within tmux session)
./scripts/start-coordinator.sh

# Launch worker Claude (merge coordinator executes)
./scripts/start-worker.sh recommendation-api
./scripts/start-worker.sh notification-api

# After merge complete, terminate worker Claude
./scripts/stop-worker.sh recommendation-api
```

## Cleanup After Parallel Development

After all tasks complete and integration branch merges to main, perform cleanup.

### Cleanup Conditions

All of the following must be met:

- [ ] All tasks merged
- [ ] Integration branch merged to main
- [ ] Integration tests pass
- [ ] No unresolved issues in `.parallel-dev-issues/`

### Execute Cleanup

Use `scripts/cleanup-parallel-dev.sh`:

```bash
# Cleanup with confirmation
./scripts/cleanup-parallel-dev.sh

# Cleanup without confirmation
./scripts/cleanup-parallel-dev.sh --force
```

**Note**: Delete branches manually:

```bash
git branch -d feature/recommendation-api
git branch -d feature/notification-api
```

---

## Worktree Operations in Quick Task Mode (Mode B)

For worktree operations in quick task mode, see dedicated guide:

→ **[quick-mode-guide.md](quick-mode-guide.md)** - Quick Task Mode Operations Guide

Main templates for quick task mode:

- [templates/quick-session-template.md](templates/quick-session-template.md) - Session file (required)
- [templates/quick-task-template.md](templates/quick-task-template.md) - Simple task instructions
- [templates/quick-task-coordinator.md](templates/quick-task-coordinator.md) - Task reception and merge coordinator
