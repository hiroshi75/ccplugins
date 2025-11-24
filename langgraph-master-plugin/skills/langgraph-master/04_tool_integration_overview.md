# 04. Tool Integration

Integration and execution control of external tools.

## Overview

In LangGraph, LLMs can interact with external systems by calling **tools**. Tools provide various capabilities such as search, calculation, API calls, and more.

## Key Components

### 1. [Tool Definition](04_tool_integration_tool_definition.md)

How to define tools:
- `@tool` decorator
- Function descriptions and parameters
- Structured output

### 2. [Tool Node](04_tool_integration_tool_node.md)

Nodes that execute tools:
- Using `ToolNode`
- Error handling
- Custom tool nodes

### 3. [Command API](04_tool_integration_command_api.md)

Controlling tool execution:
- Integration of state updates and control flow
- Transition control from tools

## Basic Implementation

```python
from langchain_core.tools import tool
from langgraph.prebuilt import ToolNode
from langgraph.graph import MessagesState, StateGraph

# 1. Define tools
@tool
def search(query: str) -> str:
    """Perform a web search.

    Args:
        query: Search query
    """
    return perform_search(query)

@tool
def calculator(expression: str) -> float:
    """Calculate a mathematical expression.

    Args:
        expression: Expression to calculate (e.g., "2 + 2")
    """
    return eval(expression)

tools = [search, calculator]

# 2. Bind tools to LLM
llm_with_tools = llm.bind_tools(tools)

# 3. Agent node
def agent(state: MessagesState):
    response = llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

# 4. Tool node
tool_node = ToolNode(tools)

# 5. Build graph
builder = StateGraph(MessagesState)
builder.add_node("agent", agent)
builder.add_node("tools", tool_node)

# 6. Conditional edges
def should_continue(state: MessagesState):
    last_message = state["messages"][-1]
    if last_message.tool_calls:
        return "tools"
    return END

builder.add_edge(START, "agent")
builder.add_conditional_edges("agent", should_continue)
builder.add_edge("tools", "agent")

graph = builder.compile()
```

## Types of Tools

### Search Tools

```python
@tool
def web_search(query: str) -> str:
    """Search the web"""
    return search_api(query)
```

### Calculator Tools

```python
@tool
def calculator(expression: str) -> float:
    """Calculate a mathematical expression"""
    return eval(expression)
```

### API Tools

```python
@tool
def get_weather(city: str) -> dict:
    """Get weather information"""
    return weather_api(city)
```

### Database Tools

```python
@tool
def query_database(sql: str) -> list[dict]:
    """Query the database"""
    return execute_sql(sql)
```

## Tool Execution Flow

```
User Query
    ↓
[Agent Node]
    ↓
LLM decides: Use tool?
    ↓ Yes
[Tool Node] ← Execute tool
    ↓
[Agent Node] ← Tool result
    ↓
LLM decides: Continue?
    ↓ No
Final Answer
```

## Key Principles

1. **Clear Descriptions**: Write detailed docstrings for tools
2. **Error Handling**: Handle tool execution errors appropriately
3. **Type Safety**: Explicitly specify parameter types
4. **Approval Flow**: Incorporate Human-in-the-Loop for critical tools

## Next Steps

For details on each component, please refer to the following pages:

- [04_tool_integration_tool_definition.md](04_tool_integration_tool_definition.md) - How to define tools
- [04_tool_integration_tool_node.md](04_tool_integration_tool_node.md) - Tool node implementation
- [04_tool_integration_command_api.md](04_tool_integration_command_api.md) - Using the Command API
