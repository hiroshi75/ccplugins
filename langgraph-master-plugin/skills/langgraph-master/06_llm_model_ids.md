# LLM モデル ID リファレンス

LangGraph でよく使用される主要な LLM プロバイダーのモデル ID 一覧。各プロバイダーの詳細な情報とベストプラクティスについては、個別のページを参照してください。

> **最終更新**: 2025-11-24
> **注意**: モデルの可用性や名称は変更される可能性があります。最新情報は各プロバイダーの公式ドキュメントを参照してください。

## 📚 プロバイダー別ドキュメント

### [Google Gemini モデル](06_llm_model_ids_gemini.md)

Google の最新 LLM モデル。大規模コンテキスト（最大 1M トークン）が特徴。

**主要モデル**:
- `google/gemini-3-pro-preview` - 最新の高性能モデル
- `gemini-2.5-flash` - 高速応答版（1M トークン）
- `gemini-2.5-flash-lite-preview` - 軽量高速版

**詳細**: [Gemini モデル ID 完全ガイド](06_llm_model_ids_gemini.md)

---

### [Anthropic Claude モデル](06_llm_model_ids_claude.md)

Anthropic の Claude 4.x シリーズ。バランスの取れた性能とコストが特徴。

**主要モデル**:
- `claude-opus-4-1-20250805` - 最強モデル
- `claude-sonnet-4-5` - バランス型（推奨）
- `claude-haiku-4-5-20251001` - 高速・低コスト

**詳細**: [Claude モデル ID 完全ガイド](06_llm_model_ids_claude.md)

---

### [OpenAI GPT モデル](06_llm_model_ids_openai.md)

OpenAI の GPT-5 シリーズ。幅広いタスクに対応し、400K コンテキストと高度な推論能力が特徴。

**主要モデル**:
- `gpt-5` - GPT-5 標準版
- `gpt-5-mini` - 小型版（コスト効率◎）
- `gpt-5.1-thinking` - 適応的推論モデル

**詳細**: [OpenAI モデル ID 完全ガイド](06_llm_model_ids_openai.md)

---

## 🚀 クイックスタート

### 基本的な使用方法

```python
from langchain_anthropic import ChatAnthropic
from langchain_openai import ChatOpenAI
from langchain_google_genai import ChatGoogleGenerativeAI

# Claude を使用
claude_llm = ChatAnthropic(model="claude-sonnet-4-5")

# OpenAI を使用
openai_llm = ChatOpenAI(model="gpt-5")

# Gemini を使用
gemini_llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash")
```

### LangGraph での使用

```python
from langgraph.graph import StateGraph
from langchain_anthropic import ChatAnthropic
from typing import TypedDict, Annotated
from langgraph.graph.message import add_messages

# 状態定義
class State(TypedDict):
    messages: Annotated[list, add_messages]

# モデルの初期化
llm = ChatAnthropic(model="claude-sonnet-4-5")

# ノード定義
def chat_node(state: State):
    response = llm.invoke(state["messages"])
    return {"messages": [response]}

# グラフ構築
graph = StateGraph(State)
graph.add_node("chat", chat_node)
graph.set_entry_point("chat")
graph.set_finish_point("chat")

app = graph.compile()
```

## 📊 モデル選択ガイド

### 用途別おすすめモデル

| 用途 | 推奨モデル | 理由 |
|------|-----------|------|
| **コスト重視** | `claude-haiku-4-5`<br>`gpt-5-mini`<br>`gemini-2.5-flash-lite` | 低コストで高速 |
| **バランス重視** | `claude-sonnet-4-5`<br>`gpt-5`<br>`gemini-2.5-flash` | 性能とコストのバランス |
| **性能重視** | `claude-opus-4-1`<br>`gpt-5-pro`<br>`gemini-3-pro` | 最高性能 |
| **推論特化** | `gpt-5.1-thinking`<br>`gpt-5.1-instant` | 適応的推論・数学・科学 |
| **大規模コンテキスト** | `gemini-2.5-pro` | 1M トークンのコンテキスト |

### タスク複雑さによる選択

```python
def select_model(task_complexity: str, budget: str = "normal"):
    """タスクと予算に応じて最適なモデルを選択"""

    # 予算重視
    if budget == "low":
        models = {
            "simple": "claude-haiku-4-5-20251001",
            "medium": "gpt-5-mini",
            "complex": "claude-sonnet-4-5"
        }
        return models.get(task_complexity, "gpt-5-mini")

    # 性能重視
    if budget == "high":
        models = {
            "simple": "claude-sonnet-4-5",
            "medium": "gpt-5",
            "complex": "claude-opus-4-1-20250805"
        }
        return models.get(task_complexity, "claude-opus-4-1-20250805")

    # バランス重視（デフォルト）
    models = {
        "simple": "gpt-5-mini",
        "medium": "claude-sonnet-4-5",
        "complex": "gpt-5"
    }
    return models.get(task_complexity, "claude-sonnet-4-5")
```

## 🔄 マルチモデル戦略

### プロバイダー間のフォールバック

