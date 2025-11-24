# 01. Core Concepts

Understanding the three core elements of LangGraph.

## Overview

LangGraph is a framework that models agent workflows as **graphs**. By decomposing complex workflows into **discrete steps (nodes)**, it achieves the following:

- **Improved Resilience**: Create checkpoints at node boundaries
- **Enhanced Visibility**: Enable state inspection between each step
- **Independent Testing**: Easy unit testing of individual nodes
- **Error Handling**: Apply different strategies for each error type

## Three Core Elements

### 1. [State](01_core_concepts_state.md)
- Memory shared across all nodes in the graph
- Snapshot of the current execution state
- Defined with TypedDict or Pydantic models

### 2. [Node](01_core_concepts_node.md)
- Python functions that execute individual tasks
- Receive the current state and return updates
- Basic unit of processing

### 3. [Edge](01_core_concepts_edge.md)
- Define transitions between nodes
- Fixed transitions or conditional branching
- Determine control flow

## Design Philosophy

The core concept of LangGraph is **decomposition into discrete steps**:

```python
# Split agent into individual nodes
graph = StateGraph(State)
graph.add_node("analyze", analyze_node)  # Analysis step
graph.add_node("decide", decide_node)     # Decision step
graph.add_node("execute", execute_node)   # Execution step
```

This approach allows each step to operate independently, building a robust system as a whole.

## Important Principles

1. **Store Raw Data**: Store raw data in State, format prompts dynamically within nodes
2. **Return Updates**: Nodes return update contents instead of directly modifying state
3. **Transparent Control Flow**: Explicitly declare the next destination with Command objects

## Next Steps

For details on each element, refer to the following pages:

- [01_core_concepts_state.md](01_core_concepts_state.md) - State management details
- [01_core_concepts_node.md](01_core_concepts_node.md) - How to implement nodes
- [01_core_concepts_edge.md](01_core_concepts_edge.md) - Edges and control flow
