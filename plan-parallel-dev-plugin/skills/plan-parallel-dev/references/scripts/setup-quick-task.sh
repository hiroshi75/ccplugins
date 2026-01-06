#!/bin/bash
# setup-quick-task.sh
# クイックタスクのセットアップを自動化するスクリプト
#
# 使用方法:
#   ./setup-quick-task.sh <task-name> [branch-prefix] [base-branch]
#
# 例:
#   ./setup-quick-task.sh fix-login-validation
#   ./setup-quick-task.sh add-logout-button feature main
#
# このスクリプトは以下を実行します:
#   1. 必要なディレクトリの作成
#   2. .gitignore の更新
#   3. worktree の作成
#   4. 環境のセットアップ（.env コピー、依存関係インストール）
#   5. 簡易タスク指示書の生成

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
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 引数チェック
if [ -z "$1" ]; then
  echo "使用方法: $0 <task-name> [branch-prefix] [base-branch]"
  echo ""
  echo "引数:"
  echo "  task-name      タスク名（kebab-case、例: fix-login-validation）"
  echo "  branch-prefix  ブランチのプレフィックス（デフォルト: fix）"
  echo "  base-branch    ベースブランチ（デフォルト: main）"
  echo ""
  echo "例:"
  echo "  $0 fix-login-validation"
  echo "  $0 add-logout-button feature main"
  exit 1
fi

TASK_NAME="$1"
BRANCH_PREFIX="${2:-fix}"
BASE_BRANCH="${3:-main}"
BRANCH="${BRANCH_PREFIX}/${TASK_NAME}"

info "クイックタスクをセットアップ中: ${TASK_NAME}"
info "ブランチ: ${BRANCH}"
info "ベース: ${BASE_BRANCH}"

# 1. ディレクトリ作成
info "ディレクトリを作成中..."
mkdir -p .parallel-dev/tasks
mkdir -p .parallel-dev-signals
mkdir -p .parallel-dev-issues
success "ディレクトリ作成完了"

# 2. .gitignore 更新
info ".gitignore を更新中..."
if [ -f .gitignore ]; then
  grep -q "^\.parallel-dev-signals/$" .gitignore 2>/dev/null || echo ".parallel-dev-signals/" >> .gitignore
  grep -q "^\.parallel-dev-issues/$" .gitignore 2>/dev/null || echo ".parallel-dev-issues/" >> .gitignore
  grep -q "^worktree/$" .gitignore 2>/dev/null || echo "worktree/" >> .gitignore
  grep -q "^\.intent/brief\.json$" .gitignore 2>/dev/null || echo ".intent/brief.json" >> .gitignore
  grep -q "^worktree/\*\*/\.intent/brief\.json$" .gitignore 2>/dev/null || echo "worktree/**/.intent/brief.json" >> .gitignore
  success ".gitignore 更新完了"
else
  cat > .gitignore << 'EOF'
.parallel-dev-signals/
.parallel-dev-issues/
worktree/
.intent/brief.json
worktree/**/.intent/brief.json
EOF
  success ".gitignore 作成完了"
fi

# 3. worktree 作成
info "worktree を作成中..."
if [ -d "worktree/${TASK_NAME}" ]; then
  warn "worktree/${TASK_NAME} は既に存在します。スキップします。"
else
  git worktree add "worktree/${TASK_NAME}" -b "${BRANCH}"
  success "worktree 作成完了: worktree/${TASK_NAME}"
fi

# 4. 環境セットアップ
info "環境をセットアップ中..."

# .env コピー
if [ -f .env ]; then
  cp .env "worktree/${TASK_NAME}/.env"
  success ".env をコピー"
fi

# ポート番号の計算（既存 worktree 数に基づく）
WORKTREE_COUNT=$(git worktree list | wc -l)
PORT_BE=$((3000 + WORKTREE_COUNT - 1))
PORT_FE=$((5173 + WORKTREE_COUNT - 1))

# .env.local 作成
cat > "worktree/${TASK_NAME}/.env.local" << EOF
# クイックタスク: ${TASK_NAME}
# 自動生成: $(date '+%Y-%m-%d %H:%M')
PORT=${PORT_BE}
VITE_PORT=${PORT_FE}
EOF
success ".env.local 作成（BE: ${PORT_BE}, FE: ${PORT_FE}）"

# .intent/brief.json 作成（gitignore される）
info ".intent/brief.json を作成中..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"

# .intent ディレクトリを作成
mkdir -p "worktree/${TASK_NAME}/.intent"

