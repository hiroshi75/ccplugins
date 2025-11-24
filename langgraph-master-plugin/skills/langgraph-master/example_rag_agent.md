# RAG Agent

Implementation example of a RAG (Retrieval-Augmented Generation) agent with search functionality.

## Complete Code

```python
from typing import Annotated, Literal
from langgraph.graph import StateGraph, START, END, MessagesState
from langgraph.prebuilt import ToolNode
from langgraph.checkpoint.memory import MemorySaver
from langchain_anthropic import ChatAnthropic
from langchain_core.tools import tool

# 1. Define tool
@tool
def retrieve_documents(query: str) -> str:
    """Retrieve relevant documents.

    Args:
        query: Search query
    """
    # In practice, search with vector store, etc.
    # Using dummy data here
    docs = [
        "LangGraph is an agent framework.",
        "StateGraph manages state.",
        "You can extend agents with tools."
    ]

    return "\n".join(docs)

tools = [retrieve_documents]

# 2. Bind tools to LLM
llm = ChatAnthropic(model="claude-sonnet-4-5-20250929")
llm_with_tools = llm.bind_tools(tools)

# 3. Define nodes
def agent_node(state: MessagesState):
    """Agent node"""
    response = llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

def should_continue(state: MessagesState) -> Literal["tools", "end"]:
    """Determine tool usage"""
    last_message = state["messages"][-1]

    if last_message.tool_calls:
        return "tools"
    return "end"

# 4. Build graph
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

# 5. Compile
checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)

# 6. Execute
config = {"configurable": {"thread_id": "rag-session-1"}}

query = "What is LangGraph?"

for chunk in graph.stream(
    {"messages": [{"role": "user", "content": query}]},
    config,
    stream_mode="values"
):
    chunk["messages"][-1].pretty_print()
```

## Execution Flow

```
User Query: "What is LangGraph?"
    ↓
[Agent Node]
    ↓
LLM: "I'll search for information" + ToolCall(retrieve_documents)
    ↓
[Tool Node] ← Execute search
    ↓
ToolMessage: "LangGraph is an agent framework..."
    ↓
[Agent Node] ← Use search results
    ↓
LLM: "LangGraph is a framework for building agents..."
    ↓
END
```

## Extension Examples

### Multiple Search Tools

```python
@tool
def web_search(query: str) -> str:
    """Search the web"""
    return search_web(query)

@tool
def database_search(query: str) -> str:
    """Search database"""
    return search_database(query)

tools = [retrieve_documents, web_search, database_search]
```

### Vector Search Implementation

```python
from langchain_community.vectorstores import FAISS
from langchain_openai import OpenAIEmbeddings

# Initialize vector store
embeddings = OpenAIEmbeddings()
vectorstore = FAISS.from_texts(
    ["LangGraph is an agent framework.", ...],
    embeddings
)

@tool
def semantic_search(query: str) -> str:
    """Perform semantic search"""
    docs = vectorstore.similarity_search(query, k=3)
    return "\n".join([doc.page_content for doc in docs])
```

### Adding Human-in-the-Loop

```python
from langgraph.types import interrupt

@tool
def sensitive_search(query: str) -> str:
    """Search sensitive information (requires approval)"""
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

## Related Pages

- [02_graph_architecture_agent.md](02_graph_architecture_agent.md) - Agent pattern
- [04_tool_integration_overview.md](04_tool_integration_overview.md) - Tool details
- [example_basic_chatbot.md](example_basic_chatbot.md) - Basic chatbot
