# タスク指示書テンプレート

各worktreeで作業する claude 向けの指示書テンプレート。
**この claude はマージ担当から tmux 経由で起動される。**

ファイル名: `.parallel-dev/tasks/{branch-name}.md`

---

## テンプレート

```markdown
# タスク指示書: {branch-name}

## 実行コンテキスト

このタスクはマージ担当から tmux 経由で起動される。
作業ディレクトリ: `worktree/{branch-name}/`

**環境変数 `PROJECT_ROOT`**: マージ担当が tmux 起動時に渡すプロジェクトルートへの絶対パス。
`.done` ファイルは `$PROJECT_ROOT/.parallel-dev-signals/` に、問題報告は `$PROJECT_ROOT/.parallel-dev-issues/` に作成する（worktree 内ではなく親プロジェクトに作成）。

---

## 作業開始時の必須ステップ

**重要**: 作業を開始する前に、必ず以下を実行する。

### 1. プロジェクトコンテキストの確認

```bash
# .intent/project.json と .intent/brief.json を確認（存在する場合）
cat $PROJECT_ROOT/.intent/project.json  # プロジェクト全体の方針
cat .intent/brief.json                   # この worktree の方針
```

### 2. コンテキストの要約

以下の JSON キーを確認し、要約してから作業を開始する:

**.intent/project.json から:**
- **`intent`**: プロジェクトの狙い
- **`successCriteria`**: 成功条件（配列）
- **`guardrails`**: 守るべき制約（配列）
- **`nonGoals`**: やらないこと（配列）

**.intent/brief.json から（存在する場合）:**
- **`mode`**: `explore` / `converge` / `maintain`
- **`focus`**: いま注目している軸（配列）
- **`nonGoals`**: この worktree ではやらないこと（配列）
- **`nextBet`**: 次に試す一手

**重要**: このコンテキスト確認を省略すると、プロジェクトの方針と異なる実装をしてしまう可能性がある。

---

## 基本情報

| 項目 | 内容 |
|------|------|
| ブランチ | `feature/{branch-name}` |
| worktree | `worktree/{branch-name}/` |
| ステータス | 未着手 / 進行中 / 完了 / マージ済 |
| バックエンドポート | {PORT_BE} |
| フロントエンドポート | {PORT_FE} |

---

## 実装内容

### 概要

{このタスクで実装する機能の概要を1-2文で}

### 成果物

- [ ] {成果物1: ファイルパス or エンドポイント or コンポーネント名}
- [ ] {成果物2}
- [ ] {成果物3}

### 詳細仕様

{実装の詳細仕様を記載}

#### API仕様（バックエンドの場合）

**エンドポイント**: `{METHOD} /api/v1/{path}`

**リクエスト**:
```typescript
interface RequestBody {
  // ...
}
```

**レスポンス**:
```typescript
interface Response {
  // ...
}
```

#### コンポーネント仕様（フロントエンドの場合）

**コンポーネント名**: `{ComponentName}`

**Props**:
```typescript
interface Props {
  // ...
}
```

**配置場所**: `src/components/{path}/`

---

## 依存関係

### このタスクが依存するもの

| 依存先 | 種類 | 状態 | 備考 |
|--------|------|------|------|
| feature/{branch} | API | 未完了 | {API名}が必要 |
| feature/{branch} | 型定義 | 完了 | 利用可能 |

### このタスクに依存するもの

| 依存元 | 影響 |
|--------|------|
| feature/{branch} | このタスク完了後に統合作業を開始 |

### 依存タスクが未完了の場合の対応

**重要**: 依存タスクが未完了の場合、このタスクは開始しない。

- **待機**: 依存タスクが統合ブランチにマージされるまで待機
- **モック利用**（部分的に進める場合のみ）: `src/mocks/{mock-file}` を使用
- **型定義のみ先行利用**（部分的に進める場合のみ）: `src/types/{type-file}` から import

**注意**: 依存先ブランチを直接取り込まない。必ず統合ブランチ経由で取り込む。

---

## 作業手順

### 1. 実装

1. {手順1}
2. {手順2}
3. {手順3}

**重要**: git commit / git push は**行わない**。コードを書くことに集中する。

### 2. 開発サーバー起動

`.env.local` に設定されたポートを使用する:

```bash
# バックエンド（例: FastAPI/Uvicorn）
uvicorn main:app --port $PORT

