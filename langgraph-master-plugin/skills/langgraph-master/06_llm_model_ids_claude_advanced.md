# Claude 高度な機能

Claude モデルの高度な設定とパラメータ調整。

## コンテキストウィンドウと出力制限

| モデル | コンテキストウィンドウ | 最大出力トークン | 備考 |
|--------|-------------------|---------------|------|
| `claude-opus-4-1-20250805` | 200,000 | 32,000 | 最高性能 |
| `claude-sonnet-4-5` | 1,000,000 | 64,000 | 最新版 |
| `claude-sonnet-4-20250514` | 200,000 (1M beta) | 64,000 | beta ヘッダーで 1M |
| `claude-haiku-4-5-20251001` | 200,000 | 64,000 | 高速版 |

**注意**: Sonnet 4 で 1M コンテキストを使用する場合は beta ヘッダーが必要です。

## パラメータ設定

```python
from langchain_anthropic import ChatAnthropic

llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    temperature=0.7,          # 創造性 (0.0-1.0)
    max_tokens=64000,         # 最大出力（Sonnet 4.5: 64K）
    top_p=0.9,               # 多様性
    top_k=40,                # サンプリング
)

# Opus 4.1（最大出力 32K）
llm_opus = ChatAnthropic(
    model="claude-opus-4-1-20250805",
    max_tokens=32000,
)
```

## 1M コンテキストの利用

### Sonnet 4.5（標準）

```python
llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    max_tokens=64000
)

# 1M トークンのコンテキストを処理可能
long_document = "..." * 500000  # 長文ドキュメント
response = llm.invoke(f"以下の文書を分析してください：\n\n{long_document}")
```

### Sonnet 4（beta ヘッダー）

```python
# beta ヘッダーで 1M コンテキストを有効化
llm = ChatAnthropic(
    model="claude-sonnet-4-20250514",
    max_tokens=64000,
    default_headers={
        "anthropic-beta": "max-tokens-3-5-sonnet-2024-07-15"
    }
)
```

## ストリーミング

```python
llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    streaming=True
)

for chunk in llm.stream("質問"):
    print(chunk.content, end="", flush=True)
```

## プロンプトキャッシング

長いプロンプトの一部をキャッシュして効率化：

```python
from langchain_anthropic import ChatAnthropic

llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    max_tokens=4096
)

# キャッシュ対象のシステムプロンプト
system_prompt = """
あなたは専門的なコードレビューアです。
以下のコーディング規約に従ってレビューしてください：
[長いガイドライン...]
"""

# キャッシュを利用
response = llm.invoke(
    [
        {"role": "system", "content": system_prompt, "cache_control": {"type": "ephemeral"}},
        {"role": "user", "content": "このコードをレビューしてください"}
    ]
)
```

**キャッシュの利点**:
- コスト削減（キャッシュヒット時 90% オフ）
- レイテンシ削減（再利用時の処理時間短縮）

## ビジョン（画像処理）

```python
from langchain_anthropic import ChatAnthropic
from langchain_core.messages import HumanMessage

llm = ChatAnthropic(model="claude-sonnet-4-5")

message = HumanMessage(
    content=[
        {"type": "text", "text": "この画像には何が写っていますか？"},
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

## JSON モード

構造化された出力が必要な場合：

```python
llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    model_kwargs={
        "response_format": {"type": "json_object"}
    }
)

response = llm.invoke("ユーザー情報をJSON形式で返してください")
```

## トークン使用量の追跡

```python
from langchain.callbacks import get_openai_callback

llm = ChatAnthropic(model="claude-sonnet-4-5")

with get_openai_callback() as cb:
    response = llm.invoke("質問")
    print(f"Total Tokens: {cb.total_tokens}")
    print(f"Prompt Tokens: {cb.prompt_tokens}")
    print(f"Completion Tokens: {cb.completion_tokens}")
```

## エラーハンドリング

```python
from anthropic import AnthropicError, RateLimitError

try:
    llm = ChatAnthropic(model="claude-sonnet-4-5")
    response = llm.invoke("質問")
except RateLimitError:
    print("レート制限に達しました")
except AnthropicError as e:
    print(f"Anthropic エラー: {e}")
```

## レート制限の処理

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
response = invoke_with_retry(llm, ["質問"])
```

## モデル一覧の取得

```python
import anthropic
import os

client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
models = client.models.list()

for model in models.data:
    print(f"{model.id} - {model.display_name}")
```

## コスト最適化

### モデル選択によるコスト管理

```python
# 低コスト版（単純なタスク）
llm_cheap = ChatAnthropic(model="claude-haiku-4-5-20251001")

# バランス版（汎用タスク）
llm_balanced = ChatAnthropic(model="claude-sonnet-4-5")

# 高性能版（複雑なタスク）
llm_powerful = ChatAnthropic(model="claude-opus-4-1-20250805")

# タスクに応じて使い分け
def get_llm_for_task(complexity):
    if complexity == "simple":
        return llm_cheap
    elif complexity == "medium":
        return llm_balanced
    else:
        return llm_powerful
```

### プロンプトキャッシングによるコスト削減

```python
# 長いシステムプロンプトをキャッシュ
system = {"role": "system", "content": long_guidelines, "cache_control": {"type": "ephemeral"}}

# 複数回の呼び出しでキャッシュを再利用（90% コスト削減）
for user_input in user_inputs:
    response = llm.invoke([system, {"role": "user", "content": user_input}])
```

## 大規模コンテキストの活用

```python
llm = ChatAnthropic(model="claude-sonnet-4-5")

# 大量の文書を一度に処理（1M トークン対応）
documents = load_large_documents()  # 長文ドキュメント群

response = llm.invoke(f"""
以下の複数の文書を分析してください：

{documents}

主要なテーマと結論を教えてください。
""")
```

## 参考リンク

- [Claude API Documentation](https://docs.anthropic.com/)
- [Anthropic API Reference](https://docs.anthropic.com/en/api/)
- [Claude Models Overview](https://docs.anthropic.com/en/docs/about-claude/models/overview)
- [Prompt Caching Guide](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
