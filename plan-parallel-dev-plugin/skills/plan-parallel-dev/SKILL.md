---
name: plan-parallel-dev
description: 複数開発者での並列開発計画書を作成するスキル。git worktree を活用したブランチ戦略、タスクの依存関係分析、クリティカルパス計算、開発者ロール割り当て、タイムライン作成を行う。「並列開発計画を作って」「複数人で同時開発したい」「worktree で分担したい」「開発を最大限並列化したい」などのリクエスト時に使用。
---

# Parallel Development Planning

機能開発を複数開発者で最大限並列化するための実装計画書を作成する。

## Workflow

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
   └─→ 必要なエージェント数を算出
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
       └─→ tasks/*.md (各タスク用)
   └─→ Claude Code 起動手順をユーザーに伝える（会話で）
```

## Terminology（用語定義）

混乱を避けるため、以下の用語を統一する:

| 用語 | 説明 | 例 |
|------|------|-----|
| **タスク名** | ブランチ名と同一。作業単位の識別子 | `skill-files-api`, `recommendation-ui` |
| **担当者/ロール** | 作業者の識別子。技術領域+番号 | `BE-1`, `FE-1`, `INFRA-1` |
| **統合ブランチ** | 全タスクをマージする先のブランチ | `feature/multi-file-skills` |

**重要**: 完了報告や状態管理では**タスク名（ブランチ名）**を使う。担当者名だけでは、複数タスクを担当している場合に特定できない。

## Task Decomposition Rules

タスク分割の原則:

1. **単一責任**: 1タスク = 1機能/1コンポーネント
2. **適切な粒度**: 0.5日〜2日の作業量
3. **明確な成果物**: 各タスクにAPI/コンポーネント/ファイル等の具体的成果物
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

| 依存タイプ | 記号 | 説明 |
|-----------|------|------|
| ブロッキング | `→` | 完了必須 |
| 並行可能 | `//` | 独立して進行可 |
| 統合待ち | `↓` | マージ後に開始 |

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

| ロール | 担当ブランチ | 必要スキル |
|--------|--------------|------------|
| BE-1 | feature/xxx-api | Python, FastAPI |
| FE-1 | feature/xxx-ui | React, TypeScript |

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

worktree作成後、各ディレクトリで開発環境を準備する:

1. **依存関係インストール**: `uv sync` / `pnpm install` など
2. **secrets コピー**: プロジェクトルートの `.env` をworktreeにコピー
3. **ポート設定**: `.env.local` にworktree固有のポート番号を設定

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

AIエージェントによる並列開発では、各エージェントへの指示書を `.parallel-dev/` に配置する。

ディレクトリ構成:
```
project/
├── .parallel-dev/                    # 並列開発管理
│   ├── PLAN.md                       # 計画書（重要な参照情報）
│   ├── README.md                     # 全体概要・進捗サマリ
│   ├── merge-coordinator.md          # マージ担当エージェント用
│   ├── tasks/                        # 各タスク用指示書
│   │   ├── xxx-api.md
│   │   └── xxx-ui.md
│   ├── signals/                      # 完了通知
│   │   └── xxx-api.done
│   └── issues/                       # 問題報告
│       └── xxx-ui.md
├── worktree/
│   ├── xxx-api/
│   └── xxx-ui/
└── ...
```

各ファイルの役割:

| ファイル | 対象 | 内容 |
|----------|------|------|
| `PLAN.md` | 全員（参照用） | 計画書全体、ブランチ戦略、タイムライン |
| `README.md` | 全エージェント | 進捗サマリ、タスク一覧、依存関係図 |
| `merge-coordinator.md` | マージ担当 | マージ順序、コンフリクト対応方針 |
| `tasks/{branch}.md` | 作業エージェント | 実装仕様、依存関係、完了条件 |
| `signals/{branch}.done` | マージ担当 | 完了通知（git request-pull出力） |
| `issues/{branch}.md` | マージ担当 | 問題報告、ブロッカー |

テンプレート:
- [references/templates/parallel-dev-readme.md](references/templates/parallel-dev-readme.md)
- [references/templates/merge-coordinator.md](references/templates/merge-coordinator.md)
- [references/templates/task-instruction.md](references/templates/task-instruction.md)

## Task Completion Flow

### 役割分担

| 役割 | 作業エージェント | マージ担当 |
|------|------------------|------------|
| コード実装 | ✅ | - |
| .done ファイル作成 | ✅ | - |
| git commit | - | ✅ |
| git fetch/merge (統合ブランチ) | - | ✅ |
| テスト実行 | - | ✅ |
| git push | - | ✅ |
| 統合ブランチへのマージ | - | ✅ |

**設計思想**: 作業エージェントはコードを書くことに集中。マージ順序の管理はマージ担当のみが把握。

### 作業エージェントの完了フロー

1. コード実装を完了
2. `.done` ファイルを作成（コミット前に！）
3. 作業終了を報告

```bash
# 作業完了時（コミットはしない）
cat > ../../.parallel-dev/signals/{branch-name}.done << 'EOF'
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

# 4. コンフリクトがあれば解決（または作業エージェントに依頼）

# 5. テスト実行
{test-command}

# 6. テスト失敗時 → 作業エージェントに修正依頼して終了

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

問題発生時は `.parallel-dev/issues/{branch-name}.md` に記録:
- エラー内容、影響範囲、試した対応を記載
- マージ担当が担当を割り当て、必要に応じて新規worktree/ブランチを作成

テンプレート: [references/templates/issue-template.md](references/templates/issue-template.md)

## Phased Task Design

依存関係のあるタスク（特にFE↔BE連携）では、Phaseを明確に分離する:

### Phase分離のパターン

**例: フロントエンドがバックエンドAPIに依存する場合**

```markdown
## Phase 1: UI実装（API完成前）
- [ ] モックAPIでUI完成
- [ ] .done ファイル作成 → マージ担当がコミット・マージ

## Phase 2: API統合（依存API完成後）
- [ ] マージ担当から通知を受けたら開始
- [ ] モックAPIを本番APIに置換
- [ ] .done ファイル作成 → マージ担当がコミット・マージ
```

### Phaseを使う判断基準

以下の場合はPhase分離を検討:
- 依存タスクの完了を待つ間に、部分的に作業を進められる
- モック/スタブを使った先行開発が可能
- 統合作業が明確に分離できる

## Dependency Completion Notification

マージ担当は、依存タスクをマージした後、依存元タスクに通知する:

```
【依存タスク完了通知】{dependency-branch}

マージ完了: feature/{dependency-branch}
統合ブランチ: feature/{integration-branch}

依存していたタスク:
- feature/{dependent-branch}: Phase 2 開始可能

作業エージェントは Phase 2 の実装を開始してください。
（統合ブランチの取り込みはマージ担当が行います）
```

## Timeline Visualization

ユーザーにタイムラインを伝える際は、ASCIIアート形式で視覚的に示す:

```
Day 1                Day 2                Day 3
────────────────────────────────────────────────
BE-1  ████████████████████████████  レビュー
      BE-01: API実装 (2日)           ↓完了

FE-1  ████████████████  ████████████████████████
      FE-01: UI (1日)    FE-02: 統合 (1日)
                         ↑ BE-01完了後
```

## Output Template

### 計画書（ユーザーに伝える + ファイル保存）

計画書の内容はユーザーに直接伝えつつ、`.parallel-dev/PLAN.md` にも保存する。
構成の参考: [references/parallel-dev-template.md](references/parallel-dev-template.md)

主要セクション:
1. 概要・目標
2. エージェント/ロール定義
3. ブランチ戦略
4. 作業一覧（タスク名・担当者付き）
5. 並行開発タイムライン
6. 依存関係マトリクス
7. マージ順序
8. 各タスク詳細仕様
9. 完了定義 (Definition of Done)
10. リスク管理

### エージェント指示書（ファイルに作成）

計画書とは別に、エージェント向けの指示書を `.parallel-dev/` にファイルとして作成:

| テンプレート | 出力先 | 用途 |
|-------------|--------|------|
| [parallel-dev-readme.md](references/templates/parallel-dev-readme.md) | `.parallel-dev/README.md` | 全体進捗管理 |
| [merge-coordinator.md](references/templates/merge-coordinator.md) | `.parallel-dev/merge-coordinator.md` | マージ担当用 |
| [task-instruction.md](references/templates/task-instruction.md) | `.parallel-dev/tasks/*.md` | 各タスク用 |

### Claude Code 起動手順を教える

計画書作成後、ユーザーに以下を直接伝える（ファイルではなく会話で）:

```
## マージ担当エージェントを起動

プロジェクトルートで:
claude

初期指示: ".parallel-dev/merge-coordinator.md を読んで並列開発を開始して"
```

**注意**: 作業エージェントはマージ担当がサブエージェントとして起動する。人間が個別に起動する必要はない。

## Rules（全エージェント共通）

### 作業エージェントのルール

- **コミットしない**: コードを書くだけ。コミットはマージ担当が行う
- **プッシュしない**: リモートへのプッシュもマージ担当が行う
- **.done ファイルで完了報告**: 実装内容と変更ファイルを記載
- **依存タスクが未完了なら待機**: マージ担当からの通知を待つ
- **UI仕様は人間の承認必須**: UIの見た目・動作の決定は勝手に行わない。issues/ に確認依頼を出し、人間の承認を得てから実装する（詳細は「UI Specification Approval」セクション参照）

### マージ担当のルール

- **作業エージェントをサブエージェントとして起動**: Taskツールで各worktreeの作業を並列実行
- **`--no-ff` で常にマージ**（マージコミットを残す）
- **マージ順序**: 依存関係 > 変更範囲 > 完了順
- **テスト必須**: 統合ブランチマージ後、必ずテストを実行
- **テスト失敗時**: 作業エージェントに修正依頼、統合ブランチへのマージは中止
- **コンフリクト対応**: 軽微なら自分で解決、複雑なら作業エージェントに依頼
- **UI仕様確認の中継**: 作業エージェントから issues/ にUI仕様確認依頼が出されたら、AskUserQuestion ツールで人間に確認を取り、回答を作業エージェントに伝達する

### 依存関係ルール

- 依存タスクが**統合ブランチにマージされるまで**開始しない
- マージ担当が依存タスクの完了を通知するまで待機

### ポート割り当てルール

- BE: 3000 + index, FE: 5173 + index
- index 0 = プロジェクトルート、worktree は 1 から

### 状態更新の責任分担

| 更新対象 | 責任者 | タイミング |
|----------|--------|------------|
| .done ファイル | 作業エージェント | 実装完了時 |
| git commit/push | マージコーディネーター | .done 検知後 |
| タスク指示書のステータス | マージコーディネーター | マージ後「マージ済」へ |
| README.md の進捗 | マージコーディネーター | マージ後 |
| 依存元タスクへの通知 | マージコーディネーター | マージ後 |

## Asking Clarifying Questions

計画作成前に確認すべき項目:

1. **開発対象**: どの機能・改善を実装するか
2. **技術スタック**: BE/FE/インフラの技術選定
3. **開発者数**: 最大何名で開発可能か
4. **既存資料**: PRD、設計書、改善案などの有無
5. **制約**: 期限、依存する外部要因など

## UI Specification Approval（UI仕様の人間確認）

**重要**: UIに関する仕様を決定する際は、必ず人間の確認を取ること。

### 確認が必要なUI決定事項

以下の項目は人間の承認なしに確定しない:

| カテゴリ | 確認が必要な項目 |
|----------|------------------|
| レイアウト | ページ構成、コンポーネント配置、グリッド設計 |
| デザイン | 色使い、フォント、アイコン選定、スタイリング方針 |
| インタラクション | ボタン配置、フォーム設計、ナビゲーション構造 |
| UXフロー | 画面遷移、操作手順、エラー表示方法 |
| コンポーネント | 新規UIコンポーネントの設計、既存コンポーネントの変更 |

### 確認フロー

```
1. UI仕様案の作成
   └─→ エージェントがUI仕様案を作成
   └─→ 選択肢がある場合は複数案を提示

2. 人間への確認依頼
   └─→ AskUserQuestion ツールを使用
   └─→ 仕様案を具体的に説明（ワイヤーフレーム風記述も可）
   └─→ 判断に必要な情報（トレードオフ等）を提示

3. 承認後に実装開始
   └─→ 人間の承認を得てからタスク指示書に記載
   └─→ 承認内容を .parallel-dev/PLAN.md に記録
```

### 確認依頼のテンプレート

```markdown
【UI仕様確認依頼】{機能名}

## 概要
{何のUIについての確認か}

## 提案する仕様

### 案A: {案の名前}
- レイアウト: {配置の説明}
- 動作: {インタラクションの説明}
- メリット: {利点}
- デメリット: {欠点}

### 案B: {案の名前}（必要に応じて）
...

## 判断ポイント
- {ユーザーが判断する際に考慮すべき点}

## 推奨
{エージェントの推奨案とその理由（任意）}
```

### 作業エージェントでのUI仕様確認

作業エージェントがタスク実行中にUI仕様を決める必要が生じた場合:

1. **実装を一時停止**
2. **issues/{branch-name}.md に確認依頼を記載**
3. **マージ担当経由で人間に確認**
4. **人間の回答を得てから実装再開**

```markdown
<!-- .parallel-dev/issues/{branch-name}.md -->
【UI仕様確認待ち】{branch-name}

## 状況
{branch-name} の実装中に以下のUI仕様について判断が必要になりました。

## 確認事項
{上記テンプレートに沿った確認内容}

## 現在のステータス
- 実装: 一時停止中
- 待ち: 人間からのUI仕様承認
```

### ルール

- **勝手に決めない**: UIの見た目・動作に関する決定は人間の承認が必須
- **選択肢を提示**: 単一案ではなく、可能な限り複数案を提示
- **根拠を説明**: 各案のメリット・デメリットを明確に
- **推奨は明示**: エージェントの推奨がある場合は理由とともに明示
- **承認を記録**: 人間の決定内容を PLAN.md に記録し、後から参照可能に

## Lessons Learned / Best Practices

並列開発で発生しやすい問題と対策。

### 1. サブエージェントのファイル編集権限

**問題**: サブエージェントがファイル編集ツール（Edit/Write）を使用できない場合がある。

**対策**:
- タスク指示書に「権限問題が発生した場合は、実装コードを .done ファイルに出力する」と明記
- マージコーディネーターが直接コードを適用する代替フローを用意
- サブエージェント起動時のプロンプトに「ファイル編集が可能」と明示

### 2. worktree とブランチの履歴分岐

**問題**: 複数の worktree で作業中に統合ブランチが更新され、マージ時に履歴が分岐する。

**対策**:
- **コミット前に必ず統合ブランチの最新を取り込む**（fetch + merge/rebase）
- worktree 内でのコミット後、プッシュ前に再度統合ブランチをマージ
- マージコーディネーターが一元的にマージ順序を管理し、履歴の一貫性を保つ

```bash
# worktree でのコミット前チェック
git fetch origin
git merge origin/feature/{integration-branch} --no-ff
# コンフリクトがあれば解決してからコミット
```

### 3. 統合ブランチの初期化

**問題**: 統合ブランチがリモートに未プッシュだと、worktree から `origin/feature/{integration}` を参照できない。

**対策**:
- **並列開発開始時に統合ブランチをリモートにプッシュ**
- merge-coordinator.md の初期セットアップ手順に明記

```bash
# 統合ブランチ作成後、すぐにプッシュ
git checkout -b feature/integration main
git push -u origin feature/integration
```

### 4. タスク指示書の精度

**問題**: 指示書で参照しているファイルが存在しない、または実装状況が異なる。

**対策**:
- **タスク指示書作成時にファイル存在確認を必須化**
- 「参考資料」セクションにファイルパスだけでなく、現在の実装状況も記載
- 指示書作成前にコードベースを探索し、実際の構造を把握

```markdown
## 参考資料

- 既存実装: `src/components/xxx.tsx`（現在のコンポーネント名: YyyComponent）
- API: `backend/server.py` の `zzz_endpoint` 関数を参考に
```

### 5. 完了通知フローの明確化

**問題**: .done ファイルと TaskOutput の使い分けが曖昧。

**対策**:
- **TaskOutput**: サブエージェントの完了検知に使用（主要な完了判定）
- **.done ファイル**: 実装内容の詳細記録、マージ後の履歴として保持
- マージコーディネーターは両方を確認し、整合性を検証

### 6. 並列度の最適化

**問題**: 依存関係を厳密に守りすぎて、並列性が低下する。

**対策**:
- **依存関係のない部分は可能な限り同時に開始**
- BE/FE 連携でも、FE のコンポーネント設計・スタイリングは BE 完了前に開始可能
- タスク分解時に「先行可能な作業」と「依存待ちの作業」を明確に分離

```
例: FE タスクの分解
- Phase 1（BE 完了前に開始可能）: UI コンポーネント作成、スタイリング、モック接続
- Phase 2（BE 完了後）: 本番 API 接続、エラーハンドリング調整
```

### 7. マージコーディネーターの単一責任

**問題**: マージコーディネーターが実装作業まで行うと、並列性のメリットが失われる。

**対策**:
- マージコーディネーターは**調整・マージ・テストに専念**
- 実装はサブエージェントに委譲（権限問題がある場合のみ例外的に対応）
- 複雑な修正が必要な場合は、新たなサブエージェントを起動
