# Agent（自律的ツール使用）

LLMがツール選択を動的に判断し、予測不可能な問題解決に対応するパターン。

## 概要

Agentパターンは、LLMが**ReAct**（Reasoning + Acting）に従い、ツールを動的に選択・実行して問題を解決します。

## ReActパターン

**ReAct** = Reasoning（推論） + Acting（行動）

1. **Reasoning**: 「次に何をすべきか？」を考える
2. **Acting**: ツールを使って行動する
3. **Observing**: 結果を観察する
4. 最終回答を出すまで **1-3を繰り返す**

## 実装例: 基本的なエージェント

```python
from langgraph.graph import StateGraph, START, END, MessagesState
from langgraph.prebuilt import ToolNode
from typing import Literal

# ツールの定義
@tool
def search(query: str) -> str:
    """ウェブ検索を実行"""
    return perform_search(query)

@tool
def calculator(expression: str) -> float:
    """計算を実行"""
    return eval(expression)

tools = [search, calculator]

# エージェントノード
def agent_node(state: MessagesState):
    """LLMがツール使用を判断"""
    messages = state["messages"]

    # ツールを持つLLMを呼び出し
    response = llm_with_tools.invoke(messages)

    return {"messages": [response]}

# 継続判定
def should_continue(state: MessagesState) -> Literal["tools", "end"]:
    """ツール呼び出しがあるか確認"""
    last_message = state["messages"][-1]

    # ツール呼び出しがあれば継続
    if last_message.tool_calls:
        return "tools"

    # なければ終了（最終回答）
    return "end"

# グラフ構築
builder = StateGraph(MessagesState)

builder.add_node("agent", agent_node)
builder.add_node("tools", ToolNode(tools))

builder.add_edge(START, "agent")

# ReActループ
builder.add_conditional_edges(
    "agent",
    should_continue,
    {
        "tools": "tools",
        "end": END
    }
)

# ツール実行後はエージェントに戻る
builder.add_edge("tools", "agent")

graph = builder.compile()
```

## ツールの定義

### 基本的なツール

```python
from langchain_core.tools import tool

@tool
def get_weather(location: str) -> str:
    """指定された場所の天気を取得します。

    Args:
        location: 都市名（例: "Tokyo", "New York"）
    """
    return fetch_weather_data(location)

@tool
def send_email(to: str, subject: str, body: str) -> str:
    """メールを送信します。

    Args:
        to: 送信先メールアドレス
        subject: 件名
        body: 本文
    """
    return send_email_api(to, subject, body)
```

### 構造化出力ツール

```python
from pydantic import BaseModel, Field

class WeatherResponse(BaseModel):
    location: str
    temperature: float
    condition: str
    humidity: int

@tool(response_format="content_and_artifact")
def get_detailed_weather(location: str) -> tuple[str, WeatherResponse]:
    """詳細な天気情報を取得"""
    data = fetch_weather_data(location)

    weather = WeatherResponse(
        location=location,
        temperature=data["temp"],
        condition=data["condition"],
        humidity=data["humidity"]
    )

    message = f"{location}の天気: {weather.condition}, {weather.temperature}°C"

    return message, weather
```

## 応用パターン

### パターン1: 複数エージェントの協調

```python
# 専門エージェント
def research_agent(state: State):
    """研究専門エージェント"""
    response = research_llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

def coding_agent(state: State):
    """コーディング専門エージェント"""
    response = coding_llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

# ルーター
def route_to_specialist(state: State) -> Literal["research", "coding"]:
    """タスクに応じて専門家を選択"""
    last_message = state["messages"][-1]

    if "調査" in last_message.content or "検索" in last_message.content:
        return "research"
    elif "コード" in last_message.content or "実装" in last_message.content:
        return "coding"

    return "research"  # デフォルト
```

### パターン2: メモリ付きエージェント

```python
from langgraph.checkpoint.memory import MemorySaver

class AgentState(TypedDict):
    messages: Annotated[list, add_messages]
    context: dict  # 長期記憶

def agent_with_memory(state: AgentState):
    """コンテキストを活用するエージェント"""
    messages = state["messages"]
    context = state.get("context", {})

    # コンテキストをプロンプトに追加
    system_message = f"Context: {context}"

    response = llm_with_tools.invoke([
        {"role": "system", "content": system_message},
        *messages
    ])

    return {"messages": [response]}

# チェックポインター付きでコンパイル
checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)
```

