# Map-Reduce (Parallel Processing Pattern)

A pattern for parallel processing and aggregation of large datasets.

## Overview

Map-Reduce is a pattern that combines **Map** (parallel processing) and **Reduce** (aggregation). In LangGraph, it's implemented using the Send API.

## Basic Implementation

```python
from langgraph.types import Send
from typing import Annotated
from operator import add

class MapReduceState(TypedDict):
    items: list[str]
    results: Annotated[list[str], add]
    final_result: str

def map_node(state: MapReduceState):
    """Map: Send each item to worker"""
    return [
        Send("worker", {"item": item})
        for item in state["items"]
    ]

def worker_node(item_state: dict):
    """Process individual item"""
    result = process_item(item_state["item"])
    return {"results": [result]}

def reduce_node(state: MapReduceState):
    """Reduce: Aggregate results"""
    final = aggregate_results(state["results"])
    return {"final_result": final}

# Build graph
builder = StateGraph(MapReduceState)
builder.add_node("map", map_node)
builder.add_node("worker", worker_node)
builder.add_node("reduce", reduce_node)

builder.add_edge(START, "map")
builder.add_edge("worker", "reduce")
builder.add_edge("reduce", END)

graph = builder.compile()
```

## Types of Reducers

### Addition (List Concatenation)

```python
from operator import add

class State(TypedDict):
    results: Annotated[list, add]  # Concatenate lists

# [1, 2] + [3, 4] = [1, 2, 3, 4]
```

### Custom Reducer

```python
def merge_dicts(left: dict, right: dict) -> dict:
    """Merge dictionaries"""
    return {**left, **right}

class State(TypedDict):
    data: Annotated[dict, merge_dicts]
```

## Application Patterns

### Pattern 1: Parallel Document Summarization

```python
class DocSummaryState(TypedDict):
    documents: list[str]
    summaries: Annotated[list[str], add]
    final_summary: str

def map_documents(state: DocSummaryState):
    """Send each document to worker"""
    return [
        Send("summarize_worker", {"doc": doc, "index": i})
        for i, doc in enumerate(state["documents"])
    ]

def summarize_worker(worker_state: dict):
    """Summarize individual document"""
    summary = llm.invoke(f"Summarize: {worker_state['doc']}")
    return {"summaries": [summary]}

def final_summary_node(state: DocSummaryState):
    """Integrate all summaries"""
    combined = "\n".join(state["summaries"])
    final = llm.invoke(f"Create final summary from:\n{combined}")
    return {"final_summary": final}
```

### Pattern 2: Hierarchical Map-Reduce

```python
def level1_map(state: State):
    """Level 1: Split data into chunks"""
    chunks = create_chunks(state["data"], chunk_size=100)
    return [
        Send("level1_worker", {"chunk": chunk})
        for chunk in chunks
    ]

def level1_worker(worker_state: dict):
    """Level 1 worker: Aggregate within chunk"""
    partial_result = aggregate_chunk(worker_state["chunk"])
    return {"level1_results": [partial_result]}

def level2_map(state: State):
    """Level 2: Further aggregate partial results"""
    return [
        Send("level2_worker", {"partial": result})
        for result in state["level1_results"]
    ]

def level2_worker(worker_state: dict):
    """Level 2 worker: Final aggregation"""
    final = final_aggregate(worker_state["partial"])
    return {"final_result": final}
```

### Pattern 3: Dynamic Parallelism Control

```python
import os

def adaptive_map(state: State):
    """Adjust parallelism based on system resources"""
    max_workers = int(os.getenv("MAX_WORKERS", "10"))
    items = state["items"]

    # Split items into batches
    batch_size = max(1, len(items) // max_workers)
    batches = [
        items[i:i+batch_size]
        for i in range(0, len(items), batch_size)
    ]

    return [
        Send("batch_worker", {"batch": batch})
        for batch in batches
    ]

def batch_worker(worker_state: dict):
    """Process batch"""
    results = [process_item(item) for item in worker_state["batch"]]
    return {"results": results}
```

### Pattern 4: Error-Resilient Map-Reduce

```python
class RobustState(TypedDict):
    items: list[str]
    successes: Annotated[list, add]
    failures: Annotated[list, add]

def robust_worker(worker_state: dict):
    """Worker with error handling"""
    try:
        result = process_item(worker_state["item"])
        return {"successes": [{"item": worker_state["item"], "result": result}]}

    except Exception as e:
        return {"failures": [{"item": worker_state["item"], "error": str(e)}]}

def error_handler(state: RobustState):
    """Process failed items"""
    if state["failures"]:
        # Retry or log failed items
        log_failures(state["failures"])

    return {"final_result": aggregate(state["successes"])}
```

## Performance Optimization

### Batch Size Adjustment

```python
def optimal_batching(items: list, target_batch_time: float = 1.0):
    """Calculate optimal batch size"""
    # Estimate processing time per item
    sample_time = estimate_processing_time(items[0])

    # Batch size to reach target time
    batch_size = max(1, int(target_batch_time / sample_time))

    batches = [
        items[i:i+batch_size]
        for i in range(0, len(items), batch_size)
    ]

    return batches
```

### Progress Tracking

```python
from langgraph.config import get_stream_writer

def map_with_progress(state: State):
    """Map that reports progress"""
    writer = get_stream_writer()
    total = len(state["items"])

    sends = []
    for i, item in enumerate(state["items"]):
        sends.append(Send("worker", {"item": item}))
        writer({"progress": f"{i+1}/{total}"})

    return sends
```

## Aggregation Patterns

### Statistical Aggregation

```python
def statistical_reduce(state: State):
    """Calculate statistics"""
    results = state["results"]

    return {
        "total": sum(results),
        "average": sum(results) / len(results),
        "min": min(results),
        "max": max(results),
        "count": len(results)
    }
```

### LLM-Based Integration

```python
def llm_reduce(state: State):
    """Integrate multiple results with LLM"""
    all_results = "\n\n".join([
        f"Result {i+1}:\n{r}"
        for i, r in enumerate(state["results"])
    ])

    final = llm.invoke(
        f"Synthesize these results into a comprehensive answer:\n\n{all_results}"
    )

    return {"final_result": final}
```

## Advantages

✅ **Scalability**: Efficiently process large datasets
✅ **Parallelism**: Execute independent tasks concurrently
✅ **Flexibility**: Dynamically adjust number of workers
✅ **Error Isolation**: One failure doesn't affect the whole

## Considerations

⚠️ **Memory Consumption**: Many worker instances
⚠️ **Order Non-deterministic**: Worker execution order is not guaranteed
⚠️ **Overhead**: Inefficient for small tasks
⚠️ **Reducer Design**: Design appropriate aggregation method

## Summary

Map-Reduce is a pattern that uses Send API to process large datasets in parallel and aggregates with Reducers. Optimal for large-scale data processing.

## Related Pages

- [02_graph_architecture_orchestrator_worker.md](02_graph_architecture_orchestrator_worker.md) - Orchestrator-Worker pattern
- [02_graph_architecture_parallelization.md](02_graph_architecture_parallelization.md) - Comparison with static parallelization
- [01_core_concepts_state.md](01_core_concepts_state.md) - Details on Reducers
