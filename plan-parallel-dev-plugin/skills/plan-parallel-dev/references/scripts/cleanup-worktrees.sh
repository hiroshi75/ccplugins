#!/bin/bash
# cleanup-worktrees.sh
# 完了したタスクの worktree をクリーンアップするスクリプト
#
# 使用方法:
#   ./cleanup-worktrees.sh [task-name]
#
# 例:
#   ./cleanup-worktrees.sh                    # マージ済みの全タスクをクリーンアップ
#   ./cleanup-worktrees.sh fix-login          # 特定のタスクのみクリーンアップ
#   ./cleanup-worktrees.sh --all              # 全 worktree を強制クリーンアップ（確認あり）
#
# このスクリプトは以下を実行します:
#   1. worktree の削除
#   2. ローカルブランチの削除
#   3. .done ファイルの削除
#   4. タスク指示書のステータス更新

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ヘルパー関数
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 単一タスクのクリーンアップ
cleanup_task() {
  local TASK_NAME="$1"
  local FORCE="$2"

  info "クリーンアップ中: ${TASK_NAME}"

  # worktree パス
  WORKTREE_PATH="worktree/${TASK_NAME}"

  # worktree が存在するか確認
  if [ ! -d "$WORKTREE_PATH" ]; then
    warn "worktree が見つかりません: ${WORKTREE_PATH}"
    return 1
  fi

  # ブランチ名を取得
  BRANCH=$(cd "$WORKTREE_PATH" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

  if [ -z "$BRANCH" ]; then
    warn "ブランチ名を取得できません"
    return 1
  fi

  # 未コミットの変更があるか確認
  if [ -n "$(cd "$WORKTREE_PATH" && git status --porcelain)" ]; then
    if [ "$FORCE" != "true" ]; then
      warn "${TASK_NAME} に未コミットの変更があります"
      echo -e "  ${YELLOW}クリーンアップをスキップします。強制実行するには --force を使用してください。${NC}"
      return 1
    else
      warn "未コミットの変更を無視してクリーンアップします"
    fi
  fi

  # 1. worktree を削除
  info "worktree を削除中..."
  git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || {
    rm -rf "$WORKTREE_PATH"
    git worktree prune
  }
  success "worktree 削除完了"

  # 2. ローカルブランチを削除
  info "ローカルブランチを削除中: ${BRANCH}"
  git branch -D "$BRANCH" 2>/dev/null && success "ブランチ削除完了" || warn "ブランチが見つからないか、既に削除されています"

  # 3. .done ファイルを削除
  if [ -f ".parallel-dev-signals/${TASK_NAME}.done" ]; then
    rm ".parallel-dev-signals/${TASK_NAME}.done"
    success ".done ファイル削除完了"
  fi

  # 4. .issue ファイルを削除（解決済みの場合）
  if [ -f ".parallel-dev-issues/${TASK_NAME}.md" ]; then
    rm ".parallel-dev-issues/${TASK_NAME}.md"
    success ".issue ファイル削除完了"
  fi

  # 5. タスク指示書のステータスを更新
  TASK_FILE=".parallel-dev/tasks/${TASK_NAME}.md"
  if [ -f "$TASK_FILE" ]; then
    if grep -q "| ステータス" "$TASK_FILE"; then
      # macOS と Linux の両方に対応
      if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/| ステータス | .* |/| ステータス | クリーンアップ済 |/' "$TASK_FILE"
      else
        sed -i 's/| ステータス | .* |/| ステータス | クリーンアップ済 |/' "$TASK_FILE"
      fi
      success "タスク指示書のステータスを更新"
    fi
  fi

  success "${TASK_NAME} のクリーンアップ完了"
  echo ""
}

# メイン処理
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE} 並列開発クリーンアップ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 引数処理
TARGET="$1"
FORCE="false"

if [ "$TARGET" == "--force" ] || [ "$2" == "--force" ]; then
  FORCE="true"
fi

if [ "$TARGET" == "--all" ]; then
  # 全 worktree をクリーンアップ
  echo -e "${YELLOW}警告: 全ての worktree をクリーンアップします${NC}"
  echo ""
  read -p "続行しますか？ (y/N): " CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "キャンセルしました"
    exit 0
  fi

  # worktree/ 以下の全ディレクトリを対象
  if [ -d "worktree" ]; then
    for WORKTREE_DIR in worktree/*/; do
      if [ -d "$WORKTREE_DIR" ]; then
        TASK_NAME=$(basename "$WORKTREE_DIR")
        cleanup_task "$TASK_NAME" "$FORCE" || true
      fi
    done
  fi

  # worktree ディレクトリ自体を削除
  if [ -d "worktree" ]; then
    rmdir worktree 2>/dev/null && success "worktree/ ディレクトリを削除" || true
  fi

  # 孤立した worktree を整理
  git worktree prune
  success "git worktree prune 完了"

elif [ -n "$TARGET" ] && [ "$TARGET" != "--force" ]; then
  # 特定のタスクをクリーンアップ
  cleanup_task "$TARGET" "$FORCE"

else
  # マージ済みのタスクを自動検出してクリーンアップ
  info "マージ済みタスクを検索中..."
  echo ""

  CLEANED=0

  if [ -d ".parallel-dev/tasks" ]; then
    for TASK_FILE in .parallel-dev/tasks/*.md; do
      if [ -f "$TASK_FILE" ]; then
        TASK_NAME=$(basename "$TASK_FILE" .md)

        # ステータスがマージ済みかどうか確認
        if grep -q "マージ済" "$TASK_FILE" 2>/dev/null; then
          # worktree が存在する場合のみクリーンアップ
          if [ -d "worktree/${TASK_NAME}" ]; then
            cleanup_task "$TASK_NAME" "$FORCE" && CLEANED=$((CLEANED + 1)) || true
          fi
        fi
      fi
    done
  fi

  if [ $CLEANED -eq 0 ]; then
    info "クリーンアップ対象のタスクはありません"
    echo ""
    echo "特定のタスクをクリーンアップするには:"
    echo "  $0 <task-name>"
    echo ""
    echo "全てのタスクをクリーンアップするには:"
    echo "  $0 --all"
  else
    success "${CLEANED} 個のタスクをクリーンアップしました"
  fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} クリーンアップ完了${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 残りの worktree を表示
info "残りの worktree:"
git worktree list
echo ""
