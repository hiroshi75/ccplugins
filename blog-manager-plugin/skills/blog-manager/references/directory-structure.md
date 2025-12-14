# Directory Structure

ブログ執筆プロジェクトの推奨ディレクトリ構成（Zenn CLI ベース拡張型 + 3層構造）です。

## Three-Layer Concept

ブログ執筆は「素材」「観点」「成果物」の3層で管理する:

| レイヤー | ディレクトリ | 役割 | 再利用 |
|---------|-------------|------|--------|
| 素材 | `ideas/` | 何を書くか（ネタ） | ○ |
| 観点 | `perspectives/` | どう書くか（スタイル） | ○ |
| 成果物 | `.draft/` → `articles/` | 生成された記事 | × |

## Standard Structure

```
my-blog/
├── .claude/                    # Claude Code 設定
│   └── settings.local.json
├── .draft/                     # 下書き生成先（一時置き場）
│   ├── YYYYMMDD_article-zenn.md    # Zenn 用下書き（例: 20241215_article-zenn.md）
│   ├── YYYYMMDD_article-devto.md   # dev.to 用下書き
│   └── YYYYMMDD_article-medium.md  # Medium 用下書き
├── ideas/                      # 記事アイデア・素材（再利用可能）
│   ├── YYYYMMDD_langchain-tips.md    # 例: 20241215_langchain-tips.md
│   ├── YYYYMMDD_claude-code-intro.md
│   └── ...
├── perspectives/               # 観点テンプレート（再利用可能）
│   ├── showcase.md             # 製品紹介向け
│   ├── personal.md             # 個人的な考え
│   ├── tutorial.md             # ハンズオン教育
│   └── deep-dive.md            # 技術深掘り
├── articles/                   # Zenn 公開用（Zenn CLI 互換）
│   └── my-published-article.md
├── books/                      # Zenn 本（オプション）
│   └── my-book/
│       ├── config.yaml
│       └── chapters/
├── images/                     # 共有画像・GIF（Zenn CLI 互換）
│   └── screenshots/
├── external/                   # 他プラットフォーム確定版
│   ├── devto/
│   │   ├── drafts/
│   │   └── published/
│   └── medium/
│       ├── drafts/
│       └── published/
├── .gitignore
└── README.md
```

## Directory Roles

| ディレクトリ | 役割 | 備考 |
|-------------|------|------|
| `.draft/` | スキルによる自動生成先 | レビュー後に移動 |
| `ideas/` | 記事ネタのストック（素材） | 再利用可能、フロントマターで状態管理 |
| `perspectives/` | 観点テンプレート | 再利用可能、記事のトーン・スタイルを定義 |
| `articles/` | Zenn 公開用 | Zenn CLI 互換、`npx zenn preview` 可能 |
| `books/` | Zenn 本 | オプション |
| `images/` | 画像ファイル | Zenn CLI 互換 |
| `external/` | dev.to, Medium 用 | drafts/published で分離 |

## Zenn CLI Compatibility

このディレクトリ構成は Zenn CLI と完全互換です:

```bash
# Zenn CLI のプレビュー
npx zenn preview

# 新しい記事を作成
npx zenn new:article

# 新しい本を作成
npx zenn new:book
```

## Setup Commands

新規プロジェクトを作成する場合:

```bash
# ディレクトリ作成
mkdir -p my-blog/{.draft,ideas,perspectives,articles,books,images/screenshots}
mkdir -p my-blog/external/{devto,medium}/{drafts,published}

# 移動
cd my-blog

# Git 初期化
git init

# Zenn CLI セットアップ（オプション）
npm init -y
npm install zenn-cli
npx zenn init
```

### perspectives/ の初期テンプレート

perspectives/ には以下のテンプレートを配置:

```bash
# 標準テンプレートを作成
touch perspectives/{showcase,personal,tutorial,deep-dive}.md
```

各テンプレートの内容は [perspectives.md](perspectives.md) を参照。

## Recommended .gitignore

```gitignore
# OS
.DS_Store
Thumbs.db

# Editor
.vscode/
.idea/
*.swp
*~

# Node
node_modules/
package-lock.json

# Optional: 下書きを Git 管理しない場合
# .draft/

# Secrets
.env
.env.local
```

## File Naming Conventions

### .draft/
- `YYYYMMDD_article-{platform}.md` - 生成日プレフィックス付き
- 例: `20241215_article-zenn.md`, `20241215_article-devto.md`
- platform: `zenn`, `devto`, `medium`

### ideas/
- `YYYYMMDD_topic-name.md` - 作成日プレフィックス + ケバブケース
- 例: `20241215_langchain-tips.md`, `20241210_claude-code-intro.md`

### articles/ (Zenn)
- `slug-name.md` - URL スラッグになる
- 例: `how-to-use-langchain.md`
- Zenn では14文字以上50文字以下の半角英数字（a-z0-9）とハイフン

### external/
- `YYYY-MM-DD-title.md` - 日付プレフィックス推奨
- 例: `2024-01-15-langchain-tips.md`

## Project Initialization Checklist

新規プロジェクト作成時の確認事項:

- [ ] ディレクトリ構成を作成（ideas/, perspectives/, .draft/ など）
- [ ] `.gitignore` を設定
- [ ] Git リポジトリを初期化
- [ ] Zenn CLI をセットアップ（Zenn を使う場合）
- [ ] perspectives/ に標準テンプレートを配置
- [ ] README.md にプロジェクト説明を記載
- [ ] 最初のアイデアを `ideas/` に追加
