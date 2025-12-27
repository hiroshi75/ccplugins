---
name: plan-parallel-dev
description: 複数開発者での並列開発計画書を作成するスキル。git worktree を活用したブランチ戦略、タスクの依存関係分析、クリティカルパス計算、開発者ロール割り当て、タイムライン作成を行う。「並列開発計画を作って」「複数人で同時開発したい」「worktree で分担したい」「開発を最大限並列化したい」などのリクエスト時に使用。また、「〇〇を並列で修正して」「worktree で△△をやって」「並列タスクを追加」などのリクエストで、オンデマンドの並列タスクを即座に開始できる。
---

# Parallel Development Planning

機能開発を複数開発者で最大限並列化するための実装計画書を作成する。
また、完成後のプロジェクトに対するオンデマンドの並列タスク（バグ修正・機能追加）もサポートする。

## 利用モード

このスキルには2つのモードがある:

### モード A: 初期並列開発（計画書作成モード）

新規プロジェクトや大規模機能開発の初期段階で使用。

**トリガーフレーズ**:
- 「並列開発計画を作って」
- 「複数人で同時開発したい」
- 「worktree で分担したい」
- 「開発を最大限並列化したい」

**ワークフロー**: 9段階のワークフロー（後述）で計画書を作成し、複数タスクを一斉に開始。

### モード B: メンテナンス並列開発（クイックタスクモード）

既存プロジェクトへのバグ修正・機能追加で使用。計画書なしで即座に作業を開始。

**トリガーフレーズ**:
- 「〇〇を並列で修正して」
- 「〇〇を並列で対応して」
- 「worktree で△△をやって」
- 「並列タスクを追加: 〇〇」
- 「これを worktree でやって: 〇〇」

**ワークフロー**: 詳細は「Quick Task Workflow（クイックタスク）」セクション参照。

---

## Workflow（モード A: 初期並列開発）

```
1. 要件の把握
   └─→ 開発対象の機能一覧を収集
   └─→ 技術スタック確認 (BE/FE/インフラ等)

2. タスク分解
   └─→ 各機能を独立したタスクに分割
   └─→ 粒度: 0.5〜2日程度の作業単位
   └─→ ⚠️ UI仕様は人間の確認を取ってから確定（後述）

3. 依存関係分析
   └─→ タスク間のブロッキング関係を特定
   └─→ クリティカルパスを計算

4. 並列度の決定
   └─→ 必要な claude 数を算出
   └─→ 待機時間を最小化する割り当て

5. ブランチ戦略
   └─→ 統合ブランチの設計
   └─→ 機能ブランチの命名規則
   └─→ マージ順序の決定

6. タイムライン作成
   └─→ Gantt風の並列スケジュール

7. 計画書・指示書の作成
   └─→ 計画書の内容をユーザーに直接伝える（会話で）
   └─→ .parallel-dev/ にファイルを作成
       ├─→ PLAN.md (計画書)
       ├─→ README.md (全体概要・進捗管理)
       ├─→ merge-coordinator.md (マージ担当用)
       ├─→ tasks/*.md (各タスク用)
       ├─→ signals/ (完了通知用ディレクトリ)
       └─→ issues/ (問題報告用ディレクトリ)

8. 環境セットアップ
   └─→ 統合ブランチを作成してリモートにプッシュ
   └─→ 各タスク用の worktree を作成
   └─→ 各 worktree で依存関係インストール
   └─→ 各 worktree で .env コピー、.env.local 作成

9. Claude Code 起動手順を伝える（会話で）
   └─→ tmux 内で起動することを明示
   └─→ マージ担当の初期指示を伝える
```

## Quick Task Workflow（モード B: クイックタスク）

既存プロジェクトに対するバグ修正や機能追加を、計画書なしで即座に開始するモード。

### ワークフロー概要

```
1. タスク受付 → タスク名を決定（kebab-case）
2. 自動セットアップ → worktree 作成、環境設定、簡易指示書生成
3. 作業用 claude を起動 → tmux split-window で起動
4. 完了検知 → マージ → クリーンアップ
```

### モード A との違い

| 観点 | 初期並列開発（A） | クイックタスク（B） |
|------|-------------------|---------------------|
| 起点 | 計画書作成から開始 | 依頼を受けて即座に開始 |
| 計画書 | PLAN.md を作成 | 作成しない |
| マージ先 | 統合ブランチ → main | main に直接マージ |

### 詳細ガイド・テンプレート

- [references/templates/quick-task-template.md](references/templates/quick-task-template.md) - 簡易タスク指示書テンプレート
- [references/templates/quick-task-coordinator.md](references/templates/quick-task-coordinator.md) - タスク受付・マージ担当用
- [references/worktree-guide.md](references/worktree-guide.md) - クイックタスクモードでの worktree 運用

