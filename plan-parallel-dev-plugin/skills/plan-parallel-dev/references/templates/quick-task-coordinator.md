# クイックタスクコーディネーター指示書テンプレート

クイックタスクモード（モード B）で、タスク受付・worktree セットアップ・マージを担当する Claude 向けの指示書。
初期並列開発モード（モード A）の merge-coordinator.md とは異なり、計画書なしでオンデマンドにタスクを処理する。

ファイル名: `.parallel-dev/quick-task-coordinator.md`（任意、セッション中に参照用として作成）

---

## テンプレート

```markdown
# クイックタスクコーディネーター指示書

## 役割

この Claude はクイックタスクモード（モード B）において以下を担当する:

### タスク受付
- ユーザーからのタスク依頼を受け付け
- タスク名（kebab-case）を決定
- worktree とブランチを作成
- 簡易タスク指示書を生成

### 作業用 Claude の起動
- **Bash ツールで `tmux split-window` を実行して起動**
- PROJECT_ROOT 環境変数を渡す
- ペインにタスク名を設定

### 完了監視・マージ
- `.parallel-dev-signals/*.done` を監視
- 完了したタスクをコミット・テスト・マージ
- worktree のクリーンアップ

---

## タスク受付フロー

### 1. タスク依頼の受付

ユーザーから以下のような依頼を受ける:
- 「〇〇を並列で修正して」
- 「worktree で△△をやって」
- 「並列タスクを追加: 〇〇」

### 2. タスク名の決定

依頼内容から適切なタスク名を決定（kebab-case）:

| 作業種類 | プレフィックス | 例 |
|----------|---------------|-----|
| バグ修正 | `fix-` | `fix-login-validation` |
| 機能追加 | `add-` / `feature-` | `add-logout-button` |
| 改善 | `improve-` | `improve-search-perf` |
| リファクタリング | `refactor-` | `refactor-auth` |

### 3. 初期セットアップ

```bash
# 変数設定
TASK_NAME="{task-name}"
BRANCH="fix/${TASK_NAME}"  # または feature/ に応じて
BASE_BRANCH="main"  # または指定されたブランチ

# ディレクトリ作成（初回のみ）
mkdir -p .parallel-dev/tasks
mkdir -p .parallel-dev-signals
mkdir -p .parallel-dev-issues

# .gitignore 追加（未追加の場合）
grep -q ".parallel-dev-signals/" .gitignore 2>/dev/null || echo ".parallel-dev-signals/" >> .gitignore
grep -q ".parallel-dev-issues/" .gitignore 2>/dev/null || echo ".parallel-dev-issues/" >> .gitignore
grep -q "worktree/" .gitignore 2>/dev/null || echo "worktree/" >> .gitignore

# worktree 作成
git worktree add worktree/${TASK_NAME} -b ${BRANCH}

# 環境セットアップ
cp .env worktree/${TASK_NAME}/.env 2>/dev/null || true
cd worktree/${TASK_NAME}

# 依存関係インストール
if [ -f "pyproject.toml" ]; then
  uv sync
elif [ -f "package.json" ]; then
  pnpm install
fi

cd ../..
```

### 4. タスク指示書の生成

`.parallel-dev/tasks/${TASK_NAME}.md` を作成:

```markdown
# クイックタスク: ${TASK_NAME}

## 基本情報

| 項目 | 内容 |
|------|------|
| 依頼内容 | {ユーザーの依頼} |
| ブランチ | ${BRANCH} |
| worktree | worktree/${TASK_NAME}/ |
| ベースブランチ | ${BASE_BRANCH} |
| 作成日時 | $(date '+%Y-%m-%d %H:%M') |
| ステータス | 作業中 |

## 依頼内容

{依頼内容をそのまま記載}

## 作業手順

1. 依頼内容を理解し、関連ファイルを特定
2. 修正を実装
3. ローカルで動作確認
4. .done ファイルを作成

## ルール

- コミットしない
- プッシュしない
- 完了したら .done ファイルを作成
```

### 5. 作業用 Claude の起動

```bash
export PROJECT_ROOT=$(pwd)

# ペインタイトル表示を有効化（初回のみ）
tmux set-option pane-border-status top
tmux set-option pane-border-format " #{pane_index}: #{pane_title} "

# 作業用 Claude を起動
tmux split-window -h "cd worktree/${TASK_NAME} && PROJECT_ROOT=$PROJECT_ROOT claude '../../.parallel-dev/tasks/${TASK_NAME}.md を読んで実装してください。完了したら .done ファイルを作成してください。'"
tmux select-pane -T "${TASK_NAME}"

# レイアウト調整（複数タスクの場合）
tmux select-layout tiled
```

---

## 完了監視

### 監視ループ

```bash
# 5秒間隔で監視（最大9分）
for i in {1..108}; do
  echo "=== チェック $i/108: $(date) ==="

  # 完了通知を確認
  DONE_FILES=$(ls .parallel-dev-signals/*.done 2>/dev/null || true)
  if [ -n "$DONE_FILES" ]; then
    echo "完了通知あり: $DONE_FILES"
    break
  fi

  # 問題報告を確認
  ISSUE_FILES=$(ls .parallel-dev-issues/*.md 2>/dev/null || true)
  if [ -n "$ISSUE_FILES" ]; then
    echo "問題報告あり: $ISSUE_FILES"
    break
  fi

  sleep 5
done
```

### 監視対象

```
project-root/
├── .parallel-dev-signals/     # 完了通知
│   └── {task-name}.done
└── .parallel-dev-issues/      # 問題報告
    └── {task-name}.md
```

---

## マージフロー

### .done 検知後の手順

```bash
TASK_NAME="{完了したタスク名}"
BRANCH="fix/${TASK_NAME}"  # または feature/
BASE_BRANCH="main"

# 1. worktree に移動してコミット
cd worktree/${TASK_NAME}
git add .
git commit -m "fix: ${TASK_NAME}"  # または feat:

# 2. ベースブランチの最新を取り込み
git fetch origin
git merge origin/${BASE_BRANCH} --no-ff -m "Merge ${BASE_BRANCH}"

# 3. コンフリクトがあれば解決

# 4. テスト実行
{test-command}

# 5. テスト成功 → プッシュ
git push origin ${BRANCH}

# 6. プロジェクトルートに戻ってマージ
cd ../..
git checkout ${BASE_BRANCH}
git pull origin ${BASE_BRANCH}
git merge origin/${BRANCH} --no-ff -m "Merge ${BRANCH}"
git push origin ${BASE_BRANCH}

# 7. クリーンアップ
rm .parallel-dev-signals/${TASK_NAME}.done
git worktree remove worktree/${TASK_NAME}
git branch -d ${BRANCH}

# 8. タスク指示書のステータスを更新
# .parallel-dev/tasks/${TASK_NAME}.md の ステータス を「マージ済」に
```

### テスト失敗時

```bash
# .done を削除
rm .parallel-dev-signals/${TASK_NAME}.done

# 修正依頼を作成
cat > .parallel-dev-issues/${TASK_NAME}.md << 'EOF'
【修正依頼】${TASK_NAME}

## 状況
テストが失敗しました。

## エラー内容
{エラー出力}

## 対応依頼
worktree/${TASK_NAME}/ で修正し、再度 .done ファイルを作成してください。
EOF

# 作業用 Claude を再起動
tmux split-window -h "cd worktree/${TASK_NAME} && PROJECT_ROOT=$PROJECT_ROOT claude '$PROJECT_ROOT/.parallel-dev-issues/${TASK_NAME}.md を読んで修正してください。'"
tmux select-pane -T "${TASK_NAME}-fix"
```

### PR 作成を選択する場合

直接マージではなく PR を作成する場合:

```bash
# プッシュ後に PR 作成
git push origin ${BRANCH}
gh pr create --base ${BASE_BRANCH} --head ${BRANCH} \
  --title "fix: ${TASK_NAME}" \
  --body "## 概要
{依頼内容}

## 変更内容
{.done ファイルの内容から抜粋}"
```

---

## 複数タスクの並列処理

### 一括セットアップ

```bash
TASKS=("fix-login-validation" "add-logout-button" "update-header")
export PROJECT_ROOT=$(pwd)

for TASK in "${TASKS[@]}"; do
  # worktree 作成
  git worktree add worktree/${TASK} -b fix/${TASK}
  cp .env worktree/${TASK}/.env 2>/dev/null || true

  # 指示書生成（各タスクに応じて内容を変更）
  # ...

  # 作業用 Claude 起動
  tmux split-window -h "cd worktree/${TASK} && PROJECT_ROOT=$PROJECT_ROOT claude '../../.parallel-dev/tasks/${TASK}.md を読んで実装してください。'"
  tmux select-pane -T "${TASK}"
done

tmux select-layout tiled
```

### 完了したものから順次マージ

複数タスクが並列で動作している場合、完了したものから順にマージする。
依存関係がなければ順序は問わない。

---

## 問題対応

### 問題報告の確認

`.parallel-dev-issues/${TASK_NAME}.md` を確認し、内容に応じて対応:

1. **軽微な問題**: 作業用 Claude に修正を依頼
2. **ブロッキング問題**: 人間に報告（AskUserQuestion）
3. **別タスクへの影響**: 関連タスクを一時停止

### 新規タスク追加が必要な場合

問題解決に別タスクが必要な場合:

```bash
# 新しいタスクとして追加
NEW_TASK="fix-${TASK_NAME}-related"
git worktree add worktree/${NEW_TASK} -b fix/${NEW_TASK}
# ... セットアップと起動
```

---

## ルール

- **`--no-ff` で常にマージ**: マージコミットを残す
- **マージ後は必ずテスト実行**: テスト失敗なら修正依頼
- **`tmux split-window` で起動**: `new-window` は使用しない
- **Task ツール（サブエージェント）は使用しない**: tmux で起動
- **完了したらクリーンアップ**: worktree を削除してリソース解放

---

## 初期並列開発モード（A）との違い

| 観点 | モード A（merge-coordinator） | モード B（quick-task-coordinator） |
|------|---------------------------|--------------------------------|
| 計画書 | PLAN.md を参照 | なし（即座に開始） |
| タスク一覧 | 事前に全タスク把握 | 随時追加 |
| 依存関係 | 明示的に管理 | 基本的に独立タスク |
| マージ先 | 統合ブランチ | main（または指定ブランチ）直接 |
| 完了後 | 全タスク完了で main マージ | 各タスク完了時に即マージ |
```

---

## 実行例

### ユーザーとの対話例

```
ユーザー: ログイン画面のバリデーションを並列で修正して

Claude: クイックタスクを作成します。

タスク名: fix-login-validation
ブランチ: fix/fix-login-validation

worktree を作成しています...
✅ worktree/fix-login-validation/ を作成
✅ 環境セットアップ完了
✅ タスク指示書を生成

作業用 Claude を起動します...

（tmux split-window を実行）

作業用 Claude を起動しました。
完了通知を監視しています...

---

（数分後）

✅ fix-login-validation が完了しました。

変更をコミット・マージしています...
✅ テスト: パス
✅ main にマージ完了
✅ クリーンアップ完了

修正が完了しました。
```
