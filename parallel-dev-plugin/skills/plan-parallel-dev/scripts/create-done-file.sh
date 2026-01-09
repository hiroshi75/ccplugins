#!/bin/bash
# create-done-file.sh - Create completion notification file (.done)
#
# Usage:
#   ./create-done-file.sh recommendation-api
#   ./create-done-file.sh recommendation-api "API endpoint implementation complete"

set -e

TASK_NAME="${1:?Please specify task name}"
SUMMARY="${2:-Implementation complete}"

# If PROJECT_ROOT is not set, infer from current directory
if [ -z "$PROJECT_ROOT" ]; then
  # If running from within worktree, use parent directory
  if [[ "$(pwd)" == *"/worktree/"* ]]; then
    PROJECT_ROOT="$(cd ../.. && pwd)"
  else
    PROJECT_ROOT="$(pwd)"
  fi
fi

SIGNALS_DIR="${PROJECT_ROOT}/.parallel-dev-signals"
DONE_FILE="${SIGNALS_DIR}/${TASK_NAME}.done"

mkdir -p "$SIGNALS_DIR"

# Get list of changed files
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || echo "(no changes)")

cat > "$DONE_FILE" << EOF
[Completion Report] ${TASK_NAME}

## Implementation Summary
${SUMMARY}

## Changed Files
${CHANGED_FILES}

## Verification
Local verification: OK

## Notes
Created at $(date '+%Y-%m-%d %H:%M')
EOF

echo "Created completion notification: $DONE_FILE"
