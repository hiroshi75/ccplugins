# Project Intent 情報管理ガイド

## 目次

1. [背景：なぜこの方式が必要か](#背景なぜこの方式が必要か)
2. [基本的な考え方](#基本的な考え方)
3. [採用する運用方式](#採用する運用方式)
4. [各ファイルの役割](#各ファイルの役割)
5. [セットアップ手順](#セットアップ手順)
6. [日常的な運用ルール](#日常的な運用ルール)
7. [効果とメリット](#効果とメリット)

---

## 背景：なぜこの方式が必要か

Claude Code を使って複数の開発プロジェクトや worktree を同時並行で進めていると、次のような問題が頻発する:

- **コンテキストの喪失**: どのプロジェクトで、どんな意識・判断基準で進めていたか分からなくなる
- **前提の混同**: 別 worktree の前提や制約を混ぜたまま作業してしまう
- **設計判断の忘却**: 「なぜその設計判断をしたのか」を思い出すコストが高い
- **意図の復元困難**: Issue / Task を見ても、上位の意図（方向性）が復元できない

これはタスク管理の問題ではなく、**「そのプロジェクト（あるいはその worktree）で、何を正しいとみなしていたか」** という *上位コンテキスト* が失われることが原因である。

---

## 基本的な考え方

### 管理したいのは「作業」ではなく「姿勢」

Issue や Task は「何をするか」を管理するが、並列開発で失われやすいのは次のような情報:

- いまは探索なのか、収束なのか
- 何を優先し、何を捨てると決めていたか
- 判断に迷ったときの基準
- 次に意思決定するための一手（仮説・賭け）

これらは **作業ログではなく、思考の前提** であり、コードと同じ粒度で履歴管理する対象ではない。

### Project と Worktree では不変性が違う

- **プロジェクト全体の目的や勝ち筋は、基本的に不変**
- **worktree は実験・分岐・一時的探索になりやすく、前提が頻繁に変わる**

そのため、以下のように分離して管理する:

- **プロジェクトの根本方針** → `PROJECT.md`（commit する）
- **worktree ごとの一時的な進め方** → `BRIEF.md`（gitignore する）

---

## 採用する運用方式

### 方針まとめ

- プロジェクト全体の方針は **commit する**
- worktree ごとの思考メモは **commit しない**
- Claude Code には毎回、明示的に **両方を読ませる**

### ファイル構成

```
プロジェクトルート/
├── PROJECT.md              # プロジェクト共通・基本不変（commit）
├── worktrees/
│   ├── task-a/
│   │   └── BRIEF.md        # worktree 固有・可変（gitignore）
│   ├── task-b/
│   │   └── BRIEF.md
│   └── task-c/
│       └── BRIEF.md
└── .gitignore              # BRIEF.md を除外
```

---

## 各ファイルの役割

### PROJECT.md（commit する）

**役割**: このプロジェクトの「憲法」

- このプロジェクトは何を作るのか
- 何を成功とみなすのか
- 絶対に守る制約は何か
- プロジェクトとして「やらないこと」

→ **将来の自分や、AI エージェントが読んでもブレない内容だけを書く**

#### PROJECT.md に書く項目

- **Intent / North Star**: プロジェクトの狙い・目指す姿
- **Success Criteria**: 成功条件（客観的な基準）
- **Guardrails**: 守るべき制約
- **Project-level Non-goals**: プロジェクト全体でやらないこと
- **Technical Stack**: 使用する技術スタック
- **Project History**: 重要な意思決定の履歴

**テンプレート**: [references/templates/PROJECT.md](templates/PROJECT.md)

---

### BRIEF.md（gitignore する）

**役割**: この worktree における「今の進め方メモ」

- 一時的な判断
- 仮説や賭け
- 捨てた選択肢
- この枝だけの制約

→ **思考の RAM。PR や履歴に残すことを目的としない**

#### BRIEF.md に書く項目（最小セット）

- **Parent Project**: プロジェクト名
- **Why this worktree exists**: この枝の目的
- **Mode**: 探索 / 収束 / 保守
- **Focus**: いま注目している軸
- **Non-goals**: この枝ではやらないこと
- **Next Bet**: 次に試して意思決定する一手
- **Exit / Merge criteria**: いつ終わるか
- **Decisions Log**: この worktree での意思決定履歴
- **Discarded Options**: 捨てた選択肢

**テンプレート**: [references/templates/BRIEF.md](templates/BRIEF.md)

---

## セットアップ手順

### 1. プロジェクト全体のセットアップ

プロジェクトルートで PROJECT.md を作成:

```bash
# スクリプトを使用する場合
bash .claude/skills/plan-parallel-dev/scripts/init-project-intent.sh

# または手動でテンプレートをコピー
cp .claude/skills/plan-parallel-dev/references/templates/PROJECT.md ./PROJECT.md
# エディタで編集
```

### 2. gitignore の設定

`.gitignore` に以下を追加:

```gitignore
# Worktree thinking / intent
BRIEF.md
worktrees/**/BRIEF.md
```

### 3. worktree ごとの BRIEF.md 作成

各 worktree で BRIEF.md を作成:

```bash
# worktree ディレクトリに移動
cd worktrees/task-name

# スクリプトを使用する場合
bash ../../.claude/skills/plan-parallel-dev/scripts/init-brief.sh "task-name"

# または手動でテンプレートをコピー
cp ../../.claude/skills/plan-parallel-dev/references/templates/BRIEF.md ./BRIEF.md
# エディタで編集
```

---

## 日常的な運用ルール

### 作業開始時の定型プロンプト

各 worktree で作業を開始する際、**必ず以下を Claude に指示する**:

```
この worktree の BRIEF.md と、プロジェクトの PROJECT.md を読み、
Mode / Focus / Non-goals / Next Bet を最初に要約してから作業を開始してください。
```

**ポイント**:
- 「要約してから作業」を必須にする
- 読み漏れや文脈混線を防ぐための儀式として毎回行う

### BRIEF.md の更新タイミング

以下のタイミングで BRIEF.md を更新する:

1. **重要な判断をしたとき**
   - 技術選定、設計方針の決定など
   - → `Decisions Log` に記録

2. **選択肢を捨てたとき**
   - 検討したが採用しなかった方法
   - → `Discarded Options` に記録

3. **フォーカスが変わったとき**
   - 注目する軸が変化した
   - → `Focus` を更新

4. **モードが変わったとき**
   - 探索 → 収束、収束 → 保守など
   - → `Mode` を更新

5. **次の一手が明確になったとき**
   - 仮説や検証方法が決まった
   - → `Next Bet` を更新

### PROJECT.md への昇格

BRIEF.md で記録した判断のうち、**プロジェクト全体に影響する重要な決定** は PROJECT.md に昇格させる:

```bash
# BRIEF.md から重要な決定を抽出
# → PROJECT.md の "Project History / Key Decisions" に追記
# → commit する
```

---

## 効果とメリット

この運用方式により、以下の効果が期待できる:

### 1. コンテキストスイッチの高速化

worktree を切り替えても「何を考えていたか」がすぐ戻る。

### 2. 前提混同の防止

別プロジェクトの前提を混ぜる事故が減る。

### 3. AI エージェントの理解向上

Claude Code が「今の正解」を理解した状態で作業できる。

### 4. 思考の自由度向上

BRIEF.md を気軽に書き換えられる（履歴を汚さない）。

### 5. 設計判断の追跡可能性

なぜその判断をしたのかが明確に記録される。

---

## 将来拡張（参考）

この Level 1 運用は、将来的に以下へ自然に拡張できる:

- **CONTEXT.md の自動生成**: PROJECT.md + BRIEF.md を統合
- **worktree 移動時の自動ロード**: シェルスクリプトで自動読み込み
- **エージェントによる自己チェック**: Claude が自動でコンテキストを確認

まずは **「書く → 読ませる → 要約させる」** を人力で徹底する。

---

## まとめ

- 並列開発で失われるのはタスクではなく **「判断基準」**
- Project（不変）と Worktree（可変）を **分離する**
- BRIEF.md は **思考の RAM** と割り切り、gitignore
- Claude Code には毎回、**明示的に両方を読ませる**

この最小構成だけで、並列開発時の混乱は大きく減らせる。

---

## 関連ドキュメント

- [PROJECT.md テンプレート](templates/PROJECT.md)
- [BRIEF.md テンプレート](templates/BRIEF.md)
- [Worktree 運用ガイド](worktree-guide.md)
- [Quick Mode ガイド](quick-mode-guide.md)
