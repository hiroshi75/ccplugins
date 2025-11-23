# OpenAI GPT-5 高度な機能

GPT-5 モデルの高度な設定とマルチモーダル機能。

## パラメータ設定

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    model="gpt-5",
    temperature=0.7,          # 創造性 (0.0-2.0)
    max_tokens=128000,        # 最大出力（GPT-5: 128K）
    top_p=0.9,               # 多様性
    frequency_penalty=0.0,    # 繰り返しペナルティ
    presence_penalty=0.0,     # 話題の多様性
)

# GPT-5 Pro（最大出力が大きい）
llm_pro = ChatOpenAI(
    model="gpt-5-pro",
    max_tokens=272000,        # GPT-5 Pro: 272K
)
```

## コンテキストウィンドウと出力制限

| モデル | コンテキストウィンドウ | 最大出力トークン |
|--------|-------------------|---------------|
| `gpt-5` | 400,000 (API) | 128,000 |
| `gpt-5-mini` | 400,000 (API) | 128,000 |
| `gpt-5-nano` | 400,000 (API) | 128,000 |
| `gpt-5-pro` | 400,000 | 272,000 |
| `gpt-5.1` | 128,000 (ChatGPT) / 400,000 (API) | 128,000 |
| `gpt-5.1-codex` | 400,000 | 128,000 |

**注意**: コンテキストウィンドウは入力＋出力の合計長です。

## ビジョン（画像処理）

```python
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

llm = ChatOpenAI(model="gpt-5")

message = HumanMessage(
    content=[
        {"type": "text", "text": "この画像には何が写っていますか？"},
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

## ツール使用（Function Calling）

```python
from langchain_openai import ChatOpenAI
from langchain_core.tools import tool

@tool
def get_weather(location: str) -> str:
    """天気を取得"""
    return f"{location}の天気は晴れです"

@tool
def calculate(expression: str) -> float:
    """計算"""
    return eval(expression)

llm = ChatOpenAI(model="gpt-5")
llm_with_tools = llm.bind_tools([get_weather, calculate])

response = llm_with_tools.invoke("東京の天気と2+2を教えて")
print(response.tool_calls)
```

## 並列ツール呼び出し

```python
@tool
def get_stock_price(symbol: str) -> float:
    """株価を取得"""
    return 150.25

@tool
def get_company_info(symbol: str) -> dict:
    """企業情報を取得"""
    return {"name": "Apple Inc.", "industry": "Technology"}

llm = ChatOpenAI(model="gpt-5")
llm_with_tools = llm.bind_tools([get_stock_price, get_company_info])

# 複数のツールを並列で呼び出し
response = llm_with_tools.invoke("AAPLの株価と企業情報を教えて")
```

## ストリーミング

```python
llm = ChatOpenAI(
    model="gpt-5",
    streaming=True
)

for chunk in llm.stream("質問"):
    print(chunk.content, end="", flush=True)
```

## JSON モード

```python
llm = ChatOpenAI(
    model="gpt-5",
    model_kwargs={"response_format": {"type": "json_object"}}
)

response = llm.invoke("ユーザー情報をJSON形式で返してください")
```

## GPT-5.1 適応的推論の使用

### Instant モード

速度と精度のバランス：

```python
llm = ChatOpenAI(model="gpt-5.1-instant")

# 適応的に推論時間を調整
response = llm.invoke("この問題を解いて...")
```

### Thinking モード

複雑な問題に対して深い思考：

```python
llm = ChatOpenAI(model="gpt-5.1-thinking")

# より長い思考時間で精度を向上
response = llm.invoke("複雑な数学問題...")
```

## GPT-5 Pro の活用

企業・研究環境向けの拡張推論：

```python
llm = ChatOpenAI(
    model="gpt-5-pro",
    temperature=0.3,  # 精度重視
    max_tokens=272000  # 大量の出力が可能
)

# より詳細で信頼性の高い回答
response = llm.invoke("詳細な分析を...")
```

## コード生成特化モデル

```python
# GitHub Copilot で使用される Codex
llm = ChatOpenAI(model="gpt-5.1-codex")

response = llm.invoke("Pythonでクイックソートを実装して")

# 小型版（高速）
llm_mini = ChatOpenAI(model="gpt-5.1-codex-mini")
```

## トークン使用量の追跡

```python
from langchain.callbacks import get_openai_callback

llm = ChatOpenAI(model="gpt-5")

with get_openai_callback() as cb:
    response = llm.invoke("質問")
    print(f"Total Tokens: {cb.total_tokens}")
    print(f"Prompt Tokens: {cb.prompt_tokens}")
    print(f"Completion Tokens: {cb.completion_tokens}")
    print(f"Total Cost (USD): ${cb.total_cost}")
```

## Azure OpenAI Service

GPT-5 は Azure でも利用可能：

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

### 環境変数（Azure）

```bash
export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com/"
export AZURE_OPENAI_API_KEY="your-azure-api-key"
export AZURE_OPENAI_DEPLOYMENT_NAME="gpt-5"
```

## エラーハンドリング

```python
from langchain_openai import ChatOpenAI
from openai import OpenAIError, RateLimitError

try:
    llm = ChatOpenAI(model="gpt-5")
    response = llm.invoke("質問")
except RateLimitError:
    print("レート制限に達しました")
except OpenAIError as e:
    print(f"OpenAI エラー: {e}")
```

## レート制限の処理

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
response = invoke_with_retry(llm, ["質問"])
```

## 大規模コンテキストの活用

GPT-5 の 400K コンテキストウィンドウを活用：

```python
llm = ChatOpenAI(model="gpt-5")

# 大量の文書を一度に処理
long_document = "..." * 100000  # 長文ドキュメント

response = llm.invoke(f"""
以下の文書を分析してください：

{long_document}

要約と主要なポイントを教えてください。
""")
```

## Compaction 技術

GPT-5.1 では、実質的により長い文脈を扱える技術が導入されています：

```python
# 非常に長い会話履歴やドキュメントの処理
llm = ChatOpenAI(model="gpt-5.1")

# Compaction により効率的に処理
response = llm.invoke(very_long_context)
```

## 参考リンク

- [OpenAI GPT-5 Documentation](https://openai.com/gpt-5/)
- [OpenAI GPT-5.1 Documentation](https://openai.com/index/gpt-5-1/)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [OpenAI Platform Models](https://platform.openai.com/docs/models)
- [Azure OpenAI Documentation](https://learn.microsoft.com/azure/ai-services/openai/)
