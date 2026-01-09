#!/bin/bash
# setup-worktree.sh - Create worktree + environment setup
#
# Usage:
#   ./setup-worktree.sh recommendation-api
#   ./setup-worktree.sh recommendation-api 3001 5174
#   ./setup-worktree.sh recommendation-api 3001 5174 feature

set -e

TASK_NAME="${1:?Please specify a task name}"
PORT_BE="${2:-}"
PORT_FE="${3:-}"
PREFIX="${4:-feature}"  # feature or fix

BRANCH="${PREFIX}/${TASK_NAME}"

# Auto-calculate ports from current worktree count
if [ -z "$PORT_BE" ]; then
  CURRENT_COUNT=$(git worktree list | wc -l)
  PORT_BE=$((3000 + CURRENT_COUNT))
  PORT_FE=$((5173 + CURRENT_COUNT))
fi

echo "=== Worktree Setup ==="
echo "Task name: $TASK_NAME"
echo "Branch: $BRANCH"
echo "Ports: BE=$PORT_BE, FE=$PORT_FE"

# Create directories
mkdir -p .parallel-dev/tasks
mkdir -p .parallel-dev-signals
mkdir -p .parallel-dev-issues

# Add to .gitignore
grep -q ".parallel-dev-signals/" .gitignore 2>/dev/null || echo ".parallel-dev-signals/" >> .gitignore
grep -q ".parallel-dev-issues/" .gitignore 2>/dev/null || echo ".parallel-dev-issues/" >> .gitignore
grep -q "worktree/" .gitignore 2>/dev/null || echo "worktree/" >> .gitignore

# Create worktree
echo "Creating worktree..."
git worktree add "worktree/${TASK_NAME}" -b "$BRANCH"

# Copy .env
if [ -f ".env" ]; then
  cp .env "worktree/${TASK_NAME}/.env"
  echo "Copied .env"
fi

# Create .env.local
cat > "worktree/${TASK_NAME}/.env.local" << EOF
PROJECT_ROOT=$(pwd)
PORT=$PORT_BE
VITE_PORT=$PORT_FE
EOF
echo "Created .env.local"

# Install dependencies
cd "worktree/${TASK_NAME}"
if [ -f "pyproject.toml" ]; then
  echo "Running uv sync..."
  uv sync
elif [ -f "package.json" ]; then
  if command -v pnpm &> /dev/null; then
    echo "Running pnpm install..."
    pnpm install
  else
    echo "Running npm install..."
    npm install
  fi
fi
cd ../..

echo ""
echo "=== Setup Complete ==="
echo "worktree: worktree/${TASK_NAME}/"
echo "Branch: $BRANCH"
