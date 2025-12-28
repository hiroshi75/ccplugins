# Advanced Features（高度な機能）

並列開発のオプション機能・高度なテクニックのガイド。

---

## Phased Task Design（フェーズ分離）

**通常のフロー**: 依存タスクは依存先がマージされてから起動する。この場合、Phase 分離は不要。

**Phase 分離を使うケース**: 並列性を最大化するため、依存タスクも最初から起動したい場合。

### Phase 分離のパターン

**例: フロントエンドがバックエンド API に依存するが、先行開始したい場合**

```markdown
## Phase 1: UI 実装（API 完成前）

- [ ] モック API で UI 完成
- [ ] .done ファイル作成（{branch-name}-phase1.done）

## Phase 2: API 統合（依存 API 完成後）

- [ ] 依存先がマージされたら開始
- [ ] モック API を本番 API に置換
- [ ] .done ファイル作成（{branch-name}.done）
```

### Phase 分離を使う判断基準

以下の**すべて**を満たす場合のみ Phase 分離を検討:

- 依存タスクの完了を待つと並列性が大きく低下する
- モック/スタブを使った先行開発が可能
- Phase 1 と Phase 2 の作業が明確に分離できる

**通常は Phase 分離を使わず、依存先マージ後に起動する方がシンプル。**

---

## Dependency Task Launch（依存タスクの起動）

マージ担当は、依存先タスクをマージした後、依存タスクを tmux で起動する:

```bash
# 依存先がマージされたので、依存タスクを起動
# PROJECT_ROOT を渡して、.done ファイルの作成先を伝える
tmux split-window -h "cd worktree/{dependent-branch} && PROJECT_ROOT=$PROJECT_ROOT claude '../../.parallel-dev/tasks/{dependent-branch}.md を読んで実装してください。依存タスク {dependency-branch} はマージ済みです。完了したら .done ファイルを作成してください。'"
# ペインにタスク名を設定（どのペインがどのタスクか識別しやすくする）
tmux select-pane -T "{dependent-branch}"
```

---

## Timeline Visualization（タイムライン可視化）

ユーザーにタイムラインを伝える際は、ASCII アート形式で視覚的に示す:

```
Day 1                Day 2                Day 3
────────────────────────────────────────────────
BE-1  ████████████████████████████  レビュー
      BE-01: API実装 (2日)           ↓完了

FE-1  ████████████████  ████████████████████████
      FE-01: UI (1日)    FE-02: 統合 (1日)
                         ↑ BE-01完了後
```

---

## Output Template（計画書の出力）

### 計画書（ユーザーに伝える + ファイル保存）

計画書の内容はユーザーに直接伝えつつ、`.parallel-dev/PLAN.md` にも保存する。
構成の参考: [templates/parallel-dev-template.md](templates/parallel-dev-template.md)

### 主要セクション

1. 概要・目標
2. claude/ロール定義
3. ブランチ戦略
4. 作業一覧（タスク名・担当者付き）
5. 並行開発タイムライン
6. 依存関係マトリクス
7. マージ順序
8. 各タスク詳細仕様
9. 完了定義 (Definition of Done)
10. リスク管理

### claude 指示書（ファイルに作成）

計画書とは別に、各 claude 向けの指示書を `.parallel-dev/` にファイルとして作成:

| テンプレート | 出力先 | 用途 |
|-------------|--------|------|
| [parallel-dev-readme.md](templates/parallel-dev-readme.md) | `.parallel-dev/README.md` | 全体進捗管理 |
| [merge-coordinator.md](templates/merge-coordinator.md) | `.parallel-dev/merge-coordinator.md` | マージ担当用 |
| [task-instruction.md](templates/task-instruction.md) | `.parallel-dev/tasks/*.md` | 各タスク用 |

---

## Claude Code 起動手順

計画書作成後、ユーザーに以下の tmux コマンドを実行するよう伝える:

```bash
# プロジェクトルートでマージ担当を起動（tmux セッション内で実行すること）
export PROJECT_ROOT=$(pwd)
tmux split-window -h "cd $PROJECT_ROOT && claude '.parallel-dev/merge-coordinator.md を読んで並列開発を開始して'"
```

**注意**: 作業用 claude はマージ担当が `tmux split-window` で起動する。人間が個別に起動する必要はない。

---

## Asking Clarifying Questions（事前確認）

計画作成前に確認すべき項目:

1. **開発対象**: どの機能・改善を実装するか
2. **技術スタック**: BE/FE/インフラの技術選定
3. **開発者数**: 最大何名で開発可能か
4. **既存資料**: PRD、設計書、改善案などの有無
5. **制約**: 期限、依存する外部要因など
6. **テストコマンド**: マージ後に実行するテストコマンド（例: `uv run pytest tests/ -v`）
7. **テスト環境**: 外部API・DB接続に使用する環境（開発/ステージング）
