#!/bin/bash
# load-context.sh
# PROJECT.md と BRIEF.md を読み込んで、Claude に渡すためのコンテキストを生成

set -euo pipefail

# 引数チェック
WORKTREE_PATH="${1:-.}"

echo "=== Project Context Loading ==="
echo ""

# プロジェクトルートを探す（PROJECT.md がある場所）
PROJECT_ROOT="$WORKTREE_PATH"
while [ "$PROJECT_ROOT" != "/" ]; do
    if [ -f "$PROJECT_ROOT/PROJECT.md" ]; then
        break
    fi
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done

# PROJECT.md の存在チェック
if [ ! -f "$PROJECT_ROOT/PROJECT.md" ]; then
    echo "⚠️  PROJECT.md が見つかりません。"
    echo "以下のコマンドで作成してください:"
    echo "  bash scripts/init-project-intent.sh"
    exit 1
fi

# BRIEF.md の存在チェック
if [ ! -f "$WORKTREE_PATH/BRIEF.md" ]; then
    echo "⚠️  BRIEF.md が見つかりません。"
    echo "以下のコマンドで作成してください:"
    echo "  bash scripts/init-brief.sh <worktree-name>"
    exit 1
fi

echo "📄 PROJECT.md: $PROJECT_ROOT/PROJECT.md"
echo "📄 BRIEF.md: $WORKTREE_PATH/BRIEF.md"
echo ""
echo "---"
echo ""

# PROJECT.md の主要セクションを抽出
echo "## プロジェクト全体の方針 (PROJECT.md)"
echo ""
if command -v grep &> /dev/null && command -v sed &> /dev/null; then
    # Intent / North Star セクションを抽出
    echo "### Intent / North Star"
    sed -n '/## Intent \/ North Star/,/^## /p' "$PROJECT_ROOT/PROJECT.md" | sed '$d' | grep -v "^## Intent"
    echo ""

    # Success Criteria セクションを抽出
    echo "### Success Criteria"
    sed -n '/## Success Criteria/,/^## /p' "$PROJECT_ROOT/PROJECT.md" | sed '$d' | grep -v "^## Success"
    echo ""

    # Guardrails セクションを抽出
    echo "### Guardrails"
    sed -n '/## Guardrails/,/^## /p' "$PROJECT_ROOT/PROJECT.md" | sed '$d' | grep -v "^## Guardrails"
    echo ""

    # Non-goals セクションを抽出
    echo "### Non-goals"
    sed -n '/## Project-level Non-goals/,/^## /p' "$PROJECT_ROOT/PROJECT.md" | sed '$d' | grep -v "^## Project-level"
    echo ""
else
    # grep/sed が使えない場合は全文表示
    cat "$PROJECT_ROOT/PROJECT.md"
fi

echo "---"
echo ""

# BRIEF.md の主要セクションを抽出
echo "## この Worktree の方針 (BRIEF.md)"
echo ""
if command -v grep &> /dev/null && command -v sed &> /dev/null; then
    # Mode セクションを抽出
    echo "### Mode"
    sed -n '/## Mode/,/^## /p' "$WORKTREE_PATH/BRIEF.md" | sed '$d' | grep -v "^## Mode"
    echo ""

    # Focus セクションを抽出
    echo "### Focus"
    sed -n '/## Focus/,/^## /p' "$WORKTREE_PATH/BRIEF.md" | sed '$d' | grep -v "^## Focus"
    echo ""

    # Non-goals セクションを抽出
    echo "### Non-goals"
    sed -n '/## Non-goals/,/^## /p' "$WORKTREE_PATH/BRIEF.md" | sed '$d' | grep -v "^## Non-goals"
    echo ""

    # Next Bet セクションを抽出
    echo "### Next Bet"
    sed -n '/## Next Bet/,/^## /p' "$WORKTREE_PATH/BRIEF.md" | sed '$d' | grep -v "^## Next Bet"
    echo ""
else
    # grep/sed が使えない場合は全文表示
    cat "$WORKTREE_PATH/BRIEF.md"
fi

echo "---"
echo ""
echo "✅ コンテキストの読み込みが完了しました。"
echo ""
echo "Claude に以下のように指示してください:"
echo "---"
echo "上記の PROJECT.md と BRIEF.md の内容を踏まえて、"
echo "Mode / Focus / Non-goals / Next Bet を要約してから作業を開始してください。"
echo "---"
