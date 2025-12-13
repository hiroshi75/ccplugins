# マージコーディネーター指示書テンプレート

マージを専門で担当するAIエージェント向けの指示書テンプレート。

ファイル名: `.parallel-dev/merge-coordinator.md`

---

## テンプレート

```markdown
# マージコーディネーター指示書

## 役割

このエージェントは以下を担当する:
- **作業エージェントをサブエージェントとして起動**
- `.parallel-dev/signals/` の完了通知（.done ファイル）を監視
- `.parallel-dev/issues/` の問題報告を監視し、担当を割り当て
- **作業エージェントの変更をコミット**
- **統合ブランチの最新をマージ**
- **テスト実行**
- **統合ブランチへのマージ**
- マージ順序の管理
- 必要に応じて新規 worktree/ブランチの作成と指示書の更新

**重要**: 作業エージェントはコミット・プッシュを行わない。マージ担当がすべてのgit操作を行う。

---

## 作業エージェントの起動

### 開始時に起動するタスク

依存のないタスクは並列でサブエージェントを起動する:

```
Taskツールで以下を並列実行:

タスク1: worktree/recommendation-api で作業
  prompt: "cd worktree/recommendation-api && cat ../../.parallel-dev/tasks/recommendation-api.md を読んで実装してください。完了したら .done ファイルを作成してください。"

タスク2: worktree/notification-api で作業
  prompt: "cd worktree/notification-api && cat ../../.parallel-dev/tasks/notification-api.md を読んで実装してください。完了したら .done ファイルを作成してください。"
```

### 依存タスクの起動

依存タスクがマージされたら、待機中のタスクを起動する:

```
Taskツールで実行:

タスク: worktree/project-card-enhance で作業
  prompt: "cd worktree/project-card-enhance && cat ../../.parallel-dev/tasks/project-card-enhance.md を読んで実装してください。依存タスク recommendation-api はマージ済みです。完了したら .done ファイルを作成してください。"
```

---

## 監視対象ディレクトリ

```
.parallel-dev/
├── signals/           # 完了通知を監視
│   ├── task-a.done    # task-a の完了通知
│   └── task-b.done
├── issues/            # 問題報告を監視
│   └── task-c.md      # task-c で発生した問題
└── ...
```

### 完了通知の確認

```bash
# signals ディレクトリを確認
ls -la .parallel-dev/signals/

# 新しい .done ファイルがあればマージを検討
cat .parallel-dev/signals/{task-name}.done
```

### 問題報告の確認

```bash
# issues ディレクトリを確認
ls -la .parallel-dev/issues/

# 問題があれば内容を確認し、担当を割り当て
cat .parallel-dev/issues/{task-name}.md
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
# （複雑な場合は作業エージェントに依頼）

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
# 2b-1. 作業エージェントに修正依頼
# .done ファイルに修正依頼を追記するか、直接通知

# 2b-2. 修正依頼の内容
【修正依頼】{branch-name}

統合ブランチマージ後のテストが失敗しました。

エラー内容:
{テストエラーの出力}

対応依頼:
1. worktree/{branch-name}/ で修正
2. 修正完了後、再度 .done ファイルを作成

※ コミットは不要です。
```

### 3. コンフリクト発生時

1. **軽微なコンフリクト**: 手動解決してマージ続行
2. **複雑なコンフリクト**: 作業エージェントに依頼
3. **解決不能**: マージを中止し、人間に報告

---

## 状態更新ルール

### .done 検知時の確認事項

.done ファイルを検知したら以下を確認:

- [ ] worktree/{branch-name}/ に未コミットの変更がある
- [ ] 依存タスクがすべてマージ済み（依存がある場合）
- [ ] .done ファイル内にコード記載がないか確認（権限問題対応）

**注意**: 作業エージェントはコミット・プッシュを行わない。変更は worktree 内にある。

### .done ファイルにコードが含まれている場合

サブエージェントがファイル編集権限の問題に遭遇した場合、実装コードを .done ファイルに記載することがある。

**対処手順**:

```bash
# 1. .done ファイルの内容を確認
cat .parallel-dev/signals/{branch-name}.done

# 2. 「ファイル編集権限の問題」セクションがあるか確認
# ある場合は、記載されたコードを該当ファイルに適用

# 3. worktree に移動してコードを適用
cd worktree/{branch-name}

# 4. 各ファイルを編集（.done に記載されたコードを適用）
# Edit ツールを使用して変更を適用

# 5. 構文チェック
python -m py_compile {changed-files}  # Python の場合
npx tsc --noEmit                       # TypeScript の場合

# 6. 通常のマージフローを続行
```

**重要**: コードを適用する前に、対象ファイルの現在の状態を確認し、適切な位置に挿入すること。

### マージ後の更新

マージ完了後:

1. `.parallel-dev/tasks/{branch-name}.md` のステータスを「マージ済」に更新
2. `.parallel-dev/README.md` の進捗を更新
3. `merge-coordinator.md` のタスク状態を更新
4. **依存元タスクに完了通知**（下記テンプレート使用）
5. `.parallel-dev/signals/{branch-name}.done` を削除（または processed/ に移動）

### 状態更新の責任分担

| 更新対象 | 責任者 | タイミング |
|----------|--------|------------|
| .done ファイル | 作業エージェント | 実装完了時 |
| git commit/push | マージコーディネーター | .done 検知後 |
| タスク指示書のステータス | マージコーディネーター | マージ後「マージ済」へ |
| README.md の進捗 | マージコーディネーター | マージ後 |
| 依存元タスクへの通知 | マージコーディネーター | マージ後 |

### 依存元タスクへの完了通知

マージしたタスクに依存しているタスクがあれば、通知する:

```
【依存タスク完了通知】{merged-branch}

マージ完了: feature/{merged-branch}
統合ブランチ: feature/{integration-branch}

依存していたタスク:
- feature/{dependent-branch}: Phase 2 開始可能

作業エージェントは Phase 2 の実装を開始してください。
（統合ブランチの取り込みはマージ担当が行います）
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

### 手順

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
# .parallel-dev/issues/{task-name}.md

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
