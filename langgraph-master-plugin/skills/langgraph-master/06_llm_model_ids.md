# LLM Model ID Reference

List of model IDs for major LLM providers commonly used in LangGraph. For detailed information and best practices for each provider, please refer to the individual pages.

> **Last Updated**: 2025-11-24
> **Note**: Model availability and names may change. Please refer to each provider's official documentation for the latest information.

## 📚 Provider-Specific Documentation

### [Google Gemini Models](06_llm_model_ids_gemini.md)

Google's latest LLM models featuring large-scale context (up to 1M tokens).

**Key Models**:

- `google/gemini-3-pro-preview` - Latest high-performance model
- `gemini-2.5-flash` - Fast response version (1M tokens)
- `gemini-2.5-flash-lite` - Lightweight fast version

**Details**: [Gemini Model ID Complete Guide](06_llm_model_ids_gemini.md)

---

### [Anthropic Claude Models](06_llm_model_ids_claude.md)

Anthropic's Claude 4.x series featuring balanced performance and cost.

**Key Models**:

- `claude-opus-4-1-20250805` - Most powerful model
- `claude-sonnet-4-5` - Balanced (recommended)
- `claude-haiku-4-5-20251001` - Fast and low-cost

**Details**: [Claude Model ID Complete Guide](06_llm_model_ids_claude.md)

---

### [OpenAI GPT Models](06_llm_model_ids_openai.md)

OpenAI's GPT-5 series supporting a wide range of tasks, with 400K context and advanced reasoning capabilities.

**Key Models**:

- `gpt-5` - GPT-5 standard version
- `gpt-5-mini` - Small version (cost-efficient ◎)
- `gpt-5.1-thinking` - Adaptive reasoning model

**Details**: [OpenAI Model ID Complete Guide](06_llm_model_ids_openai.md)

---

## 🚀 Quick Start

### Basic Usage

```python
from langchain_anthropic import ChatAnthropic
from langchain_openai import ChatOpenAI
from langchain_google_genai import ChatGoogleGenerativeAI

# Use Claude
claude_llm = ChatAnthropic(model="claude-sonnet-4-5")

# Use OpenAI
openai_llm = ChatOpenAI(model="gpt-5")

# Use Gemini
gemini_llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash")
```

### Using with LangGraph

```python
from langgraph.graph import StateGraph
from langchain_anthropic import ChatAnthropic
from typing import TypedDict, Annotated
from langgraph.graph.message import add_messages

# State definition
class State(TypedDict):
    messages: Annotated[list, add_messages]

# Model initialization
llm = ChatAnthropic(model="claude-sonnet-4-5")

# Node definition
def chat_node(state: State):
    response = llm.invoke(state["messages"])
    return {"messages": [response]}

# Graph construction
graph = StateGraph(State)
graph.add_node("chat", chat_node)
graph.set_entry_point("chat")
graph.set_finish_point("chat")

app = graph.compile()
```

## 📊 Model Selection Guide

### Recommended Models by Use Case

| Use Case | Recommended Model | Reason |
| ---------------------- | ------------------------------------------------------------- | ------------------------- |
| **Cost-focused** | `claude-haiku-4-5`<br>`gpt-5-mini`<br>`gemini-2.5-flash-lite` | Low cost and fast |
| **Balance-focused** | `claude-sonnet-4-5`<br>`gpt-5`<br>`gemini-2.5-flash` | Balance of performance and cost |
| **Performance-focused** | `claude-opus-4-1`<br>`gpt-5-pro`<br>`gemini-3-pro` | Maximum performance |
| **Reasoning-specialized** | `gpt-5.1-thinking`<br>`gpt-5.1-instant` | Adaptive reasoning, math, science |
| **Large-scale context** | `gemini-2.5-pro` | 1M token context |

### Selection by Task Complexity

```python
def select_model(task_complexity: str, budget: str = "normal"):
    """Select optimal model based on task and budget"""

    # Budget-focused
    if budget == "low":
        models = {
            "simple": "claude-haiku-4-5-20251001",
            "medium": "gpt-5-mini",
            "complex": "claude-sonnet-4-5"
        }
        return models.get(task_complexity, "gpt-5-mini")

    # Performance-focused
    if budget == "high":
        models = {
            "simple": "claude-sonnet-4-5",
            "medium": "gpt-5",
            "complex": "claude-opus-4-1-20250805"
        }
        return models.get(task_complexity, "claude-opus-4-1-20250805")

    # Balance-focused (default)
    models = {
        "simple": "gpt-5-mini",
        "medium": "claude-sonnet-4-5",
        "complex": "gpt-5"
    }
    return models.get(task_complexity, "claude-sonnet-4-5")
```

