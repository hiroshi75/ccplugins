# OpenAI GPT-5 Advanced Features

Advanced settings and multimodal features for GPT-5 models.

## Parameter Settings

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    model="gpt-5",
    temperature=0.7,          # Creativity (0.0-2.0)
    max_tokens=128000,        # Max output (GPT-5: 128K)
    top_p=0.9,               # Diversity
    frequency_penalty=0.0,    # Repetition penalty
    presence_penalty=0.0,     # Topic diversity
)

# GPT-5 Pro (larger max output)
llm_pro = ChatOpenAI(
    model="gpt-5-pro",
    max_tokens=272000,        # GPT-5 Pro: 272K
)
```

## Context Window and Output Limits

| Model | Context Window | Max Output Tokens |
|--------|-------------------|---------------|
| `gpt-5` | 400,000 (API) | 128,000 |
| `gpt-5-mini` | 400,000 (API) | 128,000 |
| `gpt-5-nano` | 400,000 (API) | 128,000 |
| `gpt-5-pro` | 400,000 | 272,000 |
| `gpt-5.1` | 128,000 (ChatGPT) / 400,000 (API) | 128,000 |
| `gpt-5.1-codex` | 400,000 | 128,000 |

**Note**: Context window is the combined length of input + output.

## Vision (Image Processing)

```python
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

llm = ChatOpenAI(model="gpt-5")

message = HumanMessage(
    content=[
        {"type": "text", "text": "What is shown in this image?"},
        {
            "type": "image_url",
            "image_url": {
                "url": "https://example.com/image.jpg",
                "detail": "high"  # "low", "high", "auto"
            }
        }
    ]
)

response = llm.invoke([message])
```

## Tool Use (Function Calling)

```python
from langchain_openai import ChatOpenAI
from langchain_core.tools import tool

@tool
def get_weather(location: str) -> str:
    """Get weather"""
    return f"The weather in {location} is sunny"

@tool
def calculate(expression: str) -> float:
    """Calculate"""
    return eval(expression)

llm = ChatOpenAI(model="gpt-5")
llm_with_tools = llm.bind_tools([get_weather, calculate])

response = llm_with_tools.invoke("Tell me the weather in Tokyo and 2+2")
print(response.tool_calls)
```

## Parallel Tool Calling

```python
@tool
def get_stock_price(symbol: str) -> float:
    """Get stock price"""
    return 150.25

@tool
def get_company_info(symbol: str) -> dict:
    """Get company information"""
    return {"name": "Apple Inc.", "industry": "Technology"}

llm = ChatOpenAI(model="gpt-5")
llm_with_tools = llm.bind_tools([get_stock_price, get_company_info])

# Call multiple tools in parallel
response = llm_with_tools.invoke("Tell me the stock price and company info for AAPL")
```

## Streaming

```python
llm = ChatOpenAI(
    model="gpt-5",
    streaming=True
)

for chunk in llm.stream("Question"):
    print(chunk.content, end="", flush=True)
```

## JSON Mode

```python
llm = ChatOpenAI(
    model="gpt-5",
    model_kwargs={"response_format": {"type": "json_object"}}
)

response = llm.invoke("Return user information in JSON format")
```

## Using GPT-5.1 Adaptive Reasoning

### Instant Mode

Balance between speed and accuracy:

```python
llm = ChatOpenAI(model="gpt-5.1-instant")

# Adaptively adjusts reasoning time
response = llm.invoke("Solve this problem...")
```

### Thinking Mode

Deep thought for complex problems:

```python
llm = ChatOpenAI(model="gpt-5.1-thinking")

# Improves accuracy with longer thinking time
response = llm.invoke("Complex math problem...")
```

## Leveraging GPT-5 Pro

Extended reasoning for enterprise and research environments:

```python
llm = ChatOpenAI(
    model="gpt-5-pro",
    temperature=0.3,  # Precision-focused
    max_tokens=272000  # Large output possible
)

# More detailed and reliable responses
response = llm.invoke("Detailed analysis of...")
```

## Code Generation Specialized Models

```python
# Codex used in GitHub Copilot
llm = ChatOpenAI(model="gpt-5.1-codex")

response = llm.invoke("Implement quicksort in Python")

# Compact version (fast)
llm_mini = ChatOpenAI(model="gpt-5.1-codex-mini")
```

## Tracking Token Usage

```python
from langchain.callbacks import get_openai_callback

llm = ChatOpenAI(model="gpt-5")

with get_openai_callback() as cb:
    response = llm.invoke("Question")
    print(f"Total Tokens: {cb.total_tokens}")
    print(f"Prompt Tokens: {cb.prompt_tokens}")
    print(f"Completion Tokens: {cb.completion_tokens}")
    print(f"Total Cost (USD): ${cb.total_cost}")
```

## Azure OpenAI Service

GPT-5 is also available on Azure:

```python
from langchain_openai import AzureChatOpenAI

llm = AzureChatOpenAI(
    azure_endpoint="https://your-resource.openai.azure.com/",
    api_key="your-azure-api-key",
    api_version="2024-12-01-preview",
    deployment_name="gpt-5",
    model="gpt-5"
)
```

### Environment Variables (Azure)

```bash
export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com/"
export AZURE_OPENAI_API_KEY="your-azure-api-key"
export AZURE_OPENAI_DEPLOYMENT_NAME="gpt-5"
```

## Error Handling

```python
from langchain_openai import ChatOpenAI
from openai import OpenAIError, RateLimitError

try:
    llm = ChatOpenAI(model="gpt-5")
    response = llm.invoke("Question")
except RateLimitError:
    print("Rate limit reached")
except OpenAIError as e:
    print(f"OpenAI error: {e}")
```

## Handling Rate Limits

```python
from tenacity import retry, wait_exponential, stop_after_attempt
from openai import RateLimitError

@retry(
    wait=wait_exponential(multiplier=1, min=4, max=60),
    stop=stop_after_attempt(5),
    retry=lambda e: isinstance(e, RateLimitError)
)
def invoke_with_retry(llm, messages):
    return llm.invoke(messages)

llm = ChatOpenAI(model="gpt-5")
response = invoke_with_retry(llm, ["Question"])
```

## Leveraging Large Context

Utilizing GPT-5's 400K context window:

```python
llm = ChatOpenAI(model="gpt-5")

# Process large amounts of documents at once
long_document = "..." * 100000  # Long document

response = llm.invoke(f"""
Please analyze the following document:

{long_document}

Provide a summary and key points.
""")
```

## Compaction Technology

GPT-5.1 introduces technology that effectively handles longer contexts:

```python
# Processing very long conversation histories or documents
llm = ChatOpenAI(model="gpt-5.1")

# Efficiently processed through Compaction
response = llm.invoke(very_long_context)
```

## Reference Links

- [OpenAI GPT-5 Documentation](https://openai.com/gpt-5/)
- [OpenAI GPT-5.1 Documentation](https://openai.com/index/gpt-5-1/)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [OpenAI Platform Models](https://platform.openai.com/docs/models)
- [Azure OpenAI Documentation](https://learn.microsoft.com/azure/ai-services/openai/)
