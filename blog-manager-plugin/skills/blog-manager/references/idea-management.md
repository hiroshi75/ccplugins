# Idea Management

記事アイデア（素材）のフロントマター管理方式です。

## Purpose

- アイデアの状態を追跡（backlog → in-progress → done）
- **素材として再利用可能**（1つの idea を複数の記事に使える）
- 複数プラットフォームへの公開を追跡
- どの記事でこの素材が使われたかを追跡

**重要:** idea は「素材」であり、記事の「観点（perspective）」は持たない。
観点は記事生成時に別途指定する。→ [perspectives.md](perspectives.md) を参照

## Idea File Template

`ideas/` ディレクトリに以下の形式でファイルを作成:

**ファイル名形式:** `YYYYMMDD_topic-name.md`（例: `20241215_langchain-tips.md`）

```yaml
---
status: backlog              # backlog | in-progress | done
priority: medium             # high | medium | low
tags: [langchain, ai, python]
created: 2024-01-10
source_path:                 # (オプション) 元となるプロジェクトパス
source_feature:              # (オプション) 対象の機能名
used_in: []                  # この素材が使われた記事
published_to: []             # 公開後に記録
---

# 記事タイトル案

## 書きたいこと

- ポイント1
- ポイント2
- ポイント3

## ターゲット読者

- 対象読者の説明

## 参考資料

- [リンク1](url)
- [リンク2](url)

## 記事の設計

執筆前にこのセクションを埋めることで、やりとりの手戻りを減らせる。

### 読者
- 前提知識: （初心者/中級者/この分野を知っている人）
- 概念説明の要否: （「◯◯とは」の説明が必要か不要か）

### 主題と材料の関係
- 主題（一番伝えたいこと）:
- 実例・材料の位置づけ: （主題を支える例/主題そのもの）

### 実例のワークフロー（実例を使う場合）
- 実際にどういう手順でやったか、具体的なエピソードをメモ
- **ツール/機能紹介の場合**: ユーザーが何を言うと何が起こるか、対話の流れを記載

### イントロの型
- 直球型: 「この記事では〜を紹介します」とシンプルに始める
- 悩み系: 「こんな悩みはありませんか？」から始める
- 体験ベース: 「先日〜したとき」のようにストーリーから始める
- 問いかけ型: 「〜だと思いませんか？」と読者に問いかける

### 文体
- スタイル: （箇条書き中心/ストーリー性重視/技術解説重視）
- 使いたい用語:
- 避ける用語:
- 避けたいトーン: （マーケティング調/煽り/量産を匂わせる表現 など）

### 視覚化
- 図の要否: （テキストで十分/図が欲しい）
- 図の形式: （Mermaid フローチャート/ディレクトリツリー/表/なし）

### 補足情報
- カスタマイズの余地: （読者が自分で調整できる部分）
- 代替手段・応用パターン: （別のやり方があれば）
```

### used_in の役割

`used_in` は、この素材がどの記事で使われたかを記録する:

```yaml
used_in:
  - path: articles/langchain-rag-guide.md
    perspective: tutorial
    date: 2024-01-20
  - path: external/devto/published/20240125_langchain-intro.md
    perspective: showcase
    date: 2024-01-25
```

これにより:
- 同じ素材を違う観点で再利用したことが分かる
- 素材がどれだけ活用されているか把握できる
- `published_to` と組み合わせて完全な履歴を追跡

### 開発ディレクトリから自動生成される場合

ユーザーが `「/path/to/project の認証機能について記事を書いて」` と指示した場合、
以下のようなファイルが `ideas/` に自動生成される:

```yaml
---
status: in-progress
priority: high
tags: [authentication, nextjs, security]
created: 2024-01-20
source_path: /path/to/project
source_feature: 認証機能
published_to: []
---

# Next.js 認証機能の実装解説

## 元ネタ

/path/to/project の認証機能から記事を生成

## 記事化のポイント

- JWT トークンの実装
- セッション管理
- ミドルウェアでの認証チェック
```

`source_path` があることで:
- 同じ機能について再度記事を書こうとした時に検知できる
- 元のコードに戻って確認できる

## Status Definitions

| status | 意味 | 次のアクション |
|--------|------|---------------|
| `backlog` | アイデアのみ。未着手 | 執筆開始時に `in-progress` へ |
| `in-progress` | 執筆中 | 公開後に `done` へ |
| `done` | 記事化完了 | 必要に応じて他プラットフォームに展開 |

## Priority Levels

| priority | 意味 | 目安 |
|----------|------|------|
| `high` | すぐに書きたい | 今週〜来週 |
| `medium` | いつか書きたい | 今月中 |
| `low` | ネタとしてストック | 時間があれば |

## Published To Format

記事を公開したら `published_to` を更新:

```yaml
published_to:
  - platform: zenn
    url: https://zenn.dev/username/articles/article-slug
    date: 2024-01-15
  - platform: devto
    url: https://dev.to/username/article-title-xxx
    date: 2024-01-16
  - platform: medium
    url: https://medium.com/@username/article-title-xxx
    date: 2024-01-17
```

## Workflow Examples

### 1. 新しいアイデアを追加

```bash
# ideas/20240120_mcp-server-intro.md を作成
```

```yaml
---
status: backlog
priority: high
tags: [mcp, claude, ai]
created: 2024-01-20
published_to: []
---

# MCP サーバーの作り方入門

## 書きたいこと

- MCP とは何か
- 簡単なサーバーの実装
- Claude Code との連携

## ターゲット読者

- Claude Code ユーザー
- AI ツール開発者
```

### 2. 執筆開始時に status 更新

```yaml
---
status: in-progress    # ← backlog から変更
priority: high
tags: [mcp, claude, ai]
created: 2024-01-20
published_to: []
---
```

### 3. Zenn に公開後

```yaml
---
status: done           # ← in-progress から変更
priority: high
tags: [mcp, claude, ai]
created: 2024-01-20
published_to:
  - platform: zenn
    url: https://zenn.dev/ayu/articles/mcp-server-intro
    date: 2024-01-25
---
```

### 4. dev.to にも公開後

```yaml
---
status: done
priority: high
tags: [mcp, claude, ai]
created: 2024-01-20
published_to:
  - platform: zenn
    url: https://zenn.dev/ayu/articles/mcp-server-intro
    date: 2024-01-25
  - platform: devto
    url: https://dev.to/ayu/how-to-build-mcp-server-xxx
    date: 2024-01-26
---
```

## Querying Ideas

### backlog のアイデア一覧
```
ideas/ の中で status: backlog のファイルを一覧して
```

### 優先度 high のアイデア
```
ideas/ の中で priority: high のファイルを一覧して
```

### 特定タグのアイデア
```
ideas/ の中で tags に "langchain" を含むファイルを一覧して
```

### まだ dev.to に公開していないアイデア
```
ideas/ の中で status: done かつ published_to に devto がないファイルを一覧して
```

## Best Practices

1. **アイデアは具体的に**
   - 「AI について書く」ではなく「LangChain の RAG 実装パターン3選」

2. **ターゲット読者を明確に**
   - 誰が読むかで書き方が変わる

3. **参考資料はその場でメモ**
   - 後で探すのは大変

4. **定期的に backlog をレビュー**
   - 古くなったアイデアは削除または更新

5. **公開したら必ず published_to を更新**
   - 重複投稿を防ぐため

6. **執筆前に「記事の設計」を埋める**
   - 読者の前提知識、主題と実例の関係、文体を事前に決めておく
   - これにより執筆中の手戻りを大幅に減らせる
   - 実例を使う場合は、実際のワークフローを具体的にメモしておく
