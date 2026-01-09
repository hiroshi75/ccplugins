# Task Instruction Template

Instruction template for Claude working in each worktree.
**This Claude is launched via tmux by the merge coordinator.**

Filename: `.parallel-dev/tasks/{branch-name}.md`

---

## Template

```markdown
# Task Instructions: {branch-name}

## Execution Context

This task is launched via tmux by the merge coordinator.
Working directory: `worktree/{branch-name}/`

**Environment variable `PROJECT_ROOT`**: Absolute path to the project root passed by the merge coordinator at tmux launch.
Create `.done` files in `$PROJECT_ROOT/.parallel-dev-signals/` and issue reports in `$PROJECT_ROOT/.parallel-dev-issues/` (create in parent project, not within worktree).

---

## Basic Information

| Item | Value |
|------|-------|
| Branch | `feature/{branch-name}` |
| Worktree | `worktree/{branch-name}/` |
| Status | Not Started / In Progress / Complete / Merged |
| Backend Port | {PORT_BE} |
| Frontend Port | {PORT_FE} |

---

## Implementation Details

### Overview

{1-2 sentence description of the feature to implement in this task}

### Deliverables

- [ ] {Deliverable 1: file path or endpoint or component name}
- [ ] {Deliverable 2}
- [ ] {Deliverable 3}

### Detailed Specification

{Detailed implementation specification}

#### API Specification (for backend)

**Endpoint**: `{METHOD} /api/v1/{path}`

**Request**:
```typescript
interface RequestBody {
  // ...
}
```

**Response**:
```typescript
interface Response {
  // ...
}
```

#### Component Specification (for frontend)

**Component Name**: `{ComponentName}`

**Props**:
```typescript
interface Props {
  // ...
}
```

**Location**: `src/components/{path}/`

---

## Dependencies

### What This Task Depends On

| Dependency | Type | Status | Notes |
|------------|------|--------|-------|
| feature/{branch} | API | Not Complete | Needs {API name} |
| feature/{branch} | Type Definition | Complete | Available for use |

### What Depends On This Task

| Dependent | Impact |
|-----------|--------|
| feature/{branch} | Integration work starts after this task completes |

### Handling Incomplete Dependencies

**Important**: If a dependency task is not complete, do not start this task.

- **Wait**: Wait until the dependency task is merged to the integration branch
- **Use mocks** (only for partial progress): Use `src/mocks/{mock-file}`
- **Use type definitions only** (only for partial progress): Import from `src/types/{type-file}`

**Note**: Do not directly incorporate dependency branches. Always incorporate via the integration branch.

---

## Work Steps

### 1. Implementation

1. {Step 1}
2. {Step 2}
3. {Step 3}

**Important**: Do NOT git commit or git push. Focus on writing code.

### 2. Start Development Server

Use the ports configured in `.env.local`:

```bash
# Backend (e.g., FastAPI/Uvicorn)
uvicorn main:app --port $PORT

# Frontend (e.g., Vite)
pnpm dev
```

### 3. Verification

Perform local verification. Run test commands if available:

```bash
{test-command}
```

### 4. Completion Notification (Create .done File)

When implementation is complete, notify the merge coordinator. **Commit is not required**.

```bash
# Create .done file
# PROJECT_ROOT is an environment variable passed by merge coordinator at tmux launch
cat > $PROJECT_ROOT/.parallel-dev-signals/{branch-name}.done << 'EOF'
【Completion Report】{branch-name}

## Implementation
- {Description of implemented features}
- {List of changed files}

## Verification
Local verification: OK / NG

## Notes
{Other information}
EOF
```

### 5. End Session

After creating the .done file, this Claude's work is complete. End the session.

The merge coordinator will detect the .done file and perform commit, merge, and testing.

### 6. On Error or Blockage

If issues occur, record them in `$PROJECT_ROOT/.parallel-dev-issues/{branch-name}.md`.

---

## Best Practices for File Editing

### Pre-Edit Checklist

1. **Verify file existence**: Confirm the target file actually exists before editing
2. **Check existing code**: Confirm that referenced functions, types, and components are already implemented
3. **Verify import paths**: Confirm that relative paths are correct

```bash
# Example of file existence check
ls -la src/components/target/
head -20 src/lib/api.ts  # Check existing functions
```

---

## Phase Separation (Optional: Only for Maximizing Parallelism)

**Normal case**: Since dependent tasks are launched after dependencies are merged, Phase separation is not needed.

**When to use Phase separation**: Only when explicitly stated in the task instructions.

### Phase 1: Advance Implementation (Before Dependent API Completion)

- [ ] Implement features with mock API
- [ ] Verify locally
- [ ] Create `.done` file on Phase 1 completion (`{branch-name}-phase1.done`)
- [ ] End session

### Phase 2: Integration (After Dependent API Completion)

When dependencies are merged, the merge coordinator will launch this Claude again via tmux.

- [ ] Replace mocks with production API
- [ ] Verify locally
- [ ] Create `.done` file on Phase 2 completion (`{branch-name}.done`)
- [ ] End session

---

## Completion Criteria

- [ ] All deliverables are implemented
- [ ] Locally verified
- [ ] Created `$PROJECT_ROOT/.parallel-dev-signals/{branch-name}.done`

---

## Rules

- **Don't commit**: Only write code. The merge coordinator handles commits
- **Don't push**: The merge coordinator handles remote pushes
- **Wait if dependency is incomplete**: Wait for notification from merge coordinator
- **Verify file existence before editing**: Confirm target files exist

---

## Notes

- {Project-specific notes}
- {Reference to coding conventions}
- {Points requiring coordination with other tasks}

---

## References

- Design document: {link}
- Related PR: {link}
- Similar implementation: `src/{path}`
```

---

## Writing Guide

### Status Transitions

```
Not Started → In Progress → Complete → Merged
```

### How to Write Dependencies

**Dependency Types:**
- `API`: Depends on endpoint implementation
- `Type Definition`: Depends on TypeScript types
- `Component`: Depends on UI components
- `Data`: Depends on DB schema or migrations

### Granularity of Deliverables

Be specific:
- ❌ "Implement API"
- ✅ "`GET /api/v1/recommendations` endpoint"

- ❌ "Create component"
- ✅ "`RecommendationCard` component (`src/components/recommendations/`)"

### Reference Material Accuracy

When creating task instructions, verify file existence and document current implementation status:
- ❌ Refer to `src/components/xxx.tsx`
- ✅ `src/components/xxx.tsx` (current component name: YyyComponent, props: id, name)
