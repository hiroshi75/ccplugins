# Merge Coordinator Instructions Template

Instructions template for Claude that specializes in merge coordination.

Filename: `.parallel-dev/merge-coordinator.md`

---

## Template

```markdown
# Merge Coordinator Instructions

## Role

This Claude is responsible for:
- **Launching worker Claude via `tmux new-window -n "{task-name}"`** (identify tasks by window name)
- Monitoring `.parallel-dev-signals/` for completion notifications (.done files)
- Monitoring `.parallel-dev-issues/` for problem reports and assigning owners
- **Committing worker Claude changes**
- **Merging the latest from the integration branch**
- **Running tests**
- **Merging to the integration branch**
- Managing merge order
- Creating new worktrees/branches and updating instructions as needed

**Important**: Worker Claude does NOT commit or push. The merge coordinator handles all git operations.

**Single Responsibility**: The merge coordinator **focuses exclusively on coordination, merging, and testing**, and does NOT perform implementation work. Implementation is delegated to worker Claude.

---

## Launching Worker Claude

**Important**: Worker Claude is launched by **executing `tmux new-window` command via the Bash tool**.
- **Do NOT use Task tool (sub-agent)**: Always use tmux commands to launch

Since this runs inside tmux, you can directly launch Claude Code in a separate window using `tmux new-window`.

### Tasks to Launch at Start

Launch tasks with no dependencies in parallel. **Execute the following commands via Bash tool**:

```bash
# Set PROJECT_ROOT (record current project root)
export PROJECT_ROOT=$(pwd)

# Task 1: work in worktree/recommendation-api (window name: recommendation-api)
tmux new-window -n "recommendation-api" "cd worktree/recommendation-api && PROJECT_ROOT=$PROJECT_ROOT claude 'Read ../../.parallel-dev/tasks/recommendation-api.md and implement. When complete, create a .done file in $PROJECT_ROOT/.parallel-dev-signals/ (create in parent project, not in worktree).'"

