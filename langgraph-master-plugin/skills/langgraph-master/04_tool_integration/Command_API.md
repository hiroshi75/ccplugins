# Command API

状態更新と制御フローを統合する高度なAPI。

## 概要

Command APIは、ノードから**状態更新**と**制御フロー**を同時に指定できる機能です。

## 基本的な使用

```python
from langgraph.types import Command

def decision_node(state: State) -> Command:
    """状態を更新して次のノードを指定"""
    result = analyze(state["data"])

    if result["confidence"] > 0.8:
        return Command(
            update={"result": result, "confident": True},
            goto="finalize"
        )
    else:
        return Command(
            update={"result": result, "confident": False},
            goto="review"
        )
```

## Commandオブジェクトのパラメータ

```python
Command(
    update: dict,           # 状態への更新
    goto: str | list[str],  # 次のノード（単数または複数）
    graph: str | None = None  # サブグラフナビゲーション用
)
```

## vs 通常の状態更新

### 通常の方法

```python
def node(state: State) -> dict:
    return {"result": "value"}

# エッジで制御フロー
def route(state: State) -> str:
    if state["result"] == "value":
        return "next_node"
    return "other_node"

builder.add_conditional_edges("node", route, {...})
```

### Command API

```python
def node(state: State) -> Command:
    return Command(
        update={"result": "value"},
        goto="next_node"  # 制御フローも指定
    )

# エッジは不要（Commandが制御）
```

## 応用パターン

### パターン1: 条件付き分岐

```python
def validator(state: State) -> Command:
    """検証して次のノードを決定"""
    is_valid = validate(state["data"])

    if is_valid:
        return Command(
            update={"valid": True},
            goto="process"
        )
    else:
        return Command(
            update={"valid": False, "errors": get_errors(state["data"])},
            goto="error_handler"
        )
```

### パターン2: 並列実行

```python
def fan_out_node(state: State) -> Command:
    """複数のノードへ並列分岐"""
    return Command(
        update={"started": True},
        goto=["worker_a", "worker_b", "worker_c"]  # 並列実行
    )
```

### パターン3: ループ制御

```python
def iterator_node(state: State) -> Command:
    """反復処理"""
    iteration = state.get("iteration", 0) + 1
    result = process_iteration(state["data"], iteration)

    if iteration < state["max_iterations"] and not result["done"]:
        return Command(
            update={"iteration": iteration, "result": result},
            goto="iterator_node"  # 自分自身にループ
        )
    else:
        return Command(
            update={"final_result": result},
            goto=END
        )
```

### パターン4: サブグラフナビゲーション

```python
def sub_node(state: State) -> Command:
    """サブグラフから親グラフへナビゲート"""
    result = process(state["data"])

    if need_parent_intervention(result):
        return Command(
            update={"sub_result": result},
            goto="parent_handler",
            graph=Command.PARENT  # 親グラフへ
        )

    return {"sub_result": result}
```

## ツールとの統合

### ツール実行後の制御

```python
def tool_node_with_command(state: MessagesState) -> Command:
    """ツール実行後に次のアクションを決定"""
    last_message = state["messages"][-1]
    tool_results = []

    for tool_call in last_message.tool_calls:
        tool = tool_map[tool_call["name"]]
        result = tool.invoke(tool_call["args"])

        tool_results.append(
            ToolMessage(
                content=str(result),
                tool_call_id=tool_call["id"]
            )
        )

    # 結果に応じて次のノードを決定
    if any("error" in r.content.lower() for r in tool_results):
        return Command(
            update={"messages": tool_results},
            goto="error_handler"
        )
    else:
        return Command(
            update={"messages": tool_results},
            goto="agent"
        )
```

### ツール内からのCommand

```python
from langgraph.types import interrupt

@tool
def send_email(to: str, subject: str, body: str) -> str:
    """メールを送信（承認付き）"""

    # 承認を求める
    approved = interrupt({
        "action": "send_email",
        "to": to,
        "subject": subject,
        "message": "Approve sending this email?"
    })

    if approved:
        result = actually_send_email(to, subject, body)
        return f"Email sent to {to}"
    else:
        return "Email cancelled by user"
```

## 動的ルーティング

```python
def dynamic_router(state: State) -> Command:
    """状態に基づいて動的にルート選択"""
    score = evaluate(state["data"])

    # スコアに応じてルートを選択
    if score > 0.9:
        route = "expert_handler"
    elif score > 0.7:
        route = "standard_handler"
    else:
        route = "basic_handler"

    return Command(
        update={"confidence_score": score},
        goto=route
    )
```

## エラーリカバリー

```python
def processor_with_fallback(state: State) -> Command:
    """エラー時にフォールバック"""
    try:
        result = risky_operation(state["data"])

        return Command(
            update={"result": result, "error": None},
            goto="success_handler"
        )

    except Exception as e:
        return Command(
            update={"error": str(e)},
            goto="fallback_handler"
        )
```

## 状態マシンの実装

```python
def state_machine_node(state: State) -> Command:
    """状態マシン"""
    current_state = state.get("state", "initial")

    transitions = {
        "initial": ("validate", {"state": "validating"}),
        "validating": ("process" if state.get("valid") else "error", {"state": "processing"}),
        "processing": ("finalize", {"state": "finalizing"}),
        "finalizing": (END, {"state": "done"})
    }

    next_node, update = transitions[current_state]

    return Command(
        update=update,
        goto=next_node
    )
```

## 利点

✅ **簡潔性**: 状態更新と制御フローを1箇所で定義
✅ **可読性**: ノードの意図が明確
✅ **柔軟性**: 動的なルーティングが容易
✅ **デバッグ**: 制御フローが追跡しやすい

## 注意点

⚠️ **複雑さ**: 過度に複雑な条件分岐は避ける
⚠️ **テスト**: 全ての分岐をテストする必要
⚠️ **並列実行**: 並列ノードの順序は不定

## まとめ

Command APIは状態更新と制御フローを統合し、より柔軟で可読性の高いグラフを構築できます。

## 関連ページ

- [01_基本概念/Node.md](../01_基本概念/Node.md) - ノードの基本
- [01_基本概念/Edge.md](../01_基本概念/Edge.md) - エッジとの比較
- [02_グラフアーキテクチャ/Subgraph.md](../02_グラフアーキテクチャ/Subgraph.md) - サブグラフナビゲーション