---

## Terminology（用語定義）

混乱を避けるため、以下の用語を統一する:

| 用語              | 説明                               | 例                                     |
| ----------------- | ---------------------------------- | -------------------------------------- |
| **タスク名**      | ブランチ名と同一。作業単位の識別子 | `skill-files-api`, `recommendation-ui` |
| **担当者/ロール** | 作業者の識別子。技術領域+番号      | `BE-1`, `FE-1`, `INFRA-1`              |
| **統合ブランチ**  | 全タスクをマージする先のブランチ   | `feature/multi-file-skills`            |

**重要**: 完了報告や状態管理では**タスク名（ブランチ名）**を使う。担当者名だけでは、複数タスクを担当している場合に特定できない。

## Task Decomposition Rules

タスク分割の原則:

1. **単一責任**: 1 タスク = 1 機能/1 コンポーネント
2. **適切な粒度**: 0.5 日〜2 日の作業量
3. **明確な成果物**: 各タスクに API/コンポーネント/ファイル等の具体的成果物
4. **テスト可能**: 独立してテスト・レビュー可能な単位

ブランチ命名:

```
feature/recommendation-api  # 機能名ベース
feature/notification-api
feature/project-card-enhance
```

ロール（担当者）命名:

```
BE-1, BE-2, ...    # バックエンド担当
FE-1, FE-2, ...    # フロントエンド担当
INFRA-1, ...       # インフラ担当
```

## Dependency Analysis

依存関係の種類:

| 依存タイプ   | 記号 | 説明           |
| ------------ | ---- | -------------- |
| ブロッキング | `→`  | 完了必須       |
| 並行可能     | `//` | 独立して進行可 |
| 統合待ち     | `↓`  | マージ後に開始 |

クリティカルパス計算:

```
最長パス = max(各経路の合計工数)
最適人数 = ceil(総工数 / クリティカルパス)
```

依存関係マトリクスの作成:

```
         BE-01  BE-02  FE-01  FE-02
BE-01      -      //     ↓      //
BE-02     //       -     //      ↓
FE-01     待      //      -      //
FE-02     //      待     //       -
```

## Developer Role Assignment

ロール定義テンプレート:

| ロール | 担当ブランチ    | 必要スキル        |
| ------ | --------------- | ----------------- |
| BE-1   | feature/xxx-api | Python, FastAPI   |
| FE-1   | feature/xxx-ui  | React, TypeScript |

待機時間最小化の原則:

1. 依存元タスクの担当者に依存先も割り当て
2. 独立タスクで待機時間を埋める
3. レビュー・支援で空き時間を活用

## Branch Strategy with Worktree

git worktree を使った並列開発:

```bash
# 統合ブランチ作成
git checkout -b feature/integration main

# worktree ディレクトリを .gitignore に追加
echo "worktree/" >> .gitignore

# 各機能ブランチ用 worktree（プロジェクト内の worktree/ 以下に作成）
# ディレクトリ名 = ブランチ名（feature/ プレフィックスを除く）
git worktree add worktree/api-a -b feature/api-a
git worktree add worktree/ui-a -b feature/ui-a
```

### worktree 環境セットアップ

worktree 作成後、各ディレクトリで開発環境を準備する:

1. **依存関係インストール**: `uv sync` / `pnpm install` など
2. **secrets コピー**: プロジェクトルートの `.env` を worktree にコピー
3. **ポート設定**: `.env.local` に worktree 固有のポート番号を設定

```bash
# 例: worktree作成 + 環境セットアップ
BRANCH=api-a
INDEX=1

git worktree add worktree/$BRANCH -b feature/$BRANCH
cp .env worktree/$BRANCH/.env
cat > worktree/$BRANCH/.env.local << EOF
PORT=$((3000 + INDEX))
VITE_PORT=$((5173 + INDEX))
EOF
cd worktree/$BRANCH && uv sync && cd ../..
```

ポート番号割り当ての詳細は [references/templates/env-local-template.md](references/templates/env-local-template.md) 参照。

ブランチ構造:

```
main
└── feature/integration (統合ブランチ)
    ├── feature/xxx-api     → worktree/xxx-api/
    ├── feature/yyy-api     → worktree/yyy-api/
    ├── feature/xxx-ui      → worktree/xxx-ui/  ← xxx-api 完了後にAPI統合
    └── feature/yyy-ui      → worktree/yyy-ui/
```

詳細は [references/worktree-guide.md](references/worktree-guide.md) 参照。

## Agent Instruction Files

claude による並列開発では、各 claude への指示書を `.parallel-dev/` に配置する。

