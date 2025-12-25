# Git Worktree を使った並列開発ガイド

git worktree を使うと、1つのリポジトリから複数のブランチを同時にチェックアウトし、並列で開発できる。

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

| 指示書 | worktree | ブランチ |
|--------|----------|----------|
| `.parallel-dev/tasks/recommendation-api.md` | `worktree/recommendation-api/` | `feature/recommendation-api` |
| `.parallel-dev/tasks/notification-api.md` | `worktree/notification-api/` | `feature/notification-api` |

**各ファイルの役割:**

| ファイル | 対象 | 内容 |
|----------|------|------|
| `README.md` | 全 claude・人間 | 全体進捗、タスク一覧、依存関係図 |
| `merge-coordinator.md` | マージ担当 | マージ順序、コンフリクト対応方針 |
| `tasks/*.md` | 作業用 claude | 実装仕様、依存関係、完了条件 |

テンプレートは以下を参照:
- [templates/parallel-dev-readme.md](templates/parallel-dev-readme.md)
- [templates/merge-coordinator.md](templates/merge-coordinator.md)
- [templates/task-instruction.md](templates/task-instruction.md)

### 5. worktree の環境セットアップ

worktree作成後、各ディレクトリで開発環境を準備する。

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

プロジェクトルートの `.env`（APIキーなどのsecrets）を各worktreeにコピーし、
ポート番号などの非secretsは `.env.local` で上書きする。

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

各worktreeで開発サーバーが衝突しないよう、異なるポートを割り当てる:

| worktree | バックエンドポート | フロントエンドポート |
|----------|-------------------|---------------------|
| (プロジェクトルート) | 3000 | 5173 |
| recommendation-api | 3001 | 5174 |
| notification-api | 3002 | 5175 |
| project-card-enhance | 3003 | 5176 |
| search-filter | 3004 | 5177 |

#### セットアップの自動化

worktree作成時に環境セットアップも行う例:

```bash
# worktree作成 + 環境セットアップ（Python/uv）
BRANCH=recommendation-api
PORT_BE=3001
PORT_FE=5174

git worktree add worktree/$BRANCH -b feature/$BRANCH
cp .env worktree/$BRANCH/.env
cat > worktree/$BRANCH/.env.local << EOF
PROJECT_ROOT=$(pwd)
PORT=$PORT_BE
VITE_PORT=$PORT_FE
EOF
cd worktree/$BRANCH && uv sync && cd ../..
```

```bash
# worktree作成 + 環境セットアップ（Node.js/pnpm）
BRANCH=project-card-enhance
PORT_BE=3003
PORT_FE=5176

git worktree add worktree/$BRANCH -b feature/$BRANCH
cp .env worktree/$BRANCH/.env
cat > worktree/$BRANCH/.env.local << EOF
PROJECT_ROOT=$(pwd)
PORT=$PORT_BE
VITE_PORT=$PORT_FE
EOF
cd worktree/$BRANCH && pnpm install && cd ../..
```

**重要**: `PROJECT_ROOT` は worktree から親プロジェクトのルートを参照するために必要。
`.parallel-dev-signals/` や `.parallel-dev-issues/` へのパス解決に使用される。

テンプレート: [templates/env-local-template.md](templates/env-local-template.md)

## 作業フロー

### 役割分担

| 役割 | 作業用 claude | マージ担当 |
|------|------------------|------------|
| コード実装 | ✅ | - |
| .done ファイル作成 | ✅ | - |
| git commit | - | ✅ |
| git fetch/merge (統合ブランチ) | - | ✅ |
| テスト実行 | - | ✅ |
| git push | - | ✅ |
| 統合ブランチへのマージ | - | ✅ |

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
**コミットは不要**。実装内容を報告書として記載する。

