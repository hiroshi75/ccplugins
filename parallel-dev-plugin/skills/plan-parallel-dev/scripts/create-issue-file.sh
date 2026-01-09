#!/bin/bash
# create-issue-file.sh - 問題報告ファイルを作成
#
# 使用例:
#   ./create-issue-file.sh recommendation-api
#   ./create-issue-file.sh recommendation-api "ビルドエラー"

set -e

TASK_NAME="${1:?タスク名を指定してください}"
SITUATION="${2:-問題が発生}"

# PROJECT_ROOT が設定されていなければ現在のディレクトリから推測
if [ -z "$PROJECT_ROOT" ]; then
  if [[ "$(pwd)" == *"/worktree/"* ]]; then
    PROJECT_ROOT="$(cd ../.. && pwd)"
  else
    PROJECT_ROOT="$(pwd)"
  fi
fi

ISSUES_DIR="${PROJECT_ROOT}/.parallel-dev-issues"
ISSUE_FILE="${ISSUES_DIR}/${TASK_NAME}.md"

mkdir -p "$ISSUES_DIR"

cat > "$ISSUE_FILE" << EOF
# Issue: ${TASK_NAME}

## 発生日時
$(date '+%Y-%m-%d %H:%M')

## 状況
${SITUATION}

## エラー内容
\`\`\`
（エラーメッセージをここに貼り付け）
\`\`\`

## 影響範囲
- このタスク: ${TASK_NAME}
- 依存しているタスク: （該当があれば記載）

## 試した対応
1.

## 必要な対応
- [ ] 他タスクとの調整が必要
- [ ] 新しいブランチ/worktree が必要
- [ ] 人間のエスカレーションが必要

## 担当
（マージ担当が割り当てる）
EOF

echo "問題報告を作成しました: $ISSUE_FILE"
echo "エラー内容を編集してください"
