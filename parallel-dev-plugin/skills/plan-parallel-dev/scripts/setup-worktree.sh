#!/bin/bash
# setup-worktree.sh - worktree作成 + 環境セットアップ
#
# 使用例:
#   ./setup-worktree.sh recommendation-api
#   ./setup-worktree.sh recommendation-api 3001 5174
#   ./setup-worktree.sh recommendation-api 3001 5174 feature

set -e

TASK_NAME="${1:?タスク名を指定してください}"
PORT_BE="${2:-}"
PORT_FE="${3:-}"
PREFIX="${4:-feature}"  # feature または fix

BRANCH="${PREFIX}/${TASK_NAME}"

# 現在の worktree 数からポートを自動計算
if [ -z "$PORT_BE" ]; then
  CURRENT_COUNT=$(git worktree list | wc -l)
  PORT_BE=$((3000 + CURRENT_COUNT))
  PORT_FE=$((5173 + CURRENT_COUNT))
fi

echo "=== worktree セットアップ ==="
echo "タスク名: $TASK_NAME"
echo "ブランチ: $BRANCH"
echo "ポート: BE=$PORT_BE, FE=$PORT_FE"

# ディレクトリ作成
mkdir -p .parallel-dev/tasks
mkdir -p .parallel-dev-signals
mkdir -p .parallel-dev-issues

# .gitignore に追加
grep -q ".parallel-dev-signals/" .gitignore 2>/dev/null || echo ".parallel-dev-signals/" >> .gitignore
grep -q ".parallel-dev-issues/" .gitignore 2>/dev/null || echo ".parallel-dev-issues/" >> .gitignore
grep -q "worktree/" .gitignore 2>/dev/null || echo "worktree/" >> .gitignore

# worktree 作成
echo "worktree を作成中..."
git worktree add "worktree/${TASK_NAME}" -b "$BRANCH"

# .env コピー
if [ -f ".env" ]; then
  cp .env "worktree/${TASK_NAME}/.env"
  echo ".env をコピーしました"
fi

# .env.local 作成
cat > "worktree/${TASK_NAME}/.env.local" << EOF
PROJECT_ROOT=$(pwd)
PORT=$PORT_BE
VITE_PORT=$PORT_FE
EOF
echo ".env.local を作成しました"

# 依存関係インストール
cd "worktree/${TASK_NAME}"
if [ -f "pyproject.toml" ]; then
  echo "uv sync を実行中..."
  uv sync
elif [ -f "package.json" ]; then
  if command -v pnpm &> /dev/null; then
    echo "pnpm install を実行中..."
    pnpm install
  else
    echo "npm install を実行中..."
    npm install
  fi
fi
cd ../..

echo ""
echo "=== セットアップ完了 ==="
echo "worktree: worktree/${TASK_NAME}/"
echo "ブランチ: $BRANCH"
