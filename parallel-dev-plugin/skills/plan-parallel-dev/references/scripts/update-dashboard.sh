#!/bin/bash
# update-dashboard.sh
# 進捗ダッシュボード（.parallel-dev/README.md）を自動更新するスクリプト
#
# 使用方法:
#   ./update-dashboard.sh
#   ./update-dashboard.sh --init    # README.md を新規作成
#
# このスクリプトは以下を実行します:
#   1. タスク一覧と状態を収集
#   2. 進捗状況を計算
#   3. .parallel-dev/README.md を更新

set -e

# 色の定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ヘルパー関数
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }

README_FILE=".parallel-dev/README.md"
TASKS_DIR=".parallel-dev/tasks"
SIGNALS_DIR=".parallel-dev-signals"
ISSUES_DIR=".parallel-dev-issues"

# ディレクトリ確認
if [ ! -d ".parallel-dev" ]; then
  echo "エラー: .parallel-dev/ ディレクトリが見つかりません"
  echo "先にタスクをセットアップしてください"
  exit 1
fi

info "ダッシュボードを更新中..."

# タスク情報を収集
TASK_COUNT=0
COMPLETED_COUNT=0
IN_PROGRESS_COUNT=0
WAITING_COUNT=0
ISSUE_COUNT=0

declare -a TASK_ROWS

if [ -d "$TASKS_DIR" ]; then
  for TASK_FILE in "$TASKS_DIR"/*.md 2>/dev/null; do
    if [ -f "$TASK_FILE" ]; then
      TASK_COUNT=$((TASK_COUNT + 1))
      TASK_NAME=$(basename "$TASK_FILE" .md)

      # ステータスを判定
      if grep -q "マージ済" "$TASK_FILE" 2>/dev/null; then
        STATUS="✅ マージ済"
        COMPLETED_COUNT=$((COMPLETED_COUNT + 1))
        COMPLETED_AT=$(grep -E "完了日時|マージ日時" "$TASK_FILE" 2>/dev/null | head -1 | sed 's/.*| //' | sed 's/ |.*//' || echo "-")
      elif [ -f "${SIGNALS_DIR}/${TASK_NAME}.done" ]; then
        STATUS="📦 完了（マージ待ち）"
        COMPLETED_AT=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "${SIGNALS_DIR}/${TASK_NAME}.done" 2>/dev/null || stat -c "%y" "${SIGNALS_DIR}/${TASK_NAME}.done" 2>/dev/null | cut -d. -f1 || echo "-")
      elif [ -f "${ISSUES_DIR}/${TASK_NAME}.md" ]; then
        STATUS="⚠️ 問題あり"
        ISSUE_COUNT=$((ISSUE_COUNT + 1))
        COMPLETED_AT="-"
      elif grep -q "作業中" "$TASK_FILE" 2>/dev/null; then
        STATUS="🔄 作業中"
        IN_PROGRESS_COUNT=$((IN_PROGRESS_COUNT + 1))
        COMPLETED_AT="-"
      else
        STATUS="⏳ 待機中"
        WAITING_COUNT=$((WAITING_COUNT + 1))
        COMPLETED_AT="-"
      fi

      # ブランチ名を取得
      BRANCH=$(grep -E "^\| ブランチ" "$TASK_FILE" 2>/dev/null | head -1 | sed 's/.*`//' | sed 's/`.*//' || echo "-")

      TASK_ROWS+=("| ${TASK_NAME} | ${STATUS} | ${BRANCH} | ${COMPLETED_AT} |")
    fi
  done
fi

# 進捗率を計算
if [ $TASK_COUNT -gt 0 ]; then
  PROGRESS=$((COMPLETED_COUNT * 100 / TASK_COUNT))
  FILLED=$((PROGRESS / 5))
  EMPTY=$((20 - FILLED))
  BAR=$(printf '%*s' "$FILLED" | tr ' ' '█')$(printf '%*s' "$EMPTY" | tr ' ' '░')
else
  PROGRESS=0
  BAR="░░░░░░░░░░░░░░░░░░░░"
fi

# 更新日時
UPDATED_AT=$(date '+%Y-%m-%d %H:%M:%S')

# README.md を生成
cat > "$README_FILE" << EOF
# 並列開発ダッシュボード

最終更新: ${UPDATED_AT}

## 進捗状況

\`\`\`
[${BAR}] ${PROGRESS}% (${COMPLETED_COUNT}/${TASK_COUNT})
\`\`\`

| 指標 | 数 |
|------|-----|
| 総タスク数 | ${TASK_COUNT} |
| 完了（マージ済） | ${COMPLETED_COUNT} |
| 作業中 | ${IN_PROGRESS_COUNT} |
| 待機中 | ${WAITING_COUNT} |
| 問題発生 | ${ISSUE_COUNT} |

## タスク一覧

| タスク | 状態 | ブランチ | 完了日時 |
|--------|------|----------|----------|
EOF

# タスク行を追加
for ROW in "${TASK_ROWS[@]}"; do
  echo "$ROW" >> "$README_FILE"
done

# タスクがない場合
if [ $TASK_COUNT -eq 0 ]; then
  echo "| （タスクなし） | - | - | - |" >> "$README_FILE"
fi

# 問題報告セクション
cat >> "$README_FILE" << 'EOF'

## 問題報告

EOF

if [ -d "$ISSUES_DIR" ] && [ -n "$(ls -A $ISSUES_DIR 2>/dev/null)" ]; then
  for ISSUE_FILE in "$ISSUES_DIR"/*.md 2>/dev/null; do
    if [ -f "$ISSUE_FILE" ]; then
      ISSUE_NAME=$(basename "$ISSUE_FILE" .md)
      FIRST_LINE=$(head -n 1 "$ISSUE_FILE" | sed 's/^#\s*//')
      echo "- **${ISSUE_NAME}**: ${FIRST_LINE}" >> "$README_FILE"
    fi
  done
else
  echo "問題報告はありません。" >> "$README_FILE"
fi

# フッター
cat >> "$README_FILE" << 'EOF'

---

## クイックリンク

- [マージ担当指示書](merge-coordinator.md)
- [タスク一覧](tasks/)

## コマンド

```bash
# 状態確認
./scripts/status.sh

# シグナル監視
./scripts/watch-signals.sh

# クリーンアップ
./scripts/cleanup-worktrees.sh
```
EOF

success "ダッシュボードを更新しました: ${README_FILE}"
echo ""
echo "内容:"
echo "  - 総タスク数: ${TASK_COUNT}"
echo "  - 完了: ${COMPLETED_COUNT}"
echo "  - 進捗: ${PROGRESS}%"
echo ""
