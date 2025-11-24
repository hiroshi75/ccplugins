# Agent (Autonomous Tool Usage)

A pattern where the LLM dynamically determines tool selection to handle unpredictable problem-solving.

## Overview

The Agent pattern follows **ReAct** (Reasoning + Acting), where the LLM dynamically selects and executes tools to solve problems.

## ReAct Pattern

**ReAct** = Reasoning + Acting

1. **Reasoning**: Think "What should I do next?"
2. **Acting**: Take action using tools
3. **Observing**: Observe the results
4. **Repeat steps 1-3** until reaching a final answer

## Implementation Example: Basic Agent

```python
from langgraph.graph import StateGraph, START, END, MessagesState
from langgraph.prebuilt import ToolNode
from typing import Literal

# Tool definitions
@tool
def search(query: str) -> str:
    """Execute web search"""
    return perform_search(query)

@tool
def calculator(expression: str) -> float:
    """Execute calculation"""
    return eval(expression)

tools = [search, calculator]

# Agent node
def agent_node(state: MessagesState):
    """LLM determines tool usage"""
    messages = state["messages"]

    # Invoke LLM with tools
    response = llm_with_tools.invoke(messages)

    return {"messages": [response]}

# Continue decision
def should_continue(state: MessagesState) -> Literal["tools", "end"]:
    """Check if there are tool calls"""
    last_message = state["messages"][-1]

    # Continue if there are tool calls
    if last_message.tool_calls:
        return "tools"

    # End if no tool calls (final answer)
    return "end"

# Build graph
builder = StateGraph(MessagesState)

builder.add_node("agent", agent_node)
builder.add_node("tools", ToolNode(tools))

builder.add_edge(START, "agent")

# ReAct loop
builder.add_conditional_edges(
    "agent",
    should_continue,
    {
        "tools": "tools",
        "end": END
    }
)

# Return to agent after tool execution
builder.add_edge("tools", "agent")

graph = builder.compile()
```

## Tool Definitions

### Basic Tools

```python
from langchain_core.tools import tool

@tool
def get_weather(location: str) -> str:
    """Get weather for the specified location.

    Args:
        location: City name (e.g., "Tokyo", "New York")
    """
    return fetch_weather_data(location)

@tool
def send_email(to: str, subject: str, body: str) -> str:
    """Send an email.

    Args:
        to: Recipient email address
        subject: Email subject
        body: Email body
    """
    return send_email_api(to, subject, body)
```

### Structured Output Tools

```python
from pydantic import BaseModel, Field

class WeatherResponse(BaseModel):
    location: str
    temperature: float
    condition: str
    humidity: int

@tool(response_format="content_and_artifact")
def get_detailed_weather(location: str) -> tuple[str, WeatherResponse]:
    """Get detailed weather information"""
    data = fetch_weather_data(location)

    weather = WeatherResponse(
        location=location,
        temperature=data["temp"],
        condition=data["condition"],
        humidity=data["humidity"]
    )

    message = f"Weather in {location}: {weather.condition}, {weather.temperature}°C"

    return message, weather
```

## Advanced Patterns

### Pattern 1: Multi-Agent Collaboration

```python
# Specialist agents
def research_agent(state: State):
    """Research specialist agent"""
    response = research_llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

def coding_agent(state: State):
    """Coding specialist agent"""
    response = coding_llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

# Router
def route_to_specialist(state: State) -> Literal["research", "coding"]:
    """Select specialist based on task"""
    last_message = state["messages"][-1]

    if "research" in last_message.content or "search" in last_message.content:
        return "research"
    elif "code" in last_message.content or "implement" in last_message.content:
        return "coding"

    return "research"  # Default
```

### Pattern 2: Agent with Memory

```python
from langgraph.checkpoint.memory import MemorySaver

class AgentState(TypedDict):
    messages: Annotated[list, add_messages]
    context: dict  # Long-term memory

def agent_with_memory(state: AgentState):
    """Agent utilizing context"""
    messages = state["messages"]
    context = state.get("context", {})

    # Add context to prompt
    system_message = f"Context: {context}"

    response = llm_with_tools.invoke([
        {"role": "system", "content": system_message},
        *messages
    ])

    return {"messages": [response]}

# Compile with checkpointer
checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)
```

