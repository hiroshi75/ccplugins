# Zenn Article Guide

Zenn で公開する日本語技術記事を作成するためのガイドです。

## Output

生成ファイル: `.draft/YYYYMMDD_article-zenn.md`

**ファイル名の形式:** `YYYYMMDD_` は生成日の8桁日付（例: `20241215_article-zenn.md`）

---

## Workflow

### Step 1: 元となる情報を確認

ユーザーが提供する README.md やプロジェクト情報を読み込み、以下を把握:

- プロジェクトの目的と価値提案
- 主要な機能と特徴
- インストール方法
- 使用例
- ターゲット読者

### Step 2: 記事タイプの選択

Zenn には2種類の記事タイプがある:

- **tech**: 技術記事（コード、ライブラリ、ツール紹介など）→ ほとんどの場合はこちら
- **idea**: アイデア記事（ポエム、キャリア、考察など）

### Step 3: 記事の生成

`.draft/YYYYMMDD_article-zenn.md` に記事を作成。以下の構成に従う。

---

## Article Structure

### Frontmatter (必須)

```yaml
---
title: "記事タイトル（40文字以内推奨）"
emoji: "🚀"
type: "tech"
topics: ["topic1", "topic2", "topic3", "topic4"]
published: false
_meta:
  perspective: showcase
  perspective_notes: ""
  sources:
    - ideas/20240120_example.md
  generated_at: 2024-01-20
---
```

| フィールド | 必須 | 説明 |
|-----------|------|------|
| title | ○ | 記事タイトル |
| emoji | ○ | 記事を表す絵文字1つ |
| type | ○ | `tech` または `idea` |
| topics | ○ | タグ（最大4つ、小文字英数字） |
| published | ○ | `true` で公開、`false` で下書き |
| _meta | - | 生成メタデータ（管理用、公開時は削除可） |

### _meta フィールド（生成メタデータ）

記事生成時に自動付与される管理用フィールド:

```yaml
_meta:
  perspective: tutorial              # 使用した観点
  perspective_notes: "丁寧に説明"     # 追加の観点指示
  sources:                           # 使用した素材
    - ideas/20240110_langchain-tips.md
    - ideas/20240115_rag-patterns.md
  generated_at: 2024-01-20           # 生成日
```

| フィールド | 説明 |
|-----------|------|
| perspective | 使用した観点テンプレート名 |
| perspective_notes | ユーザーが追加で指定した観点の補足 |
| sources | 使用した素材（ideas/ のパス） |
| generated_at | 記事生成日 |

**注意:** `_meta` は記事管理用であり、Zenn に公開する前に削除しても問題ない。

### Section Structure

```markdown
---
title: "[技術名] で [達成すること] する方法"
emoji: "🚀"
type: "tech"
topics: ["python", "ai", "llm", "tutorial"]
published: false
---

この記事では、[技術名] を使って [何ができるか] を解説します。
[所要時間] で [ゴール] を達成できる、実践的なチュートリアルです。

## 前提条件

### 必要な環境

- Python 3.10 以上
- pip

### 想定読者

- Python の基本がわかる方

## この記事のゴール

- [達成できること1]
- [達成できること2]

## セットアップ

\`\`\`bash
pip install package-name
\`\`\`

## 基本的な使い方

\`\`\`python
from package import Main

result = Main.run()
print(result)
# => 出力結果
\`\`\`

## 実装手順

### ステップ1: [タイトル]

[説明]

\`\`\`python
# コード
\`\`\`

### ステップ2: [タイトル]

[説明]

\`\`\`python
# コード
\`\`\`

## まとめ

この記事では以下を解説しました：

- [ポイント1]
- [ポイント2]

### 参考リンク

- [公式ドキュメント](link)
```

---

## Writing Guidelines

### タイトルの付け方

**良いタイトルの例:**
- 「【2024年版】Python で始める LLM アプリ開発入門」
- 「Next.js 14 の新機能を使ってブログを作り直した話」
- 「ChatGPT API のコストを 80% 削減した方法」

