# Claude プラットフォーム別ガイド

Claude を異なるクラウドプラットフォームで使用する方法。

## Anthropic API（直接）

### 基本的な使用

```python
from langchain_anthropic import ChatAnthropic

llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    anthropic_api_key="sk-ant-..."
)
```

### モデル一覧の取得

```python
import anthropic
import os

client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
models = client.models.list()

for model in models.data:
    print(f"{model.id} - {model.display_name}")
```

## Google Vertex AI

### モデル ID 形式

Vertex AI では `@` 記法を使用：

```
claude-opus-4-1@20250805
claude-sonnet-4@20250514
claude-haiku-4.5@20251001
```

### 使用方法

```python
from langchain_google_vertexai import ChatVertexAI

llm = ChatVertexAI(
    model="claude-haiku-4.5@20251001",
    project="your-gcp-project",
    location="us-central1"
)
```

### 環境設定

```bash
# GCP 認証
gcloud auth application-default login

# 環境変数
export GOOGLE_CLOUD_PROJECT="your-project-id"
export GOOGLE_CLOUD_LOCATION="us-central1"
```

## AWS Bedrock

### モデル ID 形式

Bedrock では ARN 形式を使用：

```
anthropic.claude-opus-4-1-20250805-v1:0
anthropic.claude-sonnet-4-20250514-v1:0
anthropic.claude-haiku-4-5-20251001-v1:0
```

### 使用方法

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

### 環境設定

```bash
# AWS CLI 設定
aws configure

# または環境変数
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

## Azure AI (Microsoft Foundry)

> **公開**: 2025年11月にパブリックプレビュー開始

### モデル ID 形式

Azure AI では Anthropic API と同じ形式を使用：

```
claude-opus-4-1
claude-sonnet-4-5
claude-haiku-4-5
```

### 利用可能モデル

- **Claude Opus 4.1** (`claude-opus-4-1`)
- **Claude Sonnet 4.5** (`claude-sonnet-4-5`)
- **Claude Haiku 4.5** (`claude-haiku-4-5`)

### 使用方法

```python
# Azure OpenAI SDK を使用した Claude の呼び出し
import os
from openai import AzureOpenAI

client = AzureOpenAI(
    azure_endpoint=os.getenv("AZURE_FOUNDRY_ENDPOINT"),
    api_key=os.getenv("AZURE_FOUNDRY_API_KEY"),
    api_version="2024-12-01-preview"
)

# デプロイメント名を指定（デフォルトはモデルIDと同じ）
response = client.chat.completions.create(
    model="claude-sonnet-4-5",  # または独自のデプロイメント名
    messages=[
        {"role": "user", "content": "こんにちは"}
    ]
)
```

### カスタムデプロイメント

Foundry ポータルで独自のデプロイメント名を設定可能：

```python
# カスタムデプロイメント名の使用例
response = client.chat.completions.create(
    model="my-custom-claude-deployment",
    messages=[...]
)
```

### 環境設定

```bash
export AZURE_FOUNDRY_ENDPOINT="https://your-foundry-resource.azure.com"
export AZURE_FOUNDRY_API_KEY="your-api-key"
```

### リージョン制限

現在、以下のリージョンで利用可能：
- **East US2**
- **Sweden Central**

デプロイメントタイプ: **Global Standard**

## プラットフォーム別の特徴

| プラットフォーム | モデルID形式 | メリット | デメリット |
|----------------|------------|---------|-----------|
| **Anthropic API** | `claude-sonnet-4-5` | 最新モデルに即座にアクセス | 単一プロバイダー依存 |
| **Vertex AI** | `claude-sonnet-4@20250514` | GCP サービスとの統合 | セットアップが複雑 |
| **AWS Bedrock** | `anthropic.claude-sonnet-4-20250514-v1:0` | AWS エコシステムとの統合 | モデル ID 形式が複雑 |
| **Azure AI** | `claude-sonnet-4-5` | Azure + GPT と Claude を統合 | リージョン制限あり |

## プラットフォーム間のフォールバック

```python
from langchain_anthropic import ChatAnthropic
from langchain_google_vertexai import ChatVertexAI
from langchain_aws import ChatBedrock

# メインとフォールバック（複数プラットフォーム対応）
primary = ChatAnthropic(model="claude-sonnet-4-5")
fallback_gcp = ChatVertexAI(
    model="claude-sonnet-4@20250514",
    project="your-project"
)
fallback_aws = ChatBedrock(
    model_id="anthropic.claude-sonnet-4-20250514-v1:0",
    region_name="us-east-1"
)

# 3つのプラットフォームでフォールバック
llm = primary.with_fallbacks([fallback_gcp, fallback_aws])
```

## モデルID対応表

| Anthropic API | Vertex AI | AWS Bedrock | Azure AI |
|--------------|-----------|-------------|----------|
| `claude-opus-4-1-20250805` | `claude-opus-4-1@20250805` | `anthropic.claude-opus-4-1-20250805-v1:0` | `claude-opus-4-1` |
| `claude-sonnet-4-5` | `claude-sonnet-4@20250514` | `anthropic.claude-sonnet-4-20250514-v1:0` | `claude-sonnet-4-5` |
| `claude-haiku-4-5-20251001` | `claude-haiku-4.5@20251001` | `anthropic.claude-haiku-4-5-20251001-v1:0` | `claude-haiku-4-5` |

## 参考リンク

- [Anthropic API Documentation](https://docs.anthropic.com/)
- [Vertex AI Claude Models](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/claude)
- [AWS Bedrock Claude Models](https://docs.aws.amazon.com/bedrock/latest/userguide/model-parameters-claude.html)
- [Azure AI Claude Documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/how-to/use-foundry-models-claude)
- [Claude in Microsoft Foundry Announcement](https://www.anthropic.com/news/claude-in-microsoft-foundry)