ディレクトリ構成:

```
project/
├── .parallel-dev/                    # 並列開発管理（git管理）
│   ├── PLAN.md                       # 計画書（重要な参照情報）
│   ├── README.md                     # 全体概要・進捗サマリ
│   ├── merge-coordinator.md          # マージ担当用
│   └── tasks/                        # 各タスク用指示書
│       ├── xxx-api.md
│       └── xxx-ui.md
├── .parallel-dev-signals/            # 完了通知（.gitignore）
│   └── xxx-api.done
├── .parallel-dev-issues/             # 問題報告（.gitignore）
│   └── xxx-ui.md
├── worktree/                         # worktree（.gitignore）
│   ├── xxx-api/
│   └── xxx-ui/
└── ...
```

\*_.gitignore に追加:_

```
.parallel-dev-signals/
.parallel-dev-issues/
worktree/
```

各ファイルの役割:

| ファイル                              | 対象           | 内容                                   |
| ------------------------------------- | -------------- | -------------------------------------- |
| `PLAN.md`                             | 全員（参照用） | 計画書全体、ブランチ戦略、タイムライン |
| `README.md`                           | 全 claude      | 進捗サマリ、タスク一覧、依存関係図     |
| `merge-coordinator.md`                | マージ担当     | マージ順序、コンフリクト対応方針       |
| `tasks/{branch}.md`                   | 作業用 claude  | 実装仕様、依存関係、完了条件           |
| `.parallel-dev-signals/{branch}.done` | マージ担当     | 完了通知（git 管理外）                 |
| `.parallel-dev-issues/{branch}.md`    | マージ担当     | 問題報告、ブロッカー（git 管理外）     |

テンプレート:

- [references/templates/parallel-dev-readme.md](references/templates/parallel-dev-readme.md)
- [references/templates/merge-coordinator.md](references/templates/merge-coordinator.md)
- [references/templates/task-instruction.md](references/templates/task-instruction.md)

## Task Completion Flow

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

### 作業用 claude の完了フロー

1. コード実装を完了
2. `.done` ファイルを作成（コミット前に！）
3. 作業終了を報告

```bash
# 作業完了時（コミットはしない）
# PROJECT_ROOT は tmux 起動時にマージ担当から渡される環境変数
cat > $PROJECT_ROOT/.parallel-dev-signals/{branch-name}.done << 'EOF'
【完了報告】{branch-name}

## 実装内容
- {実装した機能の説明}
- {変更したファイル}

## 未コミットの変更
worktree/{branch-name}/ に未コミットの変更あり

## テスト状況
ローカルでの動作確認: OK / NG（詳細を記載）
EOF
```

### マージ担当の統合フロー

.done ファイルを検知したら、マージ担当が以下を実行:

```bash
# 1. 作業 worktree に移動
cd worktree/{branch-name}

# 2. 変更をコミット
git add .
git commit -m "feat: {branch-name} の実装"

# 3. 統合ブランチの最新を取り込み
git fetch origin
git merge origin/feature/{integration} --no-ff

# 4. コンフリクトがあれば解決（または作業用 claudeに依頼）

# 5. テスト実行
{test-command}

# 6. テスト失敗時 → 作業用 claudeに修正依頼して終了

# 7. テスト成功時 → プッシュ
git push origin feature/{branch-name}

# 8. 統合ブランチにマージ
cd ../..  # プロジェクトルートへ
git checkout feature/{integration}
git merge origin/feature/{branch-name} --no-ff
git push origin feature/{integration}

# 9. 状態更新
# - タスク指示書のステータスを「マージ済」に
# - README.md の進捗を更新
# - 依存元タスクに通知
```

### テスト失敗時の対応

マージ担当がテスト失敗を検知したら:

```
【修正依頼】{branch-name}

統合ブランチマージ後のテストが失敗しました。

エラー内容:
{テストエラーの出力}

対応依頼:
1. worktree/{branch-name}/ で修正
2. 修正完了後、再度 .done ファイルを作成

※ コミットは不要です。マージ担当が行います。
```

### エラー・ブロック時

問題発生時は `.parallel-dev-issues/{branch-name}.md` に記録:

- エラー内容、影響範囲、試した対応を記載
- マージ担当が担当を割り当て、必要に応じて新規 worktree/ブランチを作成

テンプレート: [references/templates/issue-template.md](references/templates/issue-template.md)

## Rules（全 claude 共通）

### 作業用 claude のルール

