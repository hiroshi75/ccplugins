# Parallelization (Parallel Processing)

A pattern for executing multiple independent tasks simultaneously.

## Overview

Parallelization is a pattern that executes **multiple tasks that don't depend on each other** simultaneously, achieving speed improvements and reliability verification.

## Use Cases

- Scoring documents with multiple evaluation criteria
- Analysis from different perspectives (technical/business/legal)
- Comparing results from multiple translation engines
- Implementing Map-Reduce pattern

## Implementation Example

```python
from typing import Annotated, TypedDict
from operator import add

class State(TypedDict):
    document: str
    scores: Annotated[list[dict], add]  # Aggregate multiple results

def technical_review(state: State):
    """Review from technical perspective"""
    score = llm.invoke(
        f"Technical review: {state['document']}"
    )
    return {"scores": [{"type": "technical", "score": score}]}

def business_review(state: State):
    """Review from business perspective"""
    score = llm.invoke(
        f"Business review: {state['document']}"
    )
    return {"scores": [{"type": "business", "score": score}]}

def legal_review(state: State):
    """Review from legal perspective"""
    score = llm.invoke(
        f"Legal review: {state['document']}"
    )
    return {"scores": [{"type": "legal", "score": score}]}

def aggregate_scores(state: State):
    """Aggregate scores"""
    total = sum(s["score"] for s in state["scores"])
    return {"final_score": total / len(state["scores"])}

# Build graph
builder = StateGraph(State)

# Nodes to be executed in parallel
builder.add_node("technical", technical_review)
builder.add_node("business", business_review)
builder.add_node("legal", legal_review)
builder.add_node("aggregate", aggregate_scores)

# Edges for parallel execution
builder.add_edge(START, "technical")
builder.add_edge(START, "business")
builder.add_edge(START, "legal")

# To aggregation node
builder.add_edge("technical", "aggregate")
builder.add_edge("business", "aggregate")
builder.add_edge("legal", "aggregate")
builder.add_edge("aggregate", END)

graph = builder.compile()
```

## Important Concept: Reducer

A **Reducer** is essential for aggregating results from parallel execution:

```python
from operator import add

class State(TypedDict):
    # Additively aggregate results from multiple nodes
    results: Annotated[list, add]

    # Keep maximum value
    max_score: Annotated[int, max]

    # Custom Reducer
    combined: Annotated[dict, combine_dicts]
```

## Benefits

✅ **Speed**: Time reduction through parallel task execution
✅ **Reliability**: Verification by comparing multiple results
✅ **Scalability**: Adjust parallelism based on task count
✅ **Robustness**: Can continue if some succeed even if others fail

## Considerations

⚠️ **Reducer Required**: Explicitly define result aggregation method
⚠️ **Resource Consumption**: Increased memory and API calls from parallel execution
⚠️ **Uncertain Order**: Execution order not guaranteed
⚠️ **Debugging Complexity**: Parallel execution troubleshooting is difficult

## Advanced Patterns

### Pattern 1: Fan-out / Fan-in

```python
# Fan-out: One node to multiple
builder.add_edge("router", "task_a")
builder.add_edge("router", "task_b")
builder.add_edge("router", "task_c")

# Fan-in: Multiple to one aggregation
builder.add_edge("task_a", "aggregator")
builder.add_edge("task_b", "aggregator")
builder.add_edge("task_c", "aggregator")
```

### Pattern 2: Balancing (defer=True)

Wait for branches of different lengths:

```python
from operator import add

def add_with_defer(left: list, right: list) -> list:
    return left + right

class State(TypedDict):
    results: Annotated[list, add_with_defer]

# Specify defer=True at compile time
graph = builder.compile(
    checkpointer=checkpointer,
    # Wait until all branches complete
)
```

### Pattern 3: Reliability Through Redundancy

```python
def provider_a(state: State):
    """Provider A"""
    return {"responses": [call_api_a(state["query"])]}

def provider_b(state: State):
    """Provider B (backup)"""
    return {"responses": [call_api_b(state["query"])]}

def provider_c(state: State):
    """Provider C (backup)"""
    return {"responses": [call_api_c(state["query"])]}

def select_best(state: State):
    """Select best response"""
    responses = state["responses"]
    best = max(responses, key=lambda r: r.confidence)
    return {"result": best}
```

## vs Other Patterns

| Pattern | Parallelization | Prompt Chaining |
|---------|----------------|-----------------|
| Execution Order | Parallel | Sequential |
| Dependencies | None | Yes |
| Execution Time | Short | Long |
| Result Aggregation | Reducer required | Not required |

## Summary

Parallelization is optimal for **simultaneous execution of independent tasks**. It's important to properly aggregate results using a Reducer.

## Related Pages

- [02_graph_architecture_orchestrator_worker.md](02_graph_architecture_orchestrator_worker.md) - Dynamic parallel processing
- [05_advanced_features_map_reduce.md](05_advanced_features_map_reduce.md) - Map-Reduce pattern
- [01_core_concepts_state.md](01_core_concepts_state.md) - Reducer details
