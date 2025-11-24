# 05. Advanced Features

Advanced features and implementation patterns.

## Overview

By leveraging LangGraph's advanced features, you can build more sophisticated agent systems.

## Key Features

### 1. [Human-in-the-Loop (Approval Flow)](HumanInTheLoop.md)

Pause graph execution and request human intervention:
- Dynamic interrupt
- Static interrupt
- Approval, editing, and rejection flows

### 2. [Streaming](Streaming.md)

Monitor progress in real-time:
- LLM token streaming
- State update streaming
- Custom event streaming

### 3. [Map-Reduce (Parallel Processing Pattern)](MapReduce.md)

Parallel processing of large datasets:
- Dynamic worker generation with Send API
- Result aggregation with Reducers
- Hierarchical parallel processing

## Feature Comparison

| Feature | Use Case | Implementation Complexity |
|---------|----------|--------------------------|
| Human-in-the-Loop | Approval flows, quality control | Medium |
| Streaming | Real-time monitoring, UX improvement | Low |
| Map-Reduce | Large-scale data processing | High |

## Combination Patterns

### Human-in-the-Loop + Streaming

```python
# Stream while requesting approval
for chunk in graph.stream(input, config, stream_mode="values"):
    print(chunk)

    # Pause at interrupt
    if chunk.get("__interrupt__"):
        approval = input("Approve? (y/n): ")
        graph.invoke(None, config, resume=approval == "y")
```

### Map-Reduce + Streaming

```python
# Stream progress of parallel processing
for chunk in graph.stream(
    {"items": large_dataset},
    stream_mode="updates",
    subgraphs=True  # Also show worker progress
):
    print(f"Progress: {chunk}")
```

## Next Steps

For details on each feature, refer to the following pages:

- [HumanInTheLoop.md](HumanInTheLoop.md) - Implementation of approval flows
- [Streaming.md](Streaming.md) - How to use streaming
- [MapReduce.md](MapReduce.md) - Map-Reduce pattern
