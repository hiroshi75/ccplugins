#!/bin/bash
# start-worker.sh - Start a worker claude
#
# Usage:
#   ./start-worker.sh recommendation-api
#   ./start-worker.sh recommendation-api "Dependency task api-base has been merged"
#
# Prerequisite: Run within a tmux session

set -e

TASK_NAME="${1:?Please specify a task name}"
EXTRA_MESSAGE="${2:-}"

WORKTREE_DIR="worktree/${TASK_NAME}"
TASK_FILE=".parallel-dev/tasks/${TASK_NAME}.md"

if [ ! -d "$WORKTREE_DIR" ]; then
  echo "Error: $WORKTREE_DIR not found"
  exit 1
fi

if [ ! -f "$TASK_FILE" ]; then
  echo "Error: $TASK_FILE not found"
  exit 1
fi

export PROJECT_ROOT=$(pwd)

echo "=== Starting Worker Claude ==="
echo "Task: $TASK_NAME"
echo "worktree: $WORKTREE_DIR"

# Build instruction message
INSTRUCTION="Read ../../${TASK_FILE} and implement it."
if [ -n "$EXTRA_MESSAGE" ]; then
  INSTRUCTION="${INSTRUCTION} ${EXTRA_MESSAGE}"
fi
INSTRUCTION="${INSTRUCTION} When complete, create a .done file in \$PROJECT_ROOT/.parallel-dev-signals/ (create in parent project, not within worktree)."

# Start worker claude in a new window
tmux new-window -n "${TASK_NAME}" "cd ${WORKTREE_DIR} && PROJECT_ROOT=$PROJECT_ROOT claude '${INSTRUCTION}'"

echo "Worker claude started (window: ${TASK_NAME})"
