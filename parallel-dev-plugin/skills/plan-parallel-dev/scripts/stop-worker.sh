#!/bin/bash
# stop-worker.sh - Stop a worker claude
#
# Usage:
#   ./stop-worker.sh recommendation-api

set -e

TASK_NAME="${1:?Please specify a task name}"

echo "Stopping worker claude: ${TASK_NAME}"
tmux send-keys -t "${TASK_NAME}" C-c C-c

echo "Stop command sent"
