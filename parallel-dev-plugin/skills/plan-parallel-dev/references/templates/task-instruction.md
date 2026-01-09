# Task Instruction Template

Instructions for worker Claude in each worktree.

## Template Content

```markdown
# Task Instructions: {branch-name}

## Execution Context
Launched via tmux by merge coordinator.
Working directory: `worktree/{branch-name}/`

**Environment variable `PROJECT_ROOT`**: Absolute path to project root passed at launch.
Create .done files in `$PROJECT_ROOT/.parallel-dev-signals/` and issues in `$PROJECT_ROOT/.parallel-dev-issues/`.

## Before Starting Work

### 1. Check Project Context
```bash
cat $PROJECT_ROOT/.intent/project.json  # Project-wide policy
cat .intent/brief.json                  # This worktree's policy (if exists)
```

### 2. Summarize Context
Review these JSON keys before starting:
- `intent`: Project goals
- `successCriteria`: Success criteria
- `guardrails`: Constraints
- `nonGoals`: What NOT to do
- `mode`: explore/converge/maintain (from brief.json)
- `focus`: Current focus areas (from brief.json)

## Basic Info
| Item | Value |
|------|-------|
| Branch | `feature/{branch-name}` |
| Worktree | `worktree/{branch-name}/` |
| Status | Not Started / In Progress / Complete / Merged |
| Backend Port | {PORT_BE} |
| Frontend Port | {PORT_FE} |

## Implementation Details

### Overview
{1-2 sentence description of what to implement}

### Deliverables
- [ ] {Deliverable 1: file path or endpoint or component}
- [ ] {Deliverable 2}

### Detailed Spec
{Detailed implementation specification}

## Dependencies

### This Task Depends On
| Dependency | Type | Status | Notes |
|------------|------|--------|-------|
| feature/{branch} | API | Not Complete | {API name} needed |

**Important**: If dependency not complete, wait until it's merged to integration branch.

## Work Steps

### 1. Implementation
1. {Step 1}
2. {Step 2}

**Important**: Do NOT git commit or git push. Focus on writing code only.

### 2. Local Verification
Run tests locally if available:
```bash
{test-command}
```

### 3. Completion Notification (.done file)
When implementation complete, notify coordinator:

```bash
cat > $PROJECT_ROOT/.parallel-dev-signals/{branch-name}.done << 'EOF'
【Completion Report】{branch-name}

## Implementation
- {Description of what was implemented}
- {List of changed files}

## Verification
Local verification: OK / NG

## Notes
{Other information}
EOF
```

### 4. End Session
After creating .done file, work is complete. End session.
Coordinator will detect .done, commit, merge, and test.

### 5. On Error/Blockage
If issues arise, record in `$PROJECT_ROOT/.parallel-dev-issues/{branch-name}.md`.

## Completion Criteria
- [ ] All deliverables implemented
- [ ] Locally verified
- [ ] `.done` file created in `$PROJECT_ROOT/.parallel-dev-signals/`

## Rules
- **Don't commit**: Only write code. Coordinator handles commits
- **Don't push**: Coordinator handles remote pushes
- **Wait if dependency incomplete**: Wait for coordinator's notification
- **Verify file existence before editing**: Confirm target files exist
```
