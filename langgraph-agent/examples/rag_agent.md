# RAGエージェント

検索機能を持つRAG（Retrieval-Augmented Generation）エージェントの実装例。

## 完全なコード

```python
from typing import Annotated, Literal
from langgraph.graph import StateGraph, START, END, MessagesState
from langgraph.prebuilt import ToolNode
from langgraph.checkpoint.memory import MemorySaver
from langchain_anthropic import ChatAnthropic
from langchain_core.tools import tool

# 1. ツールの定義
@tool
def retrieve_documents(query: str) -> str:
    """関連する文書を検索します。

    Args:
        query: 検索クエリ
    """
    # 実際にはベクトルストアなどで検索
    # ここではダミーデータ
    docs = [
        "LangGraphはエージェントフレームワークです。",
        "StateGraphで状態管理を行います。",
        "ツールを使ってエージェントを拡張できます。"
    ]

    return "\n".join(docs)

tools = [retrieve_documents]

# 2. LLMにツールをバインド
llm = ChatAnthropic(model="claude-sonnet-4-5-20250929")
llm_with_tools = llm.bind_tools(tools)

# 3. ノードの定義
def agent_node(state: MessagesState):
    """エージェントノード"""
    response = llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

def should_continue(state: MessagesState) -> Literal["tools", "end"]:
    """ツール使用の判定"""
    last_message = state["messages"][-1]

    if last_message.tool_calls:
        return "tools"
    return "end"

# 4. グラフの構築
builder = StateGraph(MessagesState)

builder.add_node("agent", agent_node)
builder.add_node("tools", ToolNode(tools))

builder.add_edge(START, "agent")
builder.add_conditional_edges(
    "agent",
    should_continue,
    {
        "tools": "tools",
        "end": END
    }
)
builder.add_edge("tools", "agent")

# 5. コンパイル
checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)

# 6. 実行
config = {"configurable": {"thread_id": "rag-session-1"}}

query = "LangGraphとは何ですか？"

for chunk in graph.stream(
    {"messages": [{"role": "user", "content": query}]},
    config,
    stream_mode="values"
):
    chunk["messages"][-1].pretty_print()
```

## 実行フロー

```
User Query: "LangGraphとは何ですか？"
    ↓
[Agent Node]
    ↓
LLM: "情報を検索します" + ToolCall(retrieve_documents)
    ↓
[Tool Node] ← 検索実行
    ↓
ToolMessage: "LangGraphはエージェントフレームワークです。..."
    ↓
[Agent Node] ← 検索結果を使用
    ↓
LLM: "LangGraphは、エージェントを構築するためのフレームワークです..."
    ↓
END
```

## 拡張例

### 複数の検索ツール

```python
@tool
def web_search(query: str) -> str:
    """ウェブを検索"""
    return search_web(query)

@tool
def database_search(query: str) -> str:
    """データベースを検索"""
    return search_database(query)

tools = [retrieve_documents, web_search, database_search]
```

### ベクトル検索の実装

```python
from langchain_community.vectorstores import FAISS
from langchain_openai import OpenAIEmbeddings

# ベクトルストアの初期化
embeddings = OpenAIEmbeddings()
vectorstore = FAISS.from_texts(
    ["LangGraphはエージェントフレームワークです。", ...],
    embeddings
)

@tool
def semantic_search(query: str) -> str:
    """セマンティック検索を実行"""
    docs = vectorstore.similarity_search(query, k=3)
    return "\n".join([doc.page_content for doc in docs])
```

### Human-in-the-Loopの追加

```python
from langgraph.types import interrupt

@tool
def sensitive_search(query: str) -> str:
    """機密情報の検索（承認必要）"""
    approved = interrupt({
        "action": "sensitive_search",
        "query": query,
        "message": "Approve this sensitive search?"
    })

    if approved:
        return perform_sensitive_search(query)
    else:
        return "Search cancelled by user"
```

## 関連ページ

- [02_グラフアーキテクチャ/06_Agent.md](../02_グラフアーキテクチャ/06_Agent.md) - エージェントパターン
- [04_ツール統合](../04_ツール統合/README.md) - ツールの詳細
- [basic_chatbot.md](basic_chatbot.md) - 基本的なチャットボット
