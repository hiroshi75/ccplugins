# Git Worktree を使った並列開発ガイド

git worktree を使うと、1 つのリポジトリから複数のブランチを同時にチェックアウトし、並列で開発できる。

## 基本コマンド

### worktree の作成

```bash
# 既存ブランチを新しいディレクトリにチェックアウト
git worktree add <path> <branch>

# 新しいブランチを作成してチェックアウト
git worktree add <path> -b <new-branch>

# 例: feature/api-a ブランチを worktree/api-a にチェックアウト
git worktree add worktree/api-a -b feature/api-a
```

### worktree の一覧表示

```bash
git worktree list
```

### worktree の削除

```bash
# ディレクトリを削除してから
rm -rf <path>

# worktree を整理
git worktree prune
```

## 並列開発のセットアップ例

### 1. 統合ブランチの作成

```bash
# main から統合ブランチを作成
git checkout -b feature/ui-improvements main
git push -u origin feature/ui-improvements
```

### 2. 各機能ブランチ用 worktree の作成

```bash
# プロジェクトルートで実行
cd /path/to/project

# worktree ディレクトリを .gitignore に追加
echo "worktree/" >> .gitignore

# 各機能ブランチ用 worktree を作成
# ディレクトリ名 = ブランチ名（feature/ プレフィックスを除く）
git worktree add worktree/recommendation-api -b feature/recommendation-api
git worktree add worktree/notification-api -b feature/notification-api
git worktree add worktree/project-card-enhance -b feature/project-card-enhance
git worktree add worktree/search-filter -b feature/search-filter
```

### 3. ディレクトリ構造

```
project/                              # プロジェクトルート (main or 統合ブランチ)
├── src/
├── ...
├── .gitignore                        # worktree/, .parallel-dev/ を除外
├── .parallel-dev/                    # 並列開発用の指示書（下記参照）
│   ├── README.md
│   ├── merge-coordinator.md
│   └── tasks/
│       ├── recommendation-api.md
│       └── ...
└── worktree/                         # worktree 用ディレクトリ
    ├── recommendation-api/           # feature/recommendation-api ブランチ
    ├── notification-api/             # feature/notification-api ブランチ
    ├── project-card-enhance/         # feature/project-card-enhance ブランチ
    └── search-filter/                # feature/search-filter ブランチ
```

### 4. claude 指示書の配置

claude による並列開発では、各 claude への指示書を `.parallel-dev/` に配置する。

```
.parallel-dev/
├── README.md                 # 全体概要・進捗サマリ
├── merge-coordinator.md      # マージ担当用指示書
└── tasks/                    # 各タスク用指示書
    ├── recommendation-api.md # worktree/recommendation-api/ の作業指示
    ├── notification-api.md
    ├── project-card-enhance.md
    └── search-filter.md
```

**ファイルの対応関係:**

| 指示書                                      | worktree                       | ブランチ                     |
| ------------------------------------------- | ------------------------------ | ---------------------------- |
| `.parallel-dev/tasks/recommendation-api.md` | `worktree/recommendation-api/` | `feature/recommendation-api` |
| `.parallel-dev/tasks/notification-api.md`   | `worktree/notification-api/`   | `feature/notification-api`   |

**各ファイルの役割:**

| ファイル               | 対象            | 内容                             |
| ---------------------- | --------------- | -------------------------------- |
| `README.md`            | 全 claude・人間 | 全体進捗、タスク一覧、依存関係図 |
| `merge-coordinator.md` | マージ担当      | マージ順序、コンフリクト対応方針 |
| `tasks/*.md`           | 作業用 claude   | 実装仕様、依存関係、完了条件     |

テンプレートは以下を参照:

- [templates/parallel-dev-readme.md](templates/parallel-dev-readme.md)
- [templates/merge-coordinator.md](templates/merge-coordinator.md)
- [templates/task-instruction.md](templates/task-instruction.md)

### 5. worktree の環境セットアップ

worktree 作成後、各ディレクトリで開発環境を準備する。

#### 依存関係のインストール

```bash
# Python (uv) の場合
cd worktree/recommendation-api
uv sync

# Node.js (pnpm) の場合
cd worktree/project-card-enhance
pnpm install

# Node.js (npm) の場合
npm install
```

#### 環境変数ファイルのセットアップ

プロジェクトルートの `.env`（API キーなどの secrets）を各 worktree にコピーし、
ポート番号などの非 secrets は `.env.local` で上書きする。

