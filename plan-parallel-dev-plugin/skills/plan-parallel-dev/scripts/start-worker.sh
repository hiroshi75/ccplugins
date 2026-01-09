#!/bin/bash
# start-worker.sh - 作業用 claude を起動
#
# 使用例:
#   ./start-worker.sh recommendation-api
#   ./start-worker.sh recommendation-api "依存タスク api-base はマージ済みです"
#
# 前提: tmux セッション内で実行すること

set -e

TASK_NAME="${1:?タスク名を指定してください}"
EXTRA_MESSAGE="${2:-}"

WORKTREE_DIR="worktree/${TASK_NAME}"
TASK_FILE=".parallel-dev/tasks/${TASK_NAME}.md"

if [ ! -d "$WORKTREE_DIR" ]; then
  echo "エラー: $WORKTREE_DIR が見つかりません"
  exit 1
fi

if [ ! -f "$TASK_FILE" ]; then
  echo "エラー: $TASK_FILE が見つかりません"
  exit 1
fi

export PROJECT_ROOT=$(pwd)

echo "=== 作業用 claude を起動 ==="
echo "タスク: $TASK_NAME"
echo "worktree: $WORKTREE_DIR"

# 指示メッセージを構築
INSTRUCTION="../../${TASK_FILE} を読んで実装してください。"
if [ -n "$EXTRA_MESSAGE" ]; then
  INSTRUCTION="${INSTRUCTION} ${EXTRA_MESSAGE}"
fi
INSTRUCTION="${INSTRUCTION} 完了したら \$PROJECT_ROOT/.parallel-dev-signals/ に .done ファイルを作成してください（worktree 内ではなく親プロジェクトに作成）。"

# 作業用 claude を新しいウィンドウで起動
tmux new-window -n "${TASK_NAME}" "cd ${WORKTREE_DIR} && PROJECT_ROOT=$PROJECT_ROOT claude '${INSTRUCTION}'"

echo "作業用 claude を起動しました (window: ${TASK_NAME})"
