# クイックタスクモード（モード B）運用ガイド

クイックタスクモードでは、計画書なしで即座に git worktree を作成してタスクを開始する。
初期並列開発モード（モード A）との主な違いは以下の通り。

## モード A と モード B の違い

| 観点           | 初期並列開発（A）    | クイックタスク（B）                             |
| -------------- | -------------------- | ----------------------------------------------- |
| 起点           | 計画書作成から開始   | 依頼を受けて即座に開始                          |
| コーディネーターファイル | `.parallel-dev/merge-coordinator.md`（固定） | `.parallel-dev/quick-session-{timestamp}.md`（一意） |
| 複数セッション並行 | 不可 | 可能（タイムスタンプで識別） |
| worktree 作成  | 一斉に複数作成       | 必要時に都度作成                                |
| 統合ブランチ   | 必須                 | 不要だが作業ブランチは作る（main に直接マージ） |
| 計画書         | PLAN.md を作成       | 作成しない                                      |
| マージ先       | 統合ブランチ → main  | main（または指定ブランチ）に直接                |
| クリーンアップ | 全タスク完了後に一括 | 各タスク完了後に即座に                          |

## セッションファイルの作成

クイックセッション開始時に、一意のセッションファイルを作成する。

詳細テンプレート: [templates/quick-session-template.md](templates/quick-session-template.md)

**重要**: セッションファイルは複数のクイックセッションが並行しても衝突しないよう、タイムスタンプで一意に識別される。

## クイックタスク用 worktree の作成

`scripts/setup-worktree.sh` を使用:

```bash
# バグ修正（fix/ プレフィックス）
./scripts/setup-worktree.sh fix-login-validation "" "" fix

# 機能追加（feature/ プレフィックス、デフォルト）
./scripts/setup-worktree.sh add-logout-button

# ポート指定
./scripts/setup-worktree.sh fix-login-validation 3001 5174 fix
```

**注意**: 初回実行時に `.parallel-dev/`, `.parallel-dev-signals/`, `.parallel-dev-issues/` ディレクトリと `.gitignore` エントリが自動作成される。

## クイックタスクのディレクトリ構造

```
project/
├── .parallel-dev/                    # タスク管理（初回作成時に追加）
│   ├── quick-session-20250105143022.md  # セッションファイル（一意）
│   └── tasks/
│       └── fix-login-validation.md   # 簡易タスク指示書
├── .parallel-dev-signals/            # 完了通知（.gitignore）
│   └── fix-login-validation.done
├── .parallel-dev-issues/             # 問題報告（.gitignore）
│   └── fix-login-validation.md
└── worktree/                         # worktree（.gitignore）
    └── fix-login-validation/         # fix/fix-login-validation ブランチ
```

## 作業用 Claude の起動

`scripts/start-worker.sh` を使用:

```bash
./scripts/start-worker.sh fix-login-validation
```

**前提**: tmux セッション内で実行すること。

## 完了後のマージとクリーンアップ

クイックタスクモードでは、各タスク完了後に即座にマージ・クリーンアップを行う:

1. **worktree でコミット・マージ・プッシュ**
   ```bash
   cd worktree/fix-login-validation
   git add . && git commit -m "fix: fix-login-validation"
   git fetch origin && git merge origin/main --no-ff
   # テスト実行
   git push origin fix/fix-login-validation
   ```

2. **ベースブランチにマージ**
   ```bash
   cd ../..
   git checkout main && git pull origin main
   git merge origin/fix/fix-login-validation --no-ff
   git push origin main
   ```

3. **クリーンアップ**
   ```bash
   ./scripts/stop-worker.sh fix-login-validation
   ./scripts/cleanup-parallel-dev.sh --force  # または個別に worktree 削除
   ```

4. **セッションファイルを更新** - タスクステータスを「マージ済」に変更

## 複数クイックタスクの並列実行

複数のタスクを同時に依頼された場合、各スクリプトを順に実行:

```bash
# 1. 各タスクの worktree をセットアップ
./scripts/setup-worktree.sh fix-login-validation "" "" fix
./scripts/setup-worktree.sh add-logout-button
./scripts/setup-worktree.sh update-header-style

# 2. 各タスクの指示書を作成（テンプレート参照）
# → templates/quick-task-template.md

# 3. 作業用 Claude を起動
./scripts/start-worker.sh fix-login-validation
./scripts/start-worker.sh add-logout-button
./scripts/start-worker.sh update-header-style

# 4. レイアウト調整
tmux select-layout tiled
```

指示書テンプレート: [templates/quick-task-template.md](templates/quick-task-template.md)

## クイックタスクのポート割り当て

`scripts/setup-worktree.sh` がポートを自動割り当てする。手動で指定する場合:

```bash
./scripts/setup-worktree.sh fix-login-validation 3001 5174 fix
```

ポート割り当てルール → [worktree-guide.md の「ポート番号の割り当て」](worktree-guide.md#ポート番号の割り当て)

## テンプレート

クイックタスクモード用のテンプレート:

- [templates/quick-session-template.md](templates/quick-session-template.md) - セッションファイル（必須）
- [templates/quick-task-template.md](templates/quick-task-template.md) - 簡易タスク指示書
- [templates/quick-task-coordinator.md](templates/quick-task-coordinator.md) - タスク受付・マージ担当
