#!/bin/bash
# create-issue-file.sh - Create issue report file
#
# Usage:
#   ./create-issue-file.sh recommendation-api
#   ./create-issue-file.sh recommendation-api "Build error"

set -e

TASK_NAME="${1:?Please specify task name}"
SITUATION="${2:-Issue occurred}"

# If PROJECT_ROOT is not set, infer from current directory
if [ -z "$PROJECT_ROOT" ]; then
  if [[ "$(pwd)" == *"/worktree/"* ]]; then
    PROJECT_ROOT="$(cd ../.. && pwd)"
  else
    PROJECT_ROOT="$(pwd)"
  fi
fi

ISSUES_DIR="${PROJECT_ROOT}/.parallel-dev-issues"
ISSUE_FILE="${ISSUES_DIR}/${TASK_NAME}.md"

mkdir -p "$ISSUES_DIR"

cat > "$ISSUE_FILE" << EOF
# Issue: ${TASK_NAME}

## Date/Time
$(date '+%Y-%m-%d %H:%M')

## Situation
${SITUATION}

## Error Details
\`\`\`
(Paste error message here)
\`\`\`

## Impact Scope
- This task: ${TASK_NAME}
- Dependent tasks: (List if applicable)

## Attempted Solutions
1.

## Required Actions
- [ ] Coordination with other tasks needed
- [ ] New branch/worktree needed
- [ ] Human escalation needed

## Assignee
(To be assigned by merge coordinator)
EOF

echo "Created issue report: $ISSUE_FILE"
echo "Please edit the error details"