# フロントエンド（例: Vite）
pnpm dev
```

### 3. 動作確認

ローカルで動作確認を行う。テストコマンドがあれば実行:

```bash
{test-command}
```

### 4. 完了通知（.done ファイル作成）

実装が完了したら、マージ担当に通知する。**コミットは不要**。

```bash
# .done ファイルを作成
# PROJECT_ROOT は tmux 起動時にマージ担当から渡される環境変数
cat > $PROJECT_ROOT/.parallel-dev-signals/{branch-name}.done << 'EOF'
【完了報告】{branch-name}

## 実装内容
- {実装した機能の説明}
- {変更したファイル一覧}

## 動作確認
ローカルでの動作確認: OK / NG

## 備考
{その他の情報}
EOF
```

### 5. セッション終了

.done ファイル作成後、この claude の作業は完了。セッションを終了する。

マージ担当が .done を検知し、コミット・マージ・テストを行う。

### 6. エラー・ブロック時

問題が発生した場合は `$PROJECT_ROOT/.parallel-dev-issues/{branch-name}.md` に記録。

---

## ファイル編集のベストプラクティス

### 編集前の確認事項

1. **ファイル存在確認**: 編集する前に、対象ファイルが実際に存在することを確認する
2. **既存コードの確認**: 参照する関数・型・コンポーネントが実装済みかを確認する
3. **インポートパスの確認**: 相対パスが正しいことを確認する

```bash
# ファイル存在確認の例
ls -la src/components/target/
head -20 src/lib/api.ts  # 既存関数の確認
```

---

## Phase分離（オプション：並列性を最大化する場合のみ）

**通常**: 依存タスクは依存先がマージされてから起動されるため、Phase 分離は不要。

**Phase 分離を使う場合**: タスク指示書に明記されている場合のみ。

### Phase 1: 先行実装（依存API完成前）

- [ ] モックAPIで機能実装
- [ ] ローカルで動作確認
- [ ] Phase 1 完了時に `.done` ファイル作成（`{branch-name}-phase1.done`）
- [ ] セッション終了

### Phase 2: 統合（依存API完成後）

依存先がマージされると、マージ担当が再度 tmux でこの claude を起動する。

- [ ] モックを本番APIに置換
- [ ] ローカルで動作確認
- [ ] Phase 2 完了時に `.done` ファイル作成（`{branch-name}.done`）
- [ ] セッション終了

---

## 完了条件

- [ ] すべての成果物が実装されている
- [ ] ローカルで動作確認済み
- [ ] `$PROJECT_ROOT/.parallel-dev-signals/{branch-name}.done` を作成済み

---

## ルール

- **コミットしない**: コードを書くだけ。コミットはマージ担当が行う
- **プッシュしない**: リモートへのプッシュもマージ担当が行う
- **依存タスクが未完了なら待機**: マージ担当からの通知を待つ
- **ファイル編集前に存在確認**: 編集対象ファイルが存在することを確認する

---

## 注意事項

- {プロジェクト固有の注意点}
- {コーディング規約への参照}
- {他タスクとの調整が必要な点}

---

## 参考資料

- 設計書: {link}
- 関連PR: {link}
- 類似実装: `src/{path}`
```

---

## 記入ガイド

### ステータスの遷移

```
未着手 → 進行中 → 完了 → マージ済
```

### 依存関係の書き方

**依存の種類:**
- `API`: エンドポイントの実装に依存
- `型定義`: TypeScript型に依存
- `コンポーネント`: UIコンポーネントに依存
- `データ`: DBスキーマやマイグレーションに依存

### 成果物の粒度

具体的に記載する:
- ❌ 「APIを実装」
- ✅ 「`GET /api/v1/recommendations` エンドポイント」

- ❌ 「コンポーネントを作成」
- ✅ 「`RecommendationCard` コンポーネント（`src/components/recommendations/`）」

### 参考資料の精度

タスク指示書作成時にファイル存在を確認し、現在の実装状況も記載する:
- ❌ `src/components/xxx.tsx` を参考に
- ✅ `src/components/xxx.tsx`（現在のコンポーネント名: YyyComponent、props: id, name）
