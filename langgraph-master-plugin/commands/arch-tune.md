---
name: arch-tune
description: Architecture-level tuning through parallel exploration of multiple graph structure changes
---

# LangGraph Architecture Tuning Command

LangGraph アプリケーションのグラフ構成を大胆に変更して性能を向上させます。複数の改善案を並列に探索し、最善の構成を特定します。

## 🎯 目的

以下の目的に従ってグラフ構造を最適化します：

```
$ARGUMENTS
```

**fine-tune スキル**がプロンプトとパラメータの最適化に焦点を当てるのに対し、**arch-tune コマンド**はグラフ構造そのものを変更します：

- ノード・エッジの追加/削除
- サブグラフの導入
- 並列処理の追加
- ルーティング戦略の変更
- アーキテクチャパターンの切り替え

## 📋 実行フロー

### 初期化: タスク登録

arch-tune コマンドの開始時に TodoWrite ツールを使用して次節以降の全 Phase をそれぞれタスクとして登録してください。(その際、このファイルの内容を忘れないようにこのファイルの参照を入れておくといいでしょう。)

各 Phase の開始時に `in_progress` に更新し、完了時に `completed` に更新します。

### Phase 1: 分析と提案（arch-analysis スキル）

**実行内容**:

1. **`arch-analysis` スキルを起動**
   - 評価プログラムの確認・作成（`.langgraph-master/evaluation/`）
   - ベースラインパフォーマンス測定（3-5 回実行）
   - グラフ構造の分析（Serena MCP 使用）
   - ボトルネックの特定
   - アーキテクチャパターンの検討
   - 3-5 個の具体的な改善案を発案

**出力**:

- `analysis/baseline_performance.json` - ベースライン性能（統計情報含む）
- `analysis/analysis_report.md` - 現状分析と問題点
- `analysis/improvement_proposals.md` - 詳細な改善提案（Proposal 1-5）
- `.langgraph-master/evaluation/` - 評価プログラム（作成または確認済み）

→ 詳細な手順とワークフローは arch-analysis スキルを使用

### Phase 2: 実装（Implementation）

**目的**: 各改善案のグラフ構造を実装

**実行内容**:

1. **Git Worktree の作成と準備**

   改善提案ごとに独立した作業環境を作成：

   ```bash
   # Proposal 1, 2, 3 それぞれに worktree を作成
   git worktree add .worktree/proposal-1 -b proposal-1
   git worktree add .worktree/proposal-2 -b proposal-2
   git worktree add .worktree/proposal-3 -b proposal-3

   # 各 worktree に分析結果, .envをコピー
   for dir in .worktree/*/; do
     cp -r analysis "$dir"
     cp .env "$dir"
   done

   # 評価プログラムが元のディレクトリにある場合、各 worktree で実行可能に
   # （共有の .langgraph-master/evaluation/ を使用する場合はコピー不要）
   ```

   **ディレクトリ構造**:

   ```
   プロジェクト/
   ├── .worktree/
   │   ├── proposal-1/          # 独立した作業環境 1
   │   │   ├── analysis/        # 分析結果（コピー **これはcommitして渡すのではなく、worktreeを作ったあとにファイルとしてコピーしてください！**）
   │   │   │   ├── baseline_performance.json
   │   │   │   ├── analysis_report.md
   │   │   │   └── improvement_proposals.md
   │   │   └── [プロジェクトファイル]
   │   ├── proposal-2/          # 独立した作業環境 2
   │   └── proposal-3/          # 独立した作業環境 3
   ├── analysis/                # 分析結果（元）
   └── [元のプロジェクトファイル]
   ```

2. **langgraph-engineer による並列実装**

   **各 Proposal に対して langgraph-engineer エージェントを起動**：

   ```markdown
   作業 worktree: .worktree/proposal-X/
   改善提案: Proposal X (analysis/improvement_proposals.md より)
   タスク: グラフ構造の変更を実装し、正しく動くかテストしてください（ノード、エッジ、サブグラフの追加・変更）

   langgraph-engineer として実装を完了してください。
   詳細は agents/langgraph-engineer.md を参照。
   ```

   **並列実行パターン**：

   - 全ての Proposal（1, 2, 3, ...）の実装を並列に開始
   - 各 langgraph-engineer エージェントが独立して作業

3. **全実装の完了を待機**
   - 親エージェントは全ての実装完了を確認

### Phase 3: 最適化（Optimization）

**目的**: 実装されたグラフのプロンプトとパラメータを最適化

**実行内容**:

1. **langgraph-tuner による並列最適化**

   **Phase 2 完了後、各 worktree の Proposal の実装に対して langgraph-tuner エージェントを起動**：

   ```markdown
   作業 worktree: .worktree/proposal-X/
   改善提案: Proposal X (analysis/improvement_proposals.md より)
   最適化目標: [ユーザー指定の目標]

   注意: グラフ構造の変更は Phase 2 で完了済みです。Phase 2 をスキップし、Phase 3（テスト）から開始してください。

   結果レポート:

   - ファイル名: `proposal_X_result.md` (.worktree/proposal-X/ 直下に保存)
   - 形式: 短くコンパクトに実験結果と考察をまとめる
   - 必須項目: ベースラインとの比較表、改善率、主要な変更点、推奨事項

   langgraph-tuner として最適化ワークフローを実行してください。
   詳細は agents/langgraph-tuner.md を参照。
   ```

   **並列実行パターン**：

   - 全ての Proposal（1, 2, 3, ...）の最適化を並列に開始
   - 各 langgraph-tuner エージェントが独立して作業

