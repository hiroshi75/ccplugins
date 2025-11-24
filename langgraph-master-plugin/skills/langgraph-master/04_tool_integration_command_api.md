# Command API

An advanced API that integrates state updates and control flow.

## Overview

The Command API is a feature that allows nodes to specify **state updates** and **control flow** simultaneously.

## Basic Usage

```python
from langgraph.types import Command

def decision_node(state: State) -> Command:
    """Update state and specify the next node"""
    result = analyze(state["data"])

    if result["confidence"] > 0.8:
        return Command(
            update={"result": result, "confident": True},
            goto="finalize"
        )
    else:
        return Command(
            update={"result": result, "confident": False},
            goto="review"
        )
```

## Command Object Parameters

```python
Command(
    update: dict,           # Updates to state
    goto: str | list[str],  # Next node(s) (single or multiple)
    graph: str | None = None  # For subgraph navigation
)
```

## vs Traditional State Updates

### Traditional Method

```python
def node(state: State) -> dict:
    return {"result": "value"}

# Control flow in edges
def route(state: State) -> str:
    if state["result"] == "value":
        return "next_node"
    return "other_node"

builder.add_conditional_edges("node", route, {...})
```

### Command API

```python
def node(state: State) -> Command:
    return Command(
        update={"result": "value"},
        goto="next_node"  # Specify control flow as well
    )

# No edges needed (Command controls flow)
```

## Advanced Patterns

### Pattern 1: Conditional Branching

```python
def validator(state: State) -> Command:
    """Validate and determine next node"""
    is_valid = validate(state["data"])

    if is_valid:
        return Command(
            update={"valid": True},
            goto="process"
        )
    else:
        return Command(
            update={"valid": False, "errors": get_errors(state["data"])},
            goto="error_handler"
        )
```

### Pattern 2: Parallel Execution

```python
def fan_out_node(state: State) -> Command:
    """Branch to multiple nodes in parallel"""
    return Command(
        update={"started": True},
        goto=["worker_a", "worker_b", "worker_c"]  # Parallel execution
    )
```

### Pattern 3: Loop Control

```python
def iterator_node(state: State) -> Command:
    """Iterative processing"""
    iteration = state.get("iteration", 0) + 1
    result = process_iteration(state["data"], iteration)

    if iteration < state["max_iterations"] and not result["done"]:
        return Command(
            update={"iteration": iteration, "result": result},
            goto="iterator_node"  # Loop back to self
        )
    else:
        return Command(
            update={"final_result": result},
            goto=END
        )
```

### Pattern 4: Subgraph Navigation

```python
def sub_node(state: State) -> Command:
    """Navigate from subgraph to parent graph"""
    result = process(state["data"])

    if need_parent_intervention(result):
        return Command(
            update={"sub_result": result},
            goto="parent_handler",
            graph=Command.PARENT  # Navigate to parent graph
        )

    return {"sub_result": result}
```

## Integration with Tools

### Control After Tool Execution

```python
def tool_node_with_command(state: MessagesState) -> Command:
    """Determine next action after tool execution"""
    last_message = state["messages"][-1]
    tool_results = []

    for tool_call in last_message.tool_calls:
        tool = tool_map[tool_call["name"]]
        result = tool.invoke(tool_call["args"])

        tool_results.append(
            ToolMessage(
                content=str(result),
                tool_call_id=tool_call["id"]
            )
        )

    # Determine next node based on results
    if any("error" in r.content.lower() for r in tool_results):
        return Command(
            update={"messages": tool_results},
            goto="error_handler"
        )
    else:
        return Command(
            update={"messages": tool_results},
            goto="agent"
        )
```

### Command from Within Tools

```python
from langgraph.types import interrupt

@tool
def send_email(to: str, subject: str, body: str) -> str:
    """Send email (with approval)"""

    # Request approval
    approved = interrupt({
        "action": "send_email",
        "to": to,
        "subject": subject,
        "message": "Approve sending this email?"
    })

    if approved:
        result = actually_send_email(to, subject, body)
        return f"Email sent to {to}"
    else:
        return "Email cancelled by user"
```

## Dynamic Routing

```python
def dynamic_router(state: State) -> Command:
    """Dynamically select route based on state"""
    score = evaluate(state["data"])

    # Select route based on score
    if score > 0.9:
        route = "expert_handler"
    elif score > 0.7:
        route = "standard_handler"
    else:
        route = "basic_handler"

    return Command(
        update={"confidence_score": score},
        goto=route
    )
```

## Error Recovery

```python
def processor_with_fallback(state: State) -> Command:
    """Fallback on error"""
    try:
        result = risky_operation(state["data"])

        return Command(
            update={"result": result, "error": None},
            goto="success_handler"
        )

    except Exception as e:
        return Command(
            update={"error": str(e)},
            goto="fallback_handler"
        )
```

## State Machine Implementation

```python
def state_machine_node(state: State) -> Command:
    """State machine"""
    current_state = state.get("state", "initial")

    transitions = {
        "initial": ("validate", {"state": "validating"}),
        "validating": ("process" if state.get("valid") else "error", {"state": "processing"}),
        "processing": ("finalize", {"state": "finalizing"}),
        "finalizing": (END, {"state": "done"})
    }

    next_node, update = transitions[current_state]

    return Command(
        update=update,
        goto=next_node
    )
```

## Benefits

✅ **Conciseness**: Define state updates and control flow in one place
✅ **Readability**: Node intent is clear
✅ **Flexibility**: Dynamic routing is easier
✅ **Debugging**: Control flow is easier to track

## Considerations

⚠️ **Complexity**: Avoid overly complex conditional branching
⚠️ **Testing**: All branches need to be tested
⚠️ **Parallel Execution**: Order of parallel nodes is non-deterministic

## Summary

The Command API integrates state updates and control flow, enabling more flexible and readable graph construction.

## Related Pages

- [01_core_concepts_node.md](01_core_concepts_node.md) - Node basics
- [01_core_concepts_edge.md](01_core_concepts_edge.md) - Comparison with edges
- [02_graph_architecture_subgraph.md](02_graph_architecture_subgraph.md) - Subgraph navigation