```bash
# .env をコピー（secrets）
cp .env worktree/recommendation-api/.env

# .env.local を作成（ポート番号など）
cat > worktree/recommendation-api/.env.local << 'EOF'
PORT=3001
VITE_PORT=5174
EOF
```

#### ポート番号の割り当て

各 worktree で開発サーバーが衝突しないよう、異なるポートを割り当てる:

| worktree             | バックエンドポート | フロントエンドポート |
| -------------------- | ------------------ | -------------------- |
| (プロジェクトルート) | 3000               | 5173                 |
| recommendation-api   | 3001               | 5174                 |
| notification-api     | 3002               | 5175                 |
| project-card-enhance | 3003               | 5176                 |
| search-filter        | 3004               | 5177                 |

#### セットアップの自動化

`scripts/setup-worktree.sh` を使用:

```bash
# 基本使用（ポート自動割り当て）
./scripts/setup-worktree.sh recommendation-api

# ポート指定
./scripts/setup-worktree.sh recommendation-api 3001 5174

# fix/ プレフィックスでブランチ作成
./scripts/setup-worktree.sh login-bug 3001 5174 fix
```

**重要**: `PROJECT_ROOT` は worktree から親プロジェクトのルートを参照するために必要。
`.parallel-dev-signals/` や `.parallel-dev-issues/` へのパス解決に使用される。

## 作業フロー

### 役割分担

| 役割                           | 作業用 claude | マージ担当 |
| ------------------------------ | ------------- | ---------- |
| コード実装                     | ✅            | -          |
| .done ファイル作成             | ✅            | -          |
| git commit                     | -             | ✅         |
| git fetch/merge (統合ブランチ) | -             | ✅         |
| テスト実行                     | -             | ✅         |
| git push                       | -             | ✅         |
| 統合ブランチへのマージ         | -             | ✅         |

**設計思想**: 作業用 claude はコードを書くことに集中。マージ順序の管理はマージ担当のみが把握。

### 各 worktree での作業

```bash
# 作業対象の worktree ディレクトリに移動
cd worktree/recommendation-api

# コード実装（git commit / git push は行わない）
# ... 実装作業 ...

# ローカルで動作確認
# uv run pytest / pnpm test など
```

**重要**: git commit / git push は**行わない**。コードを書くことに集中する。

### 完了通知（.done ファイル）

実装完了後、プロジェクトルートの `.parallel-dev-signals/` に完了通知ファイルを作成する。
**コミットは不要**。

`scripts/create-done-file.sh` を使用:

```bash
# worktree 内で実行
cd worktree/recommendation-api
../../scripts/create-done-file.sh recommendation-api "APIエンドポイント実装完了"
```

マージ担当はこのファイルを検知して、以下を実行する:

1. worktree に移動してコミット
2. 統合ブランチをマージ
3. テスト実行
4. プッシュ
5. 統合ブランチへのマージ

### エラー・ブロック時の対応

問題が発生して作業を継続できない場合、プロジェクトルートの `.parallel-dev-issues/` に記録する。

`scripts/create-issue-file.sh` を使用:

```bash
# worktree 内で実行
cd worktree/recommendation-api
../../scripts/create-issue-file.sh recommendation-api "ビルドエラー"
# → エディタで詳細を編集
```

**マージ担当の対応:**

1. `.parallel-dev-issues/` を監視
2. 問題の内容を確認し、担当を割り当て
3. 必要に応じて新しい worktree/ブランチを作成

### 統合ブランチへのマージ

```bash
# プロジェクトルートに戻る
cd ../..

# 統合ブランチをチェックアウト
git checkout feature/ui-improvements

# 機能ブランチをマージ（順序に注意、下記参照）
git merge feature/recommendation-api
git merge feature/notification-api
```

### マージ順序の決定

複数のブランチを統合ブランチにマージする際、順序が重要になる場合がある。

**マージ順序を決める基準:**

| 優先度 | 基準                   | 説明                                         |
| ------ | ---------------------- | -------------------------------------------- |
| 1      | **依存関係**           | 他のブランチが依存するブランチを先にマージ   |
| 2      | **変更範囲**           | 広範囲の変更を先に、小さい変更で調整         |
| 3      | **コンフリクトリスク** | 同じファイルを変更するブランチ間の順序を考慮 |
| 4      | **完了順**             | 上記に該当しなければ完了した順               |

**依存関係の例:**

```
feature/recommendation-api  ← 先にマージ（APIを提供）
       ↓
feature/project-card-enhance  ← 後でマージ（APIを利用するUI）
```