# Task 2: work in worktree/notification-api (window name: notification-api)
tmux new-window -n "notification-api" "cd worktree/notification-api && PROJECT_ROOT=$PROJECT_ROOT claude 'Read ../../.parallel-dev/tasks/notification-api.md and implement. When complete, create a .done file in $PROJECT_ROOT/.parallel-dev-signals/ (create in parent project, not in worktree).'"
```

**Window Identification Points**:
- `tmux new-window -n "task-name"`: Creates a new window and sets the window name
- Task names are displayed in the tmux window list, making switching easy

### Launching Dependent Tasks

Launch waiting tasks when their dependencies are merged:

```bash
tmux new-window -n "project-card-enhance" "cd worktree/project-card-enhance && PROJECT_ROOT=$PROJECT_ROOT claude 'Read ../../.parallel-dev/tasks/project-card-enhance.md and implement. Dependent task recommendation-api has been merged. When complete, create a .done file in $PROJECT_ROOT/.parallel-dev-signals/ (create in parent project, not in worktree).'"
```

---

## Completion Monitoring

After launching worker Claude, wait for completion.

### Monitoring Loop

Execute the following command via Bash tool (specify timeout: 600000ms):

```bash
# Wait for completion (5 second intervals, max 108 times = 9 minutes)
for i in {1..108}; do
  echo "=== Check $i/108: $(date) ==="

  # Check for completion notifications
  DONE_FILES=$(ls .parallel-dev-signals/*.done 2>/dev/null || true)
  if [ -n "$DONE_FILES" ]; then
    echo "Completion notification found: $DONE_FILES"
    break
  fi

  # Check for problem reports
  ISSUE_FILES=$(ls .parallel-dev-issues/*.md 2>/dev/null || true)
  if [ -n "$ISSUE_FILES" ]; then
    echo "Problem report found: $ISSUE_FILES"
    break
  fi

  sleep 5
done

# Check results
if [ -n "$DONE_FILES" ]; then
  echo "=== Completion Detected ==="
  cat $DONE_FILES
elif [ -n "$ISSUE_FILES" ]; then
  echo "=== Problem Detected ==="
  cat $ISSUE_FILES
else
  echo "=== 9 minutes elapsed, no completion notification ==="
  echo "Please run the monitoring loop again"
fi
```

- Exit the loop and start processing when completion or problem is detected
- If not complete within 9 minutes, run the monitoring loop again

### Directories to Monitor

```
project-root/
├── .parallel-dev-signals/     # Completion notifications (directly under project root)
│   ├── task-a.done
│   └── task-b.done
└── .parallel-dev-issues/      # Problem reports (directly under project root)
    └── task-c.md
```

**Note**: Monitor `.parallel-dev-signals/` and `.parallel-dev-issues/` directly under project root, NOT inside `.parallel-dev/`.

---

## Branch Information

| Item | Value |
|------|-------|
| Integration Branch | `feature/{integration-branch}` |
| Base Branch | `main` |
| Working Directory | Project root |

### Initial Setup (Run when starting parallel development)

```bash
# Push integration branch to remote (so worktrees can reference it)
git push -u origin feature/{integration-branch}
```

**Important**: Without this push, worktrees cannot reference `origin/feature/{integration-branch}`, causing merge errors.

---

## Task List and Dependencies

### Dependency Diagram

```
feature/{task-a}  ─────────────────────────────────┐
                                                   ↓
feature/{task-b}  ──────────────────────────► feature/{task-d}
                                                   ↑
feature/{task-c}  ─────────────────────────────────┘
```

### Task Status

| Branch | Assignee | Status | Dependencies | Merge Order |
|--------|----------|--------|--------------|-------------|
| feature/{task-a} | BE-1 | Not Complete | None | 1 |
| feature/{task-b} | BE-2 | Not Complete | None | 2 |
| feature/{task-c} | BE-1 | Not Complete | None | 3 |
| feature/{task-d} | FE-1 | Not Complete | task-a, task-b, task-c | 4 |

---

## Merge Order

### Determined Merge Order

Order based on dependencies and conflict risk:

```
Phase 1: Independent Tasks (Can be merged in parallel)
─────────────────────────────────────
1. feature/{task-a}  # No dependencies
2. feature/{task-b}  # No dependencies
3. feature/{task-c}  # No dependencies

Phase 2: Dependent Tasks
─────────────────────────────────────
4. feature/{task-d}  # Depends on task-a, b, c
```

### Rationale for Merge Order

| Order | Branch | Rationale |
|-------|--------|-----------|
| 1 | feature/{task-a} | Other tasks depend on it, can be completed independently |
| 2 | feature/{task-b} | Independent, limited change scope |
| 3 | feature/{task-c} | Independent |
| 4 | feature/{task-d} | Depends on all Phase 1 tasks |

---

## Integration Flow (Procedure after .done detection)

After detecting a .done file, perform integration with the following procedure.

### 1. Processing in Worker Worktree

```bash
# 1-1. Move to worker worktree
cd worktree/{branch-name}

# 1-2. Commit changes
git add .
git commit -m "feat: {branch-name} implementation"

# 1-3. Pull latest from integration branch
git fetch origin
git merge origin/feature/{integration-branch} --no-ff -m "Merge integration branch"

# 1-4. Resolve conflicts if any
# (For complex cases, request worker Claude)

# 1-5. Run tests
{test-command}
```

### 2. Branch Based on Test Results

**When tests pass:**
```bash
# 2a-1. Push
git push origin feature/{branch-name}

# 2a-2. Return to project root
cd ../..

# 2a-3. Merge to integration branch
git checkout feature/{integration-branch}
git pull origin feature/{integration-branch}
git merge origin/feature/{branch-name} --no-ff -m "Merge feature/{branch-name} into integration"
git push origin feature/{integration-branch}

# 2a-4. Update status
# - Update task instruction status to "Merged"
# - Update README.md progress
# - Notify dependent tasks
```

**When tests fail:**
```bash
# 2b-1. Delete existing .done file
rm .parallel-dev-signals/{branch-name}.done

# 2b-2. Create issue file for fix request
cat > .parallel-dev-issues/{branch-name}.md << 'EOF'
[Fix Request] {branch-name}

## Situation
Tests failed after merging integration branch.

## Error Details
{test error output}

## Action Required
1. Fix in worktree/{branch-name}/
2. After fix is complete, create .done file again

※ No commit needed.
EOF

# 2b-3. Restart worker Claude
tmux new-window -n "{branch-name}-fix" "cd worktree/{branch-name} && PROJECT_ROOT=$PROJECT_ROOT claude 'Read $PROJECT_ROOT/.parallel-dev-issues/{branch-name}.md and fix. When complete, create a .done file in $PROJECT_ROOT/.parallel-dev-signals/ (create in parent project, not in worktree).'"
```

### 3. When Conflicts Occur

1. **Minor conflicts**: Resolve manually and continue merge

2. **Complex conflicts**: Restart worker Claude and request resolution
```bash
# Record conflict details in issue
cat > .parallel-dev-issues/{branch-name}-conflict.md << 'EOF'
[Conflict Resolution Request] {branch-name}

## Situation
Conflicts occurred when merging integration branch.

## Conflicting Files
{list of conflicting files}

## Action Required
Please resolve the conflicts. Create .done file after resolution.
EOF

# Restart worker Claude
tmux new-window -n "{branch-name}-conflict" "cd worktree/{branch-name} && PROJECT_ROOT=$PROJECT_ROOT claude 'Read $PROJECT_ROOT/.parallel-dev-issues/{branch-name}-conflict.md and resolve conflicts. When complete, create a .done file in $PROJECT_ROOT/.parallel-dev-signals/ (create in parent project, not in worktree).'"
```

3. **Unresolvable**: Abort merge and report to human

---

## Status Update Rules

### Items to Check When .done is Detected

When a .done file is detected, check the following:

- [ ] There are uncommitted changes in worktree/{branch-name}/
- [ ] All dependent tasks have been merged (if there are dependencies)

**Note**: Worker Claude does NOT commit or push. Changes are in the worktree.

### Checking .done File

Check the contents of the completion report and verify there are no issues.

### Updates After Merge

After merge completion:

1. Update status in `.parallel-dev/tasks/{branch-name}.md` to "Merged"
2. Update progress in `.parallel-dev/README.md`
3. Update task status in `merge-coordinator.md`
4. **Notify dependent tasks of completion** (use template below)
5. Delete `.parallel-dev-signals/{branch-name}.done` (or move to processed/)

### Responsibility for Status Updates

| Update Target | Responsible | Timing |
|---------------|-------------|--------|
| .done file | Worker Claude | When implementation complete |
| git commit/push | Merge Coordinator | After .done detection |
| Task instruction status | Merge Coordinator | After merge, set to "Merged" |
| README.md progress | Merge Coordinator | After merge |
| Launching dependent tasks | Merge Coordinator | After dependency merge |

### Launching Dependent Tasks

If there are tasks that depend on the merged task, launch them:

```bash
# Launch dependent task since dependency has been merged
tmux new-window -n "{dependent-branch}" "cd worktree/{dependent-branch} && PROJECT_ROOT=$PROJECT_ROOT claude 'Read ../../.parallel-dev/tasks/{dependent-branch}.md and implement. Dependent task {merged-branch} has been merged. When complete, create a .done file in $PROJECT_ROOT/.parallel-dev-signals/ (create in parent project, not in worktree).'"
```

---

## Testing Policy

**Principle: Test in production-like conditions**

Run tests connecting to actual external APIs and databases, not mocks.

### Test Environment

| Item | Setting |
|------|---------|
| DATABASE_URL | {dev/staging DB connection} |
| External API Keys | {test API keys} |
| Other Secrets | Configured in `.env` |

**Note**: worktrees have `.env` copied, so production-equivalent connection info is available.

### Testing Before Each Merge (Production-Equivalent)

Run before merging each task:

```bash
# Run in worktree/{branch-name}/

# 1. Lint/type check (fast checks)
{lint-command}
{type-check-command}

# 2. Production-equivalent tests (with external API/DB connections)
# Environment variables loaded from .env
{test-command}
```

**On test failure**: Abort merge to integration branch and request worker Claude to fix.

### Testing After All Tasks Merged

After all tasks are merged to integration branch:

```bash
# Run in project root

# Full test (production-equivalent)
{full-test-command}

# E2E test (via browser/API)
{e2e-test-command}
```

### What to Verify in Tests

- [ ] Communication with external APIs works correctly
- [ ] Read/write to DB works correctly
- [ ] Authentication/authorization functions correctly
- [ ] Integration between multiple features works

### E2E Verification (dev-browser skill)

When merging tasks that include UI, use the dev-browser skill to operate the browser and perform **happy path verification** and **visual verification**.

**Procedure**:

```bash
# 1. Start dev server in worktree (background)
cd worktree/{branch-name}
{dev-server-command} &

# 2. Run dev-browser skill
```

Execute the following with dev-browser skill:

```
/dev-browser

# Browser operations
1. Navigate to http://localhost:{port}
2. Navigate to the relevant feature screen
3. Take screenshot
4. Execute the happy path flow (see below)
5. Take screenshot of result screen
```

#### Happy Path Verification

Simulate actual user operations to verify that main features work correctly.

**Happy path flows to verify (examples)**:

| Feature Type | Verification Flow |
|--------------|-------------------|
| Login feature | Enter correct credentials → Click login button → Verify redirect to dashboard |
| Form submission | Enter valid values in form → Click submit button → Verify success message appears |
| CRUD operations | Create new → Verify appears in list → Edit → Verify changes reflected → Delete → Verify removed from list |
| Search feature | Enter search keyword → Execute search → Verify expected results appear |
| Navigation | Click menu/link → Verify correct page navigation |
| Data display | Open page → Verify data fetched from API → Verify correctly rendered |

**Points for happy path verification**:

1. **Prioritize happy path**: First verify the most common success case
2. **End-to-end**: Verify the complete flow from start to finish
3. **Data persistence**: Verify that created/updated data is actually saved
4. **Screen transitions**: Verify correct navigation after operations
5. **Feedback**: Verify appropriate UI feedback like success messages and loading indicators

**Specific example of happy path verification**:

```
# Example: Happy path flow for user registration feature
1. Navigate to /register
2. Enter the following:
   - Username: testuser123
   - Email: test@example.com
   - Password: SecurePass123!
3. Click "Register" button
4. Verify:
   - "Registration complete" message appears
   - Redirected to login page or dashboard
   - Can log in with registered user
```

#### Visual Verification Points

| Check Item | Content |
|------------|---------|
| Layout | No broken layout, overflow, or overlap |
| Display content | Expected text and images are displayed |
| Error display | No unexpected error messages |
| Interaction | Buttons and links work correctly |
| Console | No errors in browser console |

**Tasks that require E2E verification**:

- Tasks that include frontend (UI)
- Tasks that affect screen transitions/navigation
- Tasks that change layout/styling
- Tasks that include form processing/data submission
- Tasks related to authentication/authorization

**Tasks that do NOT require E2E verification**:

- Backend API-only tasks (substitute with API tests)
- Batch processing/CLI tool tasks

---

## Final Merge (Integration Branch → main)

### Prerequisites

- [ ] All tasks merged
- [ ] Integration tests pass
- [ ] Code review complete

**Important**: Merging to main has significant impact, so get confirmation from human using AskUserQuestion tool:

```
"All tasks have been merged and integration tests pass.
May I proceed with merging to main branch?"
```

### Procedure (Execute after human approval)

```bash
# 1. Update main to latest
git checkout main
git pull origin main

# 2. Merge integration branch
git merge feature/{integration-branch} --no-ff

# 3. Final tests
{full-test-command}

# 4. Push (or create PR)
git push origin main
# or
gh pr create --base main --head feature/{integration-branch}
```

---

## Troubleshooting

### Common Problems and Solutions

| Problem | Solution |
|---------|----------|
| Tests fail after merge | Revert merge and investigate cause |
| Dependent task delayed | Check status with dependency task owner |
| Frequent conflicts | Request frequent rebases from each task |

### Escalation

Report to human in the following cases:

- Unresolvable conflicts
- Cannot identify cause of test failure
- Need to change dependencies

---

## Issue Handling

### When New Task Creation is Needed

When a new worktree/branch is needed to resolve an issue:

```bash
# 1. Create new worktree
BRANCH=fix-card-conflict
INDEX=5  # Next index
git worktree add worktree/$BRANCH -b feature/$BRANCH

# 2. Environment setup
cp .env worktree/$BRANCH/.env
cat > worktree/$BRANCH/.env.local << EOF
PORT=$((3000 + INDEX))
VITE_PORT=$((5173 + INDEX))
EOF
cd worktree/$BRANCH && uv sync && cd ../..  # or pnpm install

# 3. Create task instructions
# Create .parallel-dev/tasks/{new-branch}.md

# 4. Update README.md
# Add new task to task list

# 5. Update merge-coordinator.md (this file)
# Add new task to merge order

# 6. Update issue file
# Assign owner and record status
```

### Updating Issue Status

```bash
# Update owner and status in issue file
# .parallel-dev-issues/{task-name}.md

## Assignee
Agent-X (assigned on YYYY-MM-DD)

## Status
In Progress → Resolved
```
```

---

## Filling Guide

### Status Definitions

| Status | Meaning |
|--------|---------|
| Not Complete | In progress or not started |
| Complete | Implementation complete, waiting for merge |
| Merged | Merge to integration branch complete |

### How to Determine Merge Order

1. **Dependencies**: Merge tasks that others depend on first
2. **Change scope**: Merge wide-ranging changes first (reduces conflicts)
3. **Conflict risk**: Consider order of tasks that modify same files
4. **Completion order**: If none of the above apply, merge in completion order

---

## Rules

- **Always merge with `--no-ff`** (preserve merge commits)
- **Always run tests after merge**
- **Request conflict resolution from the task owner** (merge coordinator does not resolve)
- **Merge order: Dependencies > Change Scope > Completion Order**
