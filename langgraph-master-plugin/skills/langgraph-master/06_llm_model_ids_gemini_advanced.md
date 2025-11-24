# Gemini Advanced Features

Advanced configuration and multimodal features for Google Gemini models.

## Context Window and Output Limits

| Model | Context Window | Max Output Tokens |
|--------|-------------------|---------------|
| Gemini 3 Pro | - | 64K |
| Gemini 2.5 Pro | 1M (2M planned) | - |
| Gemini 2.5 Flash | 1M | - |
| Gemini 2.0 Flash | 1M | - |

**Tier-based Limits**:
- Gemini Advanced / Vertex AI: 1M tokens
- Free tier: ~32K tokens

## Parameter Configuration

```python
from langchain_google_genai import ChatGoogleGenerativeAI

llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash",
    temperature=0.7,          # Creativity (0.0-1.0)
    top_p=0.9,               # Diversity
    top_k=40,                # Sampling
    max_tokens=8192,         # Max output
)
```

## Multimodal Features

### Image Input

```python
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage

llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash")

message = HumanMessage(
    content=[
        {"type": "text", "text": "What is in this image?"},
        {"type": "image_url", "image_url": "https://example.com/image.jpg"}
    ]
)

response = llm.invoke([message])
```

### Image Generation (Gemini 3.x)

```python
llm = ChatGoogleGenerativeAI(model="google/gemini-3-pro-image-preview")
response = llm.invoke("Generate a beautiful sunset landscape")
```

## Streaming

```python
llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash",
    streaming=True
)

for chunk in llm.stream("Question"):
    print(chunk.content, end="", flush=True)
```

## Safety Settings

```python
from langchain_google_genai import (
    ChatGoogleGenerativeAI,
    HarmBlockThreshold,
    HarmCategory
)

llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash",
    safety_settings={
        HarmCategory.HARM_CATEGORY_HARASSMENT: HarmBlockThreshold.BLOCK_NONE,
        HarmCategory.HARM_CATEGORY_HATE_SPEECH: HarmBlockThreshold.BLOCK_NONE,
    }
)
```

## Retrieving Model List

```python
import google.generativeai as genai
import os

genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))

for model in genai.list_models():
    if 'generateContent' in model.supported_generation_methods:
        print(f"{model.name}: {model.input_token_limit} tokens")
```

## Error Handling

```python
from google.api_core import exceptions

try:
    response = llm.invoke("Question")
except exceptions.ResourceExhausted:
    print("Rate limit reached")
except exceptions.InvalidArgument as e:
    print(f"Invalid argument: {e}")
```

## Reference Links

- [Gemini API Models](https://ai.google.dev/gemini-api/docs/models)
- [Vertex AI](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models)