## 🔄 Multi-Model Strategy

### Fallback Between Providers

```python
from langchain_anthropic import ChatAnthropic
from langchain_openai import ChatOpenAI

# Primary model and fallback
primary = ChatAnthropic(model="claude-sonnet-4-5")
fallback1 = ChatOpenAI(model="gpt-5")
fallback2 = ChatGoogleGenerativeAI(model="gemini-2.5-flash")

llm_with_fallback = primary.with_fallbacks([fallback1, fallback2])

# Automatically fallback until one model succeeds
response = llm_with_fallback.invoke("Question content")
```

### Cost-Optimized Auto-Routing

```python
from langgraph.graph import StateGraph
from typing import TypedDict, Annotated, Literal
from langgraph.graph.message import add_messages

class State(TypedDict):
    messages: Annotated[list, add_messages]
    complexity: Literal["simple", "medium", "complex"]

# Use different models based on complexity
simple_llm = ChatAnthropic(model="claude-haiku-4-5-20251001")  # Low cost
medium_llm = ChatOpenAI(model="gpt-5-mini")  # Balance
complex_llm = ChatAnthropic(model="claude-opus-4-1-20250805")  # High performance

def analyze_complexity(state: State):
    """Analyze message complexity"""
    message = state["messages"][-1].content
    # Simple complexity determination
    if len(message) < 50:
        complexity = "simple"
    elif len(message) < 200:
        complexity = "medium"
    else:
        complexity = "complex"
    return {"complexity": complexity}

def route_by_complexity(state: State):
    """Route based on complexity"""
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

# Graph construction
graph = StateGraph(State)
graph.add_node("analyze", analyze_complexity)
graph.add_node("simple_node", simple_node)
graph.add_node("medium_node", medium_node)
graph.add_node("complex_node", complex_node)

graph.set_entry_point("analyze")
graph.add_conditional_edges("analyze", route_by_complexity)

app = graph.compile()
```

## 🔧 Best Practices

### 1. Environment Variable Management

```python
import os

# Flexibly manage models with environment variables
DEFAULT_MODEL = os.getenv("DEFAULT_LLM_MODEL", "claude-sonnet-4-5")
FAST_MODEL = os.getenv("FAST_LLM_MODEL", "claude-haiku-4-5-20251001")
SMART_MODEL = os.getenv("SMART_LLM_MODEL", "claude-opus-4-1-20250805")

# Switch provider based on environment
PROVIDER = os.getenv("LLM_PROVIDER", "anthropic")

if PROVIDER == "anthropic":
    llm = ChatAnthropic(model=DEFAULT_MODEL)
elif PROVIDER == "openai":
    llm = ChatOpenAI(model="gpt-5")
elif PROVIDER == "google":
    llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash")
```

### 2. Fixed Model Version (Production)

```python
# ✅ Recommended: Use dated version (production)
prod_llm = ChatAnthropic(model="claude-sonnet-4-20250514")

# ⚠️ Caution: No version specified (potential unexpected updates)
dev_llm = ChatAnthropic(model="claude-sonnet-4")
```

### 3. Cost Monitoring

```python
from langchain.callbacks import get_openai_callback

# OpenAI cost tracking
with get_openai_callback() as cb:
    response = openai_llm.invoke("question")
    print(f"Total Cost: ${cb.total_cost}")
    print(f"Tokens: {cb.total_tokens}")

# For other providers, track manually
# Refer to each provider's detail pages
```

## 📖 Detailed Documentation

For detailed information on each provider, please refer to the following pages:

- **[Gemini Model ID](06_llm_model_ids_gemini.md)**: Model list, usage, advanced settings, multimodal features
- **[Claude Model ID](06_llm_model_ids_claude.md)**: Model list, platform-specific IDs, tool usage, deprecated model information
- **[OpenAI Model ID](06_llm_model_ids_openai.md)**: Model list, reasoning models, vision features, Azure OpenAI

## 🔗 Reference Links

### Official Documentation

- [Google Gemini API](https://ai.google.dev/gemini-api/docs/models)
- [Anthropic Claude API](https://docs.anthropic.com/en/docs/about-claude/models/overview)
- [OpenAI Platform](https://platform.openai.com/docs/models)

### Integration Guides

- [LangChain Chat Models](https://docs.langchain.com/oss/python/modules/model_io/chat/)
- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)

### Pricing Information

- [Gemini Pricing](https://ai.google.dev/pricing)
- [Claude Pricing](https://www.anthropic.com/pricing)
- [OpenAI Pricing](https://openai.com/pricing)
