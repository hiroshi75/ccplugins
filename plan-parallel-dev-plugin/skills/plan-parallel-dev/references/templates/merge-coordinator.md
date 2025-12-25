# マージコーディネーター指示書テンプレート

マージを専門で担当する claude 向けの指示書テンプレート。

ファイル名: `.parallel-dev/merge-coordinator.md`

---

## テンプレート

```markdown
# マージコーディネーター指示書

## 役割

この claude は以下を担当する:
- **作業用 claudeを tmux で起動**（別ペインで Claude Code を起動）
- `.parallel-dev-signals/` の完了通知（.done ファイル）を監視
- `.parallel-dev-issues/` の問題報告を監視し、担当を割り当て
- **作業用 claudeの変更をコミット**
- **統合ブランチの最新をマージ**
- **テスト実行**
- **統合ブランチへのマージ**
- マージ順序の管理
- 必要に応じて新規 worktree/ブランチの作成と指示書の更新

**重要**: 作業用 claudeはコミット・プッシュを行わない。マージ担当がすべてのgit操作を行う。

---

## 作業用 claudeの起動

**重要**: 作業用 claudeは **Bash ツールで `tmux split-window` コマンドを実行** して起動する。
**Task ツール（サブエージェント）は使用しない。**

tmux 内で実行されているため、直接 `tmux split-window` で別ペインに Claude Code を起動できる。

### 開始時に起動するタスク

依存のないタスクは並列で起動する。**Bash ツールで以下のコマンドを実行**:

```bash
# PROJECT_ROOT を設定（現在のプロジェクトルートを記録）
export PROJECT_ROOT=$(pwd)

# タスク1: worktree/recommendation-api で作業
tmux split-window -h "cd worktree/recommendation-api && PROJECT_ROOT=$PROJECT_ROOT claude '../../.parallel-dev/tasks/recommendation-api.md を読んで実装してください。完了したら .done ファイルを作成してください。'"

# タスク2: worktree/notification-api で作業
tmux split-window -h "cd worktree/notification-api && PROJECT_ROOT=$PROJECT_ROOT claude '../../.parallel-dev/tasks/notification-api.md を読んで実装してください。完了したら .done ファイルを作成してください。'"

# ペインレイアウトを調整
tmux select-layout tiled
```

### 依存タスクの起動

依存タスクがマージされたら、待機中のタスクを起動する:

```bash
tmux split-window -h "cd worktree/project-card-enhance && PROJECT_ROOT=$PROJECT_ROOT claude '../../.parallel-dev/tasks/project-card-enhance.md を読んで実装してください。依存タスク recommendation-api はマージ済みです。完了したら .done ファイルを作成してください。'"
```

---

## 完了監視

作業用 claude起動後、完了を待つ。

### 監視ループ

以下のコマンドを Bash ツールで実行する（タイムアウト: 600000ms を指定）:

```bash
# 完了を待機（5秒間隔、最大108回 = 9分）
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

# 結果確認
if [ -n "$DONE_FILES" ]; then
  echo "=== 完了検知 ==="
  cat $DONE_FILES
elif [ -n "$ISSUE_FILES" ]; then
  echo "=== 問題検知 ==="
  cat $ISSUE_FILES
else
  echo "=== 9分経過、完了通知なし ==="
  echo "再度監視ループを実行してください"
fi
```

- 完了または問題を検知したら、ループを抜けて処理を開始
- 9分で完了しなければ、再度監視ループを実行

### 監視対象ディレクトリ

```
.parallel-dev/
├── signals/           # 完了通知
│   ├── task-a.done
│   └── task-b.done
└── issues/            # 問題報告
    └── task-c.md
```

---

## ブランチ情報

| 項目 | 値 |
|------|-----|
| 統合ブランチ | `feature/{integration-branch}` |
| ベースブランチ | `main` |
| 作業ディレクトリ | プロジェクトルート |

### 初期セットアップ（並列開発開始時に実行）

```bash
# 統合ブランチをリモートにプッシュ（worktree から参照できるようにする）
git push -u origin feature/{integration-branch}
```

**重要**: このプッシュを行わないと、worktree から `origin/feature/{integration-branch}` を参照できず、マージ時にエラーになる。

---

## タスク一覧と依存関係

### 依存関係図

```
feature/{task-a}  ─────────────────────────────────┐
                                                   ↓
feature/{task-b}  ──────────────────────────► feature/{task-d}
                                                   ↑
