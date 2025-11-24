# Anthropic Claude Model IDs

List of available model IDs for the Anthropic Claude API.

> **Last Updated**: 2025-11-24

## Model List

### Claude 4.x (2025)

| Model ID | Context | Max Output | Release | Features |
|-----------|------------|---------|---------|------|
| `claude-opus-4-1-20250805` | 200K | 32K | 2025-08 | Most powerful. Complex reasoning & code generation |
| `claude-sonnet-4-5` | 1M | 64K | 2025-09 | Latest balanced model (recommended) |
| `claude-sonnet-4-20250514` | 200K (1M beta) | 64K | 2025-05 | Production recommended (date-fixed) |
| `claude-haiku-4-5-20251001` | 200K | 64K | 2025-10 | Fast & low-cost |

**Model Characteristics**:
- **Opus**: Highest performance, complex tasks (200K context)
- **Sonnet**: Balanced, general-purpose (1M context)
- **Haiku**: Fast & low-cost ($1/M input, $5/M output)

## Basic Usage

```python
from langchain_anthropic import ChatAnthropic

# Recommended: Latest Sonnet
llm = ChatAnthropic(model="claude-sonnet-4-5")

# Production: Date-fixed version
llm = ChatAnthropic(model="claude-sonnet-4-20250514")

# Fast & low-cost
llm = ChatAnthropic(model="claude-haiku-4-5-20251001")

# Highest performance
llm = ChatAnthropic(model="claude-opus-4-1-20250805")
```

### Environment Variables

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

## Model Selection Guide

| Use Case | Recommended Model |
|------|-----------|
| Cost-focused | `claude-haiku-4-5-20251001` |
| Balanced | `claude-sonnet-4-5` |
| Performance-focused | `claude-opus-4-1-20250805` |
| Production | `claude-sonnet-4-20250514` (date-fixed) |

## Claude Features

### 1. Large Context Window

Claude Sonnet 4.5 supports **1M tokens** context window:

| Model | Standard Context | Max Output | Notes |
|--------|---------------|---------|------|
| Sonnet 4.5 | 1M | 64K | Latest version |
| Sonnet 4 | 200K (1M beta) | 64K | 1M available with beta header |
| Opus 4.1 | 200K | 32K | High-performance version |
| Haiku 4.5 | 200K | 64K | Fast version |

```python
# Using 1M context (Sonnet 4.5)
llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    max_tokens=64000  # Max output: 64K
)

# Enable 1M context for Sonnet 4 (beta)
llm = ChatAnthropic(
    model="claude-sonnet-4-20250514",
    default_headers={"anthropic-beta": "max-tokens-3-5-sonnet-2024-07-15"}
)
```

### 2. Date-Fixed Versions

For production environments, date-fixed versions are recommended to prevent unexpected updates:

```python
# ✅ Recommended (production)
llm = ChatAnthropic(model="claude-sonnet-4-20250514")

# ⚠️ Caution (development only)
llm = ChatAnthropic(model="claude-sonnet-4")
```

### 3. Tool Use (Function Calling)

Claude has powerful tool use capabilities (see [Tool Use Guide](06_llm_model_ids_claude_tools.md) for details).

### 4. Multi-Platform Support

Available on multiple cloud platforms (see [Platform-Specific Guide](06_llm_model_ids_claude_platforms.md) for details):

- Anthropic API (direct)
- Google Vertex AI
- AWS Bedrock
- Azure AI (Microsoft Foundry)

## Deprecated Models

| Model | Deprecation Date | Migration Target |
|--------|-------|--------|
| Claude 3 Opus | 2025-07-21 | `claude-opus-4-1-20250805` |
| Claude 3 Sonnet | 2025-07-21 | `claude-sonnet-4-5` |
| Claude 2.1 | 2025-07-21 | `claude-sonnet-4-5` |

## Detailed Documentation

For advanced settings and parameters:
- **[Claude Advanced Features](06_llm_model_ids_claude_advanced.md)** - Parameter configuration, streaming, caching
- **[Platform-Specific Guide](06_llm_model_ids_claude_platforms.md)** - Usage on Vertex AI, AWS Bedrock, Azure AI
- **[Tool Use Guide](06_llm_model_ids_claude_tools.md)** - Function Calling implementation

## Reference Links

- [Claude API Official](https://docs.anthropic.com/en/docs/about-claude/models/overview)
- [Anthropic Console](https://console.anthropic.com/)
- [LangChain Integration](https://docs.langchain.com/oss/python/integrations/chat/anthropic)
