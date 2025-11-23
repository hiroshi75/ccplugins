# Google Gemini モデル ID

Google Gemini API で使用可能なモデル ID 一覧。

> **最終更新**: 2025-11-24

## モデル一覧

### Gemini 3.x (最新)

| モデル ID | コンテキスト | 最大出力 | 用途 |
|-----------|------------|---------|------|
| `google/gemini-3-pro-preview` | - | 64K | 最新の高性能モデル |
| `google/gemini-3-pro-image-preview` | - | - | 画像生成 |
| `google/gemini-3-pro-image-preview-edit` | - | - | 画像編集 |

### Gemini 2.5

| モデル ID | コンテキスト | 最大出力 | 用途 |
|-----------|------------|---------|------|
| `google/gemini-2.5-pro` | 1M (2M 予定) | - | 高性能 |
| `gemini-2.5-flash` | 1M | - | 高速バランス型（推奨） |
| `gemini-2.5-flash-lite-preview` | 1M | - | 軽量高速 |

**注**: 無料版は約32K トークンに制限。Gemini Advanced (2.5 Pro) は1M トークン。

### Gemini 2.0

| モデル ID | コンテキスト | 最大出力 | 用途 |
|-----------|------------|---------|------|
| `gemini-2.0-flash-exp` | 1M | - | 実験版 |
| `gemini-2.0-flash` | 1M | - | 安定版 |

## 基本的な使用方法

```python
from langchain_google_genai import ChatGoogleGenerativeAI

# 推奨: バランス型
llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash")

# プレフィックス付きでも可
llm = ChatGoogleGenerativeAI(model="models/gemini-2.5-flash")

# 高性能版
llm = ChatGoogleGenerativeAI(model="google/gemini-3-pro-preview")

# 軽量版
llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash-lite-preview")
```

### 環境変数

```bash
export GOOGLE_API_KEY="your-api-key"
```

## モデル選択ガイド

| 用途 | 推奨モデル |
|------|-----------|
| コスト重視 | `gemini-2.5-flash-lite-preview` |
| バランス | `gemini-2.5-flash` |
| 性能重視 | `google/gemini-3-pro-preview` |
| 大規模コンテキスト | `gemini-2.5-pro` (1M トークン) |

## Gemini の特徴

### 1. 大規模コンテキストウィンドウ

Gemini は**業界初の 1M トークン対応モデル**：

| ティア | コンテキスト制限 |
|--------|---------------|
| Gemini Advanced (2.5 Pro) | 1M トークン |
| Vertex AI | 1M トークン |
| 無料版 | 約 32K トークン |

**用途**:
- 長文ドキュメントの分析
- コードベース全体の理解
- 長期的な会話履歴

```python
# 大規模コンテキストの処理
llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-pro",
    max_tokens=8192  # 出力トークン数を指定
)
```

**将来**: Gemini 2.5 Pro は 2M トークンのコンテキストウィンドウに対応予定。

### 2. マルチモーダル対応

画像入力・生成が可能（詳細は[高度な機能](06_llm_model_ids_gemini_advanced.md)を参照）。

## 注意事項

- ❌ **廃止**: Gemini 1.0, 1.5 シリーズは使用不可
- ✅ **移行推奨**: `gemini-2.5-flash` 以降のモデルを使用

## 詳細ドキュメント

高度な設定やマルチモーダル機能については：
- **[Gemini 高度な機能](06_llm_model_ids_gemini_advanced.md)**

## 参考リンク

- [Gemini API 公式](https://ai.google.dev/gemini-api/docs/models)
- [Google AI Studio](https://makersuite.google.com/)
- [LangChain Integration](https://docs.langchain.com/oss/python/integrations/chat/google_generative_ai)
