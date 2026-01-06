---
name: project-intent
description: プロジェクトの意図・方針を JSON 形式で構造化管理するスキル。AI エージェントとのコンテキスト共有を最適化し、並列開発やコンテキストスイッチ時の混乱を防ぐ。セッションの開始、終了前、ユーザー入力で開発の方向性・局面が変わった時点、一定量のタスクを終えた時点、「プロジェクトの Intent を設定して」「project.json を作成して」「brief.json を更新して」などのリクエスト時に使用。
---

# Project Intent Management

プロジェクトや worktree の意図・方針を JSON 形式で構造化管理し、AI エージェントとのコンテキスト共有を最適化する。

## 解決する課題

Claude Code を使って開発を進める際、以下の問題が発生しやすい：

- **コンテキストの喪失**: どのプロジェクトで、どんな判断基準で進めていたか分からなくなる
- **前提の混同**: 別プロジェクトや別 worktree の前提を混ぜてしまう
- **設計判断の忘却**: 「なぜその設計判断をしたのか」を思い出すコストが高い
- **意図の復元困難**: Issue / Task を見ても、上位の意図（方向性）が復元できない

これらは **「何を正しいとみなしていたか」** という上位コンテキストが失われることが原因である。

## 基本概念

### 管理するのは「作業」ではなく「姿勢」

Issue や Task は「何をするか」を管理するが、失われやすいのは以下の情報：

- いまは探索なのか、収束なのか
- 何を優先し、何を捨てると決めていたか
- 判断に迷ったときの基準
- 次に意思決定するための一手（仮説・賭け）

### 2 層構造

| ファイル               | 役割                    | commit    | 更新頻度 |
| ---------------------- | ----------------------- | --------- | -------- |
| `.intent/project.json` | プロジェクト全体の憲法  | ✅ する   | 基本不変 |
| `.intent/brief.json`   | worktree ごとの思考メモ | ❌ しない | 随時     |

---

## ファイル仕様

### .intent/project.json（プロジェクト憲法）

プロジェクト全体で共有される不変的な方針を JSON で記述する。

#### JSON キー（必須）

| キー            | 型        | 説明                                          |
| --------------- | --------- | --------------------------------------------- |
| `schemaVersion` | string    | スキーマバージョン（例: "1.0"）               |
| `type`          | "project" | 固定値                                        |
| `id`            | string    | プロジェクトの一意識別子                      |
| `name`          | string    | プロジェクト名                                |
| `intent`        | string    | プロジェクトの狙い・目指す姿（最大 200 文字） |

#### JSON キー（オプション）

| キー              | 型       | 説明                                 |
| ----------------- | -------- | ------------------------------------ |
| `summary`         | string   | 短い要約（最大 120 文字、UI 表示用） |
| `successCriteria` | string[] | 成功条件（客観的な基準）             |
| `guardrails`      | string[] | 守るべき制約                         |
| `nonGoals`        | string[] | プロジェクト全体でやらないこと       |
| `technicalStack`  | string[] | 使用する技術スタック                 |
| `keyDecisions`    | object[] | 重要な意思決定の履歴（date, text）   |

#### 例

```json
{
  "schemaVersion": "1.0",
  "type": "project",
  "id": "proj-parallel-dev-001",
  "name": "Parallel Development Platform",
  "intent": "複数の Claude が同時並行で開発タスクを進行できる環境を提供し、開発速度を最大化しながらコンフリクトを最小化する。",
  "summary": "並列開発環境の構築",
  "successCriteria": [
    "3つ以上のタスクを同時並行で進行できる",
    "タスク間のコンフリクト率が 10% 以下"
  ],
  "guardrails": [
    "マージ前に必ずテストを実行する",
    "全タスクで同じコーディング規約を使用する"
  ],
  "nonGoals": ["リアルタイム協調編集機能は提供しない", "IDE 統合は対象外"],
  "technicalStack": ["Python 3.11+", "FastAPI"],
  "keyDecisions": [
    {
      "date": "2024-01-15",
      "text": "worktree ベースの並列開発方式を採用（コンフリクト最小化のため）"
    }
  ]
}
```

**テンプレート**: [references/templates/project.json](references/templates/project.json)

---

### .intent/brief.json（worktree 思考メモ）

各 worktree の一時的な作業方針を JSON で記述する。

#### JSON キー（必須）

