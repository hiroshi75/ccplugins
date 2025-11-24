# Basic Chatbot

Implementation example of a basic chatbot using LangGraph.

## Complete Code

```python
from typing import Annotated
from langgraph.graph import StateGraph, START, END, MessagesState
from langgraph.graph.message import add_messages
from langgraph.checkpoint.memory import MemorySaver
from langchain_anthropic import ChatAnthropic

# 1. Initialize LLM
llm = ChatAnthropic(model="claude-sonnet-4-5-20250929")

# 2. Define node
def chatbot_node(state: MessagesState):
    """Chatbot node"""
    response = llm.invoke(state["messages"])
    return {"messages": [response]}

# 3. Build graph
builder = StateGraph(MessagesState)
builder.add_node("chatbot", chatbot_node)
builder.add_edge(START, "chatbot")
builder.add_edge("chatbot", END)

# 4. Compile with checkpointer
checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)

# 5. Execute
config = {"configurable": {"thread_id": "conversation-1"}}

while True:
    user_input = input("User: ")
    if user_input.lower() in ["quit", "exit", "q"]:
        break

    # Send message
    for chunk in graph.stream(
        {"messages": [{"role": "user", "content": user_input}]},
        config,
        stream_mode="values"
    ):
        chunk["messages"][-1].pretty_print()
```

## Explanation

### 1. MessagesState

```python
from langgraph.graph import MessagesState

# MessagesState is equivalent to:
class MessagesState(TypedDict):
    messages: Annotated[list[AnyMessage], add_messages]
```

- `messages`: List of messages
- `add_messages`: Reducer that adds new messages

### 2. Checkpointer

```python
from langgraph.checkpoint.memory import MemorySaver

checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)
```

- Saves conversation state
- Continues conversation with same `thread_id`

### 3. Streaming

```python
for chunk in graph.stream(input, config, stream_mode="values"):
    chunk["messages"][-1].pretty_print()
```

- `stream_mode="values"`: Complete state after each step
- `pretty_print()`: Displays messages in a readable format

## Extension Examples

### Adding System Message

```python
def chatbot_with_system(state: MessagesState):
    """With system message"""
    system_msg = {
        "role": "system",
        "content": "You are a helpful assistant."
    }

    response = llm.invoke([system_msg] + state["messages"])
    return {"messages": [response]}
```

### Limiting Message History

```python
def chatbot_with_limit(state: MessagesState):
    """Use only the latest 10 messages"""
    recent_messages = state["messages"][-10:]
    response = llm.invoke(recent_messages)
    return {"messages": [response]}
```

## Related Pages

- [01_core_concepts_overview.md](01_core_concepts_overview.md) - Understanding fundamental concepts
- [03_memory_management_overview.md](03_memory_management_overview.md) - Checkpointer details
- [example_rag_agent.md](example_rag_agent.md) - More advanced example
