# Dev.to / Medium Article Guide

dev.to および Medium で公開する英語技術記事を作成するためのガイドです。

## Output

- 生成ファイル: `.draft/YYYYMMDD_article-devto.md`
- Medium 版（オプション）: `.draft/YYYYMMDD_article-medium.md`

**ファイル名の形式:** `YYYYMMDD_` は生成日の8桁日付（例: `20241215_article-devto.md`）

---

## Workflow

### Step 1: Read and Analyze the Source

ユーザーが提供する README.md やプロジェクト情報を読み込み、以下を把握:

- Project purpose and core value proposition
- Key features and capabilities
- Installation process
- Usage examples
- Target audience

### Step 2: Generate the Article

`.draft/YYYYMMDD_article-devto.md` に記事を作成。以下の構成に従う。

### Step 3: Generate Medium Version (Optional)

リクエストがあれば `.draft/YYYYMMDD_article-medium.md` にストーリードリブンな記事を作成。

---

## Article Structure

### Frontmatter

```yaml
---
title: Your Title Here
published: false
description: One-line description for SEO (max 150 chars)
tags: ai, python, opensource, devtools
cover_image: https://your-image-url.com/cover.png
_meta:
  perspective: showcase
  perspective_notes: ""
  sources:
    - ideas/20240120_example.md
  generated_at: 2024-01-20
---
```

### _meta フィールド（生成メタデータ）

記事生成時に自動付与される管理用フィールド:

```yaml
_meta:
  perspective: showcase              # 使用した観点
  perspective_notes: "熱意を込めて"   # 追加の観点指示
  sources:                           # 使用した素材
    - ideas/20240120_mcp-server.md
  generated_at: 2024-01-20           # 生成日
```

| フィールド | 説明 |
|-----------|------|
| perspective | 使用した観点テンプレート名 |
| perspective_notes | ユーザーが追加で指定した観点の補足 |
| sources | 使用した素材（ideas/ のパス） |
| generated_at | 記事生成日 |

**注意:** `_meta` は記事管理用であり、dev.to/Medium に公開する前に削除しても問題ない。

### Required Sections (In Order)

#### 1. Title

Format: **"[Action Verb] + [Benefit/Problem Solved]"**

Examples:
- "Stop writing agents by hand: a new way to build AI systems"
- "Introducing an AI tool that designs, evaluates, and improves itself"
- "A new workflow for building AI apps—faster and smarter"

Rules:
- Maximum 60 characters for optimal display
- Use strong verbs: Stop, Introducing, Build, Create, Automate
- Promise a clear benefit
- Avoid generic titles like "My New Project"

#### 2. Hook (First 1-2 Lines)

**This is the most critical part.**

Patterns that work:

**Provocation:**
```
Stop building AI agents manually. Seriously—stop.
```

**Magic moment:**
```
I typed one line, and the entire workflow emerged automatically.
```

**Future shock:**
```
AI can now do in minutes what used to take teams days.
```

Rules:
- Short (1-2 sentences max)
- Surprising or controversial
- Opinionated
- Stand alone visually (separate paragraph)

#### 3. GIF Placeholder

Immediately after the hook:

```
[GIF: Brief description of what the demo should show - e.g., "Terminal showing automated workflow generation in 5 seconds"]
```

Guidelines:
- 5-12 seconds duration
- Show the "aha moment" only
- No audio required
- Visually demonstrate automation or results

#### 4. Problem Statement

Keep this SHORT. 3-5 sentences max.

```markdown
## The Problem

Building [X] manually means:
- [Pain point 1]
- [Pain point 2]
- [Pain point 3]

Sound familiar?
```

The reader should think: "Yes, this is exactly what I struggle with."

#### 5. Solution Overview

Do NOT dive into technical details yet.

```markdown
## What [Project Name] Does

[One sentence summary]

- **Automates** [what]
- **Generates** [what]
- **Evaluates** [what]
- **Optimizes** [what]
```

Use strong verbs:
- Automates, Generates, Evaluates, Optimizes, Integrates
- Eliminates, Simplifies, Accelerates, Transforms

