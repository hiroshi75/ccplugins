# Routing (Branching Processing)

A pattern for routing to specialized flows based on input.

## Overview

Routing is a pattern that **selects the appropriate processing path** based on input characteristics. Used for customer support question classification, etc.

## Use Cases

- Route customer questions to specialized teams by type
- Different processing pipelines by document type
- Prioritization by urgency/importance
- Processing flow selection by language

## Implementation Example: Customer Support

```python
from typing import Literal, TypedDict

class State(TypedDict):
    query: str
    category: str
    response: str

def router_node(state: State) -> Literal["pricing", "refund", "technical"]:
    """Classify and route question"""
    query = state["query"]

    # Classify with LLM
    category = llm.invoke(
        f"Classify this customer query into: pricing, refund, or technical\n"
        f"Query: {query}\n"
        f"Category:"
    )

    if "price" in query or "cost" in query:
        return "pricing"
    elif "refund" in query or "cancel" in query:
        return "refund"
    else:
        return "technical"

def pricing_node(state: State):
    """Handle pricing queries"""
    response = handle_pricing_query(state["query"])
    return {"response": response, "category": "pricing"}

def refund_node(state: State):
    """Handle refund queries"""
    response = handle_refund_query(state["query"])
    return {"response": response, "category": "refund"}

def technical_node(state: State):
    """Handle technical issues"""
    response = handle_technical_query(state["query"])
    return {"response": response, "category": "technical"}

# Build graph
builder = StateGraph(State)

builder.add_node("router", router_node)
builder.add_node("pricing", pricing_node)
builder.add_node("refund", refund_node)
builder.add_node("technical", technical_node)

# Routing edges
builder.add_edge(START, "router")
builder.add_conditional_edges(
    "router",
    lambda state: state.get("category", "technical"),
    {
        "pricing": "pricing",
        "refund": "refund",
        "technical": "technical"
    }
)

# End from each node
builder.add_edge("pricing", END)
builder.add_edge("refund", END)
builder.add_edge("technical", END)

graph = builder.compile()
```

## Advanced Patterns

### Pattern 1: Multi-Stage Routing

```python
def first_router(state: State) -> Literal["sales", "support"]:
    """Stage 1: Sales or Support"""
    if "purchase" in state["query"] or "quote" in state["query"]:
        return "sales"
    return "support"

def support_router(state: State) -> Literal["billing", "technical"]:
    """Stage 2: Classification within Support"""
    if "billing" in state["query"]:
        return "billing"
    return "technical"

# Multi-stage routing
builder.add_conditional_edges("first_router", first_router, {...})
builder.add_conditional_edges("support_router", support_router, {...})
```

### Pattern 2: Priority-Based Routing

```python
from typing import Literal

def priority_router(state: State) -> Literal["urgent", "normal", "low"]:
    """Route by urgency"""
    query = state["query"]

    # Urgent keywords
    if any(word in query for word in ["urgent", "immediately", "asap"]):
        return "urgent"

    # Importance determination
    importance = analyze_importance(query)
    if importance > 0.7:
        return "normal"

    return "low"

builder.add_conditional_edges(
    "priority_router",
    priority_router,
    {
        "urgent": "urgent_handler",    # Immediate processing
        "normal": "normal_queue",       # Normal queue
        "low": "batch_processor"        # Batch processing
    }
)
```

### Pattern 3: Semantic Routing (Embedding-Based)

```python
import numpy as np
from typing import Literal

def semantic_router(state: State) -> Literal["product", "account", "general"]:
    """Semantic routing based on embeddings"""
    query_embedding = embed(state["query"])

    # Representative embeddings for each category
    categories = {
        "product": embed("product, features, how to use"),
        "account": embed("account, login, password"),
        "general": embed("general questions")
    }

    # Select closest category
    similarities = {
        cat: cosine_similarity(query_embedding, emb)
        for cat, emb in categories.items()
    }

    return max(similarities, key=similarities.get)
```

### Pattern 4: Dynamic Routing (LLM Judgment)

```python
def llm_router(state: State):
    """Have LLM determine optimal route"""
    routes = ["expert_a", "expert_b", "expert_c", "general"]

    prompt = f"""
    Select the most appropriate expert to handle this question:
    - expert_a: Database specialist
    - expert_b: API specialist
    - expert_c: UI specialist
    - general: General questions

    Question: {state['query']}

    Selection: """

    route = llm.invoke(prompt).strip()
    return route if route in routes else "general"

builder.add_conditional_edges(
    "router",
    llm_router,
    {
        "expert_a": "database_expert",
        "expert_b": "api_expert",
        "expert_c": "ui_expert",
        "general": "general_handler"
    }
)
```

## Benefits

✅ **Specialization**: Specialized processing for each type
✅ **Efficiency**: Skip unnecessary processing
✅ **Maintainability**: Improve each route independently
✅ **Scalability**: Easy to add new routes

## Considerations

⚠️ **Classification Accuracy**: Routing errors affect the whole
⚠️ **Coverage**: Need to cover all cases
⚠️ **Fallback**: Handling unknown cases is important
⚠️ **Balance**: Consider load balancing between routes

## Best Practices

### 1. Provide Fallback Route

```python
def safe_router(state: State):
    try:
        route = determine_route(state)
        if route in valid_routes:
            return route
    except Exception:
        pass

    # Fallback
    return "general_handler"
```

### 2. Log Routing Reasons

```python
def logged_router(state: State):
    route = determine_route(state)

    return {
        "route": route,
        "routing_reason": f"Routed to {route} because..."
    }
```

### 3. Dynamic Route Addition

```python
# Load routes from configuration file
ROUTES = load_routes_config()

builder.add_conditional_edges(
    "router",
    determine_route,
    {route: handler for route, handler in ROUTES.items()}
)
```

## Summary

Routing is optimal for **appropriate processing selection based on input characteristics**. Classification accuracy and fallback handling are keys to success.

## Related Pages

- [02_graph_architecture_agent.md](02_graph_architecture_agent.md) - Combining with Agent
- [01_core_concepts_edge.md](01_core_concepts_edge.md) - Conditional edge details
- [02_graph_architecture_workflow_vs_agent.md](02_graph_architecture_workflow_vs_agent.md) - Pattern usage