### Pattern 3: Human-in-the-Loop Agent

```python
from langgraph.types import interrupt

def careful_agent(state: State):
    """Confirm with human before important actions"""
    response = llm_with_tools.invoke(state["messages"])

    # Request confirmation for important tool calls
    if response.tool_calls:
        for tool_call in response.tool_calls:
            if tool_call["name"] in ["send_email", "delete_data"]:
                # Wait for human approval
                approved = interrupt({
                    "action": tool_call["name"],
                    "args": tool_call["args"],
                    "message": "Approve this action?"
                })

                if not approved:
                    return {
                        "messages": [
                            {"role": "assistant", "content": "Action cancelled by user"}
                        ]
                    }

    return {"messages": [response]}
```

### Pattern 4: Error Handling and Retry

```python
class RobustAgentState(TypedDict):
    messages: Annotated[list, add_messages]
    retry_count: int
    errors: list[str]

def robust_tool_node(state: RobustAgentState):
    """Tool execution with error handling"""
    last_message = state["messages"][-1]
    tool_results = []

    for tool_call in last_message.tool_calls:
        try:
            result = execute_tool(tool_call)
            tool_results.append(result)

        except Exception as e:
            error_msg = f"Tool {tool_call['name']} failed: {str(e)}"

            # Check if retry is possible
            if state.get("retry_count", 0) < 3:
                tool_results.append({
                    "tool_call_id": tool_call["id"],
                    "error": error_msg,
                    "retry": True
                })
            else:
                tool_results.append({
                    "tool_call_id": tool_call["id"],
                    "error": "Max retries exceeded",
                    "retry": False
                })

    return {
        "messages": tool_results,
        "retry_count": state.get("retry_count", 0) + 1
    }
```

## Advanced Tool Features

### Dynamic Tool Generation

```python
def create_tool_for_api(api_spec: dict):
    """Dynamically generate tool from API specification"""

    @tool
    def dynamic_api_tool(**kwargs) -> str:
        f"""
        {api_spec['description']}

        Args: {api_spec['parameters']}
        """
        return call_api(api_spec['endpoint'], kwargs)

    return dynamic_api_tool
```

### Conditional Tool Usage

```python
def conditional_agent(state: State):
    """Change toolset based on situation"""
    context = state.get("context", {})

    # Basic tools only for beginners
    if context.get("user_level") == "beginner":
        tools = [basic_search, simple_calculator]
    # Advanced tools for advanced users
    else:
        tools = [advanced_search, scientific_calculator, code_executor]

    llm_with_selected_tools = llm.bind_tools(tools)
    response = llm_with_selected_tools.invoke(state["messages"])

    return {"messages": [response]}
```

## Benefits

✅ **Flexibility**: Dynamically responds to unpredictable problems
✅ **Autonomy**: LLM selects optimal tools and strategies
✅ **Extensibility**: Extend functionality by simply adding tools
✅ **Adaptability**: Solves complex multi-step tasks

## Considerations

⚠️ **Unpredictability**: May behave differently with same input
⚠️ **Cost**: Multiple LLM calls occur
⚠️ **Infinite Loops**: Proper termination conditions required
⚠️ **Tool Misuse**: LLM may use tools incorrectly

## Best Practices

1. **Clear Tool Descriptions**: Write detailed tool docstrings
2. **Maximum Iterations**: Set upper limit for loops
3. **Error Handling**: Handle tool execution errors appropriately
4. **Logging**: Make agent behavior traceable

## Summary

The Agent pattern is optimal for **dynamic and uncertain problem-solving**. It autonomously solves problems using tools through the ReAct loop.

## Related Pages

- [02_graph_architecture_workflow_vs_agent.md](02_graph_architecture_workflow_vs_agent.md) - Differences between Workflow and Agent
- [04_tool_integration_overview.md](04_tool_integration_overview.md) - Tool details
- [05_advanced_features_human_in_the_loop.md](05_advanced_features_human_in_the_loop.md) - Human intervention
