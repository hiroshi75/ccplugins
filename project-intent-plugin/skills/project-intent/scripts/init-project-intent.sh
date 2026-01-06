#!/bin/bash
# init-project-intent.sh
# プロジェクトルートに .intent/project.json を作成するスクリプト

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

# .intent ディレクトリを作成
mkdir -p "$PROJECT_ROOT/.intent"

# project.json が既に存在するかチェック
if [ -f "$PROJECT_ROOT/.intent/project.json" ]; then
    echo "⚠️  .intent/project.json は既に存在します。"
    read -p "上書きしますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "キャンセルしました。"
        exit 0
    fi
fi

# テンプレートをコピー
cp "$TEMPLATE_DIR/project.json" "$PROJECT_ROOT/.intent/project.json"

echo "✅ .intent/project.json を作成しました: $PROJECT_ROOT/.intent/project.json"
echo ""
echo "次のステップ:"
echo "1. .intent/project.json をエディタで開く"
echo "2. intent を記入（プロジェクトの狙い・目指す姿）"
echo "3. successCriteria を定義（配列）"
echo "4. guardrails を設定（配列）"
echo "5. nonGoals を明確化（配列）"
echo ""
echo "編集後、git に commit してください:"
echo "  git add .intent/project.json"
echo "  git commit -m \"docs: Add .intent/project.json (project intent)\""