- **コミットしない**: コードを書くだけ。コミットはマージ担当が行う
- **プッシュしない**: リモートへのプッシュもマージ担当が行う
- **.done ファイルで完了報告**: 実装内容と変更ファイルを記載
- **依存タスクが未完了なら待機**: マージ担当からの通知を待つ
- **UI 仕様は人間の承認必須**: UI の見た目・動作の決定は勝手に行わない。issues/ に確認依頼を出し、人間の承認を得てから実装する（詳細は「UI Specification Approval」セクション参照）

### マージ担当のルール

- **作業用 claude は Bash ツールで `tmux split-window` を実行して起動**: 別ペインで Claude Code を起動
- **`tmux new-window` は使用しない**: 別ウィンドウではなく、必ずペイン分割（`split-window`）で起動すること
- **Task ツール（サブエージェント）は使用しない**: 必ず tmux コマンドで起動すること
- **`--no-ff` で常にマージ**（マージコミットを残す）
- **マージ順序**: 依存関係 > 変更範囲 > 完了順
- **テスト必須**: 統合ブランチマージ後、必ずテストを実行
- **テスト失敗時**: 作業用 claude に修正依頼、統合ブランチへのマージは中止
- **コンフリクト対応**: 軽微なら自分で解決、複雑なら作業用 claude に依頼
- **UI 仕様確認の中継**: 作業用 claude から issues/ に UI 仕様確認依頼が出されたら、AskUserQuestion ツールで人間に確認を取り、回答を作業用 claude に伝達する

### 依存関係ルール

- 依存タスクが**統合ブランチにマージされるまで**開始しない
- マージ担当が依存タスクの完了を通知するまで待機

### ポート割り当てルール

- BE: 3000 + index, FE: 5173 + index
- index 0 = プロジェクトルート、worktree は 1 から

### 状態更新の責任分担

| 更新対象                 | 責任者                 | タイミング             |
| ------------------------ | ---------------------- | ---------------------- |
| .done ファイル           | 作業用 claude          | 実装完了時             |
| git commit/push          | マージコーディネーター | .done 検知後           |
| タスク指示書のステータス | マージコーディネーター | マージ後「マージ済」へ |
| README.md の進捗         | マージコーディネーター | マージ後               |
| 依存タスクの起動         | マージコーディネーター | 依存先マージ後         |

## Additional Guides（詳細ガイド）

以下の詳細ガイドは必要に応じて参照:

- [references/testing-guide.md](references/testing-guide.md) - テスト方針（本番同等テスト、E2E目視チェック）
- [references/ui-approval-guide.md](references/ui-approval-guide.md) - UI仕様の人間確認フロー
- [references/best-practices.md](references/best-practices.md) - よくある問題と対策
- [references/advanced-features.md](references/advanced-features.md) - Phase分離、タイムライン可視化、計画書テンプレート

## Utility Scripts（ユーティリティスクリプト）

よく使う操作を自動化するスクリプト。プロジェクトにコピーして使用する。

| スクリプト | 用途 |
|-----------|------|
| [setup-quick-task.sh](references/scripts/setup-quick-task.sh) | クイックタスクのセットアップ（worktree作成、指示書生成） |
| [watch-signals.sh](references/scripts/watch-signals.sh) | .done/.issues ファイルの監視 |
| [status.sh](references/scripts/status.sh) | 全タスクの状態一覧表示 |
| [update-dashboard.sh](references/scripts/update-dashboard.sh) | README.md（進捗ダッシュボード）の自動更新 |
| [cleanup-worktrees.sh](references/scripts/cleanup-worktrees.sh) | 完了タスクのクリーンアップ |

### 使用例

```bash
# 1. スクリプトをプロジェクトにコピー
cp -r /path/to/scripts .parallel-dev/scripts/
chmod +x .parallel-dev/scripts/*.sh

# 2. クイックタスクをセットアップ
.parallel-dev/scripts/setup-quick-task.sh fix-login-validation

# 3. シグナルを監視（完了待ち）
.parallel-dev/scripts/watch-signals.sh

# 4. 状態を確認
.parallel-dev/scripts/status.sh

# 5. ダッシュボードを更新
.parallel-dev/scripts/update-dashboard.sh

# 6. 完了タスクをクリーンアップ
.parallel-dev/scripts/cleanup-worktrees.sh
```

### マージ担当のワークフロー

マージ担当はスクリプトを使って効率的に作業できる:

```bash
# 1. 完了検知
.parallel-dev/scripts/watch-signals.sh

# 2. マージ処理（手動）
cd worktree/{task-name}
git add . && git commit -m "fix: {task-name}"
git fetch origin && git merge origin/main --no-ff
{test-command}
git push origin {branch}

# 3. ダッシュボード更新
cd ../..
.parallel-dev/scripts/update-dashboard.sh

# 4. クリーンアップ
.parallel-dev/scripts/cleanup-worktrees.sh {task-name}
```
