# Subgraph

A pattern for building hierarchical graph structures and modularizing complex systems.

## Overview

Subgraph is a pattern for hierarchically organizing complex systems by **embedding graphs as nodes in other graphs**.

## Use Cases

- Modularizing large-scale agent systems
- Integrating multiple specialized agents
- Reusable workflow components
- Multi-level hierarchical structures

## Two Implementation Approaches

### Approach 1: Add Graph as Node

Use when **sharing state keys**.

```python
# Subgraph definition
class SubState(TypedDict):
    messages: Annotated[list, add_messages]
    sub_result: str

def sub_node_a(state: SubState):
    return {"messages": [{"role": "assistant", "content": "Sub A"}]}

def sub_node_b(state: SubState):
    return {"sub_result": "Sub B completed"}

# Build subgraph
sub_builder = StateGraph(SubState)
sub_builder.add_node("sub_a", sub_node_a)
sub_builder.add_node("sub_b", sub_node_b)
sub_builder.add_edge(START, "sub_a")
sub_builder.add_edge("sub_a", "sub_b")
sub_builder.add_edge("sub_b", END)

sub_graph = sub_builder.compile()

# Use subgraph as node in parent graph
class ParentState(TypedDict):
    messages: Annotated[list, add_messages]  # Shared key
    sub_result: str  # Shared key
    parent_data: str

parent_builder = StateGraph(ParentState)

# Add subgraph directly as node
parent_builder.add_node("subgraph", sub_graph)

parent_builder.add_edge(START, "subgraph")
parent_builder.add_edge("subgraph", END)

parent_graph = parent_builder.compile()
```

### Approach 2: Call Graph from Within Node

Use when having **different state schemas**.

```python
# Subgraph (own state)
class SubGraphState(TypedDict):
    input_text: str
    output_text: str

def process_node(state: SubGraphState):
    return {"output_text": process(state["input_text"])}

sub_builder = StateGraph(SubGraphState)
sub_builder.add_node("process", process_node)
sub_builder.add_edge(START, "process")
sub_builder.add_edge("process", END)

sub_graph = sub_builder.compile()

# Parent graph (different state)
class ParentState(TypedDict):
    user_query: str
    result: str

def invoke_subgraph_node(state: ParentState):
    """Call subgraph within node"""
    # Convert parent state to subgraph state
    sub_input = {"input_text": state["user_query"]}

    # Execute subgraph
    sub_output = sub_graph.invoke(sub_input)

    # Convert subgraph output to parent state
    return {"result": sub_output["output_text"]}

parent_builder = StateGraph(ParentState)
parent_builder.add_node("call_subgraph", invoke_subgraph_node)
parent_builder.add_edge(START, "call_subgraph")
parent_builder.add_edge("call_subgraph", END)

parent_graph = parent_builder.compile()
```

## Multi-Level Subgraphs

Multiple levels of subgraphs (parent → child → grandchild) are also possible:

```python
# Grandchild graph
class GrandchildState(TypedDict):
    data: str

grandchild_builder = StateGraph(GrandchildState)
grandchild_builder.add_node("process", lambda s: {"data": f"Processed: {s['data']}"})
grandchild_builder.add_edge(START, "process")
grandchild_builder.add_edge("process", END)
grandchild_graph = grandchild_builder.compile()

# Child graph (includes grandchild graph)
class ChildState(TypedDict):
    data: str

child_builder = StateGraph(ChildState)
child_builder.add_node("grandchild", grandchild_graph)  # Add grandchild graph
child_builder.add_edge(START, "grandchild")
child_builder.add_edge("grandchild", END)
child_graph = child_builder.compile()

# Parent graph (includes child graph)
class ParentState(TypedDict):
    data: str

parent_builder = StateGraph(ParentState)
parent_builder.add_node("child", child_graph)  # Add child graph
parent_builder.add_edge(START, "child")
parent_builder.add_edge("child", END)
parent_graph = parent_builder.compile()
```

