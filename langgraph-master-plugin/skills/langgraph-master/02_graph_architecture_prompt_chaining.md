# Prompt Chaining (Sequential Processing)

A sequential pattern where each LLM call processes the previous output.

## Overview

Prompt Chaining is a pattern that **chains multiple LLM calls in sequence**. The output of each step becomes the input for the next step.

## Use Cases

- Stepwise processing like translation → summary → analysis
- Content generation → validation → correction pipeline
- Data extraction → transformation → validation flow

## Implementation Example

```python
from langgraph.graph import StateGraph, START, END
from typing import TypedDict

class State(TypedDict):
    text: str
    translated: str
    summarized: str
    analyzed: str

def translate_node(state: State):
    """Translate English → Japanese"""
    translated = llm.invoke(
        f"Translate to Japanese: {state['text']}"
    )
    return {"translated": translated}

def summarize_node(state: State):
    """Summarize translated text"""
    summarized = llm.invoke(
        f"Summarize this text: {state['translated']}"
    )
    return {"summarized": summarized}

def analyze_node(state: State):
    """Analyze summary"""
    analyzed = llm.invoke(
        f"Analyze sentiment: {state['summarized']}"
    )
    return {"analyzed": analyzed}

# Build graph
builder = StateGraph(State)
builder.add_node("translate", translate_node)
builder.add_node("summarize", summarize_node)
builder.add_node("analyze", analyze_node)

# Edges for sequential execution
builder.add_edge(START, "translate")
builder.add_edge("translate", "summarize")
builder.add_edge("summarize", "analyze")
builder.add_edge("analyze", END)

graph = builder.compile()
```

## Benefits

✅ **Simple**: Processing flow is linear and easy to understand
✅ **Predictable**: Always executes in the same order
✅ **Easy to Debug**: Each step can be tested independently
✅ **Gradual Improvement**: Quality improves at each step

## Considerations

⚠️ **Accumulated Delay**: Takes time as each step executes sequentially
⚠️ **Error Propagation**: Earlier errors affect later stages
⚠️ **Lack of Flexibility**: Dynamic branching is difficult

## Advanced Patterns

### Pattern 1: Chain with Validation

```python
def validate_translation(state: State):
    """Validate translation quality"""
    is_valid = check_quality(state["translated"])
    return {"is_valid": is_valid}

def route_after_validation(state: State):
    if state["is_valid"]:
        return "continue"
    return "retry"

# Validation → continue or retry
builder.add_conditional_edges(
    "validate",
    route_after_validation,
    {
        "continue": "summarize",
        "retry": "translate"
    }
)
```

### Pattern 2: Gradual Refinement

```python
def draft_node(state: State):
    """Create draft"""
    draft = llm.invoke(f"Write a draft: {state['topic']}")
    return {"draft": draft}

def refine_node(state: State):
    """Refine draft"""
    refined = llm.invoke(f"Improve this draft: {state['draft']}")
    return {"refined": refined}

def polish_node(state: State):
    """Final polish"""
    polished = llm.invoke(f"Polish this text: {state['refined']}")
    return {"final": polished}
```

## vs Other Patterns

| Pattern | Prompt Chaining | Parallelization |
|---------|----------------|-----------------|
| Execution Order | Sequential | Parallel |
| Dependencies | Yes | No |
| Execution Time | Long | Short |
| Use Case | Stepwise processing | Independent tasks |

## Summary

Prompt Chaining is the simplest pattern, optimal for **cases requiring stepwise processing**. Use when each step depends on the previous step.

## Related Pages

- [02_graph_architecture_parallelization.md](02_graph_architecture_parallelization.md) - Comparison with parallel processing
- [02_graph_architecture_evaluator_optimizer.md](02_graph_architecture_evaluator_optimizer.md) - Combination with validation loop
- [01_core_concepts_edge.md](01_core_concepts_edge.md) - Edge basics
