#!/bin/bash
# create-done-file.sh - 完了通知ファイル (.done) を作成
#
# 使用例:
#   ./create-done-file.sh recommendation-api
#   ./create-done-file.sh recommendation-api "APIエンドポイント実装完了"

set -e

TASK_NAME="${1:?タスク名を指定してください}"
SUMMARY="${2:-実装完了}"

# PROJECT_ROOT が設定されていなければ現在のディレクトリから推測
if [ -z "$PROJECT_ROOT" ]; then
  # worktree 内から実行された場合は親ディレクトリ
  if [[ "$(pwd)" == *"/worktree/"* ]]; then
    PROJECT_ROOT="$(cd ../.. && pwd)"
  else
    PROJECT_ROOT="$(pwd)"
  fi
fi

SIGNALS_DIR="${PROJECT_ROOT}/.parallel-dev-signals"
DONE_FILE="${SIGNALS_DIR}/${TASK_NAME}.done"

mkdir -p "$SIGNALS_DIR"

# 変更ファイル一覧を取得
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || echo "(変更なし)")

cat > "$DONE_FILE" << EOF
【完了報告】${TASK_NAME}

## 実装内容
${SUMMARY}

## 変更ファイル
${CHANGED_FILES}

## 動作確認
ローカルでの動作確認: OK

## 備考
$(date '+%Y-%m-%d %H:%M') に作成
EOF

echo "完了通知を作成しました: $DONE_FILE"