cat > "worktree/${TASK_NAME}/.intent/brief.json" << EOF
{
  "\$schema": "https://json-schema.org/draft/2020-12/schema",
  "_comment": "Worktree BRIEF（作業コンテキスト）- このファイルは .gitignore で除外する。随時更新。",

  "parentProject": "${PROJECT_NAME}",
  "projectJsonPath": "../../.intent/project.json",

  "purpose": "クイックタスク ${TASK_NAME} のために作成された一時的な worktree。",

  "mode": "maintain",

  "focus": [
    "（注目点を記載。例: バグ修正の正確性、パフォーマンス改善、など）"
  ],

  "nonGoals": [
    "（このタスクで明示的にやらないことを記載）"
  ],

  "nextBet": "（次に試す一手を記載）",

  "exitCriteria": [
    "タスクの実装が完了",
    "ローカルでの動作確認完了",
    ".done ファイル作成済み"
  ],

  "decisionsLog": [],

  "discardedOptions": [],

  "notes": []
}
EOF
success ".intent/brief.json 作成"

# 依存関係インストール
cd "worktree/${TASK_NAME}"
if [ -f "pyproject.toml" ]; then
  info "Python 依存関係をインストール中（uv sync）..."
  uv sync 2>/dev/null && success "uv sync 完了" || warn "uv sync 失敗（手動で実行してください）"
elif [ -f "package.json" ]; then
  if command -v pnpm &> /dev/null; then
    info "Node.js 依存関係をインストール中（pnpm install）..."
    pnpm install 2>/dev/null && success "pnpm install 完了" || warn "pnpm install 失敗"
  elif command -v npm &> /dev/null; then
    info "Node.js 依存関係をインストール中（npm install）..."
    npm install 2>/dev/null && success "npm install 完了" || warn "npm install 失敗"
  fi
fi
cd ../..

# 5. タスク指示書の生成
info "タスク指示書を生成中..."
CREATED_AT=$(date '+%Y-%m-%d %H:%M')

cat > ".parallel-dev/tasks/${TASK_NAME}.md" << EOF
# クイックタスク: ${TASK_NAME}

## 基本情報

| 項目 | 内容 |
|------|------|
| 依頼内容 | （ここに依頼内容を記載） |
| ブランチ | \`${BRANCH}\` |
| worktree | \`worktree/${TASK_NAME}/\` |
| ベースブランチ | \`${BASE_BRANCH}\` |
| 作成日時 | ${CREATED_AT} |
| ステータス | 作業中 |
| ポート | BE: ${PORT_BE}, FE: ${PORT_FE} |

---

## 実行コンテキスト

このタスクはマージ担当から tmux 経由で起動される。
作業ディレクトリ: \`worktree/${TASK_NAME}/\`

**環境変数 \`PROJECT_ROOT\`**: tmux 起動時に渡されるプロジェクトルートへの絶対パス。

---

## 依頼内容

（ここに具体的な依頼内容を記載）

---

## 作業手順

1. 依頼内容を理解し、関連ファイルを特定
2. 修正を実装
3. ローカルで動作確認
4. .done ファイルを作成

---

## 完了時

\`\`\`bash
cat > \$PROJECT_ROOT/.parallel-dev-signals/${TASK_NAME}.done << 'DONE_EOF'
【完了報告】${TASK_NAME}

## 実装内容
- （実装した内容）
- （変更したファイル）

## 動作確認
ローカルでの動作確認: OK

## 備考
（その他の情報）
DONE_EOF
\`\`\`

---

## ルール

- **コミットしない**: コードを書くだけ。コミットはマージ担当が行う
- **プッシュしない**: リモートへのプッシュもマージ担当が行う
EOF

success "タスク指示書作成: .parallel-dev/tasks/${TASK_NAME}.md"

# 完了メッセージ
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} クイックタスクのセットアップ完了${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "次のステップ:"
echo ""
echo "1. タスク指示書を編集して依頼内容を記載:"
echo "   vim .parallel-dev/tasks/${TASK_NAME}.md"
echo ""
echo "2. 作業用 Claude を起動:"
echo "   export PROJECT_ROOT=\$(pwd)"
echo "   tmux split-window -h \"cd worktree/${TASK_NAME} && PROJECT_ROOT=\$PROJECT_ROOT claude '../../.parallel-dev/tasks/${TASK_NAME}.md を読んで実装してください。完了したら .done ファイルを作成してください。'\""
echo "   tmux select-pane -T \"${TASK_NAME}\""
echo ""
