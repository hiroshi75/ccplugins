# Quick Session Coordinator Template

Session-specific coordinator file used in Quick Task Mode (Mode B).
Created with a unique filename for each session, preventing conflicts when multiple quick sessions run in parallel.

Filename: `.parallel-dev/quick-session-{YYYYMMDDHHmmss}.md`

Examples:
- `.parallel-dev/quick-session-20250105143022.md`
- `.parallel-dev/quick-session-20250105150530.md`

---

## Filename Generation

```bash
# Generate unique filename with timestamp
SESSION_FILE=".parallel-dev/quick-session-$(date +%Y%m%d%H%M%S).md"
echo "Session file: $SESSION_FILE"
```

---

## Template

```markdown
# Quick Session: {YYYYMMDDHHmmss}

## Session Information

| Item | Value |
|------|-------|
| Start Time | {YYYY-MM-DD HH:mm} |
| Base Branch | main |
| Status | In Progress / Completed |

---

## Task List

| Task Name | Branch | Request Details | Status |
|-----------|--------|-----------------|--------|
| {task-1} | fix/{task-1} | {request details} | Working / Merged |
| {task-2} | feature/{task-2} | {request details} | Working / Merged |

---

## Started Worker Claude Instances

| Task Name | Window Name | Start Command | Status |
|-----------|-------------|---------------|--------|
| {task-1} | {task-1} | `tmux new-window -n "{task-1}" "cd worktree/{task-1} && ..."` | Started / Finished |

---

## Completion & Merge History

### {task-1} (Merged at {HH:mm})

- Changes: {list of changed files}
- Test Results: Passed
- Commit: {commit-hash}

---

## Session End Checklist

- [ ] All tasks merged
- [ ] All worker claude instances terminated (`tmux send-keys -t "{task-name}" C-c C-c`)
- [ ] Worktree cleaned up
- [ ] Branches deleted
```

---

## Usage Instructions

### 1. At Session Start

```bash
# 1-1. Create session file
SESSION_ID=$(date +%Y%m%d%H%M%S)
SESSION_FILE=".parallel-dev/quick-session-${SESSION_ID}.md"

mkdir -p .parallel-dev

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

| Task Name | Branch | Request Details | Status |
|-----------|--------|-----------------|--------|

---

## Started Worker Claude Instances

| Task Name | Window Name | Start Command | Status |
|-----------|-------------|---------------|--------|

---

## Completion & Merge History

---

## Session End Checklist

- [ ] All tasks merged
- [ ] All worker claude instances terminated
- [ ] Worktree cleaned up
- [ ] Branches deleted
EOF

echo "Session file created: $SESSION_FILE"
```

### 2. When Adding Tasks

Update the "Task List" and "Started Worker Claude Instances" sections in the session file.

### 3. When Tasks Complete

Append merge results to "Completion & Merge History" and update the status in "Task List" to "Merged".

### 4. At Session End

Complete the checklist and update "Status" to "Completed".

---

## Differences from Mode A (merge-coordinator.md)

| Aspect | merge-coordinator.md (A) | quick-session-{timestamp}.md (B) |
|--------|--------------------------|----------------------------------|
| Filename | Fixed | Unique with timestamp |
| Creation Timing | Once when plan is created | Every time a session starts |
| Multiple Parallel | One only | Multiple sessions possible |
| Dependency Management | Detailed | Basically independent tasks |
| Merge Target | Integration branch | Direct to main |
