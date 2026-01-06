#!/bin/bash
# load-context.sh
# .intent/project.json と .intent/brief.json を読み込んで、Claude に渡すためのコンテキストを生成

set -euo pipefail

# 引数チェック
WORKTREE_PATH="${1:-.}"

echo "=== Project Context Loading ==="
echo ""

# プロジェクトルートを探す（.intent/project.json がある場所）
PROJECT_ROOT="$WORKTREE_PATH"
while [ "$PROJECT_ROOT" != "/" ]; do
    if [ -f "$PROJECT_ROOT/.intent/project.json" ]; then
        break
    fi
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done

# project.json の存在チェック
if [ ! -f "$PROJECT_ROOT/.intent/project.json" ]; then
    echo "⚠️  .intent/project.json が見つかりません。"
    echo "以下のコマンドで作成してください:"
    echo "  bash scripts/init-project-intent.sh"
    exit 1
fi

# brief.json の存在チェック
if [ ! -f "$WORKTREE_PATH/.intent/brief.json" ]; then
    echo "⚠️  .intent/brief.json が見つかりません。"
    echo "以下のコマンドで作成してください:"
    echo "  bash scripts/init-brief.sh <worktree-name>"
    exit 1
fi

echo "📄 project.json: $PROJECT_ROOT/.intent/project.json"
echo "📄 brief.json: $WORKTREE_PATH/.intent/brief.json"
echo ""
echo "---"
echo ""

# project.json の内容を表示
echo "## プロジェクト全体の方針 (.intent/project.json)"
echo ""
if command -v jq &> /dev/null; then
    # jq が使える場合は整形して表示
    echo "### Intent"
    jq -r '.intent' "$PROJECT_ROOT/.intent/project.json"
    echo ""

    echo "### Success Criteria"
    jq -r '.successCriteria[]' "$PROJECT_ROOT/.intent/project.json" 2>/dev/null | while read -r line; do
        echo "- $line"
    done
    echo ""

    echo "### Guardrails"
    jq -r '.guardrails[]' "$PROJECT_ROOT/.intent/project.json" 2>/dev/null | while read -r line; do
        echo "- $line"
    done
    echo ""

    echo "### Non-goals"
    jq -r '.nonGoals[]' "$PROJECT_ROOT/.intent/project.json" 2>/dev/null | while read -r line; do
        echo "- $line"
    done
    echo ""
else
    # jq が使えない場合は全文表示
    cat "$PROJECT_ROOT/.intent/project.json"
fi

echo "---"
echo ""

# brief.json の内容を表示
echo "## この Worktree の方針 (.intent/brief.json)"
echo ""
if command -v jq &> /dev/null; then
    # jq が使える場合は整形して表示
    echo "### Mode"
    jq -r '.mode' "$WORKTREE_PATH/.intent/brief.json"
    echo ""

    echo "### Focus"
    jq -r '.focus[]' "$WORKTREE_PATH/.intent/brief.json" 2>/dev/null | while read -r line; do
        echo "- $line"
    done
    echo ""

    echo "### Non-goals"
    jq -r '.nonGoals[]' "$WORKTREE_PATH/.intent/brief.json" 2>/dev/null | while read -r line; do
        echo "- $line"
    done
    echo ""

    echo "### Next Bet"
    jq -r '.nextBet' "$WORKTREE_PATH/.intent/brief.json"
    echo ""
else
    # jq が使えない場合は全文表示
    cat "$WORKTREE_PATH/.intent/brief.json"
fi

echo "---"
echo ""
echo "✅ コンテキストの読み込みが完了しました。"
echo ""
echo "Claude に以下のように指示してください:"
echo "---"
echo "上記の project.json と brief.json の内容を踏まえて、"
echo "mode / focus / nonGoals / nextBet を要約してから作業を開始してください。"
echo "---"