feature/{task-c}  ─────────────────────────────────┘
```

### タスク状態

| ブランチ | 担当者 | 状態 | 依存先 | マージ順 |
|----------|----------|------|--------|----------|
| feature/{task-a} | BE-1 | 未完了 | なし | 1 |
| feature/{task-b} | BE-2 | 未完了 | なし | 2 |
| feature/{task-c} | BE-1 | 未完了 | なし | 3 |
| feature/{task-d} | FE-1 | 未完了 | task-a, task-b, task-c | 4 |

---

## マージ順序

### 決定済みマージ順序

依存関係とコンフリクトリスクに基づく順序:

```
Phase 1: 独立タスク（並行マージ可能）
─────────────────────────────────────
1. feature/{task-a}  # 依存なし
2. feature/{task-b}  # 依存なし
3. feature/{task-c}  # 依存なし

Phase 2: 依存タスク
─────────────────────────────────────
4. feature/{task-d}  # task-a, b, c に依存
```

### マージ順序の根拠

| 順序 | ブランチ | 根拠 |
|------|----------|------|
| 1 | feature/{task-a} | 他タスクが依存、独立して完成可能 |
| 2 | feature/{task-b} | 独立、変更範囲が限定的 |
| 3 | feature/{task-c} | 独立 |
| 4 | feature/{task-d} | Phase 1 の全タスクに依存 |

---

## 統合フロー（.done 検知後の手順）

.done ファイルを検知したら、以下の手順で統合を行う。

### 1. 作業 worktree での処理

```bash
# 1-1. 作業 worktree に移動
cd worktree/{branch-name}

# 1-2. 変更をコミット
git add .
git commit -m "feat: {branch-name} の実装"

# 1-3. 統合ブランチの最新を取り込み
git fetch origin
git merge origin/feature/{integration-branch} --no-ff -m "Merge integration branch"

# 1-4. コンフリクトがあれば解決
# （複雑な場合は作業用 claudeに依頼）

# 1-5. テスト実行
{test-command}
```

### 2. テスト結果による分岐

**テスト成功時:**
```bash
# 2a-1. プッシュ
git push origin feature/{branch-name}

# 2a-2. プロジェクトルートに戻る
cd ../..

# 2a-3. 統合ブランチにマージ
git checkout feature/{integration-branch}
git pull origin feature/{integration-branch}
git merge origin/feature/{branch-name} --no-ff -m "Merge feature/{branch-name} into integration"
git push origin feature/{integration-branch}

# 2a-4. 状態更新
# - タスク指示書のステータスを「マージ済」に
# - README.md の進捗を更新
# - 依存元タスクに通知
```

**テスト失敗時:**
```bash
# 2b-1. 既存の .done ファイルを削除
rm .parallel-dev-signals/{branch-name}.done

# 2b-2. 修正依頼用の issue を作成
cat > .parallel-dev-issues/{branch-name}.md << 'EOF'
【修正依頼】{branch-name}

## 状況
統合ブランチマージ後のテストが失敗しました。

## エラー内容
{テストエラーの出力}

## 対応依頼
1. worktree/{branch-name}/ で修正
2. 修正完了後、再度 .done ファイルを作成

※ コミットは不要です。
EOF

# 2b-3. 作業用 claudeを再起動
tmux split-window -h "cd worktree/{branch-name} && PROJECT_ROOT=$PROJECT_ROOT claude '$PROJECT_ROOT/.parallel-dev-issues/{branch-name}.md を読んで修正してください。完了したら .done ファイルを作成してください。'"
```

### 3. コンフリクト発生時

1. **軽微なコンフリクト**: 手動解決してマージ続行

2. **複雑なコンフリクト**: 作業用 claudeを再起動して依頼
```bash
# コンフリクト内容を issue に記録
cat > .parallel-dev-issues/{branch-name}-conflict.md << 'EOF'
【コンフリクト解決依頼】{branch-name}

## 状況
統合ブランチマージ時にコンフリクトが発生しました。

## コンフリクトファイル
{コンフリクトファイル一覧}

## 対応依頼
コンフリクトを解決してください。解決後 .done ファイルを作成してください。
EOF

