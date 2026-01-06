# plan-parallel-dev-plugin

複数の Claude を使って並列開発を行うための Claude Code プラグイン。

## 概要

このプラグインは、git worktree を活用して複数の Claude が同時に異なるタスクを実行できる並列開発環境を構築・管理します。

### 主な機能

- **タスク分解**: 機能開発を独立したタスクに分割
- **依存関係分析**: タスク間のブロッキング関係を特定し、クリティカルパスを計算
- **worktree 管理**: 各タスク用の git worktree を自動作成・管理
- **マージ調整**: 統合ブランチへのマージ順序を管理
- **Project Intent 管理**: プロジェクト全体の方針と worktree ごとの作業コンテキストを管理

## 利用モード

### モード A: 初期並列開発（計画書作成モード）

プロジェクト初期化直後に、複数機能を並列開発する場合に使用。

**トリガーフレーズ**:
- 「並列開発計画を作って」
- 「複数人で同時開発したい」
- 「worktree で分担したい」

**ワークフロー**:
1. 要件の把握
2. タスク分解
3. 依存関係分析
4. 並列度の決定
5. ブランチ戦略
6. タイムライン作成
7. 計画書・指示書の作成
8. 環境セットアップ
9. マージ担当の起動

### モード B: クイックタスクモード

既存プロジェクトへのバグ修正・機能追加を即座に開始するモード。

**トリガーフレーズ**:
- 「〇〇を並列で修正して」
- 「worktree で△△をやって」
- 「並列タスクを追加: 〇〇」

## ディレクトリ構成

```
PROJECT.md               # プロジェクト全体の憲法（git管理）

.parallel-dev/           # 並列開発管理（git管理）
├── PLAN.md              # 計画書
├── README.md            # 全体概要・進捗管理
├── merge-coordinator.md # マージ担当用指示
└── tasks/*.md           # 各タスク用指示書

.parallel-dev-signals/   # 完了通知（.gitignore）
.parallel-dev-issues/    # 問題報告（.gitignore）

worktrees/               # 各タスク用 worktree（.gitignore）
└── task-name/
    └── BRIEF.md         # worktree ごとの作業コンテキスト（.gitignore）
```

## Project Intent 管理

並列開発では、複数の worktree 間でコンテキストが失われやすい問題があります。
この機能は「何を正しいとみなしていたか」という上位コンテキストを保持します。

### ファイル構成

| ファイル | 役割 | commit | 更新頻度 |
|---------|------|--------|---------|
| `PROJECT.md` | プロジェクト全体の憲法 | ✅ する | 基本不変 |
| `BRIEF.md` | worktree ごとの思考メモ | ❌ しない | 随時 |

### セットアップ

```bash
# プロジェクト全体の方針を作成
bash .claude/skills/plan-parallel-dev/scripts/init-project-intent.sh

# worktree ごとの作業コンテキストを作成
bash .claude/skills/plan-parallel-dev/scripts/init-brief.sh <task-name>

# コンテキストを読み込む
bash .claude/skills/plan-parallel-dev/scripts/load-context.sh
```

### 作業開始時のルール

各 worktree で作業を開始する際、必ず以下を実行:

```
この worktree の BRIEF.md と、プロジェクトの PROJECT.md を読み、
Mode / Focus / Non-goals / Next Bet を最初に要約してから作業を開始してください。
```

詳細は [skills/plan-parallel-dev/references/project-intent-guide.md](skills/plan-parallel-dev/references/project-intent-guide.md) を参照。

## インストール

```bash
# Claude Code の設定で plugins ディレクトリにこのプラグインを追加
```

## ライセンス

MIT
