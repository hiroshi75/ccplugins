# Claude ツール使用ガイド

Claude のツール使用（Function Calling）の実装方法。

## 基本的なツール定義

```python
from langchain_anthropic import ChatAnthropic
from langchain_core.tools import tool

@tool
def get_weather(location: str) -> str:
    """指定された場所の天気を取得します。

    Args:
        location: 天気を知りたい場所（例: "東京"）
    """
    return f"{location}の天気は晴れです"

@tool
def calculate(expression: str) -> float:
    """数式を計算します。

    Args:
        expression: 計算する数式（例: "2 + 2"）
    """
    return eval(expression)

# ツールをバインド
llm = ChatAnthropic(model="claude-sonnet-4-5")
llm_with_tools = llm.bind_tools([get_weather, calculate])

# 使用
response = llm_with_tools.invoke("東京の天気と2+2を教えて")
print(response.tool_calls)
```

## LangGraph でのツール統合

```python
from langgraph.prebuilt import create_react_agent
from langchain_anthropic import ChatAnthropic
from langchain_core.tools import tool

@tool
def search_database(query: str) -> str:
    """データベースを検索します。

    Args:
        query: 検索クエリ
    """
    return f"'{query}' の検索結果"

# エージェント作成
llm = ChatAnthropic(model="claude-sonnet-4-5")
tools = [search_database]

agent = create_react_agent(llm, tools)

# 実行
result = agent.invoke({
    "messages": [("user", "ユーザー情報を検索して")]
})
```

## カスタムツールノードの実装

```python
from langgraph.graph import StateGraph
from langchain_anthropic import ChatAnthropic
from typing import TypedDict, Annotated
from langgraph.graph.message import add_messages

class State(TypedDict):
    messages: Annotated[list, add_messages]

@tool
def get_stock_price(symbol: str) -> float:
    """株価を取得"""
    return 150.25

llm = ChatAnthropic(model="claude-sonnet-4-5")
llm_with_tools = llm.bind_tools([get_stock_price])

def agent_node(state: State):
    response = llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

def tool_node(state: State):
    # ツール呼び出しを実行
    last_message = state["messages"][-1]
    tool_calls = last_message.tool_calls

    results = []
    for tool_call in tool_calls:
        tool_result = get_stock_price.invoke(tool_call["args"])
        results.append({
            "tool_call_id": tool_call["id"],
            "output": tool_result
        })

    return {"messages": results}

# グラフ構築
graph = StateGraph(State)
graph.add_node("agent", agent_node)
graph.add_node("tools", tool_node)
# ... エッジの追加など
```

## ストリーミング + ツール使用

```python
from langchain_anthropic import ChatAnthropic
from langchain_core.tools import tool

@tool
def get_info(topic: str) -> str:
    """情報を取得"""
    return f"{topic} の情報"

llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    streaming=True
)
llm_with_tools = llm.bind_tools([get_info])

for chunk in llm_with_tools.stream("Pythonについて教えて"):
    if hasattr(chunk, 'tool_calls') and chunk.tool_calls:
        print(f"Tool: {chunk.tool_calls}")
    elif chunk.content:
        print(chunk.content, end="", flush=True)
```

## エラーハンドリング

```python
from langchain_anthropic import ChatAnthropic
from langchain_core.tools import tool
import anthropic

@tool
def risky_operation(data: str) -> str:
    """リスクのある操作"""
    if not data:
        raise ValueError("データが必要です")
    return f"処理完了: {data}"

try:
    llm = ChatAnthropic(model="claude-sonnet-4-5")
    llm_with_tools = llm.bind_tools([risky_operation])
    response = llm_with_tools.invoke("操作を実行")
except anthropic.BadRequestError as e:
    print(f"無効なリクエスト: {e}")
except Exception as e:
    print(f"エラー: {e}")
```

## ツールのベストプラクティス

### 1. 明確なドキュメント

```python
@tool
def analyze_sentiment(text: str, language: str = "ja") -> dict:
    """テキストの感情分析を実行します。

    Args:
        text: 分析するテキスト（最大1000文字）
        language: テキストの言語（"ja", "en" など）デフォルトは日本語

    Returns:
        {"sentiment": "positive|negative|neutral", "score": 0.0-1.0}
    """
    # 実装
    return {"sentiment": "positive", "score": 0.8}
```

### 2. 型ヒントの使用

```python
from typing import List, Dict

@tool
def batch_process(items: List[str]) -> Dict[str, int]:
    """複数アイテムをバッチ処理します。

    Args:
        items: 処理するアイテムのリスト

    Returns:
        各アイテムの処理結果の辞書
    """
    return {item: len(item) for item in items}
```

### 3. エラーの適切な処理

```python
@tool
def safe_operation(data: str) -> str:
    """安全な操作"""
    try:
        # 操作の実行
        result = process(data)
        return result
    except ValueError as e:
        return f"入力エラー: {e}"
    except Exception as e:
        return f"予期しないエラー: {e}"
```

## 参考リンク

- [Claude Tool Use Guide](https://docs.anthropic.com/en/docs/tool-use)
- [LangGraph Tools Documentation](https://langchain-ai.github.io/langgraph/concepts/agentic_concepts/)