**ルール:**
- 40文字以内を推奨（検索結果で切れない）
- 具体的な技術名やバージョンを含める
- 数字を使うと目を引く
- 読者のメリットを明示する

### リード文（最初の2-3行）

**効果的なパターン:**

問題提起型:
```
「LLM アプリの開発で、毎回同じようなコードを書いていませんか？」
```

成果提示型:
```
「このライブラリを使えば、10行のコードで AI エージェントが作れます。」
```

共感型:
```
「正直に言うと、私も最初は Docker が全く分かりませんでした。」
```

### 文体

- **です・ます調**を基本とする
- 専門用語は初出時に説明を加える
- 読者に語りかける親しみやすいトーン

### コードブロック

- 言語を必ず指定する（```python, ```typescript など）
- コメントは日本語で記述
- 実行可能な完全なコードを提供
- 出力例を含める（`# =>` 形式）

### 画像・図表

- プレースホルダーとして `![説明](image-placeholder.png)` を使用
- 図表の説明を本文に含める

### 長さ

- 読了時間 5-15 分を目安（2000-6000 文字程度）
- 長くなる場合は複数記事に分割を提案

---

## Zenn Markdown Extensions

**メッセージボックス:**

```markdown
:::message
これは補足情報です
:::

:::message alert
これは警告メッセージです
:::
```

**アコーディオン（折りたたみ）:**

```markdown
:::details クリックして詳細を表示
ここに詳細な説明を書く
:::
```

**数式（KaTeX）:**

```markdown
$$
E = mc^2
$$
```

---

## Topic (Tag) Selection

最大4つまで設定可能。

**AI/ML 関連:**
- `ai`, `llm`, `chatgpt`, `openai`, `claude`, `langchain`
- `machinelearning`, `deeplearning`, `python`

**Web 開発:**
- `nextjs`, `react`, `typescript`, `javascript`
- `nodejs`, `deno`, `bun`

**インフラ/ツール:**
- `docker`, `kubernetes`, `aws`, `gcp`, `azure`
- `github`, `vscode`, `cli`

**人気の組み合わせ:**
- AI系: `python`, `ai`, `llm`, `chatgpt`
- Web系: `typescript`, `react`, `nextjs`, `frontend`
- インフラ系: `docker`, `kubernetes`, `aws`, `devops`

---

## Emoji Selection

| カテゴリ | 推奨絵文字 |
|---------|-----------|
| AI/ML | 🤖 🧠 🔮 ✨ |
| Web開発 | 🌐 💻 🚀 ⚡ |
| インフラ | 🐳 ☁️ 🔧 🛠️ |
| セキュリティ | 🔐 🛡️ 🔑 |
| チュートリアル | 📝 📚 🎓 |
| Tips | 💡 ✅ 📌 |

---

## Pre-Publish Checklist

- [ ] フロントマターは正しく設定されているか
- [ ] タイトルは40文字以内で具体的か
- [ ] 絵文字は内容に合っているか
- [ ] トピックは4つ以内で適切か
- [ ] 前提条件は明記されているか
- [ ] コードは実際に動作するか
- [ ] 画像・リンクは正しく表示されるか
- [ ] 誤字脱字はないか
- [ ] まとめと参考リンクがあるか

---

## Article Types

### 入門・チュートリアル記事
- ゴールを最初に明示
- 手順は番号付きで
- 各ステップで何が起こるか説明
- つまづきやすいポイントを先回りで解説

### ライブラリ・ツール紹介記事
- 「何ができるか」を最初に見せる
- 類似ツールとの比較表
- 実際のユースケース
- メリット・デメリットを正直に

### トラブルシューティング記事
- エラーメッセージをそのまま掲載（検索でヒットする）
- 原因の説明
- 複数の解決策を提示
- 予防策も記載

### ベストプラクティス記事
- なぜそれが良いのか理由を説明
- Before/After の比較
- 実際のプロジェクトでの適用例
- 例外ケースも言及
