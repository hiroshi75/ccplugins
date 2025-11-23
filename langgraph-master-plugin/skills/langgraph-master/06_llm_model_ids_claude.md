# Anthropic Claude モデル ID

Anthropic Claude API で使用可能なモデル ID 一覧。

> **最終更新**: 2025-11-24

## モデル一覧

### Claude 4.x (2025)

| モデル ID | コンテキスト | 最大出力 | リリース | 特徴 |
|-----------|------------|---------|---------|------|
| `claude-opus-4-1-20250805` | 200K | 32K | 2025-08 | 最強。複雑な推論・コード生成 |
| `claude-sonnet-4-5` | 1M | 64K | 2025-09 | 最新バランス型（推奨） |
| `claude-sonnet-4-20250514` | 200K (1M beta) | 64K | 2025-05 | 本番環境推奨（日付固定） |
| `claude-haiku-4-5-20251001` | 200K | 64K | 2025-10 | 高速・低コスト |

**モデル特性**:
- **Opus**: 最高性能、複雑なタスク（200K コンテキスト）
- **Sonnet**: バランス型、汎用的（1M コンテキスト）
- **Haiku**: 高速・低コスト（$1/M 入力, $5/M 出力）

## 基本的な使用方法

```python
from langchain_anthropic import ChatAnthropic

# 推奨: 最新 Sonnet
llm = ChatAnthropic(model="claude-sonnet-4-5")

# 本番環境: 日付固定版
llm = ChatAnthropic(model="claude-sonnet-4-20250514")

# 高速・低コスト
llm = ChatAnthropic(model="claude-haiku-4-5-20251001")

# 最高性能
llm = ChatAnthropic(model="claude-opus-4-1-20250805")
```

### 環境変数

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

## モデル選択ガイド

| 用途 | 推奨モデル |
|------|-----------|
| コスト重視 | `claude-haiku-4-5-20251001` |
| バランス | `claude-sonnet-4-5` |
| 性能重視 | `claude-opus-4-1-20250805` |
| 本番環境 | `claude-sonnet-4-20250514` (日付固定) |

## Claude の特徴

### 1. 大規模コンテキストウィンドウ

Claude Sonnet 4.5 は **1M トークン**のコンテキストウィンドウに対応：

| モデル | 標準コンテキスト | 最大出力 | 備考 |
|--------|---------------|---------|------|
| Sonnet 4.5 | 1M | 64K | 最新版 |
| Sonnet 4 | 200K (1M beta) | 64K | beta ヘッダーで 1M 利用可 |
| Opus 4.1 | 200K | 32K | 高性能版 |
| Haiku 4.5 | 200K | 64K | 高速版 |

```python
# 1M コンテキストの利用（Sonnet 4.5）
llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    max_tokens=64000  # 最大出力: 64K
)

# Sonnet 4 で 1M コンテキストを有効化（beta）
llm = ChatAnthropic(
    model="claude-sonnet-4-20250514",
    default_headers={"anthropic-beta": "max-tokens-3-5-sonnet-2024-07-15"}
)
```

### 2. 日付固定バージョン

本番環境では予期しない更新を防ぐため、日付付きバージョンを推奨：

```python
# ✅ 推奨（本番）
llm = ChatAnthropic(model="claude-sonnet-4-20250514")

# ⚠️ 注意（開発のみ）
llm = ChatAnthropic(model="claude-sonnet-4")
```

### 3. ツール使用（Function Calling）

Claude はツール使用が強力（詳細は[ツール使用ガイド](06_llm_model_ids_claude_tools.md)を参照）。

### 4. マルチプラットフォーム対応

複数のクラウドプラットフォームで利用可能（詳細は[プラットフォーム別ガイド](06_llm_model_ids_claude_platforms.md)を参照）：

- Anthropic API（直接）
- Google Vertex AI
- AWS Bedrock
- Azure AI (Microsoft Foundry)

## 廃止済みモデル

| モデル | 廃止日 | 移行先 |
|--------|-------|--------|
| Claude 3 Opus | 2025-07-21 | `claude-opus-4-1-20250805` |
| Claude 3 Sonnet | 2025-07-21 | `claude-sonnet-4-5` |
| Claude 2.1 | 2025-07-21 | `claude-sonnet-4-5` |

## 詳細ドキュメント

高度な設定やパラメータについては：
- **[Claude 高度な機能](06_llm_model_ids_claude_advanced.md)** - パラメータ設定、ストリーミング、キャッシング
- **[プラットフォーム別ガイド](06_llm_model_ids_claude_platforms.md)** - Vertex AI, AWS Bedrock, Azure AI での使用方法
- **[ツール使用ガイド](06_llm_model_ids_claude_tools.md)** - Function Calling の実装方法

## 参考リンク

- [Claude API 公式](https://docs.anthropic.com/en/docs/about-claude/models/overview)
- [Anthropic Console](https://console.anthropic.com/)
- [LangChain Integration](https://docs.langchain.com/oss/python/integrations/chat/anthropic)