2. **全最適化の完了を待機**
   - 親エージェントは全ての最適化完了と結果レポート生成を確認

**重要**:

- 評価プログラムは全 worktree で同じものを使用

### Phase 4: 結果比較（proposal-comparator エージェント）

**目的**: 最善の改善案を特定

**実行内容**:

**proposal-comparator エージェントを起動**:

```markdown
実装レポート: 各 worktree の `proposal_X_result.md` を読み取る

- .worktree/proposal-1/proposal_1_result.md
- .worktree/proposal-2/proposal_2_result.md
- .worktree/proposal-3/proposal_3_result.md
  最適化目標: [ユーザー指定の目標]

proposal-comparator として比較分析を実行してください。
詳細は agents/proposal-comparator.md を参照。
```

### Phase 5: マージ確認（merge-coordinator エージェント）

**目的**: ユーザーの承認を得てマージ

**実行内容**:

**merge-coordinator エージェントを起動**:

```markdown
比較レポート: analysis/comparison_report.md
Worktree: .worktree/proposal-\*/

merge-coordinator としてユーザー承認とマージを実行してください。
詳細は agents/merge-coordinator.md を参照。
```

## 🔧 技術的な詳細

### Git Worktree コマンド

**作成**:

```bash
git worktree add .worktree/<branch-name> -b <branch-name>
```

**一覧**:

```bash
git worktree list
```

**削除**:

```bash
git worktree remove .worktree/<branch-name>
git branch -d <branch-name>
```

### 並列実行の実装

単一メッセージで複数の `Task` tool を呼び出すことで、Claude Code が自動的に並列実行します。

### サブエージェントの制約

- ❌ サブエージェントからサブエージェントは呼べない
- ✅ サブエージェントからスキルは呼べる
- → 各サブエージェントが fine-tune スキルを直接実行可能

## ⚠️ 注意事項

### Git Worktree

1. `.worktree/` を `.gitignore` に追加
2. 各 worktree は独立した作業ディレクトリ
3. 並列実行しても競合しない

### 評価

1. **評価プログラムの配置**:

   - 推奨: `.langgraph-master/evaluation/` に配置（全 worktree から参照可能）
   - 各 worktree 内の `analysis/` にコピーされたベースラインを参照

2. **統一された評価条件**:

   - 全 worktree で同じ評価プログラムを使用
   - 同じテストケースで評価
   - 環境変数（API キーなど）は共有

3. **評価の実行**:
   - 各 langgraph-tuner エージェントが独立して評価を実行
   - 3-5 回のイテレーションで統計的信頼性を確保
   - ベースラインとの比較を各エージェントが実施

### クリーンアップ

1. マージ後、不要な worktree を削除
2. ブランチも削除
3. `.worktree/` ディレクトリを確認

## 🎓 使用例

### 基本的な実行フロー

```bash
# arch-tune コマンドの実行
/arch-tune "Latency を 2.0s 以下、Accuracy を 90% 以上に改善"
```

**実行の流れ**:

1. **Phase 1**: arch-analysis スキルが 3-5 個の改善案を生成

   - 詳細な改善提案は [arch-analysis スキル](../skills/arch-analysis/SKILL.md) を参照

2. **Phase 2**: グラフ構造の実装

   - Git worktree で独立環境作成
   - langgraph-engineer が各 Proposal のグラフ構造を並列実装

3. **Phase 3**: プロンプトとパラメータの最適化

   - langgraph-tuner が各 Proposal を並列最適化
   - 結果レポート（`proposal_X_result.md`）を生成

4. **Phase 4**: 結果を比較し最善案を特定

   - 全指標を比較テーブルで表示

5. **Phase 5**: ユーザー承認後にマージ
   - 選択された案をメインブランチにマージ
   - 不要な worktree をクリーンアップ

**具体例**: カスタマーサポートチャットボット最適化の詳細な提案例は [arch-analysis スキルの improvement_proposals セクション](../skills/arch-analysis/SKILL.md#improvement_proposalsmd) を参照してください。

## 🔗 関連リソース

- [arch-analysis スキル](../skills/arch-analysis/SKILL.md) - 分析と提案生成（Phase 1）
- [langgraph-engineer エージェント](../agents/langgraph-engineer.md) - グラフ構造の実装（Phase 2）
- [langgraph-tuner エージェント](../agents/langgraph-tuner.md) - プロンプト最適化と評価（Phase 3）
- [proposal-comparator エージェント](../agents/proposal-comparator.md) - 結果比較と推奨案選定（Phase 4）
- [merge-coordinator エージェント](../agents/merge-coordinator.md) - ユーザー承認とマージ実行（Phase 5）
- [fine-tune スキル](../skills/fine-tune/SKILL.md) - プロンプト最適化（langgraph-tuner が使用）
- [langgraph-master スキル](../skills/langgraph-master/SKILL.md) - アーキテクチャパターン
