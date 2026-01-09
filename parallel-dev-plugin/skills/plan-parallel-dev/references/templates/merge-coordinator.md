# Merge Coordinator Instructions Template

Instructions for Claude managing merges and coordination.

## Template Content

```markdown
# Merge Coordinator Instructions

## Role
- Launch worker Claude via `tmux split-window` (NOT `new-window`)
- Monitor `.parallel-dev-signals/` for .done files
- Monitor `.parallel-dev-issues/` for problem reports
- Commit worker Claude changes
- Merge integration branch latest
- Run tests
- Merge to integration branch
- Manage merge order

**Important**: Worker Claude does NOT commit/push. Coordinator handles all git operations.

## Start Worker Claude

```bash
export PROJECT_ROOT=$(pwd)
tmux set-option pane-border-status top
tmux split-window -h "cd worktree/{task-name} && PROJECT_ROOT=$PROJECT_ROOT claude 'Read ../../.parallel-dev/tasks/{task-name}.md and implement. Create .done file when complete.'"
tmux select-pane -T "{task-name}"
```

## Monitor for Completion

```bash
# Watch for .done files (5 second intervals)
for i in {1..108}; do
  DONE_FILES=$(ls .parallel-dev-signals/*.done 2>/dev/null || true)
  [ -n "$DONE_FILES" ] && break
  sleep 5
done
```

## Branch Info
| Item | Value |
|------|-------|
| Integration Branch | `feature/{integration-branch}` |
| Base Branch | `main` |

## Task List & Dependencies
| Branch | Status | Depends On | Merge Order |
|--------|--------|------------|-------------|
| feature/{task-a} | Not Started | None | 1 |
| feature/{task-b} | Not Started | task-a | 2 |

## Integration Flow (After .done Detection)

### 1. In Worker Worktree
```bash
cd worktree/{branch-name}
git add .
git commit -m "feat: {branch-name} implementation"
git fetch origin
git merge origin/feature/{integration-branch} --no-ff
{test-command}
```

### 2. If Tests Pass
```bash
git push origin feature/{branch-name}
cd ../..
git checkout feature/{integration-branch}
git merge origin/feature/{branch-name} --no-ff
git push origin feature/{integration-branch}
```

### 3. If Tests Fail
```bash
rm .parallel-dev-signals/{branch-name}.done
# Create issue file requesting fixes
# Restart worker Claude
```

## Testing Policy
- Run production-equivalent tests (real DB/API connections)
- Test before merge to integration branch
- E2E visual checks for UI tasks (use dev-browser skill)

## Rules
- Always merge with `--no-ff`
- Always run tests after merge
- Delegate conflict resolution to task owner
- Merge order: Dependencies > Change Scope > Completion Order
```
