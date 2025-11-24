# Workflow vs Agent

Differences and usage between Workflow and Agent.

## Basic Differences

### Workflow
> "predetermined code paths and are designed to operate in a certain order"
> (Predetermined code paths, operates in specific order)

- **Pre-defined**: Processing flow is clear
- **Predictable**: Follows same path for same input
- **Controlled Execution**: Developer has complete control over control flow

### Agent
> "dynamic and define their own processes and tool usage"
> (Dynamic, defines its own processes and tool usage)

- **Dynamic**: LLM decides next action
- **Autonomous**: Self-determines tool selection
- **Uncertain**: May follow different paths with same input

## Implementation Comparison

### Workflow Example: Translation Pipeline

```python
def translate_node(state: State):
    return {"text": translate(state["text"])}

def summarize_node(state: State):
    return {"summary": summarize(state["text"])}

def validate_node(state: State):
    return {"valid": check_quality(state["summary"])}

# Fixed flow
builder.add_edge(START, "translate")
builder.add_edge("translate", "summarize")
builder.add_edge("summarize", "validate")
builder.add_edge("validate", END)
```

### Agent Example: Problem-Solving Agent

```python
def agent_node(state: State):
    # LLM determines tool usage
    response = llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

def should_continue(state: State):
    last_message = state["messages"][-1]
    # Continue if there are tool calls
    if last_message.tool_calls:
        return "continue"
    return "end"

# LLM decides dynamically
builder.add_conditional_edges(
    "agent",
    should_continue,
    {"continue": "tools", "end": END}
)
```

## Selection Criteria

### Choose Workflow When

✅ **Structure is Clear**
- Processing steps are known in advance
- Execution order is fixed

✅ **Predictability is Important**
- Compliance requirements exist
- Debugging needs to be easy

✅ **Cost Efficiency**
- Want to minimize LLM calls
- Want to reduce token consumption

**Examples**: Data processing pipelines, approval workflows, translation chains

### Choose Agent When

✅ **Problem is Uncertain**
- Don't know which tools are needed
- Variable number of steps

✅ **Flexibility is Needed**
- Different approaches based on situation
- Diverse user questions

✅ **Autonomy is Valuable**
- Want to leverage LLM's judgment
- ReAct (reasoning + action) pattern is suitable

**Examples**: Customer support, research assistant, complex problem solving

## Hybrid Approach

Many practical systems combine both:

```python
# Embed Agent within Workflow
builder.add_edge(START, "input_validation")  # Workflow
builder.add_edge("input_validation", "agent")  # Agent part
builder.add_conditional_edges("agent", should_continue, {...})
builder.add_edge("tools", "agent")
builder.add_conditional_edges("agent", ..., {"end": "output_formatting"})
builder.add_edge("output_formatting", END)  # Workflow
```

## ReAct Pattern (Agent Foundation)

Agent follows the **ReAct** (Reasoning + Acting) pattern:

1. **Reasoning**: Think "What should I do next?"
2. **Acting**: Take action using tools
3. **Observing**: Observe results
4. Repeat until reaching final answer

```python
# ReAct loop implementation
def agent(state):
    # Reasoning: Determine next action
    response = llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

def tools(state):
    # Acting: Execute tools
    results = execute_tools(state["messages"][-1].tool_calls)
    return {"messages": results}

# Observing & Repeat
builder.add_conditional_edges("agent", should_continue, ...)
```

## Summary

| Aspect | Workflow | Agent |
|--------|----------|-------|
| Control | Developer has complete control | LLM decides dynamically |
| Predictability | High | Low |
| Flexibility | Low | High |
| Cost | Low | High |
| Use Case | Structured tasks | Uncertain tasks |

**Important**: Both can be built with the same tools (State, Node, Edge) in LangGraph. Pattern choice depends on problem nature.

## Related Pages

- [02_graph_architecture_prompt_chaining.md](02_graph_architecture_prompt_chaining.md) - Workflow pattern example
- [02_graph_architecture_agent.md](02_graph_architecture_agent.md) - Agent pattern details
- [02_graph_architecture_routing.md](02_graph_architecture_routing.md) - Hybrid approach example
