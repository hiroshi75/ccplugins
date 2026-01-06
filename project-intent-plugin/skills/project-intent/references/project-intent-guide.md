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

- **プロジェクトの根本方針** → `.intent/project.json`（commit する）
- **worktree ごとの一時的な進め方** → `.intent/brief.json`（gitignore する）

---

## 採用する運用方式

### 方針まとめ

- プロジェクト全体の方針は **commit する**
- worktree ごとの思考メモは **commit しない**
- Claude Code には毎回、明示的に **両方を読ませる**
- Intent は **JSON で構造化**（VS Code 拡張での高速パース対応）

### ファイル構成

```
プロジェクトルート/
├── .intent/
│   └── project.json            # プロジェクト共通・基本不変（commit）
├── worktrees/
│   ├── task-a/
│   │   └── .intent/
│   │       └── brief.json      # worktree 固有・可変（gitignore）
│   ├── task-b/
│   │   └── .intent/
│   │       └── brief.json
│   └── task-c/
│       └── .intent/
│           └── brief.json
└── .gitignore                  # .intent/brief.json を除外
```

---

## 各ファイルの役割

### .intent/project.json（commit する）

**役割**: このプロジェクトの「憲法」

- このプロジェクトは何を作るのか
- 何を成功とみなすのか
- 絶対に守る制約は何か
- プロジェクトとして「やらないこと」

→ **将来の自分や、AI エージェントが読んでもブレない内容だけを記述する**

#### project.json の JSON キー

| キー | 型 | 説明 |
|------|------|------|
| `intent` | string | プロジェクトの狙い・目指す姿（1〜2文） |
| `successCriteria` | string[] | 成功条件（客観的な基準） |
| `guardrails` | string[] | 守るべき制約 |
| `nonGoals` | string[] | プロジェクト全体でやらないこと |
| `technicalStack` | object | 使用する技術スタック |
| `keyDecisions` | object[] | 重要な意思決定の履歴 |

**📌 重要**: JSON には判断の骨格のみを記述する。長文説明は別途 `notes.md` に記載。

**テンプレート**: [references/templates/project.json](templates/project.json)

---

### .intent/brief.json（gitignore する）

**役割**: この worktree における「今の進め方メモ」

- 一時的な判断
- 仮説や賭け
- 捨てた選択肢
- この枝だけの制約

→ **思考の RAM。PR や履歴に残すことを目的としない**

#### brief.json の JSON キー（必須）

| キー | 型 | 説明 |
|------|------|------|
| `parentProject` | string | プロジェクト名 |
| `purpose` | string | この枝の目的（1〜2文） |
| `mode` | enum | `explore` / `converge` / `maintain` |
| `focus` | string[] | いま注目している軸 |
| `nonGoals` | string[] | この枝ではやらないこと |
| `nextBet` | string | 次に試して意思決定する一手 |
| `exitCriteria` | string[] | いつ終わるか |

#### brief.json の JSON キー（オプション）

| キー | 型 | 説明 |
|------|------|------|
| `decisionsLog` | object[] | この worktree での意思決定履歴 |
| `discardedOptions` | object[] | 捨てた選択肢 |
| `notes` | string[] | メモ・気づき |

**📌 重要**: `mode` は以下のいずれかを使用:
- `explore`: 複数の選択肢を試行錯誤している段階
- `converge`: 方向性が決まり、実装を詰めている段階
- `maintain`: 既存機能の修正・改善

**テンプレート**: [references/templates/brief.json](templates/brief.json)

---

## セットアップ手順

### 1. プロジェクト全体のセットアップ

プロジェクトルートで `.intent/project.json` を作成:

```bash
# ディレクトリ作成
mkdir -p .intent

# スクリプトを使用する場合
bash .claude/skills/plan-parallel-dev/scripts/init-project-intent.sh

# または手動でテンプレートをコピー
cp .claude/skills/plan-parallel-dev/references/templates/project.json .intent/project.json
# エディタで編集
```

### 2. gitignore の設定

`.gitignore` に以下を追加:

```gitignore
# Worktree thinking / intent
.intent/brief.json
worktrees/**/.intent/brief.json
```

### 3. worktree ごとの brief.json 作成

各 worktree で `.intent/brief.json` を作成:

```bash
# worktree ディレクトリに移動
cd worktrees/task-name

# ディレクトリ作成
mkdir -p .intent

# スクリプトを使用する場合
bash ../../.claude/skills/plan-parallel-dev/scripts/init-brief.sh "task-name"

# または手動でテンプレートをコピー
cp ../../.claude/skills/plan-parallel-dev/references/templates/brief.json .intent/brief.json
# エディタで編集
```

---

## 日常的な運用ルール

### 作業開始時の定型プロンプト

各 worktree で作業を開始する際、**必ず以下を Claude に指示する**:

```
この worktree の .intent/brief.json と、プロジェクトの .intent/project.json を読み、
mode / focus / nonGoals / nextBet を最初に要約してから作業を開始してください。
```

**ポイント**:
- 「要約してから作業」を必須にする
- 読み漏れや文脈混線を防ぐための儀式として毎回行う
- Claude Code は JSON を直接パースして理解する

### brief.json の更新タイミング

以下のタイミングで `.intent/brief.json` を更新する:

1. **重要な判断をしたとき**
   - 技術選定、設計方針の決定など
   - → `decisionsLog` 配列に追加

2. **選択肢を捨てたとき**
   - 検討したが採用しなかった方法
   - → `discardedOptions` 配列に追加

3. **フォーカスが変わったとき**
   - 注目する軸が変化した
   - → `focus` 配列を更新

4. **モードが変わったとき**
   - 探索 → 収束、収束 → 保守など
   - → `mode` の値を更新

5. **次の一手が明確になったとき**
   - 仮説や検証方法が決まった
   - → `nextBet` を更新

### project.json への昇格

`.intent/brief.json` で記録した判断のうち、**プロジェクト全体に影響する重要な決定** は `.intent/project.json` に昇格させる:

```bash
# brief.json から重要な決定を抽出
# → project.json の "keyDecisions" 配列に追記
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

Claude Code が JSON を直接パースし、「今の正解」を正確に理解した状態で作業できる。

### 4. 思考の自由度向上

brief.json を気軽に書き換えられる（履歴を汚さない）。

### 5. 設計判断の追跡可能性

なぜその判断をしたのかが明確に記録される。

### 6. VS Code 拡張との連携

JSON 形式により、Intent Board UI での高速・安全なパースが可能。

---

## 将来拡張（参考）

この Level 1 運用は、将来的に以下へ自然に拡張できる:

- **CONTEXT.json の自動生成**: project.json + brief.json を統合
- **worktree 移動時の自動ロード**: シェルスクリプトで自動読み込み
- **エージェントによる自己チェック**: Claude が自動でコンテキストを確認
- **Intent Board UI**: VS Code 拡張での視覚的な Intent 管理

まずは **「JSON で書く → Claude に読ませる → 要約させる」** を人力で徹底する。

---

## まとめ

- 並列開発で失われるのはタスクではなく **「判断基準」**
- Project（不変）と Worktree（可変）を **分離する**
- Intent は **JSON で構造化**（VS Code 拡張でのパース対応）
- brief.json は **思考の RAM** と割り切り、gitignore
- Claude Code には毎回、**明示的に両方を読ませる**

この最小構成だけで、並列開発時の混乱は大きく減らせる。

---

## 関連ドキュメント

- [project.json テンプレート](templates/project.json)
- [brief.json テンプレート](templates/brief.json)