| キー            | 型         | 説明                                |
| --------------- | ---------- | ----------------------------------- |
| `schemaVersion` | string     | スキーマバージョン（例: "1.0"）     |
| `type`          | "worktree" | 固定値                              |
| `projectId`     | string     | 親プロジェクトの ID                 |
| `mode`          | enum       | `explore` / `converge` / `maintain` |

#### JSON キー（オプション）

| キー               | 型       | 説明                                         |
| ------------------ | -------- | -------------------------------------------- |
| `worktree`         | object   | worktree 情報（name, branch）                |
| `purpose`          | string   | この枝の目的（最大 200 文字）                |
| `statusLine`       | string   | 現在の状況（最大 120 文字、UI 表示用）       |
| `focus`            | string[] | いま注目している軸                           |
| `nonGoals`         | string[] | この枝ではやらないこと                       |
| `nextBet`          | string   | 次に試して意思決定する一手                   |
| `exitCriteria`     | string[] | いつ終わるか                                 |
| `decisionsLog`     | object[] | この worktree での意思決定履歴（date, text） |
| `discardedOptions` | string[] | 捨てた選択肢                                 |
| `notes`            | string   | メモ・気づき                                 |
| `updatedAt`        | string   | 最終更新日時（ISO 8601 形式）                |

#### Mode の定義

| 値         | 説明                                 |
| ---------- | ------------------------------------ |
| `explore`  | 複数の選択肢を試行錯誤している段階   |
| `converge` | 方向性が決まり、実装を詰めている段階 |
| `maintain` | 既存機能の修正・改善                 |

**テンプレート**: [references/templates/brief.json](references/templates/brief.json)

---

## セットアップ手順

### 1. プロジェクト全体のセットアップ

```bash
# .intent ディレクトリを作成
mkdir -p .intent

# スクリプトを使用
bash scripts/init-project-intent.sh

# または手動でテンプレートをコピー
cp templates/project.json .intent/project.json
```

### 2. .gitignore の設定

```gitignore
# Worktree thinking / intent
.intent/brief.json
worktrees/**/.intent/brief.json
```

### 3. worktree ごとの brief.json 作成

```bash
cd worktrees/task-name
mkdir -p .intent

# スクリプトを使用
bash ../../scripts/init-brief.sh "task-name"

# または手動でテンプレートをコピー
cp ../../templates/brief.json .intent/brief.json
```

---

## 日常的な運用

### 作業開始時のルーティン

各 worktree で作業を開始する際、**必ず以下を Claude に指示する**：

```
この worktree の .intent/brief.json と、プロジェクトの .intent/project.json を読み、
mode / focus / nonGoals / nextBet を最初に要約してから作業を開始してください。
```

または、スクリプトを使用：

```bash
bash scripts/load-context.sh
```

### brief.json の更新タイミング

1. **重要な判断をしたとき** → `decisionsLog` に追加
2. **選択肢を捨てたとき** → `discardedOptions` に追加
3. **フォーカスが変わったとき** → `focus` を更新
4. **モードが変わったとき** → `mode` を更新
5. **次の一手が明確になったとき** → `nextBet` を更新

### project.json への昇格

brief.json で記録した判断のうち、プロジェクト全体に影響する重要な決定は project.json に昇格させる：

```bash
# brief.json から重要な決定を抽出
# → project.json の "keyDecisions" に追記
# → commit する
```

---

## 効果

1. **コンテキストスイッチの高速化**: worktree を切り替えても「何を考えていたか」がすぐ戻る
2. **前提混同の防止**: 別プロジェクトの前提を混ぜる事故が減る
3. **AI エージェントの理解向上**: Claude が JSON を直接パースし、正確に理解できる
4. **思考の自由度向上**: brief.json を気軽に書き換えられる（履歴を汚さない）
5. **設計判断の追跡可能性**: なぜその判断をしたのかが明確に記録される
6. **VS Code 拡張との連携**: JSON 形式により、Intent Board UI での高速パースが可能

---

## 設計原則

### JSON には判断の骨格のみ

- 1〜2 文で表現できる内容のみ
- 長文説明は別途 `notes.md` に記載
- AI に曖昧な自然文解釈をさせない

### 人間と機械の責務分離

- **JSON**: 機械がパースする構造化データ
- **Markdown**: 人間が読む補足説明

---

## 関連ドキュメント

- [project.json テンプレート](references/templates/project.json)
- [brief.json テンプレート](references/templates/brief.json)
- [詳細ガイド](references/project-intent-guide.md)