```python
from langchain_anthropic import ChatAnthropic
from langchain_openai import ChatOpenAI

# メインモデルとフォールバック
primary = ChatAnthropic(model="claude-sonnet-4-5")
fallback1 = ChatOpenAI(model="gpt-5")
fallback2 = ChatGoogleGenerativeAI(model="gemini-2.5-flash")

llm_with_fallback = primary.with_fallbacks([fallback1, fallback2])

# いずれかのモデルが成功するまで自動的にフォールバック
response = llm_with_fallback.invoke("質問内容")
```

### コスト最適化の自動ルーティング

```python
from langgraph.graph import StateGraph
from typing import TypedDict, Annotated, Literal
from langgraph.graph.message import add_messages

class State(TypedDict):
    messages: Annotated[list, add_messages]
    complexity: Literal["simple", "medium", "complex"]

# 複雑さに応じて異なるモデルを使用
simple_llm = ChatAnthropic(model="claude-haiku-4-5-20251001")  # 低コスト
medium_llm = ChatOpenAI(model="gpt-5-mini")  # バランス
complex_llm = ChatAnthropic(model="claude-opus-4-1-20250805")  # 高性能

def analyze_complexity(state: State):
    """メッセージの複雑さを分析"""
    message = state["messages"][-1].content
    # 簡易的な複雑さ判定
    if len(message) < 50:
        complexity = "simple"
    elif len(message) < 200:
        complexity = "medium"
    else:
        complexity = "complex"
    return {"complexity": complexity}

def route_by_complexity(state: State):
    """複雑さに応じてルーティング"""
    routes = {
        "simple": "simple_node",
        "medium": "medium_node",
        "complex": "complex_node"
    }
    return routes[state["complexity"]]

def simple_node(state: State):
    response = simple_llm.invoke(state["messages"])
    return {"messages": [response]}

def medium_node(state: State):
    response = medium_llm.invoke(state["messages"])
    return {"messages": [response]}

def complex_node(state: State):
    response = complex_llm.invoke(state["messages"])
    return {"messages": [response]}

# グラフ構築
graph = StateGraph(State)
graph.add_node("analyze", analyze_complexity)
graph.add_node("simple_node", simple_node)
graph.add_node("medium_node", medium_node)
graph.add_node("complex_node", complex_node)

graph.set_entry_point("analyze")
graph.add_conditional_edges("analyze", route_by_complexity)

app = graph.compile()
```

## 🔧 ベストプラクティス

### 1. 環境変数での管理

```python
import os

# 環境変数でモデルを柔軟に管理
DEFAULT_MODEL = os.getenv("DEFAULT_LLM_MODEL", "claude-sonnet-4-5")
FAST_MODEL = os.getenv("FAST_LLM_MODEL", "claude-haiku-4-5-20251001")
SMART_MODEL = os.getenv("SMART_LLM_MODEL", "claude-opus-4-1-20250805")

# 環境に応じてプロバイダーを切り替え
PROVIDER = os.getenv("LLM_PROVIDER", "anthropic")

if PROVIDER == "anthropic":
    llm = ChatAnthropic(model=DEFAULT_MODEL)
elif PROVIDER == "openai":
    llm = ChatOpenAI(model="gpt-5")
elif PROVIDER == "google":
    llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash")
```

### 2. モデルバージョンの固定（本番環境）

```python
# ✅ 推奨: 日付付きバージョンを使用（本番環境）
prod_llm = ChatAnthropic(model="claude-sonnet-4-20250514")

# ⚠️ 注意: バージョン指定なし（予期しない更新の可能性）
dev_llm = ChatAnthropic(model="claude-sonnet-4")
```

### 3. コスト監視

```python
from langchain.callbacks import get_openai_callback

# OpenAI のコスト追跡
with get_openai_callback() as cb:
    response = openai_llm.invoke("質問")
    print(f"Total Cost: ${cb.total_cost}")
    print(f"Tokens: {cb.total_tokens}")

# その他のプロバイダーは手動で追跡
# 各プロバイダーの詳細ページを参照
```

## 📖 詳細ドキュメント

各プロバイダーの詳細な情報については、以下のページを参照してください：

- **[Gemini モデル ID](06_llm_model_ids_gemini.md)**: モデル一覧、使用方法、高度な設定、マルチモーダル機能
- **[Claude モデル ID](06_llm_model_ids_claude.md)**: モデル一覧、プラットフォーム別ID、ツール使用、廃止モデル情報
- **[OpenAI モデル ID](06_llm_model_ids_openai.md)**: モデル一覧、推論モデル、ビジョン機能、Azure OpenAI

## 🔗 参考リンク

### 公式ドキュメント

- [Google Gemini API](https://ai.google.dev/gemini-api/docs/models)
- [Anthropic Claude API](https://docs.anthropic.com/en/docs/about-claude/models/overview)
- [OpenAI Platform](https://platform.openai.com/docs/models)

### 統合ガイド

- [LangChain Chat Models](https://docs.langchain.com/oss/python/modules/model_io/chat/)
- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)

### 料金情報

- [Gemini Pricing](https://ai.google.dev/pricing)
- [Claude Pricing](https://www.anthropic.com/pricing)
- [OpenAI Pricing](https://openai.com/pricing)
