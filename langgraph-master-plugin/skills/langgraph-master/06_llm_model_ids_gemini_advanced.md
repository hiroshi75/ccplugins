# Gemini 高度な機能

Google Gemini モデルの高度な設定とマルチモーダル機能。

## コンテキストウィンドウと出力制限

| モデル | コンテキストウィンドウ | 最大出力トークン |
|--------|-------------------|---------------|
| Gemini 3 Pro | - | 64K |
| Gemini 2.5 Pro | 1M (2M 予定) | - |
| Gemini 2.5 Flash | 1M | - |
| Gemini 2.0 Flash | 1M | - |

**ティア別制限**:
- Gemini Advanced / Vertex AI: 1M トークン
- 無料版: 約 32K トークン

## パラメータ設定

```python
from langchain_google_genai import ChatGoogleGenerativeAI

llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash",
    temperature=0.7,          # 創造性 (0.0-1.0)
    top_p=0.9,               # 多様性
    top_k=40,                # サンプリング
    max_tokens=8192,         # 最大出力
)
```

## マルチモーダル機能

### 画像入力

```python
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage

llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash")

message = HumanMessage(
    content=[
        {"type": "text", "text": "この画像には何が写っていますか？"},
        {"type": "image_url", "image_url": "https://example.com/image.jpg"}
    ]
)

response = llm.invoke([message])
```

### 画像生成（Gemini 3.x）

```python
llm = ChatGoogleGenerativeAI(model="google/gemini-3-pro-image-preview")
response = llm.invoke("美しい夕日の風景を生成してください")
```

## ストリーミング

```python
llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash",
    streaming=True
)

for chunk in llm.stream("質問"):
    print(chunk.content, end="", flush=True)
```

## 安全設定

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

## モデル一覧の取得

```python
import google.generativeai as genai
import os

genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))

for model in genai.list_models():
    if 'generateContent' in model.supported_generation_methods:
        print(f"{model.name}: {model.input_token_limit} tokens")
```

## エラーハンドリング

```python
from google.api_core import exceptions

try:
    response = llm.invoke("質問")
except exceptions.ResourceExhausted:
    print("レート制限に達しました")
except exceptions.InvalidArgument as e:
    print(f"無効な引数: {e}")
```

## 参考リンク

- [Gemini API Models](https://ai.google.dev/gemini-api/docs/models)
- [Vertex AI](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models)
