# Quick Task Instruction Template

A simplified task instruction template for Quick Task Mode (Mode B).
Unlike the detailed task instructions in Initial Parallel Development Mode (Mode A), this contains the minimum information needed to start work immediately.

Filename: `.parallel-dev/tasks/{task-name}.md`

---

## Template

```markdown
# Quick Task: {task-name}

## Basic Information

| Item | Content |
|------|---------|
| Request | {Summary of user's request} |
| Branch | `{fix/feature}/{task-name}` |
| worktree | `worktree/{task-name}/` |
| Base Branch | `{main or specified branch}` |
| Created At | {YYYY-MM-DD HH:MM} |
| Status | In Progress |

---

## Execution Context

This task is launched via tmux from the Merge Coordinator (or requesting Claude).
Working directory: `worktree/{task-name}/`

**Environment variable `PROJECT_ROOT`**: Absolute path to the project root passed when tmux starts.
Create `.done` files in `$PROJECT_ROOT/.parallel-dev-signals/`.

---

## Request Details

{Include user's request as-is}

### Additional Information (if any)

- {Related file paths}
- {Reference to existing implementations}
- {Notes/Constraints}

---

## Work Procedure

1. Understand the request and identify related files
2. Implement the necessary changes
3. Verify locally
4. Create `.done` file and end session

---

## Upon Completion

When implementation is complete, create a completion report with the following command:

```bash
cat > $PROJECT_ROOT/.parallel-dev-signals/{task-name}.done << 'EOF'
【Completion Report】{task-name}

## Implementation Details
- {List implemented items}
- {List of changed files}

## Verification
Local verification: OK / NG

## Test Results (if tests were run)
{Test results}

## Notes
{Other information/Notes}
EOF
```

---

## When Issues Occur

If issues occur, record them in `.parallel-dev-issues/{task-name}.md`:

```bash
cat > $PROJECT_ROOT/.parallel-dev-issues/{task-name}.md << 'EOF'
【Issue Report】{task-name}

## Situation
{What happened}

## Error Details
{Error message}

## Attempted Solutions
- {What was tried 1}
- {What was tried 2}

## Required Action
{How it might be resolved}
EOF
```

---

## Rules

- **Do not commit**: Only write code. The Merge Coordinator will commit
- **Do not push**: Pushing to remote is also done by the Merge Coordinator
- **Confirm UI specifications**: Do not make UI appearance decisions unilaterally; submit a confirmation request
- **End session when complete**: After creating `.done` file, work is complete

---

## Reference Materials

- Related files: {path}
- Similar implementation: {path}
```

---

## Writing Guide

### Task Naming Conventions

Task names should be written in kebab-case and briefly describe the work:

**For bug fixes:**
- `fix-login-validation`
- `fix-header-overflow`
- `fix-api-timeout`

**For feature additions:**
- `add-logout-button`
- `add-user-avatar`
- `feature-dark-mode`

**For improvements/refactoring:**
- `improve-search-performance`
- `refactor-auth-module`
- `update-dependencies`

### Branch Prefixes

| Work Type | Prefix | Example |
|-----------|--------|---------|
| Bug fix | `fix/` | `fix/login-validation` |
| Feature addition | `feature/` | `feature/dark-mode` |
| Improvement | `improve/` | `improve/search-perf` |
| Refactoring | `refactor/` | `refactor/auth` |
| Documentation | `docs/` | `docs/api-guide` |

### Status Transitions

```
In Progress → Completed (.done created) → Merged
              ↓
            Issue Occurred (.md created) → Addressing → Resume
```

---

## Differences from Initial Parallel Development (Mode A)

| Aspect | Mode A (Detailed Task Instructions) | Mode B (Quick Task) |
|--------|-------------------------------------|---------------------|
| Information Volume | Detailed specs, API definitions, dependencies | Request and minimum information |
| Creation Timing | Pre-created during planning phase | Generated immediately upon request |
| Dependencies | Explicitly documented | Basically standalone tasks |
| Phase Separation | Supported | Not supported (for simple one-off tasks) |
| Merge Target | Integration branch | main or specified branch |

---

## Usage Examples

### Example 1: Bug Fix

```markdown
# Quick Task: fix-login-validation

## Basic Information

| Item | Content |
|------|---------|
| Request | Fix issue where email address validation is not working on login screen |
| Branch | `fix/fix-login-validation` |
| worktree | `worktree/fix-login-validation/` |
| Base Branch | `main` |
| Created At | 2024-01-15 10:30 |
| Status | In Progress |

## Request Details

Email address validation is not working on the login screen.
Invalid email addresses (e.g., "test@") can still be submitted.

### Additional Information

- Login form: `src/components/auth/LoginForm.tsx`
- Validation: `src/lib/validation.ts`
```

### Example 2: Feature Addition

```markdown
# Quick Task: add-logout-button

## Basic Information

| Item | Content |
|------|---------|
| Request | Add logout button to header |
| Branch | `feature/add-logout-button` |
| worktree | `worktree/add-logout-button/` |
| Base Branch | `main` |
| Created At | 2024-01-15 11:00 |
| Status | In Progress |

## Request Details

Please add a logout button to the top-right of the header.
When clicked, clear the session and redirect to `/login`.

### Additional Information

- Header component: `src/components/layout/Header.tsx`
- Authentication: `src/lib/auth.ts`
- Login page: `src/pages/login.tsx`
```
