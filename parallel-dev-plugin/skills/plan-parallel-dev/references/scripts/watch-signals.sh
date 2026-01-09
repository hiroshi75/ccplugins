#!/bin/bash
# watch-signals.sh
# .done ファイルと .issues ファイルを監視するスクリプト
#
# 使用方法:
#   ./watch-signals.sh [interval] [max-iterations]
#
# 例:
#   ./watch-signals.sh           # デフォルト: 5秒間隔、108回（9分）
#   ./watch-signals.sh 10        # 10秒間隔
#   ./watch-signals.sh 5 60      # 5秒間隔、60回（5分）
#
# 検知したファイルがあればループを終了し、内容を表示します。

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 引数
INTERVAL="${1:-5}"
MAX_ITERATIONS="${2:-108}"

# ディレクトリ
SIGNALS_DIR=".parallel-dev-signals"
ISSUES_DIR=".parallel-dev-issues"

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN} 並列開発シグナル監視${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "監視対象:"
echo -e "  - ${GREEN}${SIGNALS_DIR}/*.done${NC} (完了通知)"
echo -e "  - ${YELLOW}${ISSUES_DIR}/*.md${NC} (問題報告)"
echo ""
echo -e "設定: ${INTERVAL}秒間隔、最大${MAX_ITERATIONS}回 ($(( INTERVAL * MAX_ITERATIONS / 60 ))分)"
echo ""
echo -e "${BLUE}監視を開始します... (Ctrl+C で中断)${NC}"
echo ""

# 処理済みファイルを記録
PROCESSED_DONE=""
PROCESSED_ISSUES=""

for i in $(seq 1 $MAX_ITERATIONS); do
  TIMESTAMP=$(date '+%H:%M:%S')

  # 完了通知を確認
  if [ -d "$SIGNALS_DIR" ]; then
    DONE_FILES=$(ls ${SIGNALS_DIR}/*.done 2>/dev/null || true)
    if [ -n "$DONE_FILES" ]; then
      for DONE_FILE in $DONE_FILES; do
        # 既に処理済みでなければ表示
        if [[ ! "$PROCESSED_DONE" =~ "$DONE_FILE" ]]; then
          TASK_NAME=$(basename "$DONE_FILE" .done)
          echo ""
          echo -e "${GREEN}========================================${NC}"
          echo -e "${GREEN} [${TIMESTAMP}] 完了検知: ${TASK_NAME}${NC}"
          echo -e "${GREEN}========================================${NC}"
          echo ""
          cat "$DONE_FILE"
          echo ""
          echo -e "${GREEN}----------------------------------------${NC}"
          echo ""
          PROCESSED_DONE="$PROCESSED_DONE $DONE_FILE"

          # 完了を検知したら終了するかどうか選択
          echo -e "${YELLOW}次のアクション:${NC}"
          echo "  1. マージ処理を開始する場合は Ctrl+C で中断"
          echo "  2. 他のタスクの完了を待つ場合は継続"
          echo ""
        fi
      done
    fi
  fi

  # 問題報告を確認
  if [ -d "$ISSUES_DIR" ]; then
    ISSUE_FILES=$(ls ${ISSUES_DIR}/*.md 2>/dev/null || true)
    if [ -n "$ISSUE_FILES" ]; then
      for ISSUE_FILE in $ISSUE_FILES; do
        # 既に処理済みでなければ表示
        if [[ ! "$PROCESSED_ISSUES" =~ "$ISSUE_FILE" ]]; then
          TASK_NAME=$(basename "$ISSUE_FILE" .md)
          echo ""
          echo -e "${YELLOW}========================================${NC}"
          echo -e "${YELLOW} [${TIMESTAMP}] 問題報告: ${TASK_NAME}${NC}"
          echo -e "${YELLOW}========================================${NC}"
          echo ""
          cat "$ISSUE_FILE"
          echo ""
          echo -e "${YELLOW}----------------------------------------${NC}"
          echo ""
          PROCESSED_ISSUES="$PROCESSED_ISSUES $ISSUE_FILE"
        fi
      done
    fi
  fi

  # 進捗表示（10回ごと）
  if [ $((i % 10)) -eq 0 ]; then
    echo -e "${BLUE}[${TIMESTAMP}] チェック ${i}/${MAX_ITERATIONS}...${NC}"
  fi

  sleep $INTERVAL
done

echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW} 監視時間終了（${MAX_ITERATIONS}回チェック完了）${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "完了通知がない場合は、再度監視を実行してください:"
echo "  ./watch-signals.sh"
