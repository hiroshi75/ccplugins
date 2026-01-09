#!/bin/bash
# update-dashboard.sh
# Script to automatically update the progress dashboard (.parallel-dev/README.md)
#
# Usage:
#   ./update-dashboard.sh
#   ./update-dashboard.sh --init    # Create a new README.md
#
# This script performs the following:
#   1. Collect task list and status
#   2. Calculate progress
#   3. Update .parallel-dev/README.md

set -e

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }

README_FILE=".parallel-dev/README.md"
TASKS_DIR=".parallel-dev/tasks"
SIGNALS_DIR=".parallel-dev-signals"
ISSUES_DIR=".parallel-dev-issues"

# Check directory
if [ ! -d ".parallel-dev" ]; then
  echo "Error: .parallel-dev/ directory not found"
  echo "Please set up tasks first"
  exit 1
fi

info "Updating dashboard..."

# Collect task information
TASK_COUNT=0
COMPLETED_COUNT=0
IN_PROGRESS_COUNT=0
WAITING_COUNT=0
ISSUE_COUNT=0

declare -a TASK_ROWS

if [ -d "$TASKS_DIR" ]; then
  for TASK_FILE in "$TASKS_DIR"/*.md 2>/dev/null; do
    if [ -f "$TASK_FILE" ]; then
      TASK_COUNT=$((TASK_COUNT + 1))
      TASK_NAME=$(basename "$TASK_FILE" .md)

      # Determine status
      if grep -q "Merged" "$TASK_FILE" 2>/dev/null; then
        STATUS="✅ Merged"
        COMPLETED_COUNT=$((COMPLETED_COUNT + 1))
        COMPLETED_AT=$(grep -E "Completed at|Merged at" "$TASK_FILE" 2>/dev/null | head -1 | sed 's/.*| //' | sed 's/ |.*//' || echo "-")
      elif [ -f "${SIGNALS_DIR}/${TASK_NAME}.done" ]; then
        STATUS="📦 Completed (awaiting merge)"
        COMPLETED_AT=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "${SIGNALS_DIR}/${TASK_NAME}.done" 2>/dev/null || stat -c "%y" "${SIGNALS_DIR}/${TASK_NAME}.done" 2>/dev/null | cut -d. -f1 || echo "-")
      elif [ -f "${ISSUES_DIR}/${TASK_NAME}.md" ]; then
        STATUS="⚠️ Has issues"
        ISSUE_COUNT=$((ISSUE_COUNT + 1))
        COMPLETED_AT="-"
      elif grep -q "In progress" "$TASK_FILE" 2>/dev/null; then
        STATUS="🔄 In progress"
        IN_PROGRESS_COUNT=$((IN_PROGRESS_COUNT + 1))
        COMPLETED_AT="-"
      else
        STATUS="⏳ Waiting"
        WAITING_COUNT=$((WAITING_COUNT + 1))
        COMPLETED_AT="-"
      fi

      # Get branch name
      BRANCH=$(grep -E "^\| Branch" "$TASK_FILE" 2>/dev/null | head -1 | sed 's/.*`//' | sed 's/`.*//' || echo "-")

      TASK_ROWS+=("| ${TASK_NAME} | ${STATUS} | ${BRANCH} | ${COMPLETED_AT} |")
    fi
  done
fi

# Calculate progress rate
if [ $TASK_COUNT -gt 0 ]; then
  PROGRESS=$((COMPLETED_COUNT * 100 / TASK_COUNT))
  FILLED=$((PROGRESS / 5))
  EMPTY=$((20 - FILLED))
  BAR=$(printf '%*s' "$FILLED" | tr ' ' '█')$(printf '%*s' "$EMPTY" | tr ' ' '░')
else
  PROGRESS=0
  BAR="░░░░░░░░░░░░░░░░░░░░"
fi

# Update timestamp
UPDATED_AT=$(date '+%Y-%m-%d %H:%M:%S')

# Generate README.md
cat > "$README_FILE" << EOF
# Parallel Development Dashboard

Last updated: ${UPDATED_AT}

## Progress

\`\`\`
[${BAR}] ${PROGRESS}% (${COMPLETED_COUNT}/${TASK_COUNT})
\`\`\`

| Metric | Count |
|--------|-------|
| Total tasks | ${TASK_COUNT} |
| Completed (Merged) | ${COMPLETED_COUNT} |
| In progress | ${IN_PROGRESS_COUNT} |
| Waiting | ${WAITING_COUNT} |
| Issues | ${ISSUE_COUNT} |

## Task List

| Task | Status | Branch | Completed at |
|------|--------|--------|--------------|
EOF

# Add task rows
for ROW in "${TASK_ROWS[@]}"; do
  echo "$ROW" >> "$README_FILE"
done

# If no tasks
if [ $TASK_COUNT -eq 0 ]; then
  echo "| (No tasks) | - | - | - |" >> "$README_FILE"
fi

# Issue reports section
cat >> "$README_FILE" << 'EOF'

## Issue Reports

EOF

if [ -d "$ISSUES_DIR" ] && [ -n "$(ls -A $ISSUES_DIR 2>/dev/null)" ]; then
  for ISSUE_FILE in "$ISSUES_DIR"/*.md 2>/dev/null; do
    if [ -f "$ISSUE_FILE" ]; then
      ISSUE_NAME=$(basename "$ISSUE_FILE" .md)
      FIRST_LINE=$(head -n 1 "$ISSUE_FILE" | sed 's/^#\s*//')
      echo "- **${ISSUE_NAME}**: ${FIRST_LINE}" >> "$README_FILE"
    fi
  done
else
  echo "No issue reports." >> "$README_FILE"
fi

# Footer
cat >> "$README_FILE" << 'EOF'

---

## Quick Links

- [Merge Coordinator Instructions](merge-coordinator.md)
- [Task List](tasks/)

## Commands

```bash
# Check status
./scripts/status.sh

# Watch signals
./scripts/watch-signals.sh

# Cleanup
./scripts/cleanup-worktrees.sh
```
EOF

success "Dashboard updated: ${README_FILE}"
echo ""
echo "Contents:"
echo "  - Total tasks: ${TASK_COUNT}"
echo "  - Completed: ${COMPLETED_COUNT}"
echo "  - Progress: ${PROGRESS}%"
echo ""
