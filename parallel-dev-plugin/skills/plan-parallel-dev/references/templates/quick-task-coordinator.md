# Quick Task Coordinator Instruction Template

Instructions for the Claude that handles task reception, worktree setup, and merging in Quick Task Mode (Mode B).
Unlike merge-coordinator.md in Initial Parallel Development Mode (Mode A), this processes tasks on-demand without a plan document.

**Important**: Always create `.parallel-dev/quick-session-{timestamp}.md` at the start of a session.
See [quick-session-template.md](quick-session-template.md) for details.

Reference template: `.parallel-dev/quick-task-coordinator.md`

---

## Template

```markdown
# Quick Task Coordinator Instructions

## Role

This Claude handles the following in Quick Task Mode (Mode B):

### Task Reception
- Accept task requests from users
- Determine task name (kebab-case)
- Create worktree and branch
- Generate simple task instructions

### Starting Worker Claude
- **Execute `tmux new-window -n "{task-name}"` using the Bash tool to start**
- Pass PROJECT_ROOT environment variable
- Identify tasks by window name

### Completion Monitoring & Merging
- Monitor `.parallel-dev-signals/*.done`
- Commit, test, and merge completed tasks
- Clean up worktrees

---

## Task Reception Flow

### 1. Receiving Task Requests

Receive requests like the following from users:
- "Fix XX in parallel"
- "Do YY with worktree"
- "Add parallel task: XX"

### 2. Determining Task Name

Determine an appropriate task name (kebab-case) from the request content:

| Work Type | Prefix | Example |
|-----------|--------|---------|
| Bug fix | `fix-` | `fix-login-validation` |
| Feature addition | `add-` / `feature-` | `add-logout-button` |
| Improvement | `improve-` | `improve-search-perf` |
| Refactoring | `refactor-` | `refactor-auth` |

### 3. Create Session File (First Time Only)

At the start of a quick session, create a unique session file:

```bash
# Generate session ID (timestamp)
SESSION_ID=$(date +%Y%m%d%H%M%S)
SESSION_FILE=".parallel-dev/quick-session-${SESSION_ID}.md"

mkdir -p .parallel-dev

# Create session file
cat > "$SESSION_FILE" << EOF
# Quick Session: ${SESSION_ID}

## Session Information

| Item | Value |
|------|-------|
| Start Time | $(date '+%Y-%m-%d %H:%M') |
| Base Branch | main |
| Status | In Progress |

---

## Task List

| Task Name | Branch | Request Content | Status |
|-----------|--------|-----------------|--------|

---

## Started Worker Claudes

| Task Name | Pane Name | Status |
|-----------|-----------|--------|

---

## Completion & Merge History

---

## Session End Checklist

- [ ] All tasks merged
- [ ] All worker claudes terminated
- [ ] Worktrees cleaned up
- [ ] Branches deleted
EOF

echo "Session file: $SESSION_FILE"
```

**Note**: Session files are uniquely identified by timestamp to avoid conflicts even when multiple quick sessions run in parallel.

### 4. Task Initial Setup

```bash
# Variable settings
TASK_NAME="{task-name}"
BRANCH="fix/${TASK_NAME}"  # Or feature/ as appropriate
BASE_BRANCH="main"  # Or specified branch

# Create directories (first time only)
mkdir -p .parallel-dev/tasks
mkdir -p .parallel-dev-signals
mkdir -p .parallel-dev-issues

# Add to .gitignore (if not already added)
grep -q ".parallel-dev-signals/" .gitignore 2>/dev/null || echo ".parallel-dev-signals/" >> .gitignore
grep -q ".parallel-dev-issues/" .gitignore 2>/dev/null || echo ".parallel-dev-issues/" >> .gitignore
grep -q "worktree/" .gitignore 2>/dev/null || echo "worktree/" >> .gitignore

# Create worktree
git worktree add worktree/${TASK_NAME} -b ${BRANCH}

# Environment setup
cp .env worktree/${TASK_NAME}/.env 2>/dev/null || true
cd worktree/${TASK_NAME}

# Install dependencies
if [ -f "pyproject.toml" ]; then
  uv sync
elif [ -f "package.json" ]; then
  pnpm install
fi

cd ../..
```

### 5. Generate Task Instructions

Create `.parallel-dev/tasks/${TASK_NAME}.md` and also add to the "Task List" in the session file:

```markdown
# Quick Task: ${TASK_NAME}

## Basic Information

| Item | Content |
|------|---------|
| Request Content | {user's request} |
| Branch | ${BRANCH} |
| worktree | worktree/${TASK_NAME}/ |
| Base Branch | ${BASE_BRANCH} |
| Created At | $(date '+%Y-%m-%d %H:%M') |
| Status | In Progress |

## Request Content

{Include request content as-is}

## Work Procedure

1. Understand the request and identify related files
2. Implement the fix
3. Verify locally
4. Create .done file

## Rules

- Do not commit
- Do not push
- When complete, create .done file in $PROJECT_ROOT/.parallel-dev-signals/ (create in parent project, not in worktree)
```

### 6. Starting Worker Claude

After starting, update "Started Worker Claudes" in the session file.

```bash
export PROJECT_ROOT=$(pwd)

# Start worker Claude in a new window
tmux new-window -n "${TASK_NAME}" "cd worktree/${TASK_NAME} && PROJECT_ROOT=$PROJECT_ROOT claude 'Read ../../.parallel-dev/tasks/${TASK_NAME}.md and implement it. When complete, create \$PROJECT_ROOT/.parallel-dev-signals/${TASK_NAME}.done (create in parent project, not in worktree).'"
```

---

## Completion Monitoring

### Monitoring Loop

```bash
# Monitor at 5-second intervals (max 9 minutes)
for i in {1..108}; do
  echo "=== Check $i/108: $(date) ==="

  # Check for completion notifications
  DONE_FILES=$(ls .parallel-dev-signals/*.done 2>/dev/null || true)
  if [ -n "$DONE_FILES" ]; then
    echo "Completion notification found: $DONE_FILES"
    break
  fi

  # Check for issue reports
  ISSUE_FILES=$(ls .parallel-dev-issues/*.md 2>/dev/null || true)
  if [ -n "$ISSUE_FILES" ]; then
    echo "Issue report found: $ISSUE_FILES"
    break
  fi

  sleep 5
done
```

### Monitoring Targets

```
project-root/
├── .parallel-dev-signals/     # Completion notifications
│   └── {task-name}.done
└── .parallel-dev-issues/      # Issue reports
    └── {task-name}.md
```

---

## Merge Flow

### Procedure After .done Detection

```bash
TASK_NAME="{completed task name}"
BRANCH="fix/${TASK_NAME}"  # Or feature/
BASE_BRANCH="main"

# 1. Move to worktree and commit
cd worktree/${TASK_NAME}
git add .
git commit -m "fix: ${TASK_NAME}"  # Or feat:

# 2. Incorporate latest from base branch
git fetch origin
git merge origin/${BASE_BRANCH} --no-ff -m "Merge ${BASE_BRANCH}"

# 3. Resolve conflicts if any

# 4. Run tests
{test-command}

# 5. If tests pass -> Push
git push origin ${BRANCH}

# 6. Return to project root and merge
cd ../..
git checkout ${BASE_BRANCH}
git pull origin ${BASE_BRANCH}
git merge origin/${BRANCH} --no-ff -m "Merge ${BRANCH}"
git push origin ${BASE_BRANCH}

# 7. Cleanup
rm .parallel-dev-signals/${TASK_NAME}.done
git worktree remove worktree/${TASK_NAME}
git branch -d ${BRANCH}

# 8. Terminate worker claude
tmux send-keys -t "${TASK_NAME}" C-c C-c

# 9. Update status
# - Change status in .parallel-dev/tasks/${TASK_NAME}.md to "Merged"
# - Update "Task List" and "Completion & Merge History" in session file (.parallel-dev/quick-session-*.md)
```

### On Test Failure

```bash
# Delete .done
rm .parallel-dev-signals/${TASK_NAME}.done

# Create fix request
cat > .parallel-dev-issues/${TASK_NAME}.md << 'EOF'
[Fix Request] ${TASK_NAME}

## Situation
Tests failed.

## Error Content
{error output}

## Request
Fix in worktree/${TASK_NAME}/ and create .done file again.
EOF

# Restart worker Claude
tmux new-window -n "${TASK_NAME}-fix" "cd worktree/${TASK_NAME} && PROJECT_ROOT=$PROJECT_ROOT claude 'Read $PROJECT_ROOT/.parallel-dev-issues/${TASK_NAME}.md and fix the issues.'"
```

### When Choosing to Create PR

When creating a PR instead of direct merge:

```bash
# Create PR after push
git push origin ${BRANCH}
gh pr create --base ${BASE_BRANCH} --head ${BRANCH} \
  --title "fix: ${TASK_NAME}" \
  --body "## Summary
{request content}

## Changes
{excerpt from .done file content}"
```

---

## Parallel Processing of Multiple Tasks

### Batch Setup

```bash
TASKS=("fix-login-validation" "add-logout-button" "update-header")
export PROJECT_ROOT=$(pwd)

for TASK in "${TASKS[@]}"; do
  # Create worktree
  git worktree add worktree/${TASK} -b fix/${TASK}
  cp .env worktree/${TASK}/.env 2>/dev/null || true

  # Generate instructions (modify content for each task)
  # ...

  # Start worker Claude in a new window
  tmux new-window -n "${TASK}" "cd worktree/${TASK} && PROJECT_ROOT=$PROJECT_ROOT claude 'Read ../../.parallel-dev/tasks/${TASK}.md and implement it.'"
done
```

### Merge as Completed

When multiple tasks are running in parallel, merge them as they complete.
Order doesn't matter if there are no dependencies.

---

## Issue Handling

### Checking Issue Reports

Check `.parallel-dev-issues/${TASK_NAME}.md` and respond accordingly:

1. **Minor issues**: Request fix from worker Claude
2. **Blocking issues**: Report to human (AskUserQuestion)
3. **Impact on other tasks**: Temporarily pause related tasks

### When New Task is Required

When a new task is needed to solve the issue:

```bash
# Add as new task
NEW_TASK="fix-${TASK_NAME}-related"
git worktree add worktree/${NEW_TASK} -b fix/${NEW_TASK}
# ... setup and start
```

---

## Rules

- **Always merge with `--no-ff`**: Leave merge commits
- **Always run tests after merge**: Request fix if tests fail
- **Start with `tmux new-window -n "{task-name}"`**: Identify tasks by window name
- **Do not use Task tool (sub-agents)**: Start with tmux
- **Clean up when complete**: Delete worktree to free resources

---

## Differences from Initial Parallel Development Mode (A)

| Aspect | Mode A (merge-coordinator) | Mode B (quick-session-{timestamp}) |
|--------|---------------------------|--------------------------------|
| Coordinator file | `.parallel-dev/merge-coordinator.md` (fixed) | `.parallel-dev/quick-session-{timestamp}.md` (unique) |
| Parallel sessions | Not possible (1 file) | Possible (identified by timestamp) |
| Plan document | References PLAN.md | None (starts immediately) |
| Task list | All tasks known in advance | Added as needed |
| Dependencies | Explicitly managed | Basically independent tasks |
| Merge target | Integration branch | Direct to main (or specified branch) |
| After completion | Merge to main when all tasks complete | Merge immediately when each task completes |
```

---

## Execution Example

### Example Dialogue with User

```
User: Fix the login screen validation in parallel

Claude: Creating a quick task.

Task name: fix-login-validation
Branch: fix/fix-login-validation

Creating worktree...
✅ Created worktree/fix-login-validation/
✅ Environment setup complete
✅ Generated task instructions

Starting worker Claude...

(Executing tmux new-window)

Worker Claude started.
Monitoring for completion notification...

---

(A few minutes later)

✅ fix-login-validation completed.

Committing and merging changes...
✅ Tests: Passed
✅ Merged to main
✅ Cleanup complete

Fix is complete.
```
