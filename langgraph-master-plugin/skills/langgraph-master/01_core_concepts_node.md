# Node

Python functions that execute individual tasks.

## Overview

Nodes are "processing units" that read state, perform some processing, and return updates.

## Basic Implementation

```python
def my_node(state: State) -> dict:
    # Get information from state
    messages = state["messages"]

    # Execute processing
    result = process_messages(messages)

    # Return updates (don't modify state directly)
    return {"result": result, "count": state["count"] + 1}
```

## Types of Nodes

### 1. LLM Call Node

```python
def llm_node(state: State):
    messages = state["messages"]
    response = llm.invoke(messages)

    return {"messages": [response]}
```

### 2. Tool Execution Node

```python
from langgraph.prebuilt import ToolNode

tools = [search_tool, calculator_tool]
tool_node = ToolNode(tools)
```

### 3. Processing Node

```python
def process_node(state: State):
    data = state["raw_data"]

    # Data processing
    processed = clean_and_transform(data)

    return {"processed_data": processed}
```

## Node Signature

Nodes can accept the following parameters:

```python
from langgraph.types import Command

def advanced_node(
    state: State,
    config: RunnableConfig,  # Optional
) -> dict | Command:
    # Get configuration from config
    thread_id = config["configurable"]["thread_id"]

    # Processing...

    return {"result": result}
```

## Control with Command API

Specify state updates and control flow simultaneously:

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

## Important Principles

1. **Idempotency**: Return the same output for the same input
2. **Return Updates**: Return update contents instead of directly modifying state
3. **Single Responsibility**: Each node does one thing well

## Adding Nodes

```python
from langgraph.graph import StateGraph

builder = StateGraph(State)

# Add nodes
builder.add_node("analyze", analyze_node)
builder.add_node("decide", decide_node)
builder.add_node("execute", execute_node)

# Add tool node
builder.add_node("tools", tool_node)
```

## Error Handling

```python
def robust_node(state: State) -> dict:
    try:
        result = risky_operation(state["data"])
        return {"result": result, "error": None}
    except Exception as e:
        return {"result": None, "error": str(e)}
```

## Related Pages

- [01_core_concepts_state.md](01_core_concepts_state.md) - How to define State
- [01_core_concepts_edge.md](01_core_concepts_edge.md) - Connections between nodes
- [04_tool_integration_overview.md](04_tool_integration_overview.md) - Tool node details
