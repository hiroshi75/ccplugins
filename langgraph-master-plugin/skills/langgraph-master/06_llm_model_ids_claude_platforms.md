# Claude Platform-Specific Guide

How to use Claude on different cloud platforms.

## Anthropic API (Direct)

### Basic Usage

```python
from langchain_anthropic import ChatAnthropic

llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    anthropic_api_key="sk-ant-..."
)
```

### Listing Models

```python
import anthropic
import os

client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
models = client.models.list()

for model in models.data:
    print(f"{model.id} - {model.display_name}")
```

## Google Vertex AI

### Model ID Format

Vertex AI uses `@` notation:

```
claude-opus-4-1@20250805
claude-sonnet-4@20250514
claude-haiku-4.5@20251001
```

### Usage

```python
from langchain_google_vertexai import ChatVertexAI

llm = ChatVertexAI(
    model="claude-haiku-4.5@20251001",
    project="your-gcp-project",
    location="us-central1"
)
```

### Environment Setup

```bash
# GCP authentication
gcloud auth application-default login

# Environment variables
export GOOGLE_CLOUD_PROJECT="your-project-id"
export GOOGLE_CLOUD_LOCATION="us-central1"
```

## AWS Bedrock

### Model ID Format

Bedrock uses ARN format:

```
anthropic.claude-opus-4-1-20250805-v1:0
anthropic.claude-sonnet-4-20250514-v1:0
anthropic.claude-haiku-4-5-20251001-v1:0
```

### Usage

```python
from langchain_aws import ChatBedrock

llm = ChatBedrock(
    model_id="anthropic.claude-haiku-4-5-20251001-v1:0",
    region_name="us-east-1",
    model_kwargs={
        "temperature": 0.7,
        "max_tokens": 4096
    }
)
```

### Environment Setup

```bash
# AWS CLI configuration
aws configure

# Or environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

## Azure AI (Microsoft Foundry)

> **Release**: Public preview started in November 2025

### Model ID Format

Azure AI uses the same format as Anthropic API:

```
claude-opus-4-1
claude-sonnet-4-5
claude-haiku-4-5
```

### Available Models

- **Claude Opus 4.1** (`claude-opus-4-1`)
- **Claude Sonnet 4.5** (`claude-sonnet-4-5`)
- **Claude Haiku 4.5** (`claude-haiku-4-5`)

### Usage

```python
# Calling Claude using Azure OpenAI SDK
import os
from openai import AzureOpenAI

client = AzureOpenAI(
    azure_endpoint=os.getenv("AZURE_FOUNDRY_ENDPOINT"),
    api_key=os.getenv("AZURE_FOUNDRY_API_KEY"),
    api_version="2024-12-01-preview"
)

# Specify deployment name (default is same as model ID)
response = client.chat.completions.create(
    model="claude-sonnet-4-5",  # Or your custom deployment name
    messages=[
        {"role": "user", "content": "Hello"}
    ]
)
```

### Custom Deployments

You can set custom deployment names in the Foundry portal:

```python
# Using custom deployment name
response = client.chat.completions.create(
    model="my-custom-claude-deployment",
    messages=[...]
)
```

### Environment Setup

```bash
export AZURE_FOUNDRY_ENDPOINT="https://your-foundry-resource.azure.com"
export AZURE_FOUNDRY_API_KEY="your-api-key"
```

### Region Limitations

Currently available in the following regions:
- **East US2**
- **Sweden Central**

Deployment type: **Global Standard**

## Platform-Specific Features

| Platform | Model ID Format | Benefits | Drawbacks |
|----------------|------------|---------|-----------|
| **Anthropic API** | `claude-sonnet-4-5` | Instant access to latest models | Single provider dependency |
| **Vertex AI** | `claude-sonnet-4@20250514` | Integration with GCP services | Complex setup |
| **AWS Bedrock** | `anthropic.claude-sonnet-4-20250514-v1:0` | Integration with AWS ecosystem | Complex model ID format |
| **Azure AI** | `claude-sonnet-4-5` | Azure + GPT and Claude integration | Region limitations |

## Cross-Platform Fallback

```python
from langchain_anthropic import ChatAnthropic
from langchain_google_vertexai import ChatVertexAI
from langchain_aws import ChatBedrock

# Primary and fallback (multi-platform support)
primary = ChatAnthropic(model="claude-sonnet-4-5")
fallback_gcp = ChatVertexAI(
    model="claude-sonnet-4@20250514",
    project="your-project"
)
fallback_aws = ChatBedrock(
    model_id="anthropic.claude-sonnet-4-20250514-v1:0",
    region_name="us-east-1"
)

# Fallback across three platforms
llm = primary.with_fallbacks([fallback_gcp, fallback_aws])
```

## Model ID Comparison Table

| Anthropic API | Vertex AI | AWS Bedrock | Azure AI |
|--------------|-----------|-------------|----------|
| `claude-opus-4-1-20250805` | `claude-opus-4-1@20250805` | `anthropic.claude-opus-4-1-20250805-v1:0` | `claude-opus-4-1` |
| `claude-sonnet-4-5` | `claude-sonnet-4@20250514` | `anthropic.claude-sonnet-4-20250514-v1:0` | `claude-sonnet-4-5` |
| `claude-haiku-4-5-20251001` | `claude-haiku-4.5@20251001` | `anthropic.claude-haiku-4-5-20251001-v1:0` | `claude-haiku-4-5` |

## Reference Links

- [Anthropic API Documentation](https://docs.anthropic.com/)
- [Vertex AI Claude Models](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/claude)
- [AWS Bedrock Claude Models](https://docs.aws.amazon.com/bedrock/latest/userguide/model-parameters-claude.html)
- [Azure AI Claude Documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/how-to/use-foundry-models-claude)
- [Claude in Microsoft Foundry Announcement](https://www.anthropic.com/news/claude-in-microsoft-foundry)
