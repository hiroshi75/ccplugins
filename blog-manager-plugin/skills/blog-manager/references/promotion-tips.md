# Promotion Tips

記事公開後のプロモーション戦略とタイミングに関するガイドです。

---

## Timing Strategy

### Best Days

| Platform | Best Days |
|----------|-----------|
| dev.to | Tuesday, Wednesday |
| Zenn | Tuesday - Thursday |
| Medium | Tuesday, Wednesday |

### Best Time (UTC)

| Platform | Time | Reason |
|----------|------|--------|
| dev.to | 16:00 UTC | US morning + EU evening |
| X.com | 17:00-18:00 UTC | Same day as article |
| Zenn | 09:00-12:00 JST | Japanese morning |

16:00 UTC は以下をカバー:
- US 東海岸: 11:00 AM
- US 西海岸: 8:00 AM
- EU: 17:00-18:00
- 最大のグローバル同時接続

---

## Cross-Platform Amplification

### GitHub

記事公開時に GitHub リポジトリも整備:

- [ ] README トップに GIF を追加
- [ ] Quick Try / Quick Start セクションを追加
- [ ] 意味のある Topics を設定
- [ ] Release v0.1 を作成（初回のみ）
- [ ] 記事へのリンクを README に追加

### X.com (Twitter)

ピン留めするローンチツイートを作成:

```
[Hook - 1行で記事の価値を伝える]

[GIF または画像]

[簡潔な説明 - 2-3行]

🔗 [記事リンク]

#AI #Python #OpenSource
```

**ポイント:**
- Hook は記事と同じものを使用
- GIF は必須（静止画より効果的）
- 3-6 個のハッシュタグ
- 質問やフィードバックを歓迎する一文

### Discord

関連するコミュニティで共有:

| Channel | Content |
|---------|---------|
| #show-and-tell | 成果物の紹介 |
| #ai-projects | AI 関連プロジェクト |
| #tools | ツール紹介 |
| #resources | 学習リソース |

**共有テンプレート:**
```
Hey everyone! I just published an article about [topic].

[1-2 sentence summary]

Would love to hear your thoughts! [link]
```

### Zenn コミュニティ

- スクラップで補足情報を追加
- 関連記事へのリンクを追加
- コメントに積極的に返信

---

## Repository Naming Suggestions

記事のプロジェクトに良いリポジトリ名を付けるためのガイドライン:

### SEO-Friendly Naming

- キーワードを含める（例: `langchain-agent-builder`）
- 短く覚えやすく（3単語以内推奨）
- ハイフン区切り（アンダースコアより推奨）

### 避けるべき名前

- 既存の人気プロジェクトと被る名前
- 一般的すぎる名前（`ai-tool`, `helper`）
- 略語のみ（意味が伝わらない）

### 良い例

| Type | Example |
|------|---------|
| Library | `fast-embeddings`, `llm-cache` |
| CLI Tool | `ai-commit`, `code-review-bot` |
| Framework | `agent-flow`, `prompt-chain` |

---

## Recommended Hashtags

### English (dev.to, X.com)

**AI/ML:**
- #AI, #MachineLearning, #LLM, #AIagents
- #AIengineering, #GenerativeAI, #ChatGPT

**Development:**
- #Python, #TypeScript, #JavaScript
- #OpenSource, #DevTools, #CLI

**Platforms:**
- #DevTo, #GitHub, #VSCode

**Select 3-6** based on relevance.

### Japanese (Zenn, X.com Japan)

**AI/ML:**
- #AI, #LLM, #ChatGPT, #機械学習
- #生成AI, #AIエージェント

**Development:**
- #Python, #TypeScript, #プログラミング
- #OSS, #開発ツール

**Platforms:**
- #Zenn, #GitHub

---

## Pre-Publish Checklist

記事公開前:

- [ ] Hook は強力で挑発的か
- [ ] GIF は分かりやすいか
- [ ] インストールは 1-3 コマンドか
- [ ] 前半に長いコードブロックがないか
- [ ] ビジュアルは魅力的か
- [ ] CTA は明確か

---

## Post-Publish Checklist

記事公開後（最初の3時間が重要）:

- [ ] X.com でツイート（GIF + Hook）
- [ ] ツイートをピン留め
- [ ] 関連 Discord サーバーで共有
- [ ] GitHub README を更新（必要な場合）
- [ ] コメントを監視し、素早く返信

**最初の3時間のエンゲージメントが記事の露出を大きく左右する。**

---

## Engagement Tips

### コメント対応

- 公開後24時間はコメントをこまめにチェック
- 質問には丁寧に回答
- 指摘があれば記事を更新して感謝を伝える
- 建設的なフィードバックは記事に反映

### フォローアップ

- 1週間後に反応を確認
- 人気のコメントに追加で回答
- 関連する続編記事を検討
- 更新があれば記事を更新（更新履歴を追記）

---

## Common Mistakes to Avoid

### 1. タイミングを逃す

**問題:** 金曜日夜や週末に公開
**対策:** 火曜〜木曜の日中に公開

### 2. SNS での告知を忘れる

**問題:** 記事を公開して終わり
**対策:** 必ず X.com + Discord で告知

### 3. コメントを放置

**問題:** 質問や指摘に返信しない
**対策:** 最初の24時間は特に注意してチェック

### 4. ビジュアルがない

**問題:** テキストのみの記事
**対策:** 必ず GIF または画像を含める

### 5. Hook が弱い

**問題:** 「○○を作ってみた」のような弱いタイトル
**対策:** 読者のメリットを明示する強い Hook

---

## Success Metrics

記事の成功を測る指標:

| Platform | Metrics |
|----------|---------|
| dev.to | Reactions, Comments, Saves |
| Zenn | いいね, スクラップ, コメント |
| Medium | Claps, Reads, Read Ratio |
| GitHub | Stars, Forks, Issues |
| X.com | Likes, Retweets, Replies |

**目標の目安（初回公開）:**
- dev.to: 50+ reactions
- Zenn: 30+ いいね
- GitHub: 10+ stars（記事経由）