## Navigation Between Subgraphs

Transition from subgraph to another node in parent graph:

```python
from langgraph.types import Command

def sub_node_with_navigation(state: SubState):
    """Navigate from subgraph node to parent graph"""
    result = process(state["data"])

    if need_parent_intervention(result):
        # Transition to another node in parent graph
        return Command(
            update={"result": result},
            goto="parent_handler",
            graph=Command.PARENT
        )

    return {"result": result}
```

## Persistence and Debugging

### Automatic Checkpointer Propagation

```python
from langgraph.checkpoint.memory import MemorySaver

# Set checkpointer only on parent graph
checkpointer = MemorySaver()

parent_graph = parent_builder.compile(
    checkpointer=checkpointer  # Automatically propagates to child graphs
)
```

### Streaming Including Subgraph Output

```python
# Stream including subgraph details
for chunk in parent_graph.stream(
    inputs,
    stream_mode="values",
    subgraphs=True  # Include subgraph output
):
    print(chunk)
```

## Practical Example: Multi-Agent System

```python
# Research agent (subgraph)
class ResearchState(TypedDict):
    messages: Annotated[list, add_messages]
    research_result: str

research_builder = StateGraph(ResearchState)
research_builder.add_node("search", search_node)
research_builder.add_node("analyze", analyze_node)
research_builder.add_edge(START, "search")
research_builder.add_edge("search", "analyze")
research_builder.add_edge("analyze", END)
research_graph = research_builder.compile()

# Coding agent (subgraph)
class CodingState(TypedDict):
    messages: Annotated[list, add_messages]
    code: str

coding_builder = StateGraph(CodingState)
coding_builder.add_node("generate", generate_code_node)
coding_builder.add_node("test", test_code_node)
coding_builder.add_edge(START, "generate")
coding_builder.add_edge("generate", "test")
coding_builder.add_edge("test", END)
coding_graph = coding_builder.compile()

# Integrated system (parent graph)
class SystemState(TypedDict):
    messages: Annotated[list, add_messages]
    research_result: str
    code: str
    task_type: str

def router(state: SystemState):
    if "research" in state["messages"][-1].content:
        return "research"
    return "coding"

system_builder = StateGraph(SystemState)

# Add subgraphs
system_builder.add_node("research_agent", research_graph)
system_builder.add_node("coding_agent", coding_graph)

# Routing
system_builder.add_conditional_edges(
    START,
    router,
    {
        "research": "research_agent",
        "coding": "coding_agent"
    }
)

system_builder.add_edge("research_agent", END)
system_builder.add_edge("coding_agent", END)

system_graph = system_builder.compile()
```

## Benefits

✅ **Modularization**: Divide complex systems into smaller parts
✅ **Reusability**: Use subgraphs in multiple parent graphs
✅ **Maintainability**: Improve each subgraph independently
✅ **Testability**: Test subgraphs individually

## Considerations

⚠️ **State Sharing**: Carefully design which keys to share
⚠️ **Debugging Complexity**: Deep hierarchies are hard to track
⚠️ **Performance**: Multi-level increases overhead
⚠️ **Circular References**: Watch for circular dependencies between subgraphs

## Best Practices

1. **Shallow Hierarchy**: Keep hierarchy as shallow as possible (2-3 levels)
2. **Clear Responsibilities**: Clearly define role of each subgraph
3. **Minimize State**: Share only necessary state keys
4. **Independence**: Subgraphs should operate as independently as possible

## Summary

Subgraph is optimal for **hierarchical organization of complex systems**. Choose between two approaches depending on state sharing method.

## Related Pages

- [02_graph_architecture_agent.md](02_graph_architecture_agent.md) - Combination with multi-agent
- [01_core_concepts_state.md](01_core_concepts_state.md) - State design
- [03_memory_management_persistence.md](03_memory_management_persistence.md) - Checkpointer propagation
