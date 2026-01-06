#!/bin/bash
# init-brief.sh
# worktree に .intent/brief.json を作成するスクリプト

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

# .intent ディレクトリを作成
mkdir -p "$WORKTREE_PATH/.intent"

# brief.json が既に存在するかチェック
if [ -f "$WORKTREE_PATH/.intent/brief.json" ]; then
    echo "⚠️  .intent/brief.json は既に存在します。"
    read -p "上書きしますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "キャンセルしました。"
        exit 0
    fi
fi

# テンプレートをコピー
cp "$TEMPLATE_DIR/brief.json" "$WORKTREE_PATH/.intent/brief.json"

# プロジェクトルートを探す（.intent/project.json がある場所）
PROJECT_ROOT="$WORKTREE_PATH"
while [ "$PROJECT_ROOT" != "/" ]; do
    if [ -f "$PROJECT_ROOT/.intent/project.json" ]; then
        break
    fi
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done

# project.json へのパスを計算
if [ -f "$PROJECT_ROOT/.intent/project.json" ]; then
    PROJECT_JSON_PATH="$(realpath --relative-to="$WORKTREE_PATH/.intent" "$PROJECT_ROOT/.intent/project.json" 2>/dev/null || echo "$PROJECT_ROOT/.intent/project.json")"
    PROJECT_NAME="$(basename "$PROJECT_ROOT")"
else
    PROJECT_JSON_PATH="../.intent/project.json"
    PROJECT_NAME="[プロジェクト名を記入]"
fi

# プレースホルダーを置き換え（JSON 用）
if command -v sed &> /dev/null; then
    # macOS と Linux の sed の違いに対応
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|\[プロジェクト名\]|$PROJECT_NAME|g" "$WORKTREE_PATH/.intent/brief.json"
        sed -i '' "s|../../.intent/project.json|$PROJECT_JSON_PATH|g" "$WORKTREE_PATH/.intent/brief.json"
    else
        sed -i "s|\[プロジェクト名\]|$PROJECT_NAME|g" "$WORKTREE_PATH/.intent/brief.json"
        sed -i "s|../../.intent/project.json|$PROJECT_JSON_PATH|g" "$WORKTREE_PATH/.intent/brief.json"
    fi
fi

echo "✅ .intent/brief.json を作成しました: $WORKTREE_PATH/.intent/brief.json"
echo ""
echo "次のステップ:"
echo "1. .intent/brief.json をエディタで開く"
echo "2. purpose を記入（この worktree の目的）"
echo "3. mode を選択（explore/converge/maintain）"
echo "4. focus を明確化（配列）"
echo "5. nonGoals を設定（配列）"
echo "6. nextBet を定義"
echo ""
echo "⚠️  注意: .intent/brief.json は .gitignore に含めてください"
echo "  echo '.intent/brief.json' >> .gitignore"
echo "  echo 'worktrees/**/.intent/brief.json' >> .gitignore"
