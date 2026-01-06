#!/bin/bash
# init-project-intent.sh
# プロジェクトルートに PROJECT.md を作成するスクリプト

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../references/templates"

# プロジェクトルートを取得（引数で指定されていない場合は現在のディレクトリ）
PROJECT_ROOT="${1:-.}"

# プロジェクト名を取得（ディレクトリ名から）
PROJECT_NAME="$(basename "$(cd "$PROJECT_ROOT" && pwd)")"

echo "=== Project Intent 初期化 ==="
echo "プロジェクトルート: $PROJECT_ROOT"
echo "プロジェクト名: $PROJECT_NAME"
echo ""

# PROJECT.md が既に存在するかチェック
if [ -f "$PROJECT_ROOT/PROJECT.md" ]; then
    echo "⚠️  PROJECT.md は既に存在します。"
    read -p "上書きしますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "キャンセルしました。"
        exit 0
    fi
fi

# テンプレートをコピー
cp "$TEMPLATE_DIR/PROJECT.md" "$PROJECT_ROOT/PROJECT.md"

# プロジェクト名をテンプレートに挿入（Example を置き換え）
if command -v sed &> /dev/null; then
    # macOS と Linux の sed の違いに対応
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/\[プロジェクト名\]/$PROJECT_NAME/g" "$PROJECT_ROOT/PROJECT.md"
    else
        sed -i "s/\[プロジェクト名\]/$PROJECT_NAME/g" "$PROJECT_ROOT/PROJECT.md"
    fi
fi

echo "✅ PROJECT.md を作成しました: $PROJECT_ROOT/PROJECT.md"
echo ""
echo "次のステップ:"
echo "1. PROJECT.md をエディタで開く"
echo "2. Intent / North Star を記入"
echo "3. Success Criteria を定義"
echo "4. Guardrails を設定"
echo "5. Non-goals を明確化"
echo ""
echo "編集後、git に commit してください:"
echo "  git add PROJECT.md"
echo "  git commit -m \"docs: Add PROJECT.md (project intent)\""
