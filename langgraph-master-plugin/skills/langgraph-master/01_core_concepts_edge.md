# Edge（エッジ）

ノード間の遷移を定義する制御フロー。

## 概要

エッジは「次に何をするか」を決定します。ノードが処理を行い、エッジが次の行動を指示する仕組みです。

## エッジの種類

### 1. 通常のエッジ（固定遷移）

常に特定のノードへ遷移します：

```python
from langgraph.graph import START, END

# STARTからnode_aへ
builder.add_edge(START, "node_a")

# node_aからnode_bへ
builder.add_edge("node_a", "node_b")

# node_bから終了
builder.add_edge("node_b", END)
```

### 2. 条件付きエッジ（動的遷移）

状態に基づいて遷移先を決定します：

```python
from typing import Literal

def should_continue(state: State) -> Literal["continue", "end"]:
    if state["iteration"] < state["max_iterations"]:
        return "continue"
    return "end"

# 条件付きエッジを追加
builder.add_conditional_edges(
    "agent",
    should_continue,
    {
        "continue": "tools",  # continueの場合はtoolsへ
        "end": END            # endの場合は終了
    }
)
```

### 3. エントリーポイント

グラフの開始点を定義：

```python
# 単純なエントリー
builder.add_edge(START, "first_node")

# 条件付きエントリー
builder.add_conditional_edges(
    START,
    route_start,
    {
        "path_a": "node_a",
        "path_b": "node_b"
    }
)
```

## 並列実行

複数の出力エッジを持つノードは、次のステップで**すべての宛先ノードが並列実行**されます：

```python
# node_aから複数のノードへ
builder.add_edge("node_a", "node_b")
builder.add_edge("node_a", "node_c")

# node_bとnode_cが並列実行される
```

並列実行の結果を集約するには、Reducerを使用：

```python
from operator import add

class State(TypedDict):
    results: Annotated[list, add]  # 複数のノードからの結果を集約
```

## Commandによるエッジ制御

ノード内から次の遷移先を指定：

```python
from langgraph.types import Command

def smart_node(state: State) -> Command:
    result = analyze(state["data"])

    if result["confidence"] > 0.8:
        return Command(
            update={"result": result},
            goto="finalize"
        )
    else:
        return Command(
            update={"result": result, "needs_review": True},
            goto="human_review"
        )
```

## 条件分岐の実装パターン

### パターン1: ツール呼び出しのループ

```python
def should_continue(state: State) -> Literal["continue", "end"]:
    messages = state["messages"]
    last_message = messages[-1]

    # ツール呼び出しがあれば継続
    if last_message.tool_calls:
        return "continue"
    return "end"

builder.add_conditional_edges(
    "agent",
    should_continue,
    {
        "continue": "tools",
        "end": END
    }
)
```

### パターン2: ルーティング

```python
def route_query(state: State) -> Literal["search", "calculate", "general"]:
    query = state["query"]

    if "計算" in query or "+" in query:
        return "calculate"
    elif "検索" in query:
        return "search"
    return "general"

builder.add_conditional_edges(
    "router",
    route_query,
    {
        "search": "search_node",
        "calculate": "calculator_node",
        "general": "general_node"
    }
)
```

## 重要な原則

1. **明示的な制御フロー**: 遷移は透明で追跡可能にする
2. **型安全性**: Literalで遷移先を明示
3. **並列実行の活用**: 独立したタスクは並列実行

## 関連ページ

- [Node.md](Node.md) - ノードの実装
- [02_グラフアーキテクチャ/03_Routing.md](../02_グラフアーキテクチャ/03_Routing.md) - ルーティングパターン
- [05_応用機能/MapReduce.md](../05_応用機能/MapReduce.md) - 並列処理パターン
