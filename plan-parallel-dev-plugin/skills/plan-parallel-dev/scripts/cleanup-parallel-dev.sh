#!/bin/bash
# cleanup-parallel-dev.sh - 並列開発完了後のクリーンアップ
#
# 使用例:
#   ./cleanup-parallel-dev.sh           # 確認ありでクリーンアップ
#   ./cleanup-parallel-dev.sh --force   # 確認なしでクリーンアップ

set -e

FORCE=false
if [ "$1" = "--force" ]; then
  FORCE=true
fi

echo "=== 並列開発クリーンアップ ==="

# 確認
if [ "$FORCE" = false ]; then
  echo "すべてのタスクがマージ済みであることを確認してください。"
  read -p "続行しますか？ (y/N): " confirm
  if [[ "$confirm" != "y" ]]; then
    echo "キャンセルしました。"
    exit 1
  fi
fi

# worktree 削除
echo "worktree を削除中..."
for wt in worktree/*/; do
  if [ -d "$wt" ]; then
    echo "  削除: $wt"
    git worktree remove "$wt" 2>/dev/null || rm -rf "$wt"
  fi
done
git worktree prune

# worktree ディレクトリ削除
if [ -d "worktree" ]; then
  rm -rf worktree/
  echo "worktree/ ディレクトリを削除しました"
fi

# シグナルディレクトリ削除
if [ -d ".parallel-dev-signals" ]; then
  rm -rf .parallel-dev-signals/
  echo ".parallel-dev-signals/ を削除しました"
fi

# issue ディレクトリ削除
if [ -d ".parallel-dev-issues" ]; then
  rm -rf .parallel-dev-issues/
  echo ".parallel-dev-issues/ を削除しました"
fi

# .parallel-dev/ 削除（オプション）
if [ -d ".parallel-dev" ]; then
  if [ "$FORCE" = false ]; then
    read -p ".parallel-dev/ も削除しますか？ (y/N): " confirm_pd
    if [[ "$confirm_pd" = "y" ]]; then
      rm -rf .parallel-dev/
      echo ".parallel-dev/ を削除しました"
    else
      echo ".parallel-dev/ は残しました"
    fi
  else
    rm -rf .parallel-dev/
    echo ".parallel-dev/ を削除しました"
  fi
fi

echo ""
echo "=== クリーンアップ完了 ==="
echo "ブランチの削除は手動で行ってください: git branch -d <branch-name>"
