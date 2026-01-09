#!/bin/bash
# start-coordinator.sh - マージ担当の claude を起動
#
# 使用例:
#   ./start-coordinator.sh                    # merge-coordinator.md を使用
#   ./start-coordinator.sh quick-session-xxx  # クイックセッションファイルを使用
#
# 前提: tmux セッション内で実行すること

set -e

COORDINATOR_FILE="${1:-merge-coordinator.md}"

# .parallel-dev/ 内のファイルかどうか確認
if [[ "$COORDINATOR_FILE" != .parallel-dev/* ]]; then
  COORDINATOR_FILE=".parallel-dev/${COORDINATOR_FILE}"
fi

if [ ! -f "$COORDINATOR_FILE" ]; then
  echo "エラー: $COORDINATOR_FILE が見つかりません"
  exit 1
fi

export PROJECT_ROOT=$(pwd)

echo "=== マージ担当 claude を起動 ==="
echo "指示書: $COORDINATOR_FILE"
echo "PROJECT_ROOT: $PROJECT_ROOT"

# マージ担当を新しいウィンドウで起動
tmux new-window -n "coordinator" "cd $PROJECT_ROOT && PROJECT_ROOT=$PROJECT_ROOT claude '${COORDINATOR_FILE} を読んで並列開発を開始してください。'"

echo "マージ担当 claude を起動しました (window: coordinator)"
