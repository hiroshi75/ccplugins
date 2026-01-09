#!/bin/bash
# cleanup-parallel-dev.sh - Cleanup after parallel development completion
#
# Usage:
#   ./cleanup-parallel-dev.sh           # Cleanup with confirmation
#   ./cleanup-parallel-dev.sh --force   # Cleanup without confirmation

set -e

FORCE=false
if [ "$1" = "--force" ]; then
  FORCE=true
fi

echo "=== Parallel Development Cleanup ==="

# Confirmation
if [ "$FORCE" = false ]; then
  echo "Please confirm that all tasks have been merged."
  read -p "Continue? (y/N): " confirm
  if [[ "$confirm" != "y" ]]; then
    echo "Cancelled."
    exit 1
  fi
fi

# Remove worktrees
echo "Removing worktrees..."
for wt in worktree/*/; do
  if [ -d "$wt" ]; then
    echo "  Removing: $wt"
    git worktree remove "$wt" 2>/dev/null || rm -rf "$wt"
  fi
done
git worktree prune

# Remove worktree directory
if [ -d "worktree" ]; then
  rm -rf worktree/
  echo "Removed worktree/ directory"
fi

# Remove signals directory
if [ -d ".parallel-dev-signals" ]; then
  rm -rf .parallel-dev-signals/
  echo "Removed .parallel-dev-signals/"
fi

# Remove issues directory
if [ -d ".parallel-dev-issues" ]; then
  rm -rf .parallel-dev-issues/
  echo "Removed .parallel-dev-issues/"
fi

# Remove .parallel-dev/ (optional)
if [ -d ".parallel-dev" ]; then
  if [ "$FORCE" = false ]; then
    read -p "Also remove .parallel-dev/? (y/N): " confirm_pd
    if [[ "$confirm_pd" = "y" ]]; then
      rm -rf .parallel-dev/
      echo "Removed .parallel-dev/"
    else
      echo "Kept .parallel-dev/"
    fi
  else
    rm -rf .parallel-dev/
    echo "Removed .parallel-dev/"
  fi
fi

echo ""
echo "=== Cleanup Complete ==="
echo "Please delete branches manually: git branch -d <branch-name>"
