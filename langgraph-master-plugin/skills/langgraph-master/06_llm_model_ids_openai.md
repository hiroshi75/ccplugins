# OpenAI GPT Model IDs

List of available model IDs for the OpenAI API.

> **Last Updated**: 2025-11-24

## Model List

### GPT-5 Series

> **Released**: August 2025

| Model ID | Context | Max Output | Features |
|-----------|------------|---------|------|
| `gpt-5` | 400K | 128K | Full-featured. High-quality general-purpose tasks |
| `gpt-5-pro` | 400K | 272K | Extended reasoning version. Complex enterprise and research use cases |
| `gpt-5-mini` | 400K | 128K | Small high-speed version. Low latency |
| `gpt-5-nano` | 400K | 128K | Ultra-lightweight version. Resource optimized |

**Performance**: Achieved 94.6% on AIME 2025, 74.9% on SWE-bench Verified
**Note**: Context window is the combined length of input + output

### GPT-5.1 Series (Latest Update)

| Model ID | Context | Max Output | Features |
|-----------|------------|---------|------|
| `gpt-5.1` | 128K (ChatGPT) / 400K (API) | 128K | Balance of intelligence and speed |
| `gpt-5.1-instant` | 128K / 400K | 128K | Adaptive reasoning. Balances speed and accuracy |
| `gpt-5.1-thinking` | 128K / 400K | 128K | Adjusts thinking time based on problem complexity |
| `gpt-5.1-mini` | 128K / 400K | 128K | Compact version |
| `gpt-5.1-codex` | 400K | 128K | Code-specialized version (for GitHub Copilot) |
| `gpt-5.1-codex-mini` | 400K | 128K | Code-specialized compact version |

## Basic Usage

```python
from langchain_openai import ChatOpenAI

# Latest: GPT-5
llm = ChatOpenAI(model="gpt-5")

# Latest update: GPT-5.1
llm = ChatOpenAI(model="gpt-5.1")

# High performance: GPT-5 Pro
llm = ChatOpenAI(model="gpt-5-pro")

# Cost-conscious: Compact version
llm = ChatOpenAI(model="gpt-5-mini")

# Ultra-lightweight
llm = ChatOpenAI(model="gpt-5-nano")
```

### Environment Variables

```bash
export OPENAI_API_KEY="sk-..."
```

## Model Selection Guide

| Use Case | Recommended Model |
|------|-----------|
| **Maximum Performance** | `gpt-5-pro` |
| **General-Purpose Tasks** | `gpt-5` or `gpt-5.1` |
| **Cost-Conscious** | `gpt-5-mini` |
| **Ultra-Lightweight** | `gpt-5-nano` |
| **Adaptive Reasoning** | `gpt-5.1-instant` or `gpt-5.1-thinking` |
| **Code Generation** | `gpt-5.1-codex` or `gpt-5` |

## GPT-5 Features

### 1. Large Context Window

GPT-5 series has a **400K token** context window:

```python
llm = ChatOpenAI(
    model="gpt-5",
    max_tokens=128000  # Max output: 128K
)

# GPT-5 Pro has a maximum output of 272K
llm_pro = ChatOpenAI(
    model="gpt-5-pro",
    max_tokens=272000
)
```

**Use Cases**:
- Batch processing of long documents
- Analysis of large codebases
- Maintaining long conversation histories

### 2. Software On-Demand Generation

```python
llm = ChatOpenAI(model="gpt-5")
response = llm.invoke("Generate a web application")
```

### 3. Advanced Reasoning Capabilities

**Performance Metrics**:
- AIME 2025: 94.6%
- SWE-bench Verified: 74.9%
- Aider Polyglot: 88%
- MMMU: 84.2%

### 4. GPT-5.1 Adaptive Reasoning

Automatically adjusts thinking time based on problem complexity:

```python
# Balance between speed and accuracy
llm = ChatOpenAI(model="gpt-5.1-instant")

# Tasks requiring deep thought
llm = ChatOpenAI(model="gpt-5.1-thinking")
```

**Compaction Technology**: GPT-5.1 introduces technology that effectively handles longer contexts.

### 5. GPT-5 Pro - Extended Reasoning

Advanced reasoning for enterprise and research environments. **Maximum output of 272K tokens**:

```python
llm = ChatOpenAI(
    model="gpt-5-pro",
    max_tokens=272000  # Larger output possible than other models
)
# More detailed and reliable responses
```

### 6. Code-Specialized Models

```python
# Used in GitHub Copilot
llm = ChatOpenAI(model="gpt-5.1-codex")

# Compact version
llm = ChatOpenAI(model="gpt-5.1-codex-mini")
```

## Multimodal Support

GPT-5 supports images and audio (see [Advanced Features](06_llm_model_ids_openai_advanced.md) for details).

## JSON Mode

When structured output is needed:

```python
llm = ChatOpenAI(
    model="gpt-5",
    model_kwargs={"response_format": {"type": "json_object"}}
)
```

## Retrieving Model List

```python
from openai import OpenAI
import os

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
models = client.models.list()

for model in models:
    if model.id.startswith("gpt-5"):
        print(model.id)
```

## Detailed Documentation

For advanced settings, vision features, and Azure OpenAI:
- **[OpenAI Advanced Features](06_llm_model_ids_openai_advanced.md)**

## Reference Links

- [OpenAI GPT-5](https://openai.com/index/introducing-gpt-5/)
- [OpenAI GPT-5.1](https://openai.com/index/gpt-5-1/)
- [OpenAI Platform](https://platform.openai.com/)
- [LangChain Integration](https://docs.langchain.com/oss/python/integrations/chat/openai)
