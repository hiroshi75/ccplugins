# Claude Advanced Features

Advanced settings and parameter tuning for Claude models.

## Context Window and Output Limits

| Model | Context Window | Max Output Tokens | Notes |
|--------|-------------------|---------------|------|
| `claude-opus-4-1-20250805` | 200,000 | 32,000 | Highest performance |
| `claude-sonnet-4-5` | 1,000,000 | 64,000 | Latest version |
| `claude-sonnet-4-20250514` | 200,000 (1M beta) | 64,000 | 1M with beta header |
| `claude-haiku-4-5-20251001` | 200,000 | 64,000 | Fast version |

**Note**: To use 1M context with Sonnet 4, a beta header is required.

## Parameter Configuration

```python
from langchain_anthropic import ChatAnthropic

llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    temperature=0.7,          # Creativity (0.0-1.0)
    max_tokens=64000,         # Max output (Sonnet 4.5: 64K)
    top_p=0.9,               # Diversity
    top_k=40,                # Sampling
)

# Opus 4.1 (max output 32K)
llm_opus = ChatAnthropic(
    model="claude-opus-4-1-20250805",
    max_tokens=32000,
)
```

## Using 1M Context

### Sonnet 4.5 (Standard)

```python
llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    max_tokens=64000
)

# Can process 1M tokens of context
long_document = "..." * 500000  # Long document
response = llm.invoke(f"Please analyze the following document:\n\n{long_document}")
```

### Sonnet 4 (Beta Header)

```python
# Enable 1M context with beta header
llm = ChatAnthropic(
    model="claude-sonnet-4-20250514",
    max_tokens=64000,
    default_headers={
        "anthropic-beta": "max-tokens-3-5-sonnet-2024-07-15"
    }
)
```

## Streaming

```python
llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    streaming=True
)

for chunk in llm.stream("question"):
    print(chunk.content, end="", flush=True)
```

## Prompt Caching

Cache parts of long prompts for efficiency:

```python
from langchain_anthropic import ChatAnthropic

llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    max_tokens=4096
)

# System prompt for caching
system_prompt = """
You are a professional code reviewer.
Please review according to the following coding guidelines:
[long guidelines...]
"""

# Use cache
response = llm.invoke(
    [
        {"role": "system", "content": system_prompt, "cache_control": {"type": "ephemeral"}},
        {"role": "user", "content": "Please review this code"}
    ]
)
```

**Cache Benefits**:
- Cost reduction (90% off on cache hits)
- Latency reduction (faster processing on reuse)

## Vision (Image Processing)

```python
from langchain_anthropic import ChatAnthropic
from langchain_core.messages import HumanMessage

llm = ChatAnthropic(model="claude-sonnet-4-5")

message = HumanMessage(
    content=[
        {"type": "text", "text": "What's in this image?"},
        {
            "type": "image_url",
            "image_url": {
                "url": "https://example.com/image.jpg"
            }
        }
    ]
)

response = llm.invoke([message])
```

## JSON Mode

When structured output is needed:

```python
llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    model_kwargs={
        "response_format": {"type": "json_object"}
    }
)

response = llm.invoke("Return user information in JSON format")
```

## Token Usage Tracking

```python
from langchain.callbacks import get_openai_callback

llm = ChatAnthropic(model="claude-sonnet-4-5")

with get_openai_callback() as cb:
    response = llm.invoke("question")
    print(f"Total Tokens: {cb.total_tokens}")
    print(f"Prompt Tokens: {cb.prompt_tokens}")
    print(f"Completion Tokens: {cb.completion_tokens}")
```

## Error Handling

```python
from anthropic import AnthropicError, RateLimitError

try:
    llm = ChatAnthropic(model="claude-sonnet-4-5")
    response = llm.invoke("question")
except RateLimitError:
    print("Rate limit reached")
except AnthropicError as e:
    print(f"Anthropic error: {e}")
```

## Rate Limit Handling

```python
from tenacity import retry, wait_exponential, stop_after_attempt
from anthropic import RateLimitError

@retry(
    wait=wait_exponential(multiplier=1, min=4, max=60),
    stop=stop_after_attempt(5),
    retry=lambda e: isinstance(e, RateLimitError)
)
def invoke_with_retry(llm, messages):
    return llm.invoke(messages)

llm = ChatAnthropic(model="claude-sonnet-4-5")
response = invoke_with_retry(llm, ["question"])
```

## Listing Models

```python
import anthropic
import os

client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
models = client.models.list()

for model in models.data:
    print(f"{model.id} - {model.display_name}")
```

## Cost Optimization

### Cost Management by Model Selection

```python
# Low-cost version (simple tasks)
llm_cheap = ChatAnthropic(model="claude-haiku-4-5-20251001")

# Balanced version (general tasks)
llm_balanced = ChatAnthropic(model="claude-sonnet-4-5")

# High-performance version (complex tasks)
llm_powerful = ChatAnthropic(model="claude-opus-4-1-20250805")

# Select based on task
def get_llm_for_task(complexity):
    if complexity == "simple":
        return llm_cheap
    elif complexity == "medium":
        return llm_balanced
    else:
        return llm_powerful
```

### Cost Reduction with Prompt Caching

```python
# Cache long system prompt
system = {"role": "system", "content": long_guidelines, "cache_control": {"type": "ephemeral"}}

# Reuse cache across multiple calls (90% cost reduction)
for user_input in user_inputs:
    response = llm.invoke([system, {"role": "user", "content": user_input}])
```

## Leveraging Large Context

```python
llm = ChatAnthropic(model="claude-sonnet-4-5")

# Process large documents at once (1M token support)
documents = load_large_documents()  # Large document collection

response = llm.invoke(f"""
Please analyze the following multiple documents:

{documents}

Tell me the main themes and conclusions.
""")
```

## Reference Links

- [Claude API Documentation](https://docs.anthropic.com/)
- [Anthropic API Reference](https://docs.anthropic.com/en/api/)
- [Claude Models Overview](https://docs.anthropic.com/en/docs/about-claude/models/overview)
- [Prompt Caching Guide](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