**マージ順序の計画例:**

```
統合ブランチ: feature/ui-improvements

マージ順序:
1. feature/recommendation-api   # 他のブランチが依存
2. feature/notification-api     # 独立、完了次第マージ可
3. feature/project-card-enhance # recommendation-api に依存
4. feature/search-filter        # 独立、最後でOK
```

**依存先ブランチがまだマージされていない場合:**

依存タスクが統合ブランチにマージされるまで、そのタスクは開始しない。

**重要**: 依存先ブランチを直接取り込まない。必ず統合ブランチ経由で取り込む。

### 統合ブランチの変更を取り込む

統合ブランチの取り込みはマージ担当が行う。
作業用 claude は依存タスクの完了通知を待ち、Phase 2 の実装を開始する。

**マージ担当の手順:**

```bash
# 対象の worktree で
cd worktree/project-card-enhance

# 変更をコミット（未コミットの場合）
git add .
git commit -m "feat: project-card-enhance の実装"

# 統合ブランチをマージ
git fetch origin
git merge origin/feature/ui-improvements --no-ff
```

## ルール

→ **[SKILL.md の Rules セクション](../SKILL.md#rules全-claude-共通) を参照**

## 注意点

### 同じブランチは複数の worktree でチェックアウトできない

```bash
# エラーになる
git worktree add worktree/api-a-copy feature/api-a
# fatal: 'feature/api-a' is already checked out at 'worktree/api-a'
```

### .git ディレクトリの扱い

worktree のディレクトリには `.git` ファイル（ディレクトリではない）が作られ、元のリポジトリを参照する。

```bash
cat worktree/recommendation-api/.git
# gitdir: /path/to/project/.git/worktrees/recommendation-api
```

### IDE/エディタの設定

各 worktree ディレクトリを別のプロジェクトとして開く。VSCode の場合:

```bash
code worktree/recommendation-api
```

## トラブルシューティング

### worktree が壊れた場合

```bash
# 強制的に削除
git worktree remove --force <path>

# または
rm -rf <path>
git worktree prune
```

### ロックされている場合

```bash
# ロックを解除
git worktree unlock <path>
```

### worktree 一覧が古い場合

```bash
# 整理
git worktree prune
```

## Claude Code での並列開発

Claude Code で複数の worktree を使って並列開発する場合:

1. **tmux セッション内で実行**（作業用 claude を別ペインで起動するため必須）
2. **人間は `scripts/start-coordinator.sh` でマージ担当のみを起動**
3. **マージ担当が `scripts/start-worker.sh` で作業用 claude を起動・管理**
4. **Task ツール（サブエージェント）は使用しない**

```bash
# マージ担当を起動（tmux セッション内で実行すること）
./scripts/start-coordinator.sh

# 作業用 claude を起動（マージ担当が実行）
./scripts/start-worker.sh recommendation-api
./scripts/start-worker.sh notification-api

# マージ完了後、作業用 claude を終了
./scripts/stop-worker.sh recommendation-api
```

## 並列開発完了後のクリーンアップ

すべてのタスクが完了し、統合ブランチが main にマージされたら、クリーンアップを行う。

### クリーンアップの条件

以下がすべて満たされていること:

- [ ] すべてのタスクがマージ済み
- [ ] 統合ブランチが main にマージ済み
- [ ] 統合テストがパス
- [ ] `.parallel-dev-issues/` に未解決の issue がない

### クリーンアップの実行

`scripts/cleanup-parallel-dev.sh` を使用:

```bash
# 確認ありでクリーンアップ
./scripts/cleanup-parallel-dev.sh

# 確認なしでクリーンアップ
./scripts/cleanup-parallel-dev.sh --force
```

**注意**: ブランチの削除は手動で行う:

```bash
git branch -d feature/recommendation-api
git branch -d feature/notification-api
```

---

## クイックタスクモード（モード B）での worktree 運用

クイックタスクモードでの worktree 運用については、専用ガイドを参照:

→ **[quick-mode-guide.md](quick-mode-guide.md)** - クイックタスクモード運用ガイド

クイックタスクモードの主なテンプレート:

- [templates/quick-session-template.md](templates/quick-session-template.md) - セッションファイル（必須）
- [templates/quick-task-template.md](templates/quick-task-template.md) - 簡易タスク指示書
- [templates/quick-task-coordinator.md](templates/quick-task-coordinator.md) - タスク受付・マージ担当
