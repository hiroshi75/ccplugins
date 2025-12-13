# 並列開発 README テンプレート

`.parallel-dev/README.md` 用のテンプレート。全体の進捗管理と概要を記載。

---

## テンプレート

```markdown
# 並列開発: {機能名}

## 概要

{この並列開発で実装する機能の概要}

| 項目 | 値 |
|------|-----|
| 開始日 | YYYY-MM-DD |
| 目標完了日 | YYYY-MM-DD |
| 統合ブランチ | `feature/{integration-branch}` |
| タスク数 | {N} |
| 並列度 | 最大 {M} タスク同時進行 |

---

## 進捗サマリ

```
全体進捗: ████████░░░░░░░░ 50% (2/4 タスク完了)

Phase 1: ████████████████ 100% 完了
Phase 2: ████████░░░░░░░░  50% 進行中
```

### タスク状態一覧

| タスク | ブランチ | worktree | 状態 | 担当 |
|--------|----------|----------|------|------|
| {タスク名A} | feature/{task-a} | `worktree/{task-a}/` | ✅ マージ済 | Agent-1 |
| {タスク名B} | feature/{task-b} | `worktree/{task-b}/` | ✅ マージ済 | Agent-2 |
| {タスク名C} | feature/{task-c} | `worktree/{task-c}/` | 🔄 進行中 | Agent-3 |
| {タスク名D} | feature/{task-d} | `worktree/{task-d}/` | ⏳ 待機中 | Agent-1 |

**凡例**: ⬚ 未着手 / 🔄 進行中 / ✅ 完了・マージ済 / ⏳ 依存待ち / ❌ ブロック

---

## ディレクトリ構成

```
project/
├── .parallel-dev/              # 並列開発管理
│   ├── README.md               # このファイル
│   ├── merge-coordinator.md    # マージ担当用指示書
│   └── tasks/                  # 各タスク用指示書
│       ├── {task-a}.md
│       ├── {task-b}.md
│       ├── {task-c}.md
│       └── {task-d}.md
├── worktree/                   # worktree ディレクトリ
│   ├── {task-a}/
│   ├── {task-b}/
│   ├── {task-c}/
│   └── {task-d}/
└── ...
```

---

## 依存関係図

```
feature/{task-a}  ──────────────────────┐
                                        ↓
feature/{task-b}  ────────────────► feature/{task-d}
                                        ↑
feature/{task-c}  ──────────────────────┘
```

---

## マージ順序

```
Phase 1: 独立タスク
  1. feature/{task-a}  ✅ マージ済
  2. feature/{task-b}  ✅ マージ済
  3. feature/{task-c}  🔄 完了待ち

Phase 2: 依存タスク
  4. feature/{task-d}  ⏳ Phase 1 完了待ち
```

詳細は [merge-coordinator.md](merge-coordinator.md) 参照。

---

## 各エージェントへの指示

### 作業エージェント

1. 自分の担当タスクの指示書を確認: `.parallel-dev/tasks/{branch-name}.md`
2. 対応する worktree で作業: `worktree/{branch-name}/`
3. 完了したら指示書のステータスを更新
4. このREADMEの進捗も更新

### マージ担当エージェント

1. [merge-coordinator.md](merge-coordinator.md) の指示に従う
2. タスク完了を検知したらマージ順序に従ってマージ
3. マージ後、このREADMEと各タスク指示書を更新

---

## 更新履歴

| 日時 | 更新者 | 内容 |
|------|--------|------|
| YYYY-MM-DD HH:MM | {Agent/Human} | 初版作成 |
| YYYY-MM-DD HH:MM | Agent-1 | {task-a} 完了 |
| YYYY-MM-DD HH:MM | Merge-Coordinator | {task-a} マージ完了 |

---

## 問題・ブロッカー

現在の問題点があればここに記録:

| 発生日 | 問題 | 影響タスク | 状態 |
|--------|------|-----------|------|
| - | - | - | - |

---

## 完了条件

- [ ] すべてのタスクがマージ済み
- [ ] 統合テストがパス
- [ ] `feature/{integration-branch}` → `main` のPR作成・マージ
- [ ] worktree のクリーンアップ完了
```

---

## 記入ガイド

### 進捗の更新タイミング

- タスク着手時: 状態を「進行中」に
- タスク完了時: 状態を「完了」に
- マージ完了時: 状態を「マージ済」に

### 状態アイコン

| アイコン | 意味 |
|----------|------|
| ⬚ | 未着手 |
| 🔄 | 進行中 |
| ✅ | 完了・マージ済 |
| ⏳ | 依存待ち |
| ❌ | ブロック（問題あり） |

### 更新履歴の粒度

重要なイベントのみ記録:
- タスク完了
- マージ完了
- ブロッカー発生・解消
- 計画変更
