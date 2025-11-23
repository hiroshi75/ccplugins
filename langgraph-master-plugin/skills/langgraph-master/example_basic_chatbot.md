# 基本的なチャットボット

LangGraphを使った基本的なチャットボットの実装例。

## 完全なコード

```python
from typing import Annotated
from langgraph.graph import StateGraph, START, END, MessagesState
from langgraph.graph.message import add_messages
from langgraph.checkpoint.memory import MemorySaver
from langchain_anthropic import ChatAnthropic

# 1. LLMの初期化
llm = ChatAnthropic(model="claude-sonnet-4-5-20250929")

# 2. ノードの定義
def chatbot_node(state: MessagesState):
    """チャットボットノード"""
    response = llm.invoke(state["messages"])
    return {"messages": [response]}

# 3. グラフの構築
builder = StateGraph(MessagesState)
builder.add_node("chatbot", chatbot_node)
builder.add_edge(START, "chatbot")
builder.add_edge("chatbot", END)

# 4. チェックポインター付きでコンパイル
checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)

# 5. 実行
config = {"configurable": {"thread_id": "conversation-1"}}

while True:
    user_input = input("User: ")
    if user_input.lower() in ["quit", "exit", "q"]:
        break

    # メッセージを送信
    for chunk in graph.stream(
        {"messages": [{"role": "user", "content": user_input}]},
        config,
        stream_mode="values"
    ):
        chunk["messages"][-1].pretty_print()
```

## 解説

### 1. MessagesState

```python
from langgraph.graph import MessagesState

# MessagesStateは以下と同等
class MessagesState(TypedDict):
    messages: Annotated[list[AnyMessage], add_messages]
```

- `messages`: メッセージのリスト
- `add_messages`: 新しいメッセージを追加するReducer

### 2. チェックポインター

```python
from langgraph.checkpoint.memory import MemorySaver

checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)
```

- 会話の状態を保存
- 同じ`thread_id`で会話を継続

### 3. ストリーミング

```python
for chunk in graph.stream(input, config, stream_mode="values"):
    chunk["messages"][-1].pretty_print()
```

- `stream_mode="values"`: 各ステップ後の完全な状態
- `pretty_print()`: メッセージを見やすく表示

## 拡張例

### システムメッセージの追加

```python
def chatbot_with_system(state: MessagesState):
    """システムメッセージ付き"""
    system_msg = {
        "role": "system",
        "content": "あなたは親切なアシスタントです。"
    }

    response = llm.invoke([system_msg] + state["messages"])
    return {"messages": [response]}
```

### メッセージ履歴の制限

```python
def chatbot_with_limit(state: MessagesState):
    """最新10メッセージのみ使用"""
    recent_messages = state["messages"][-10:]
    response = llm.invoke(recent_messages)
    return {"messages": [response]}
```

## 関連ページ

- [01_基本概念](../01_基本概念/README.md) - 基本概念の理解
- [03_メモリ管理](../03_メモリ管理/README.md) - チェックポインターの詳細
- [rag_agent.md](rag_agent.md) - より高度な例