#### 6. Installation

As short as possible. Readers decide in 10 seconds.

```markdown
## Quick Start

\`\`\`bash
pip install your-package
\`\`\`

That's it. You're ready.
```

Rules:
- 1-3 commands maximum
- No configuration steps in this section
- Link to docs for advanced setup

#### 7. How It Works

Show the main value in the simplest possible example.

```markdown
## How It Works

[Screenshot or GIF placeholder]

\`\`\`python
# Minimal code example (5-10 lines max)
from your_package import magic

result = magic("input")
print(result)  # Amazing output
\`\`\`

[Brief explanation - 2-3 sentences]
```

Rules:
- Single screenshot OR second GIF OR short code snippet
- Avoid long code blocks
- No internal architecture explanations
- Deliver the "oh, that's cool" moment

#### 8. Feature Deep Dive (Optional)

Maximum 2-4 subsections.

```markdown
## Key Features

### Feature 1: [Name]
[2-3 sentences + optional small diagram]

### Feature 2: [Name]
[2-3 sentences + optional small diagram]
```

Use diagrams over text where possible.

#### 9. Real Output Example

Make it visually engaging.

```markdown
## See It In Action

**Before:**
| Step | Manual Effort |
|------|---------------|
| Step 1 | 30 minutes |
| Step 2 | 2 hours |

**After:**
| Step | With [Project] |
|------|----------------|
| All | 30 seconds |
```

Rules:
- Use tables for before/after comparisons
- Highlighted terminal output if needed
- Annotated screenshots
- NO large monochrome terminal dumps

#### 10. Closing + CTA

```markdown
## Get Started Today

[Project Name] is open source and ready to use.

- **[Star on GitHub](link)** to support the project
- **[Try the quickstart](link)** in 5 minutes
- **[Open an issue](link)** with your ideas
- **Share** if you found this useful!

---

Thanks for reading! Questions? Drop a comment below.
```

---

## Visual Guidelines

### Recommended Image Flow

1. **Hook → GIF (mandatory)**
2. Screenshot of "initial magic moment"
3. Diagram or annotated terminal
4. Final output or result

### GIF Guidelines

- Should show transformation or automation
- Keep under 15 seconds
- Highlight UI cues (mouse, cursor)

### Screenshots

- Use annotations when possible (arrows, highlights)
- Avoid raw terminal dumps

---

## Reusable Hooks

### Provocative
- "Stop building AI agents manually."
- "Forget prompt engineering—this changes everything."

### Future-oriented
- "AI workflows are about to look very different."
- "A new way to build AI systems—faster and smarter."

### Magic moment
- "I typed one line and the agent built itself."

---

## Hashtags (for X.com posting)

Use 3-6:
- #AI
- #Python
- #MachineLearning
- #LLM
- #AIagents
- #AIengineering
- #OpenSource
- #DevTools

---

## Pre-Publish Checklist

- [ ] Hook is provocative and stands alone
- [ ] GIF placeholder clearly describes the demo
- [ ] Installation is 1-3 commands
- [ ] No long code blocks in first half
- [ ] Visuals are described/planned
- [ ] Clear CTA at the end
- [ ] Total reading time: 4-7 minutes

---

## Medium Differences

Medium 版を作成する場合:

- より**ストーリードリブン**なアプローチ
- 個人的な経験や背景を含める
- SEO を意識した長めの記事
- 技術的な詳細よりも「なぜ」を重視
- 見出しは疑問形が効果的

Medium は長期的な検索トラフィックを狙うのに適している。

---

## Project Type Adaptations

### Libraries
Focus on:
- Installation simplicity
- One killer code snippet
- Clear before/after improvement

### Tools / Plugins
Focus on:
- Animated demo
- UI interactions
- Productivity gain

### Frameworks
Focus on:
- Architecture diagram
- Conceptual clarity
- Extensibility

### Benchmarks / Evaluators
Focus on:
- Reproducibility
- Clear metrics
- Example outputs
