# 04. ツール統合

外部ツールの統合と実行制御。

## 概要

LangGraphでは、LLMが**ツール**を呼び出すことで、外部システムとやり取りできます。ツールは検索、計算、API呼び出しなど、様々な機能を提供します。

## 主要コンポーネント

### 1. [Tool Definition（ツール定義）](Tool_Definition.md)

ツールの定義方法：
- `@tool`デコレータ
- 関数の説明とパラメータ
- 構造化出力

### 2. [Tool Node（ツールノード）](Tool_Node.md)

ツールを実行するノード：
- `ToolNode`の使用
- エラーハンドリング
- カスタムツールノード

### 3. [Command API](Command_API.md)

ツール実行の制御：
- 状態更新と制御フローの統合
- ツールからの遷移制御

## 基本的な実装

```python
from langchain_core.tools import tool
from langgraph.prebuilt import ToolNode
from langgraph.graph import MessagesState, StateGraph

# 1. ツール定義
@tool
def search(query: str) -> str:
    """ウェブ検索を実行します。

    Args:
        query: 検索クエリ
    """
    return perform_search(query)

@tool
def calculator(expression: str) -> float:
    """数式を計算します。

    Args:
        expression: 計算式（例: "2 + 2"）
    """
    return eval(expression)

tools = [search, calculator]

# 2. LLMにツールをバインド
llm_with_tools = llm.bind_tools(tools)

# 3. エージェントノード
def agent(state: MessagesState):
    response = llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

# 4. ツールノード
tool_node = ToolNode(tools)

# 5. グラフ構築
builder = StateGraph(MessagesState)
builder.add_node("agent", agent)
builder.add_node("tools", tool_node)

# 6. 条件付きエッジ
def should_continue(state: MessagesState):
    last_message = state["messages"][-1]
    if last_message.tool_calls:
        return "tools"
    return END

builder.add_edge(START, "agent")
builder.add_conditional_edges("agent", should_continue)
builder.add_edge("tools", "agent")

graph = builder.compile()
```

## ツールの種類

### 検索ツール

```python
@tool
def web_search(query: str) -> str:
    """ウェブを検索"""
    return search_api(query)
```

### 計算ツール

```python
@tool
def calculator(expression: str) -> float:
    """数式を計算"""
    return eval(expression)
```

### APIツール

```python
@tool
def get_weather(city: str) -> dict:
    """天気情報を取得"""
    return weather_api(city)
```

### データベースツール

```python
@tool
def query_database(sql: str) -> list[dict]:
    """データベースをクエリ"""
    return execute_sql(sql)
```

## ツール実行のフロー

```
User Query
    ↓
[Agent Node]
    ↓
LLM decides: Use tool?
    ↓ Yes
[Tool Node] ← Execute tool
    ↓
[Agent Node] ← Tool result
    ↓
LLM decides: Continue?
    ↓ No
Final Answer
```

## 重要な原則

1. **明確な説明**: ツールのdocstringを詳細に記述
2. **エラーハンドリング**: ツール実行のエラーを適切に処理
3. **型安全性**: パラメータの型を明示
4. **承認フロー**: 重要なツールには Human-in-the-Loop を組み込む

## 次のステップ

各コンポーネントの詳細については、以下のページを参照してください：

- [Tool_Definition.md](Tool_Definition.md) - ツールの定義方法
- [Tool_Node.md](Tool_Node.md) - ツールノードの実装
- [Command_API.md](Command_API.md) - Command APIの使用
