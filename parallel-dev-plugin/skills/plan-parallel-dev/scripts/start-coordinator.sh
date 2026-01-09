#!/bin/bash
# start-coordinator.sh - Start the merge coordinator claude
#
# Usage:
#   ./start-coordinator.sh                    # Use merge-coordinator.md
#   ./start-coordinator.sh quick-session-xxx  # Use quick session file
#
# Prerequisite: Run within a tmux session

set -e

COORDINATOR_FILE="${1:-merge-coordinator.md}"

# Check if file is within .parallel-dev/
if [[ "$COORDINATOR_FILE" != .parallel-dev/* ]]; then
  COORDINATOR_FILE=".parallel-dev/${COORDINATOR_FILE}"
fi

if [ ! -f "$COORDINATOR_FILE" ]; then
  echo "Error: $COORDINATOR_FILE not found"
  exit 1
fi

export PROJECT_ROOT=$(pwd)

echo "=== Starting Merge Coordinator Claude ==="
echo "Instructions: $COORDINATOR_FILE"
echo "PROJECT_ROOT: $PROJECT_ROOT"

# Start merge coordinator in a new window
tmux new-window -n "coordinator" "cd $PROJECT_ROOT && PROJECT_ROOT=$PROJECT_ROOT claude 'Read ${COORDINATOR_FILE} and start parallel development.'"

echo "Merge coordinator claude started (window: coordinator)"
