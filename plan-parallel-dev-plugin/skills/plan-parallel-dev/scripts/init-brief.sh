#!/bin/bash
# init-brief.sh
# worktree に BRIEF.md を作成するスクリプト

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../references/templates"

# 引数チェック
if [ $# -lt 1 ]; then
    echo "Usage: $0 <worktree-name> [worktree-path]"
    echo ""
    echo "Example:"
    echo "  $0 feature-auth-api"
    echo "  $0 feature-auth-api /path/to/worktrees/feature-auth-api"
    exit 1
fi

WORKTREE_NAME="$1"
WORKTREE_PATH="${2:-.}"

echo "=== Worktree BRIEF 初期化 ==="
echo "Worktree 名: $WORKTREE_NAME"
echo "Worktree パス: $WORKTREE_PATH"
echo ""

# BRIEF.md が既に存在するかチェック
if [ -f "$WORKTREE_PATH/BRIEF.md" ]; then
    echo "⚠️  BRIEF.md は既に存在します。"
    read -p "上書きしますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "キャンセルしました。"
        exit 0
    fi
fi

# テンプレートをコピー
cp "$TEMPLATE_DIR/BRIEF.md" "$WORKTREE_PATH/BRIEF.md"

# プロジェクトルートを探す（PROJECT.md がある場所）
PROJECT_ROOT="$WORKTREE_PATH"
while [ "$PROJECT_ROOT" != "/" ]; do
    if [ -f "$PROJECT_ROOT/PROJECT.md" ]; then
        break
    fi
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done

# PROJECT.md へのパスを計算
if [ -f "$PROJECT_ROOT/PROJECT.md" ]; then
    PROJECT_MD_PATH="$(realpath --relative-to="$WORKTREE_PATH" "$PROJECT_ROOT/PROJECT.md" 2>/dev/null || echo "$PROJECT_ROOT/PROJECT.md")"
    PROJECT_NAME="$(basename "$PROJECT_ROOT")"
else
    PROJECT_MD_PATH="[PROJECT.md のパスを記入]"
    PROJECT_NAME="[プロジェクト名を記入]"
fi

# プレースホルダーを置き換え
if command -v sed &> /dev/null; then
    # macOS と Linux の sed の違いに対応
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|\[プロジェクト名\]|$PROJECT_NAME|g" "$WORKTREE_PATH/BRIEF.md"
        sed -i '' "s|\[PROJECT.mdへのパス\]|$PROJECT_MD_PATH|g" "$WORKTREE_PATH/BRIEF.md"
    else
        sed -i "s|\[プロジェクト名\]|$PROJECT_NAME|g" "$WORKTREE_PATH/BRIEF.md"
        sed -i "s|\[PROJECT.mdへのパス\]|$PROJECT_MD_PATH|g" "$WORKTREE_PATH/BRIEF.md"
    fi
fi

echo "✅ BRIEF.md を作成しました: $WORKTREE_PATH/BRIEF.md"
echo ""
echo "次のステップ:"
echo "1. BRIEF.md をエディタで開く"
echo "2. Why this worktree exists を記入"
echo "3. Mode を選択（探索/収束/保守）"
echo "4. Focus を明確化"
echo "5. Non-goals を設定"
echo "6. Next Bet を定義"
echo ""
echo "⚠️  注意: BRIEF.md は .gitignore に含めてください"
echo "  echo 'BRIEF.md' >> .gitignore"
echo "  echo 'worktrees/**/BRIEF.md' >> .gitignore"
