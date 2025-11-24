# Orchestrator-Worker (Master-Worker)

A pattern where an orchestrator decomposes tasks and delegates them to multiple workers.

## Overview

Orchestrator-Worker is a pattern where a **master node** decomposes tasks into multiple subtasks and delegates them in parallel to **worker nodes**. Also known as the Map-Reduce pattern.

## Use Cases

- Parallel processing of multiple documents
- Dividing large tasks into smaller subtasks
- Distributed processing of datasets
- Parallel API calls

## Implementation Example: Summarizing Multiple Documents

```python
from langgraph.types import Send
from typing import TypedDict, Annotated
from operator import add

class State(TypedDict):
    documents: list[str]
    summaries: Annotated[list[str], add]
    final_summary: str

class WorkerState(TypedDict):
    document: str
    summary: str

def orchestrator_node(state: State):
    """Decompose task and delegate to workers"""
    # Send each document to a worker
    return [
        Send("worker", {"document": doc})
        for doc in state["documents"]
    ]

def worker_node(state: WorkerState):
    """Summarize individual document"""
    summary = llm.invoke(f"Summarize: {state['document']}")
    return {"summaries": [summary]}

def reducer_node(state: State):
    """Integrate all summaries"""
    all_summaries = "\n".join(state["summaries"])
    final = llm.invoke(f"Create final summary from:\n{all_summaries}")
    return {"final_summary": final}

# Build graph
builder = StateGraph(State)

builder.add_node("orchestrator", orchestrator_node)
builder.add_node("worker", worker_node)
builder.add_node("reducer", reducer_node)

# Orchestrator to workers (dynamic)
builder.add_edge(START, "orchestrator")

# Workers to aggregation node
builder.add_edge("worker", "reducer")
builder.add_edge("reducer", END)

graph = builder.compile()
```

## Using the Send API

Generate **node instances dynamically** with `Send` objects:

```python
def orchestrator(state: State):
    # Generate worker instance for each item
    return [
        Send("worker", {"item": item, "index": i})
        for i, item in enumerate(state["items"])
    ]
```

## Advanced Patterns

### Pattern 1: Hierarchical Processing

```python
def master_orchestrator(state: State):
    """Master delegates to multiple sub-orchestrators"""
    return [
        Send("sub_orchestrator", {"category": cat, "items": items})
        for cat, items in group_by_category(state["all_items"])
    ]

def sub_orchestrator(state: SubState):
    """Sub-orchestrator delegates to individual workers"""
    return [
        Send("worker", {"item": item})
        for item in state["items"]
    ]
```

### Pattern 2: Conditional Worker Selection

```python
def smart_orchestrator(state: State):
    """Select different workers based on task characteristics"""
    tasks = []

    for item in state["items"]:
        if is_complex(item):
            tasks.append(Send("advanced_worker", {"item": item}))
        else:
            tasks.append(Send("simple_worker", {"item": item}))

    return tasks
```

### Pattern 3: Batch Processing

```python
def batch_orchestrator(state: State):
    """Divide items into batches"""
    batch_size = 10
    batches = [
        state["items"][i:i+batch_size]
        for i in range(0, len(state["items"]), batch_size)
    ]

    return [
        Send("batch_worker", {"batch": batch, "batch_id": i})
        for i, batch in enumerate(batches)
    ]

def batch_worker(state: BatchState):
    """Process batch"""
    results = [process(item) for item in state["batch"]]
    return {"results": results}
```

### Pattern 4: Error Handling and Retry

```python
class WorkerState(TypedDict):
    item: str
    retry_count: int
    result: str
    error: str | None

def robust_worker(state: WorkerState):
    """Worker with error handling"""
    try:
        result = process_item(state["item"])
        return {"result": result, "error": None}
    except Exception as e:
        if state.get("retry_count", 0) < 3:
            # Retry
            return Send("worker", {
                "item": state["item"],
                "retry_count": state.get("retry_count", 0) + 1
            })
        else:
            # Maximum retries reached
            return {"error": str(e)}
```

## Dynamic Parallelism Control

```python
import os

def adaptive_orchestrator(state: State):
    """Adjust parallelism based on system resources"""
    max_workers = int(os.getenv("MAX_WORKERS", "5"))

    # Divide items into chunks
    items = state["items"]
    chunk_size = max(1, len(items) // max_workers)

    chunks = [
        items[i:i+chunk_size]
        for i in range(0, len(items), chunk_size)
    ]

    return [
        Send("worker", {"chunk": chunk})
        for chunk in chunks
    ]
```

## Reducer Implementation Patterns

### Pattern 1: Simple Aggregation

```python
from operator import add

class State(TypedDict):
    results: Annotated[list, add]

def reducer(state: State):
    """Simple aggregation of results"""
    return {"total": sum(state["results"])}
```

### Pattern 2: Complex Aggregation

```python
def advanced_reducer(state: State):
    """Calculate statistics"""
    results = state["results"]

    return {
        "total": sum(results),
        "average": sum(results) / len(results),
        "min": min(results),
        "max": max(results)
    }
```

### Pattern 3: LLM-Based Integration

```python
def llm_reducer(state: State):
    """Integrate multiple results with LLM"""
    all_results = "\n".join(state["summaries"])

    final = llm.invoke(
        f"Synthesize these summaries into one:\n{all_results}"
    )

    return {"final_summary": final}
```

## Benefits

✅ **Scalability**: Workers automatically generated based on task count
✅ **Parallel Processing**: High-speed processing of large amounts of data
✅ **Flexibility**: Dynamically adjustable worker count
✅ **Distributed Processing**: Distributable across multiple servers

## Considerations

⚠️ **Memory Consumption**: Many worker instances are generated
⚠️ **Reducer Design**: Appropriately design result aggregation method
⚠️ **Error Handling**: Handle cases where some workers fail
⚠️ **Resource Management**: May need to limit parallelism

## Best Practices

1. **Batch Size Adjustment**: Too small causes overhead, too large reduces parallelism
2. **Error Isolation**: One failure shouldn't affect the whole
3. **Progress Tracking**: Visualize progress for large task counts
4. **Resource Limits**: Set upper limit on parallelism

## Summary

Orchestrator-Worker is optimal for **parallel processing of large task volumes**. Workers are generated dynamically with the Send API, and results are aggregated with a Reducer.

## Related Pages

- [02_graph_architecture_parallelization.md](02_graph_architecture_parallelization.md) - Comparison with static parallel processing
- [05_advanced_features_map_reduce.md](05_advanced_features_map_reduce.md) - Map-Reduce details
- [01_core_concepts_state.md](01_core_concepts_state.md) - Reducer details
