#!/bin/bash
# status.sh
# 並列開発の状態を一覧表示するスクリプト
#
# 使用方法:
#   ./status.sh
#
# 表示内容:
#   - worktree 一覧と状態
#   - 完了通知（.done）
#   - 問題報告（.issues）
#   - タスク指示書の状態

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# アイコン
ICON_OK="✅"
ICON_PROGRESS="🔄"
ICON_WAIT="⏳"
ICON_WARN="⚠️"
ICON_DONE="📦"

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              並列開発ステータス                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GRAY}現在時刻: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

# ========================================
# 1. Worktree 一覧
# ========================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📁 Worktree 一覧${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

WORKTREE_COUNT=0
WORKTREE_TASK_COUNT=0

if git worktree list &>/dev/null; then
  while IFS= read -r line; do
    WORKTREE_COUNT=$((WORKTREE_COUNT + 1))
    PATH_PART=$(echo "$line" | awk '{print $1}')
    BRANCH_PART=$(echo "$line" | awk '{print $3}' | tr -d '[]')

    # worktree/ 以下かどうか
    if [[ "$PATH_PART" == *"/worktree/"* ]]; then
      WORKTREE_TASK_COUNT=$((WORKTREE_TASK_COUNT + 1))
      TASK_NAME=$(basename "$PATH_PART")

      # 状態を判定
      if [ -f ".parallel-dev-signals/${TASK_NAME}.done" ]; then
        STATUS="${GREEN}${ICON_DONE} 完了${NC}"
      elif [ -f ".parallel-dev-issues/${TASK_NAME}.md" ]; then
        STATUS="${YELLOW}${ICON_WARN} 問題あり${NC}"
      else
        STATUS="${BLUE}${ICON_PROGRESS} 作業中${NC}"
      fi

      echo -e "  ${STATUS}  ${TASK_NAME}"
      echo -e "         ${GRAY}ブランチ: ${BRANCH_PART}${NC}"
      echo -e "         ${GRAY}パス: ${PATH_PART}${NC}"
      echo ""
    fi
  done < <(git worktree list)
fi

if [ $WORKTREE_TASK_COUNT -eq 0 ]; then
  echo -e "  ${GRAY}（アクティブな worktree はありません）${NC}"
  echo ""
fi

# ========================================
# 2. 完了通知
# ========================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}${ICON_DONE} 完了通知 (.parallel-dev-signals/)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

DONE_COUNT=0
if [ -d ".parallel-dev-signals" ]; then
  for DONE_FILE in .parallel-dev-signals/*.done 2>/dev/null; do
    if [ -f "$DONE_FILE" ]; then
      DONE_COUNT=$((DONE_COUNT + 1))
      TASK_NAME=$(basename "$DONE_FILE" .done)
      MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$DONE_FILE" 2>/dev/null || stat -c "%y" "$DONE_FILE" 2>/dev/null | cut -d. -f1)
      echo -e "  ${GREEN}${ICON_OK}${NC} ${TASK_NAME}"
      echo -e "     ${GRAY}完了日時: ${MODIFIED}${NC}"
      echo ""
    fi
  done
fi

if [ $DONE_COUNT -eq 0 ]; then
  echo -e "  ${GRAY}（完了通知はありません）${NC}"
  echo ""
fi

# ========================================
# 3. 問題報告
# ========================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}${ICON_WARN} 問題報告 (.parallel-dev-issues/)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

ISSUE_COUNT=0
if [ -d ".parallel-dev-issues" ]; then
  for ISSUE_FILE in .parallel-dev-issues/*.md 2>/dev/null; do
    if [ -f "$ISSUE_FILE" ]; then
      ISSUE_COUNT=$((ISSUE_COUNT + 1))
      TASK_NAME=$(basename "$ISSUE_FILE" .md)
      FIRST_LINE=$(head -n 1 "$ISSUE_FILE" | sed 's/^#\s*//')
      echo -e "  ${YELLOW}${ICON_WARN}${NC} ${TASK_NAME}"
      echo -e "     ${GRAY}${FIRST_LINE}${NC}"
      echo ""
    fi
  done
fi

if [ $ISSUE_COUNT -eq 0 ]; then
  echo -e "  ${GRAY}（問題報告はありません）${NC}"
  echo ""
fi

# ========================================
# 4. タスク指示書
# ========================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 タスク指示書 (.parallel-dev/tasks/)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

TASK_COUNT=0
COMPLETED_COUNT=0
if [ -d ".parallel-dev/tasks" ]; then
  for TASK_FILE in .parallel-dev/tasks/*.md 2>/dev/null; do
    if [ -f "$TASK_FILE" ]; then
      TASK_COUNT=$((TASK_COUNT + 1))
      TASK_NAME=$(basename "$TASK_FILE" .md)

      # ステータスを抽出
      STATUS_LINE=$(grep -E "^\| ステータス" "$TASK_FILE" 2>/dev/null | head -1 || echo "")

      if [[ "$STATUS_LINE" == *"マージ済"* ]]; then
        STATUS="${GREEN}${ICON_OK} マージ済${NC}"
        COMPLETED_COUNT=$((COMPLETED_COUNT + 1))
      elif [ -f ".parallel-dev-signals/${TASK_NAME}.done" ]; then
        STATUS="${GREEN}${ICON_DONE} 完了（マージ待ち）${NC}"
      elif [ -f ".parallel-dev-issues/${TASK_NAME}.md" ]; then
        STATUS="${YELLOW}${ICON_WARN} 問題発生${NC}"
      elif [[ "$STATUS_LINE" == *"作業中"* ]]; then
        STATUS="${BLUE}${ICON_PROGRESS} 作業中${NC}"
      else
        STATUS="${GRAY}${ICON_WAIT} 待機中${NC}"
      fi

      echo -e "  ${STATUS}  ${TASK_NAME}"
    fi
  done
fi

if [ $TASK_COUNT -eq 0 ]; then
  echo -e "  ${GRAY}（タスク指示書はありません）${NC}"
fi
echo ""

# ========================================
# 5. サマリー
# ========================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 サマリー${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# プログレスバー
if [ $TASK_COUNT -gt 0 ]; then
  PROGRESS=$((COMPLETED_COUNT * 100 / TASK_COUNT))
  FILLED=$((PROGRESS / 5))
  EMPTY=$((20 - FILLED))
  BAR=$(printf '%*s' "$FILLED" | tr ' ' '█')$(printf '%*s' "$EMPTY" | tr ' ' '░')
  echo -e "  進捗: [${BAR}] ${PROGRESS}% (${COMPLETED_COUNT}/${TASK_COUNT})"
else
  echo -e "  進捗: [░░░░░░░░░░░░░░░░░░░░] 0%"
fi
echo ""
echo -e "  タスク総数:    ${TASK_COUNT}"
echo -e "  完了待ち:      ${DONE_COUNT}"
echo -e "  問題報告:      ${ISSUE_COUNT}"
echo -e "  アクティブ worktree: ${WORKTREE_TASK_COUNT}"
echo ""