```bash
cd worktree/recommendation-api

# PROJECT_ROOT は worktree 作成時に設定される環境変数
# signals ディレクトリがなければ作成
mkdir -p $PROJECT_ROOT/.parallel-dev-signals

# .done ファイルを作成
cat > $PROJECT_ROOT/.parallel-dev-signals/recommendation-api.done << 'EOF'
【完了報告】recommendation-api

## 実装内容
- レコメンドAPIエンドポイント（GET /api/v1/recommendations）
- レコメンドサービス（src/services/recommendation.py）
- テスト（tests/test_recommendations.py）

## 変更ファイル
- src/api/recommendations.py
- src/services/recommendation.py
- tests/test_recommendations.py

## 動作確認
ローカルでの動作確認: OK

## 備考
特になし
EOF
```

マージ担当はこのファイルを検知して、以下を実行する:
1. worktree に移動してコミット
2. 統合ブランチをマージ
3. テスト実行
4. プッシュ
5. 統合ブランチへのマージ

### エラー・ブロック時の対応

問題が発生して作業を継続できない場合、プロジェクトルートの `.parallel-dev-issues/` に記録する。

```bash
# PROJECT_ROOT は worktree 作成時に設定される環境変数
# issues ディレクトリがなければ作成
mkdir -p $PROJECT_ROOT/.parallel-dev-issues

# issue ファイルを作成
cat > $PROJECT_ROOT/.parallel-dev-issues/recommendation-api.md << 'EOF'
# Issue: recommendation-api

## 発生日時
2025-01-16 14:30

## 状況
ビルドエラー / テスト失敗 / 依存タスクの問題 / その他

## エラー内容
```
（エラーメッセージをここに貼り付け）
```

## 影響範囲
- このタスク: recommendation-api
- 依存しているタスク: project-card-enhance

## 試した対応
1. xxx を試したが解決せず
2. yyy を確認したが問題なし

## 必要な対応
- [ ] 他タスクとの調整が必要
- [ ] 新しいブランチ/worktree が必要
- [ ] 人間のエスカレーションが必要

## 担当
（マージ担当が割り当てる）
EOF
```

**マージ担当の対応:**

1. `.parallel-dev-issues/` を監視
2. 問題の内容を確認し、担当を割り当て
3. 必要に応じて新しい worktree/ブランチを作成
4. `.parallel-dev/` 内のファイルを更新:
   - `README.md`: タスク一覧に追加
   - `merge-coordinator.md`: マージ順序を更新
   - `tasks/`: 新しいタスク指示書を作成

テンプレート: [templates/issue-template.md](templates/issue-template.md)

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

| 優先度 | 基準 | 説明 |
|--------|------|------|
| 1 | **依存関係** | 他のブランチが依存するブランチを先にマージ |
| 2 | **変更範囲** | 広範囲の変更を先に、小さい変更で調整 |
| 3 | **コンフリクトリスク** | 同じファイルを変更するブランチ間の順序を考慮 |
| 4 | **完了順** | 上記に該当しなければ完了した順 |

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

### 作業用 claude のルール

- **コミットしない**: コードを書くだけ。コミットはマージ担当が行う
- **プッシュしない**: リモートへのプッシュもマージ担当が行う
- **.done ファイルで完了報告**: 実装内容と変更ファイルを記載
- **依存タスクが未完了なら待機**: マージ担当からの通知を待つ

### マージ担当のルール

- **`--no-ff` で常にマージ**: マージコミットを残し、履歴を明確にする
- **マージ順序**: 依存関係 > 変更範囲 > 完了順
- **テスト必須**: 統合ブランチマージ後、必ずテストを実行
- **テスト失敗時**: 作業用 claude に修正依頼、統合ブランチへのマージは中止
- **コンフリクト対応**: 軽微なら自分で解決、複雑なら作業用 claude に依頼

### 依存関係ルール

- **依存タスクが未完了なら開始しない**: モックで部分的に進めることは可能だが、基本は待機
- **統合ブランチにマージされてから開始**: 依存先の `.done` ファイルがあっても、統合ブランチにマージされるまで開始しない
- **依存先ブランチを直接 checkout/merge しない**: 常に `origin/feature/integration` から取り込む

