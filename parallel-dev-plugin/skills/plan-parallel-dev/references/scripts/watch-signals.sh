#!/bin/bash
# watch-signals.sh
# Script to monitor .done files and .issues files
#
# Usage:
#   ./watch-signals.sh [interval] [max-iterations]
#
# Examples:
#   ./watch-signals.sh           # Default: 5 second interval, 108 iterations (9 minutes)
#   ./watch-signals.sh 10        # 10 second interval
#   ./watch-signals.sh 5 60      # 5 second interval, 60 iterations (5 minutes)
#
# When files are detected, the loop continues and displays their contents.

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Arguments
INTERVAL="${1:-5}"
MAX_ITERATIONS="${2:-108}"

# Directories
SIGNALS_DIR=".parallel-dev-signals"
ISSUES_DIR=".parallel-dev-issues"

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN} Parallel Development Signal Monitor${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "Monitoring targets:"
echo -e "  - ${GREEN}${SIGNALS_DIR}/*.done${NC} (completion notifications)"
echo -e "  - ${YELLOW}${ISSUES_DIR}/*.md${NC} (issue reports)"
echo ""
echo -e "Settings: ${INTERVAL} second interval, max ${MAX_ITERATIONS} iterations ($(( INTERVAL * MAX_ITERATIONS / 60 )) minutes)"
echo ""
echo -e "${BLUE}Starting monitoring... (Ctrl+C to interrupt)${NC}"
echo ""

# Track processed files
PROCESSED_DONE=""
PROCESSED_ISSUES=""

for i in $(seq 1 $MAX_ITERATIONS); do
  TIMESTAMP=$(date '+%H:%M:%S')

  # Check for completion notifications
  if [ -d "$SIGNALS_DIR" ]; then
    DONE_FILES=$(ls ${SIGNALS_DIR}/*.done 2>/dev/null || true)
    if [ -n "$DONE_FILES" ]; then
      for DONE_FILE in $DONE_FILES; do
        # Display only if not already processed
        if [[ ! "$PROCESSED_DONE" =~ "$DONE_FILE" ]]; then
          TASK_NAME=$(basename "$DONE_FILE" .done)
          echo ""
          echo -e "${GREEN}========================================${NC}"
          echo -e "${GREEN} [${TIMESTAMP}] Completion detected: ${TASK_NAME}${NC}"
          echo -e "${GREEN}========================================${NC}"
          echo ""
          cat "$DONE_FILE"
          echo ""
          echo -e "${GREEN}----------------------------------------${NC}"
          echo ""
          PROCESSED_DONE="$PROCESSED_DONE $DONE_FILE"

          # Option to exit when completion is detected
          echo -e "${YELLOW}Next actions:${NC}"
          echo "  1. Press Ctrl+C to interrupt and start merge process"
          echo "  2. Continue to wait for other tasks to complete"
          echo ""
        fi
      done
    fi
  fi

  # Check for issue reports
  if [ -d "$ISSUES_DIR" ]; then
    ISSUE_FILES=$(ls ${ISSUES_DIR}/*.md 2>/dev/null || true)
    if [ -n "$ISSUE_FILES" ]; then
      for ISSUE_FILE in $ISSUE_FILES; do
        # Display only if not already processed
        if [[ ! "$PROCESSED_ISSUES" =~ "$ISSUE_FILE" ]]; then
          TASK_NAME=$(basename "$ISSUE_FILE" .md)
          echo ""
          echo -e "${YELLOW}========================================${NC}"
          echo -e "${YELLOW} [${TIMESTAMP}] Issue report: ${TASK_NAME}${NC}"
          echo -e "${YELLOW}========================================${NC}"
          echo ""
          cat "$ISSUE_FILE"
          echo ""
          echo -e "${YELLOW}----------------------------------------${NC}"
          echo ""
          PROCESSED_ISSUES="$PROCESSED_ISSUES $ISSUE_FILE"
        fi
      done
    fi
  fi

  # Progress display (every 10 iterations)
  if [ $((i % 10)) -eq 0 ]; then
    echo -e "${BLUE}[${TIMESTAMP}] Check ${i}/${MAX_ITERATIONS}...${NC}"
  fi

  sleep $INTERVAL
done

echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW} Monitoring time ended (${MAX_ITERATIONS} checks completed)${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "If no completion notifications were received, run monitoring again:"
echo "  ./watch-signals.sh"