### パターン3: Human-in-the-Loopエージェント

```python
from langgraph.types import interrupt

def careful_agent(state: State):
    """重要な行動前に人間に確認"""
    response = llm_with_tools.invoke(state["messages"])

    # 重要なツール呼び出しの場合は確認
    if response.tool_calls:
        for tool_call in response.tool_calls:
            if tool_call["name"] in ["send_email", "delete_data"]:
                # 人間の承認を待つ
                approved = interrupt({
                    "action": tool_call["name"],
                    "args": tool_call["args"],
                    "message": "Approve this action?"
                })

                if not approved:
                    return {
                        "messages": [
                            {"role": "assistant", "content": "Action cancelled by user"}
                        ]
                    }

    return {"messages": [response]}
```

### パターン4: エラー処理とリトライ

```python
class RobustAgentState(TypedDict):
    messages: Annotated[list, add_messages]
    retry_count: int
    errors: list[str]

def robust_tool_node(state: RobustAgentState):
    """エラーハンドリング付きツール実行"""
    last_message = state["messages"][-1]
    tool_results = []

    for tool_call in last_message.tool_calls:
        try:
            result = execute_tool(tool_call)
            tool_results.append(result)

        except Exception as e:
            error_msg = f"Tool {tool_call['name']} failed: {str(e)}"

            # リトライ可能か確認
            if state.get("retry_count", 0) < 3:
                tool_results.append({
                    "tool_call_id": tool_call["id"],
                    "error": error_msg,
                    "retry": True
                })
            else:
                tool_results.append({
                    "tool_call_id": tool_call["id"],
                    "error": "Max retries exceeded",
                    "retry": False
                })

    return {
        "messages": tool_results,
        "retry_count": state.get("retry_count", 0) + 1
    }
```

## ツールの高度な機能

### 動的ツール生成

```python
def create_tool_for_api(api_spec: dict):
    """API仕様からツールを動的生成"""

    @tool
    def dynamic_api_tool(**kwargs) -> str:
        f"""
        {api_spec['description']}

        Args: {api_spec['parameters']}
        """
        return call_api(api_spec['endpoint'], kwargs)

    return dynamic_api_tool
```

### ツールの条件付き使用

```python
def conditional_agent(state: State):
    """状況に応じてツールセットを変更"""
    context = state.get("context", {})

    # 初心者には基本ツールのみ
    if context.get("user_level") == "beginner":
        tools = [basic_search, simple_calculator]
    # 上級者には高度なツールも
    else:
        tools = [advanced_search, scientific_calculator, code_executor]

    llm_with_selected_tools = llm.bind_tools(tools)
    response = llm_with_selected_tools.invoke(state["messages"])

    return {"messages": [response]}
```

## 利点

✅ **柔軟性**: 予測不可能な問題に動的に対応
✅ **自律性**: LLMが最適なツールと戦略を選択
✅ **拡張性**: ツールを追加するだけで機能拡張
✅ **適応力**: 複雑なマルチステップタスクを解決

## 注意点

⚠️ **予測不可能**: 同じ入力でも異なる行動をする可能性
⚠️ **コスト**: 複数回のLLM呼び出しが発生
⚠️ **無限ループ**: 適切な終了条件が必要
⚠️ **ツール誤用**: LLMがツールを誤って使用する可能性

## ベストプラクティス

1. **明確なツール説明**: ツールのdocstringを詳細に記述
2. **最大イテレーション**: ループの上限を設定
3. **エラーハンドリング**: ツール実行のエラーを適切に処理
4. **ログ記録**: エージェントの行動を追跡可能に

## まとめ

Agentパターンは**動的で不確定な問題解決**に最適です。ReActループでツールを使いながら、自律的に問題を解決します。

## 関連ページ

- [Workflow_vs_Agent.md](Workflow_vs_Agent.md) - WorkflowとAgentの違い
- [04_ツール統合](../04_ツール統合/README.md) - ツールの詳細
- [05_応用機能/HumanInTheLoop.md](../05_応用機能/HumanInTheLoop.md) - 人間の介入
