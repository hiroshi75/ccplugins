# Node（ノード）

個別のタスクを実行するPython関数。

## 概要

ノードは「処理単位」で、状態を読み込み、何らかの処理を行い、更新を返します。

## 基本的な実装

```python
def my_node(state: State) -> dict:
    # 状態から情報を取得
    messages = state["messages"]

    # 処理を実行
    result = process_messages(messages)

    # 更新を返す（状態を直接変更しない）
    return {"result": result, "count": state["count"] + 1}
```

## ノードの種類

### 1. LLM呼び出しノード

```python
def llm_node(state: State):
    messages = state["messages"]
    response = llm.invoke(messages)

    return {"messages": [response]}
```

### 2. ツール実行ノード

```python
from langgraph.prebuilt import ToolNode

tools = [search_tool, calculator_tool]
tool_node = ToolNode(tools)
```

### 3. 処理ノード

```python
def process_node(state: State):
    data = state["raw_data"]

    # データ処理
    processed = clean_and_transform(data)

    return {"processed_data": processed}
```

## ノードのシグネチャ

ノードは以下のパラメータを受け取れます：

```python
from langgraph.types import Command

def advanced_node(
    state: State,
    config: RunnableConfig,  # オプション
) -> dict | Command:
    # configから設定を取得
    thread_id = config["configurable"]["thread_id"]

    # 処理...

    return {"result": result}
```

## Command APIによる制御

状態更新と制御フローを同時に指定：

```python
from langgraph.types import Command

def decision_node(state: State) -> Command:
    if state["should_continue"]:
        return Command(
            update={"status": "continuing"},
            goto="next_node"
        )
    else:
        return Command(
            update={"status": "done"},
            goto=END
        )
```

## 重要な原則

1. **冪等性**: 同じ入力に対して同じ出力を返す
2. **更新を返す**: 状態を直接変更せず、更新内容を返す
3. **単一責任**: 各ノードは1つのことをうまく行う

## ノードの追加

```python
from langgraph.graph import StateGraph

builder = StateGraph(State)

# ノードを追加
builder.add_node("analyze", analyze_node)
builder.add_node("decide", decide_node)
builder.add_node("execute", execute_node)

# ツールノードを追加
builder.add_node("tools", tool_node)
```

## エラーハンドリング

```python
def robust_node(state: State) -> dict:
    try:
        result = risky_operation(state["data"])
        return {"result": result, "error": None}
    except Exception as e:
        return {"result": None, "error": str(e)}
```

## 関連ページ

- [State.md](State.md) - Stateの定義方法
- [Edge.md](Edge.md) - ノード間の接続
- [04_ツール統合](../04_ツール統合/README.md) - ツールノードの詳細
