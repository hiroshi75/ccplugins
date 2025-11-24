# Edge

Control flow that defines transitions between nodes.

## Overview

Edges determine "what to do next". Nodes perform processing, and edges dictate the next action.

## Types of Edges

### 1. Normal Edges (Fixed Transitions)

Always transition to a specific node:

```python
from langgraph.graph import START, END

# From START to node_a
builder.add_edge(START, "node_a")

# From node_a to node_b
builder.add_edge("node_a", "node_b")

# From node_b to end
builder.add_edge("node_b", END)
```

### 2. Conditional Edges (Dynamic Transitions)

Determine the destination based on state:

```python
from typing import Literal

def should_continue(state: State) -> Literal["continue", "end"]:
    if state["iteration"] < state["max_iterations"]:
        return "continue"
    return "end"

# Add conditional edge
builder.add_conditional_edges(
    "agent",
    should_continue,
    {
        "continue": "tools",  # Go to tools if continue
        "end": END            # End if end
    }
)
```

### 3. Entry Points

Define the starting point of the graph:

```python
# Simple entry
builder.add_edge(START, "first_node")

# Conditional entry
builder.add_conditional_edges(
    START,
    route_start,
    {
        "path_a": "node_a",
        "path_b": "node_b"
    }
)
```

## Parallel Execution

Nodes with multiple outgoing edges will have **all destination nodes execute in parallel** in the next step:

```python
# From node_a to multiple nodes
builder.add_edge("node_a", "node_b")
builder.add_edge("node_a", "node_c")

# node_b and node_c execute in parallel
```

To aggregate results from parallel execution, use a Reducer:

```python
from operator import add

class State(TypedDict):
    results: Annotated[list, add]  # Aggregate results from multiple nodes
```

## Edge Control with Command

Specify the next destination from within a node:

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

## Conditional Branching Implementation Patterns

### Pattern 1: Tool Call Loop

```python
def should_continue(state: State) -> Literal["continue", "end"]:
    messages = state["messages"]
    last_message = messages[-1]

    # Continue if there are tool calls
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

### Pattern 2: Routing

```python
def route_query(state: State) -> Literal["search", "calculate", "general"]:
    query = state["query"]

    if "calculate" in query or "+" in query:
        return "calculate"
    elif "search" in query:
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

## Important Principles

1. **Explicit Control Flow**: Transitions should be transparent and traceable
2. **Type Safety**: Explicitly specify destinations with Literal
3. **Leverage Parallel Execution**: Execute independent tasks in parallel

## Related Pages

- [01_core_concepts_node.md](01_core_concepts_node.md) - Node implementation
- [02_graph_architecture_routing.md](02_graph_architecture_routing.md) - Routing patterns
- [05_advanced_features_map_reduce.md](05_advanced_features_map_reduce.md) - Parallel processing patterns
