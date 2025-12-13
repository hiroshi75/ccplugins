# Issue テンプレート

作業中に問題が発生して継続できない場合に使用するテンプレート。

ファイル名: `.parallel-dev/issues/{branch-name}.md`

---

## テンプレート

```markdown
# Issue: {branch-name}

## 基本情報

| 項目 | 内容 |
|------|------|
| 発生日時 | YYYY-MM-DD HH:MM |
| タスク | {branch-name} |
| worktree | `worktree/{branch-name}/` |
| 報告者 | {agent-name} |
| 担当 | （マージ担当が割り当てる） |
| ステータス | 未対応 / 対応中 / 解決済 |

---

## 状況

（以下から該当するものを選択）

- [ ] ビルドエラー
- [ ] テスト失敗
- [ ] 依存タスクの問題
- [ ] コンフリクト解決不能
- [ ] 仕様の不明点
- [ ] 環境問題（secrets、接続など）
- [ ] その他

---

## エラー内容

```
（エラーメッセージ、スタックトレースなどをここに貼り付け）
```

---

## 影響範囲

### このタスク

- {branch-name}: {現在の状態、どこまで完了しているか}

### 依存しているタスク

| タスク | 影響 |
|--------|------|
| {dependent-task} | {このissueによる影響} |

### 依存されているタスク

| タスク | 影響 |
|--------|------|
| {blocking-task} | {このタスクが完了しないことによる影響} |

---

## 試した対応

1. {試した対応1}
   - 結果: {成功/失敗/部分的に解決}

2. {試した対応2}
   - 結果: {成功/失敗/部分的に解決}

---

## 必要な対応

- [ ] 他タスクとの調整が必要
- [ ] 新しいブランチ/worktree が必要
- [ ] 仕様の確認・変更が必要
- [ ] 人間のエスカレーションが必要
- [ ] その他: {詳細}

### 対応案

{可能であれば、解決案を記載}

---

## マージ担当の対応記録

### 担当割り当て

- 割り当て日時:
- 割り当て先:

### 対応内容

{マージ担当が対応内容を記録}

### 新規タスク作成（該当する場合）

- [ ] `.parallel-dev/README.md` を更新
- [ ] `.parallel-dev/merge-coordinator.md` を更新
- [ ] `.parallel-dev/tasks/{new-task}.md` を作成
- [ ] `worktree/{new-task}/` を作成

### 解決

- 解決日時:
- 解決方法:
```

---

## 状況別の記入例

### ビルドエラーの例

```markdown
## 状況
- [x] ビルドエラー

## エラー内容
```
src/services/recommendation.py:45: error: Module "external_api" has no attribute "RecommendationClient"
```

## 試した対応
1. external_api パッケージのバージョンを確認
   - 結果: バージョンは正しい (1.2.0)
2. 型定義ファイルを確認
   - 結果: RecommendationClient は v1.3.0 で追加された

## 必要な対応
- [x] 他タスクとの調整が必要

### 対応案
external_api を 1.3.0 にアップグレードする必要がある。
他のタスクへの影響を確認してからアップグレードを実施したい。
```

### 依存タスクの問題の例

```markdown
## 状況
- [x] 依存タスクの問題

## エラー内容
```
recommendation-api の API レスポンス形式が設計書と異なる。
期待: { "items": [...] }
実際: { "recommendations": [...] }
```

## 影響範囲
### 依存されているタスク
| タスク | 影響 |
|--------|------|
| project-card-enhance | recommendation-api のレスポンスを使用 |

## 試した対応
1. recommendation-api の .done ファイルを確認
   - 結果: 仕様変更の記載なし

## 必要な対応
- [x] 仕様の確認・変更が必要

### 対応案
1. recommendation-api 側でレスポンス形式を修正
2. または project-card-enhance 側で新しい形式に対応

マージ担当の判断を仰ぐ。
```

### コンフリクト解決不能の例

```markdown
## 状況
- [x] コンフリクト解決不能

## エラー内容
```
CONFLICT (content): Merge conflict in src/components/shared/Card.tsx
Auto-merging failed; fix conflicts and then commit the result.
```

コンフリクト箇所:
- `src/components/shared/Card.tsx` の lines 45-78
- notification-api と project-card-enhance の両方が Card コンポーネントを大幅に変更

## 試した対応
1. 両方の変更を取り込もうとした
   - 結果: ロジックが矛盾するため単純なマージ不可

## 必要な対応
- [x] 他タスクとの調整が必要

### 対応案
1. Card コンポーネントを分離（NotificationCard, ProjectCard）
2. または共通の抽象化を設計し直す

両タスクの担当との調整が必要。
```

---

## マージ担当の対応フロー

1. **検知**: `.parallel-dev/issues/` に新しいファイルがあるか確認
2. **評価**: issue の内容を確認し、優先度を判断
3. **割り当て**: 担当を決定（既存タスクの担当 or 新規）
4. **追跡**: 必要に応じて新しいタスク/worktree を作成
5. **更新**: `.parallel-dev/` 内のファイルを更新
6. **通知**: 関係するタスクの指示書に情報を追記
7. **解決確認**: issue のステータスを「解決済」に更新