### ポート割り当てルール

- **ベースポート + インデックス**: BE=3000+i, FE=5173+i
- **インデックス 0 はプロジェクトルート用**: worktree は 1 から

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

1. **tmux セッション内で起動**（作業用 claude を別ペインで起動するため必須）
2. **人間はマージ担当の claude のみを起動**
3. **マージ担当が Bash ツールで `tmux split-window` を実行** して作業用 claude を起動・管理
4. **Task ツール（サブエージェント）は使用しない**

```bash
# tmux セッションを開始
tmux new-session -s parallel-dev

# プロジェクトルートでマージ担当を起動
claude

# 初期指示
".parallel-dev/merge-coordinator.md を読んで並列開発を開始して"
```

マージ担当が依存関係を考慮して、tmux で作業用 claude を起動・管理する。

## 並列開発完了後のクリーンアップ

すべてのタスクが完了し、統合ブランチが main にマージされたら、クリーンアップを行う。

### クリーンアップの条件

以下がすべて満たされていること:

- [ ] すべてのタスクがマージ済み
- [ ] 統合ブランチが main にマージ済み
- [ ] 統合テストがパス
- [ ] `.parallel-dev-issues/` に未解決の issue がない

### worktree の削除

```bash
# プロジェクトルートで実行

# 1. worktree 一覧を確認
git worktree list

# 2. 各 worktree を削除
git worktree remove worktree/recommendation-api
git worktree remove worktree/notification-api
git worktree remove worktree/project-card-enhance
git worktree remove worktree/search-filter

# 3. worktree ディレクトリが残っていれば削除
rm -rf worktree/

# 4. worktree の整理（孤立した参照を削除）
git worktree prune
```

### ブランチの削除

```bash
# ローカルブランチを削除
git branch -d feature/recommendation-api
git branch -d feature/notification-api
git branch -d feature/project-card-enhance
git branch -d feature/search-filter
git branch -d feature/integration

# リモートブランチを削除（必要に応じて）
git push origin --delete feature/recommendation-api
git push origin --delete feature/notification-api
git push origin --delete feature/project-card-enhance
git push origin --delete feature/search-filter
git push origin --delete feature/integration
```

### .parallel-dev/ の削除

すべてのタスクが完了したら `.parallel-dev/` ディレクトリを削除する。

```bash
# 削除前に完了を確認
cat .parallel-dev/README.md  # 進捗が 100% であること
ls .parallel-dev-issues/     # 未解決の issue がないこと

# 削除
rm -rf .parallel-dev/
```

**注意**: 次回の並列開発で参考にしたい場合は、アーカイブしてから削除:

```bash
# アーカイブ（日付付き）
tar -czvf parallel-dev-archive-$(date +%Y%m%d).tar.gz .parallel-dev/

# 削除
rm -rf .parallel-dev/
```

### クリーンアップの一括実行

```bash
#!/bin/bash
# cleanup-parallel-dev.sh

# 確認
echo "並列開発のクリーンアップを実行します。"
echo "すべてのタスクがマージ済みであることを確認してください。"
read -p "続行しますか？ (y/N): " confirm
if [[ "$confirm" != "y" ]]; then
  echo "キャンセルしました。"
  exit 1
fi

# worktree 削除
echo "worktree を削除中..."
for wt in worktree/*/; do
  if [ -d "$wt" ]; then
    git worktree remove "$wt" 2>/dev/null || rm -rf "$wt"
  fi
done
git worktree prune

# worktree ディレクトリ削除
rm -rf worktree/

# .parallel-dev/ 削除
echo ".parallel-dev/ を削除中..."
rm -rf .parallel-dev/

echo "クリーンアップ完了。"
echo "ブランチの削除は手動で行ってください: git branch -d <branch-name>"
```
