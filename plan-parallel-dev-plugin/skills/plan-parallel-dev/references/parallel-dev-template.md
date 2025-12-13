# 並列開発計画書テンプレート

このテンプレートを参考に計画書を作成する。プロジェクトに応じてセクションを追加・削除して使用。

---

## テンプレート

```markdown
# [機能名] 実装計画書

## 概要

本文書は [対象文書/機能] を複数開発者で並行開発するための作業分担表。

**目標**: 最大限の並行開発を実現し、開発期間を短縮する

---

## 開発者ロール定義（N名体制）

最適化の結果、**N名**で待ち時間を最小化しつつ効率的に開発できる。

| ロール | 担当ブランチ | 必要スキル |
|--------|--------------|------------|
| **BE-1** | feature/xxx-api | Python, FastAPI, ... |
| **FE-1** | feature/xxx-ui → yyy-ui | React, TypeScript, ... |

### 人員配置の根拠

```
クリティカルパス分析:
────────────────────
最長パス: [タスクA] → [タスクB] → [タスクC] (X日)

ボトルネック:
- [ボトルネックの説明]
- [解消方法]

待ち時間の発生パターン:
- [担当]: [待機発生条件と対応]
```

---

## ブランチ戦略

```
main
├── feature/[統合ブランチ名] (統合ブランチ)
│   │
│   ├── feature/xxx-api       [BE-1]
│   ├── feature/yyy-api       [BE-2]
│   │
│   ├── feature/xxx-ui        [FE-1]
│   └── feature/yyy-ui        [FE-1] ← BE-1完了後
```

---

## 作業一覧（タスク名・担当者付き）

### バックエンド作業

| ブランチ | タスク名 | 担当 | 依存 | 成果物 |
|----------|----------|------|------|--------|
| feature/recommendation-api | レコメンドAPI実装 | BE-1 | なし | `GET /api/v1/recommendations` |
| feature/notification-api | 通知API実装 | BE-1 | なし | `POST /api/v1/notifications` |

### フロントエンド作業

| ブランチ | タスク名 | 担当 | 依存 | 成果物 |
|----------|----------|------|------|--------|
| feature/project-card-enhance | カード機能強化 | FE-1 | recommendation-api | ProjectCard拡張 |
| feature/search-filter | 検索フィルタ | FE-1 | なし | SearchFilter |

---

## 並行開発タイムライン（N名体制・X日間）

```
Day 1                    Day 2                    Day 3
────────────────────────────────────────────────────────────

BE-1  ████████████████████████████████████████████  レビュー
      recommendation-api                            ↓完了

FE-1  ████████████████████████████████████████████  ████████████████████████
      search-filter                                 project-card-enhance
                                                    ↑ recommendation-api 完了後
```

### 各担当者の詳細スケジュール

| 担当 | Day 1 | Day 2 | Day 3 |
|------|-------|-------|-------|
| BE-1 | recommendation-api | 完了 | レビュー |
| FE-1 | search-filter | 完了 | project-card-enhance |

---

## 依存関係マトリクス

### 開始可能条件

| ブランチ | 開始条件 | 担当 |
|----------|----------|------|
| recommendation-api, search-filter | **即時開始可能** | BE-1, FE-1 |
| project-card-enhance | recommendation-api 完了後 | FE-1 |

### ブロッキング関係図

```
                         Day 1           Day 2           Day 3
                         ─────           ─────           ─────
BE-1  ═══════════════════════════════════╗
      recommendation-api                  ║
                                         ╚════════════════════► project-card-enhance (FE-1)

FE-1  ═══════════════════════════════════╗
      search-filter                       ║
                                         ╚════════════════════► project-card-enhance
```

---

## マージ順序

統合ブランチへのマージ順序：

### Phase 1: 独立タスク（並行マージ可能）
```
1. feature/recommendation-api [BE-1]
2. feature/search-filter [FE-1]
```

### Phase 2: 依存タスク
```
3. feature/project-card-enhance [FE-1] ← recommendation-api マージ後
```

---

## 各タスク詳細仕様

### recommendation-api

**エンドポイント**: `GET /api/v1/xxx`

**レスポンス**:
```typescript
interface XxxResponse {
  items: XxxItem[];
  generated_at: string;
}
```

**実装ポイント**:
- [実装時の注意点]

---

### project-card-enhance

**コンポーネント**: `ProjectCard`（拡張）

**実装ポイント**:
- recommendation-api の結果を表示
- [その他の注意点]

---

## 完了定義 (Definition of Done)

### 機能ごとの完了条件

| 機能 | 完了条件 |
|------|----------|
| レコメンド機能 | recommendation-api, project-card-enhance すべてマージ済み |

### 全体完了条件

- [ ] すべてのPRがレビュー済み・マージ済み
- [ ] 統合ブランチ → main のPR作成
- [ ] 統合テスト完了

---

## リスク管理

| リスク | 影響 | 対策 |
|--------|------|------|
| recommendation-api 遅延 | project-card-enhance がブロック | モックAPIでFE開発続行 |
| マージコンフリクト | 統合遅延 | 定期的に統合ブランチを merge |

---

## コミュニケーション

### 日次同期
- 毎日15分のスタンドアップ
- ブロッカーの早期報告

### ブランチ命名規則
```
feature/{機能名}
例: feature/recommendation-api
```

### コミットメッセージ規則
```
feat: 新機能追加
fix: バグ修正
refactor: リファクタリング
docs: ドキュメント更新
test: テスト追加・修正
```

---

**作成日**: YYYY-MM-DD
**バージョン**: 1.0
**ステータス**: 承認待ち
```

---

## セクション選択ガイド

プロジェクト規模に応じて必要なセクションを選択:

### 小規模（2-3名、1週間以内）
必須:
- 概要
- 開発者ロール定義
- 作業一覧
- 依存関係マトリクス

### 中規模（4-6名、2週間程度）
上記に加えて:
- ブランチ戦略
- タイムライン
- マージ順序
- 完了定義

### 大規模（7名以上、1ヶ月以上）
全セクション + 追加で:
- 詳細なリスク管理
- エスカレーションパス
- マイルストーン定義
