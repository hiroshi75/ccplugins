#!/bin/bash
# setup-quick-task.sh
# Script to automate quick task setup
#
# Usage:
#   ./setup-quick-task.sh <task-name> [branch-prefix] [base-branch]
#
# Examples:
#   ./setup-quick-task.sh fix-login-validation
#   ./setup-quick-task.sh add-logout-button feature main
#
# This script performs the following:
#   1. Create necessary directories
#   2. Update .gitignore
#   3. Create worktree
#   4. Set up environment (.env copy, dependency installation)
#   5. Generate task instruction document

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
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Argument check
if [ -z "$1" ]; then
  echo "Usage: $0 <task-name> [branch-prefix] [base-branch]"
  echo ""
  echo "Arguments:"
  echo "  task-name      Task name (kebab-case, e.g.: fix-login-validation)"
  echo "  branch-prefix  Branch prefix (default: fix)"
  echo "  base-branch    Base branch (default: main)"
  echo ""
  echo "Examples:"
  echo "  $0 fix-login-validation"
  echo "  $0 add-logout-button feature main"
  exit 1
fi

TASK_NAME="$1"
BRANCH_PREFIX="${2:-fix}"
BASE_BRANCH="${3:-main}"
BRANCH="${BRANCH_PREFIX}/${TASK_NAME}"

info "Setting up quick task: ${TASK_NAME}"
info "Branch: ${BRANCH}"
info "Base: ${BASE_BRANCH}"

# 1. Create directories
info "Creating directories..."
mkdir -p .parallel-dev/tasks
mkdir -p .parallel-dev-signals
mkdir -p .parallel-dev-issues
success "Directories created"

# 2. Update .gitignore
info "Updating .gitignore..."
if [ -f .gitignore ]; then
  grep -q "^\.parallel-dev-signals/$" .gitignore 2>/dev/null || echo ".parallel-dev-signals/" >> .gitignore
  grep -q "^\.parallel-dev-issues/$" .gitignore 2>/dev/null || echo ".parallel-dev-issues/" >> .gitignore
  grep -q "^worktree/$" .gitignore 2>/dev/null || echo "worktree/" >> .gitignore
  success ".gitignore updated"
else
  cat > .gitignore << 'EOF'
.parallel-dev-signals/
.parallel-dev-issues/
worktree/
EOF
  success ".gitignore created"
fi

# 3. Create worktree
info "Creating worktree..."
if [ -d "worktree/${TASK_NAME}" ]; then
  warn "worktree/${TASK_NAME} already exists. Skipping."
else
  git worktree add "worktree/${TASK_NAME}" -b "${BRANCH}"
  success "Worktree created: worktree/${TASK_NAME}"
fi

# 4. Environment setup
info "Setting up environment..."

# Copy .env
if [ -f .env ]; then
  cp .env "worktree/${TASK_NAME}/.env"
  success ".env copied"
fi

# Calculate port numbers (based on existing worktree count)
WORKTREE_COUNT=$(git worktree list | wc -l)
PORT_BE=$((3000 + WORKTREE_COUNT - 1))
PORT_FE=$((5173 + WORKTREE_COUNT - 1))

# Create .env.local
cat > "worktree/${TASK_NAME}/.env.local" << EOF
# Quick task: ${TASK_NAME}
# Auto-generated: $(date '+%Y-%m-%d %H:%M')
PORT=${PORT_BE}
VITE_PORT=${PORT_FE}
EOF
success ".env.local created (BE: ${PORT_BE}, FE: ${PORT_FE})"

# Install dependencies
cd "worktree/${TASK_NAME}"
if [ -f "pyproject.toml" ]; then
  info "Installing Python dependencies (uv sync)..."
  uv sync 2>/dev/null && success "uv sync complete" || warn "uv sync failed (please run manually)"
elif [ -f "package.json" ]; then
  if command -v pnpm &> /dev/null; then
    info "Installing Node.js dependencies (pnpm install)..."
    pnpm install 2>/dev/null && success "pnpm install complete" || warn "pnpm install failed"
  elif command -v npm &> /dev/null; then
    info "Installing Node.js dependencies (npm install)..."
    npm install 2>/dev/null && success "npm install complete" || warn "npm install failed"
  fi
fi
cd ../..

# 5. Generate task instruction document
info "Generating task instruction document..."
CREATED_AT=$(date '+%Y-%m-%d %H:%M')

cat > ".parallel-dev/tasks/${TASK_NAME}.md" << EOF
# Quick Task: ${TASK_NAME}

## Basic Information

| Item | Content |
|------|---------|
| Request | (Describe the request here) |
| Branch | \`${BRANCH}\` |
| Worktree | \`worktree/${TASK_NAME}/\` |
| Base Branch | \`${BASE_BRANCH}\` |
| Created | ${CREATED_AT} |
| Status | In Progress |
| Ports | BE: ${PORT_BE}, FE: ${PORT_FE} |

---

## Execution Context

This task is launched via tmux from the merge coordinator.
Working directory: \`worktree/${TASK_NAME}/\`

**Environment variable \`PROJECT_ROOT\`**: Absolute path to the project root passed at tmux startup.

---

## Request Details

(Describe the specific request here)

---

## Work Procedure

1. Understand the request and identify related files
2. Implement the fix
3. Verify locally
4. Create .done file

---

## On Completion

\`\`\`bash
cat > \$PROJECT_ROOT/.parallel-dev-signals/${TASK_NAME}.done << 'DONE_EOF'
[Completion Report] ${TASK_NAME}

## Implementation
- (What was implemented)
- (Files changed)

## Verification
Local verification: OK

## Notes
(Other information)
DONE_EOF
\`\`\`

---

## Rules

- **Do not commit**: Just write the code. The merge coordinator will commit
- **Do not push**: The merge coordinator will also push to remote
EOF

success "Task instruction document created: .parallel-dev/tasks/${TASK_NAME}.md"

# Completion message
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Quick Task Setup Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Edit the task instruction document to describe the request:"
echo "   vim .parallel-dev/tasks/${TASK_NAME}.md"
echo ""
echo "2. Launch worker Claude:"
echo "   export PROJECT_ROOT=\$(pwd)"
echo "   tmux new-window -n \"${TASK_NAME}\" \"cd worktree/${TASK_NAME} && PROJECT_ROOT=\$PROJECT_ROOT claude 'Please read ../../.parallel-dev/tasks/${TASK_NAME}.md and implement. Create \\\$PROJECT_ROOT/.parallel-dev-signals/${TASK_NAME}.done when complete (create in parent project, not in worktree).'\""
echo "   tmux select-pane -T \"${TASK_NAME}\""
echo ""
