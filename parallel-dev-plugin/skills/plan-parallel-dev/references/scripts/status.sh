#!/bin/bash
# status.sh
# Script to display the status of parallel development
#
# Usage:
#   ./status.sh
#
# Displays:
#   - Worktree list and status
#   - Completion notifications (.done)
#   - Issue reports (.issues)
#   - Task instruction status

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Icons
ICON_OK="✅"
ICON_PROGRESS="🔄"
ICON_WAIT="⏳"
ICON_WARN="⚠️"
ICON_DONE="📦"

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              Parallel Development Status                   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GRAY}Current time: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

# ========================================
# 1. Worktree List
# ========================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📁 Worktree List${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

WORKTREE_COUNT=0
WORKTREE_TASK_COUNT=0

if git worktree list &>/dev/null; then
  while IFS= read -r line; do
    WORKTREE_COUNT=$((WORKTREE_COUNT + 1))
    PATH_PART=$(echo "$line" | awk '{print $1}')
    BRANCH_PART=$(echo "$line" | awk '{print $3}' | tr -d '[]')

    # Check if under worktree/
    if [[ "$PATH_PART" == *"/worktree/"* ]]; then
      WORKTREE_TASK_COUNT=$((WORKTREE_TASK_COUNT + 1))
      TASK_NAME=$(basename "$PATH_PART")

      # Determine status
      if [ -f ".parallel-dev-signals/${TASK_NAME}.done" ]; then
        STATUS="${GREEN}${ICON_DONE} Completed${NC}"
      elif [ -f ".parallel-dev-issues/${TASK_NAME}.md" ]; then
        STATUS="${YELLOW}${ICON_WARN} Has issues${NC}"
      else
        STATUS="${BLUE}${ICON_PROGRESS} In progress${NC}"
      fi

      echo -e "  ${STATUS}  ${TASK_NAME}"
      echo -e "         ${GRAY}Branch: ${BRANCH_PART}${NC}"
      echo -e "         ${GRAY}Path: ${PATH_PART}${NC}"
      echo ""
    fi
  done < <(git worktree list)
fi

if [ $WORKTREE_TASK_COUNT -eq 0 ]; then
  echo -e "  ${GRAY}(No active worktrees)${NC}"
  echo ""
fi

# ========================================
# 2. Completion Notifications
# ========================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}${ICON_DONE} Completion Notifications (.parallel-dev-signals/)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

DONE_COUNT=0
if [ -d ".parallel-dev-signals" ]; then
  for DONE_FILE in .parallel-dev-signals/*.done 2>/dev/null; do
    if [ -f "$DONE_FILE" ]; then
      DONE_COUNT=$((DONE_COUNT + 1))
      TASK_NAME=$(basename "$DONE_FILE" .done)
      MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$DONE_FILE" 2>/dev/null || stat -c "%y" "$DONE_FILE" 2>/dev/null | cut -d. -f1)
      echo -e "  ${GREEN}${ICON_OK}${NC} ${TASK_NAME}"
      echo -e "     ${GRAY}Completed at: ${MODIFIED}${NC}"
      echo ""
    fi
  done
fi

if [ $DONE_COUNT -eq 0 ]; then
  echo -e "  ${GRAY}(No completion notifications)${NC}"
  echo ""
fi

# ========================================
# 3. Issue Reports
# ========================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}${ICON_WARN} Issue Reports (.parallel-dev-issues/)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

ISSUE_COUNT=0
if [ -d ".parallel-dev-issues" ]; then
  for ISSUE_FILE in .parallel-dev-issues/*.md 2>/dev/null; do
    if [ -f "$ISSUE_FILE" ]; then
      ISSUE_COUNT=$((ISSUE_COUNT + 1))
      TASK_NAME=$(basename "$ISSUE_FILE" .md)
      FIRST_LINE=$(head -n 1 "$ISSUE_FILE" | sed 's/^#\s*//')
      echo -e "  ${YELLOW}${ICON_WARN}${NC} ${TASK_NAME}"
      echo -e "     ${GRAY}${FIRST_LINE}${NC}"
      echo ""
    fi
  done
fi

if [ $ISSUE_COUNT -eq 0 ]; then
  echo -e "  ${GRAY}(No issue reports)${NC}"
  echo ""
fi

# ========================================
# 4. Task Instructions
# ========================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 Task Instructions (.parallel-dev/tasks/)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

TASK_COUNT=0
COMPLETED_COUNT=0
if [ -d ".parallel-dev/tasks" ]; then
  for TASK_FILE in .parallel-dev/tasks/*.md 2>/dev/null; do
    if [ -f "$TASK_FILE" ]; then
      TASK_COUNT=$((TASK_COUNT + 1))
      TASK_NAME=$(basename "$TASK_FILE" .md)

      # Extract status
      STATUS_LINE=$(grep -E "^\| Status" "$TASK_FILE" 2>/dev/null | head -1 || echo "")

      if [[ "$STATUS_LINE" == *"Merged"* ]]; then
        STATUS="${GREEN}${ICON_OK} Merged${NC}"
        COMPLETED_COUNT=$((COMPLETED_COUNT + 1))
      elif [ -f ".parallel-dev-signals/${TASK_NAME}.done" ]; then
        STATUS="${GREEN}${ICON_DONE} Completed (awaiting merge)${NC}"
      elif [ -f ".parallel-dev-issues/${TASK_NAME}.md" ]; then
        STATUS="${YELLOW}${ICON_WARN} Issue occurred${NC}"
      elif [[ "$STATUS_LINE" == *"In progress"* ]]; then
        STATUS="${BLUE}${ICON_PROGRESS} In progress${NC}"
      else
        STATUS="${GRAY}${ICON_WAIT} Waiting${NC}"
      fi

      echo -e "  ${STATUS}  ${TASK_NAME}"
    fi
  done
fi

if [ $TASK_COUNT -eq 0 ]; then
  echo -e "  ${GRAY}(No task instructions)${NC}"
fi
echo ""

# ========================================
# 5. Summary
# ========================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Progress bar
if [ $TASK_COUNT -gt 0 ]; then
  PROGRESS=$((COMPLETED_COUNT * 100 / TASK_COUNT))
  FILLED=$((PROGRESS / 5))
  EMPTY=$((20 - FILLED))
  BAR=$(printf '%*s' "$FILLED" | tr ' ' '█')$(printf '%*s' "$EMPTY" | tr ' ' '░')
  echo -e "  Progress: [${BAR}] ${PROGRESS}% (${COMPLETED_COUNT}/${TASK_COUNT})"
else
  echo -e "  Progress: [░░░░░░░░░░░░░░░░░░░░] 0%"
fi
echo ""
echo -e "  Total tasks:         ${TASK_COUNT}"
echo -e "  Awaiting merge:      ${DONE_COUNT}"
echo -e "  Issue reports:       ${ISSUE_COUNT}"
echo -e "  Active worktrees:    ${WORKTREE_TASK_COUNT}"
echo ""