# 作業用 claudeを再起動
tmux split-window -h "cd worktree/{branch-name} && PROJECT_ROOT=$PROJECT_ROOT claude '$PROJECT_ROOT/.parallel-dev-issues/{branch-name}-conflict.md を読んでコンフリクトを解決してください。完了したら .done ファイルを作成してください。'"
```

3. **解決不能**: マージを中止し、人間に報告

---

## 状態更新ルール

### .done 検知時の確認事項

.done ファイルを検知したら以下を確認:

- [ ] worktree/{branch-name}/ に未コミットの変更がある
- [ ] 依存タスクがすべてマージ済み（依存がある場合）

**注意**: 作業用 claudeはコミット・プッシュを行わない。変更は worktree 内にある。

### .done ファイルの確認

完了報告の内容を確認し、問題がないかチェックする。

### マージ後の更新

マージ完了後:

1. `.parallel-dev/tasks/{branch-name}.md` のステータスを「マージ済」に更新
2. `.parallel-dev/README.md` の進捗を更新
3. `merge-coordinator.md` のタスク状態を更新
4. **依存元タスクに完了通知**（下記テンプレート使用）
5. `.parallel-dev-signals/{branch-name}.done` を削除（または processed/ に移動）

### 状態更新の責任分担

| 更新対象 | 責任者 | タイミング |
|----------|--------|------------|
| .done ファイル | 作業用 claude | 実装完了時 |
| git commit/push | マージコーディネーター | .done 検知後 |
| タスク指示書のステータス | マージコーディネーター | マージ後「マージ済」へ |
| README.md の進捗 | マージコーディネーター | マージ後 |
| 依存タスクの起動 | マージコーディネーター | 依存先マージ後 |

### 依存タスクの起動

マージしたタスクに依存しているタスクがあれば、そのタスクを起動する:

```bash
# 依存先がマージされたので、依存タスクを起動
tmux split-window -h "cd worktree/{dependent-branch} && PROJECT_ROOT=$PROJECT_ROOT claude '../../.parallel-dev/tasks/{dependent-branch}.md を読んで実装してください。依存タスク {merged-branch} はマージ済みです。完了したら .done ファイルを作成してください。'"
```

---

## 統合テスト

### マージごとのテスト

```bash
# 各マージ後に実行
{lint-command}
{type-check-command}
{unit-test-command}
```

### 全タスクマージ後のテスト

```bash
# すべてのタスクがマージされた後
{integration-test-command}
{e2e-test-command}
```

---

## 最終マージ（統合ブランチ → main）

### 前提条件

- [ ] すべてのタスクがマージ済み
- [ ] 統合テストがパス
- [ ] コードレビュー完了

**重要**: main へのマージは影響が大きいため、AskUserQuestion ツールで人間に確認を取る:

```
「すべてのタスクがマージ済みで、統合テストがパスしました。
main ブランチへのマージを実行してよろしいですか？」
```

### 手順（人間の承認後に実行）

```bash
# 1. main を最新に
git checkout main
git pull origin main

# 2. 統合ブランチをマージ
git merge feature/{integration-branch} --no-ff

# 3. 最終テスト
{full-test-command}

# 4. プッシュ（またはPR作成）
git push origin main
# または
gh pr create --base main --head feature/{integration-branch}
```

---

## トラブルシューティング

### よくある問題と対処

| 問題 | 対処 |
|------|------|
| マージ後にテスト失敗 | マージを revert し、原因を調査 |
| 依存タスクが遅延 | 依存元タスクの担当に状況確認 |
| コンフリクトが多発 | 頻繁なリベースを各タスクに依頼 |

### エスカレーション

以下の場合は人間に報告:

- 解決不能なコンフリクト
- テスト失敗の原因が特定できない
- 依存関係の変更が必要

---

## Issue 対応

### 新規タスク作成が必要な場合

issue の解決に新しい worktree/ブランチが必要な場合:

```bash
# 1. 新しい worktree を作成
BRANCH=fix-card-conflict
INDEX=5  # 次のインデックス
git worktree add worktree/$BRANCH -b feature/$BRANCH

# 2. 環境セットアップ
cp .env worktree/$BRANCH/.env
cat > worktree/$BRANCH/.env.local << EOF
PORT=$((3000 + INDEX))
VITE_PORT=$((5173 + INDEX))
EOF
cd worktree/$BRANCH && uv sync && cd ../..  # または pnpm install

# 3. タスク指示書を作成
# .parallel-dev/tasks/{new-branch}.md を作成

# 4. README.md を更新
# タスク一覧に新しいタスクを追加

# 5. merge-coordinator.md を更新（このファイル）
# マージ順序に新しいタスクを追加

# 6. issue ファイルを更新
# 担当を割り当て、対応状況を記録
```

### issue のステータス更新

```bash
# issue ファイルの担当・ステータスを更新
# .parallel-dev-issues/{task-name}.md

## 担当
Agent-X（YYYY-MM-DD に割り当て）

## ステータス
対応中 → 解決済
```
```

---

## 記入ガイド

### 状態の定義

| 状態 | 意味 |
|------|------|
| 未完了 | 作業中または未着手 |
| 完了 | 実装完了、マージ待ち |
| マージ済 | 統合ブランチにマージ完了 |

### マージ順序の決め方

1. **依存関係**: 依存されているタスクを先に
2. **変更範囲**: 広範囲の変更を先に（コンフリクト軽減）
3. **コンフリクトリスク**: 同じファイルを変更するタスクの順序を考慮
4. **完了順**: 上記に該当しなければ完了した順

---

## ルール

- **`--no-ff` で常にマージ**（マージコミットを残す）
- **マージ後は必ずテスト実行**
- **コンフリクト解決は該当タスクの担当に依頼**（マージ担当が解決しない）
- **マージ順序: 依存関係 > 変更範囲 > 完了順**
