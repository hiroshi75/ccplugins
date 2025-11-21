# Tool Node（ツールノード）

ツールを実行するノードの実装。

## ToolNode（組み込み）

最もシンプルな方法：

```python
from langgraph.prebuilt import ToolNode

tools = [search_tool, calculator_tool]
tool_node = ToolNode(tools)

# グラフに追加
builder.add_node("tools", tool_node)
```

## 動作の仕組み

ToolNodeは：
1. 最後のメッセージから`tool_calls`を抽出
2. 各ツールを実行
3. 結果を`ToolMessage`として返す

```python
# 入力
{
    "messages": [
        AIMessage(tool_calls=[
            {"name": "search", "args": {"query": "weather"}, "id": "1"}
        ])
    ]
}

# ToolNodeの実行

# 出力
{
    "messages": [
        ToolMessage(
            content="Sunny, 25°C",
            tool_call_id="1"
        )
    ]
}
```

## カスタムツールノード

より細かい制御が必要な場合：

```python
def custom_tool_node(state: MessagesState):
    """カスタムツールノード"""
    last_message = state["messages"][-1]
    tool_results = []

    for tool_call in last_message.tool_calls:
        # ツールを検索
        tool = tool_map.get(tool_call["name"])

        if not tool:
            result = f"Tool {tool_call['name']} not found"
        else:
            try:
                # ツールを実行
                result = tool.invoke(tool_call["args"])
            except Exception as e:
                result = f"Error: {str(e)}"

        # ToolMessageを作成
        tool_results.append(
            ToolMessage(
                content=str(result),
                tool_call_id=tool_call["id"]
            )
        )

    return {"messages": tool_results}
```

## エラーハンドリング

### 基本的なエラー処理

```python
def robust_tool_node(state: MessagesState):
    """エラーハンドリング付きツールノード"""
    last_message = state["messages"][-1]
    tool_results = []

    for tool_call in last_message.tool_calls:
        try:
            tool = tool_map[tool_call["name"]]
            result = tool.invoke(tool_call["args"])

            tool_results.append(
                ToolMessage(
                    content=str(result),
                    tool_call_id=tool_call["id"]
                )
            )

        except KeyError:
            # ツールが見つからない
            tool_results.append(
                ToolMessage(
                    content=f"Error: Tool '{tool_call['name']}' not found",
                    tool_call_id=tool_call["id"]
                )
            )

        except Exception as e:
            # 実行エラー
            tool_results.append(
                ToolMessage(
                    content=f"Error executing tool: {str(e)}",
                    tool_call_id=tool_call["id"]
                )
            )

    return {"messages": tool_results}
```

### リトライロジック

```python
import time

def tool_node_with_retry(state: MessagesState, max_retries: int = 3):
    """リトライ付きツールノード"""
    last_message = state["messages"][-1]
    tool_results = []

    for tool_call in last_message.tool_calls:
        tool = tool_map[tool_call["name"]]
        retry_count = 0

        while retry_count < max_retries:
            try:
                result = tool.invoke(tool_call["args"])

                tool_results.append(
                    ToolMessage(
                        content=str(result),
                        tool_call_id=tool_call["id"]
                    )
                )
                break

            except TransientError as e:
                retry_count += 1
                if retry_count >= max_retries:
                    tool_results.append(
                        ToolMessage(
                            content=f"Failed after {max_retries} retries: {str(e)}",
                            tool_call_id=tool_call["id"]
                        )
                    )
                else:
                    time.sleep(2 ** retry_count)  # Exponential backoff

            except Exception as e:
                # リトライ不可能なエラー
                tool_results.append(
                    ToolMessage(
                        content=f"Error: {str(e)}",
                        tool_call_id=tool_call["id"]
                    )
                )
                break

    return {"messages": tool_results}
```

## ツールの条件付き実行

```python
def conditional_tool_node(state: MessagesState, *, store):
    """権限チェック付きツールノード"""
    user_id = state.get("user_id")
    user = store.get(("users", user_id), "profile")

    last_message = state["messages"][-1]
    tool_results = []

    for tool_call in last_message.tool_calls:
        tool = tool_map[tool_call["name"]]

        # 権限チェック
        if not has_permission(user, tool.name):
            tool_results.append(
                ToolMessage(
                    content=f"Permission denied for tool '{tool.name}'",
                    tool_call_id=tool_call["id"]
                )
            )
            continue

        # 実行
        result = tool.invoke(tool_call["args"])
        tool_results.append(
            ToolMessage(
                content=str(result),
                tool_call_id=tool_call["id"]
            )
        )

    return {"messages": tool_results}
```

## ツール実行のログ記録

```python
import logging

logger = logging.getLogger(__name__)

def logged_tool_node(state: MessagesState):
    """ログ記録付きツールノード"""
    last_message = state["messages"][-1]
    tool_results = []

    for tool_call in last_message.tool_calls:
        tool = tool_map[tool_call["name"]]

        logger.info(
            f"Executing tool: {tool.name}",
            extra={
                "tool": tool.name,
                "args": tool_call["args"],
                "call_id": tool_call["id"]
            }
        )

        try:
            start = time.time()
            result = tool.invoke(tool_call["args"])
            duration = time.time() - start

            logger.info(
                f"Tool completed: {tool.name}",
                extra={
                    "tool": tool.name,
                    "duration": duration,
                    "success": True
                }
            )

            tool_results.append(
                ToolMessage(
                    content=str(result),
                    tool_call_id=tool_call["id"]
                )
            )

        except Exception as e:
            logger.error(
                f"Tool failed: {tool.name}",
                extra={
                    "tool": tool.name,
                    "error": str(e)
                },
                exc_info=True
            )

            tool_results.append(
                ToolMessage(
                    content=f"Error: {str(e)}",
                    tool_call_id=tool_call["id"]
                )
            )

    return {"messages": tool_results}
```

## 並列ツール実行

```python
from concurrent.futures import ThreadPoolExecutor

def parallel_tool_node(state: MessagesState):
    """ツールを並列実行"""
    last_message = state["messages"][-1]

    def execute_tool(tool_call):
        tool = tool_map[tool_call["name"]]
        try:
            result = tool.invoke(tool_call["args"])
            return ToolMessage(
                content=str(result),
                tool_call_id=tool_call["id"]
            )
        except Exception as e:
            return ToolMessage(
                content=f"Error: {str(e)}",
                tool_call_id=tool_call["id"]
            )

    with ThreadPoolExecutor(max_workers=5) as executor:
        tool_results = list(executor.map(
            execute_tool,
            last_message.tool_calls
        ))

    return {"messages": tool_results}
```

## まとめ

ToolNodeはツールを実行し、結果をToolMessageとして返します。エラーハンドリング、権限チェック、ログ記録などを追加できます。

## 関連ページ

- [Tool_Definition.md](Tool_Definition.md) - ツールの定義
- [Command_API.md](Command_API.md) - Command APIとの統合
- [05_応用機能/HumanInTheLoop.md](../05_応用機能/HumanInTheLoop.md) - 承認フローとの組み合わせ
