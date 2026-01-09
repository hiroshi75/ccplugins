#!/bin/bash
# cleanup-worktrees.sh
# Script to clean up worktrees for completed tasks
#
# Usage:
#   ./cleanup-worktrees.sh [task-name]
#
# Examples:
#   ./cleanup-worktrees.sh                    # Clean up all merged tasks
#   ./cleanup-worktrees.sh fix-login          # Clean up a specific task only
#   ./cleanup-worktrees.sh --all              # Force clean up all worktrees (with confirmation)
#
# This script performs the following:
#   1. Delete the worktree
#   2. Delete the local branch
#   3. Delete the .done file
#   4. Update the task instruction status

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Clean up a single task
cleanup_task() {
  local TASK_NAME="$1"
  local FORCE="$2"

  info "Cleaning up: ${TASK_NAME}"

  # worktree path
  WORKTREE_PATH="worktree/${TASK_NAME}"

  # Check if worktree exists
  if [ ! -d "$WORKTREE_PATH" ]; then
    warn "worktree not found: ${WORKTREE_PATH}"
    return 1
  fi

  # Get branch name
  BRANCH=$(cd "$WORKTREE_PATH" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

  if [ -z "$BRANCH" ]; then
    warn "Unable to get branch name"
    return 1
  fi

  # Check for uncommitted changes
  if [ -n "$(cd "$WORKTREE_PATH" && git status --porcelain)" ]; then
    if [ "$FORCE" != "true" ]; then
      warn "${TASK_NAME} has uncommitted changes"
      echo -e "  ${YELLOW}Skipping cleanup. Use --force to force execution.${NC}"
      return 1
    else
      warn "Cleaning up despite uncommitted changes"
    fi
  fi

  # 1. Delete worktree
  info "Deleting worktree..."
  git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || {
    rm -rf "$WORKTREE_PATH"
    git worktree prune
  }
  success "worktree deleted"

  # 2. Delete local branch
  info "Deleting local branch: ${BRANCH}"
  git branch -D "$BRANCH" 2>/dev/null && success "Branch deleted" || warn "Branch not found or already deleted"

  # 3. Delete .done file
  if [ -f ".parallel-dev-signals/${TASK_NAME}.done" ]; then
    rm ".parallel-dev-signals/${TASK_NAME}.done"
    success ".done file deleted"
  fi

  # 4. Delete .issue file (if resolved)
  if [ -f ".parallel-dev-issues/${TASK_NAME}.md" ]; then
    rm ".parallel-dev-issues/${TASK_NAME}.md"
    success ".issue file deleted"
  fi

  # 5. Update task instruction status
  TASK_FILE=".parallel-dev/tasks/${TASK_NAME}.md"
  if [ -f "$TASK_FILE" ]; then
    if grep -q "| Status" "$TASK_FILE"; then
      # Compatible with both macOS and Linux
      if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/| Status | .* |/| Status | Cleaned up |/' "$TASK_FILE"
      else
        sed -i 's/| Status | .* |/| Status | Cleaned up |/' "$TASK_FILE"
      fi
      success "Task instruction status updated"
    fi
  fi

  success "Cleanup completed for ${TASK_NAME}"
  echo ""
}

# Main process
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE} Parallel Development Cleanup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Argument processing
TARGET="$1"
FORCE="false"

if [ "$TARGET" == "--force" ] || [ "$2" == "--force" ]; then
  FORCE="true"
fi

if [ "$TARGET" == "--all" ]; then
  # Clean up all worktrees
  echo -e "${YELLOW}Warning: This will clean up all worktrees${NC}"
  echo ""
  read -p "Continue? (y/N): " CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Cancelled"
    exit 0
  fi

  # Target all directories under worktree/
  if [ -d "worktree" ]; then
    for WORKTREE_DIR in worktree/*/; do
      if [ -d "$WORKTREE_DIR" ]; then
        TASK_NAME=$(basename "$WORKTREE_DIR")
        cleanup_task "$TASK_NAME" "$FORCE" || true
      fi
    done
  fi

  # Delete the worktree directory itself
  if [ -d "worktree" ]; then
    rmdir worktree 2>/dev/null && success "worktree/ directory deleted" || true
  fi

  # Clean up orphaned worktrees
  git worktree prune
  success "git worktree prune completed"

elif [ -n "$TARGET" ] && [ "$TARGET" != "--force" ]; then
  # Clean up a specific task
  cleanup_task "$TARGET" "$FORCE"

else
  # Auto-detect and clean up merged tasks
  info "Searching for merged tasks..."
  echo ""

  CLEANED=0

  if [ -d ".parallel-dev/tasks" ]; then
    for TASK_FILE in .parallel-dev/tasks/*.md; do
      if [ -f "$TASK_FILE" ]; then
        TASK_NAME=$(basename "$TASK_FILE" .md)

        # Check if status is merged
        if grep -q "Merged" "$TASK_FILE" 2>/dev/null; then
          # Only clean up if worktree exists
          if [ -d "worktree/${TASK_NAME}" ]; then
            cleanup_task "$TASK_NAME" "$FORCE" && CLEANED=$((CLEANED + 1)) || true
          fi
        fi
      fi
    done
  fi

  if [ $CLEANED -eq 0 ]; then
    info "No tasks to clean up"
    echo ""
    echo "To clean up a specific task:"
    echo "  $0 <task-name>"
    echo ""
    echo "To clean up all tasks:"
    echo "  $0 --all"
  else
    success "${CLEANED} task(s) cleaned up"
  fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Cleanup Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Display remaining worktrees
info "Remaining worktrees:"
git worktree list
echo ""
