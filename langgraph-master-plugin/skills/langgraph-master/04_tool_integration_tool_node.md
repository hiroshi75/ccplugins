# Tool Node

Implementation of nodes that execute tools.

## ToolNode (Built-in)

The simplest approach:

```python
from langgraph.prebuilt import ToolNode

tools = [search_tool, calculator_tool]
tool_node = ToolNode(tools)

# Add to graph
builder.add_node("tools", tool_node)
```

## How It Works

ToolNode:
1. Extracts `tool_calls` from the last message
2. Executes each tool
3. Returns results as `ToolMessage`

```python
# Input
{
    "messages": [
        AIMessage(tool_calls=[
            {"name": "search", "args": {"query": "weather"}, "id": "1"}
        ])
    ]
}

# ToolNode execution

# Output
{
    "messages": [
        ToolMessage(
            content="Sunny, 25°C",
            tool_call_id="1"
        )
    ]
}
```

## Custom Tool Node

For finer control:

```python
def custom_tool_node(state: MessagesState):
    """Custom tool node"""
    last_message = state["messages"][-1]
    tool_results = []

    for tool_call in last_message.tool_calls:
        # Find the tool
        tool = tool_map.get(tool_call["name"])

        if not tool:
            result = f"Tool {tool_call['name']} not found"
        else:
            try:
                # Execute the tool
                result = tool.invoke(tool_call["args"])
            except Exception as e:
                result = f"Error: {str(e)}"

        # Create ToolMessage
        tool_results.append(
            ToolMessage(
                content=str(result),
                tool_call_id=tool_call["id"]
            )
        )

    return {"messages": tool_results}
```

## Error Handling

### Basic Error Handling

```python
def robust_tool_node(state: MessagesState):
    """Tool node with error handling"""
    last_message = state["messages"][-1]
    tool_results = []

    for tool_call in last_message.tool_calls:
        try:
            tool = tool_map[tool_call["name"]]
            result = tool.invoke(tool_call["args"])

            tool_results.append(
                ToolMessage(
                    content=str(result),
                    tool_call_id=tool_call["id"]
                )
            )

        except KeyError:
            # Tool not found
            tool_results.append(
                ToolMessage(
                    content=f"Error: Tool '{tool_call['name']}' not found",
                    tool_call_id=tool_call["id"]
                )
            )

        except Exception as e:
            # Execution error
            tool_results.append(
                ToolMessage(
                    content=f"Error executing tool: {str(e)}",
                    tool_call_id=tool_call["id"]
                )
            )

    return {"messages": tool_results}
```

### Retry Logic

```python
import time

def tool_node_with_retry(state: MessagesState, max_retries: int = 3):
    """Tool node with retry"""
    last_message = state["messages"][-1]
    tool_results = []

    for tool_call in last_message.tool_calls:
        tool = tool_map[tool_call["name"]]
        retry_count = 0

        while retry_count < max_retries:
            try:
                result = tool.invoke(tool_call["args"])

                tool_results.append(
                    ToolMessage(
                        content=str(result),
                        tool_call_id=tool_call["id"]
                    )
                )
                break

            except TransientError as e:
                retry_count += 1
                if retry_count >= max_retries:
                    tool_results.append(
                        ToolMessage(
                            content=f"Failed after {max_retries} retries: {str(e)}",
                            tool_call_id=tool_call["id"]
                        )
                    )
                else:
                    time.sleep(2 ** retry_count)  # Exponential backoff

            except Exception as e:
                # Non-retryable error
                tool_results.append(
                    ToolMessage(
                        content=f"Error: {str(e)}",
                        tool_call_id=tool_call["id"]
                    )
                )
                break

    return {"messages": tool_results}
```

## Conditional Tool Execution

```python
def conditional_tool_node(state: MessagesState, *, store):
    """Tool node with permission checking"""
    user_id = state.get("user_id")
    user = store.get(("users", user_id), "profile")

    last_message = state["messages"][-1]
    tool_results = []

    for tool_call in last_message.tool_calls:
        tool = tool_map[tool_call["name"]]

        # Permission check
        if not has_permission(user, tool.name):
            tool_results.append(
                ToolMessage(
                    content=f"Permission denied for tool '{tool.name}'",
                    tool_call_id=tool_call["id"]
                )
            )
            continue

        # Execute
        result = tool.invoke(tool_call["args"])
        tool_results.append(
            ToolMessage(
                content=str(result),
                tool_call_id=tool_call["id"]
            )
        )

    return {"messages": tool_results}
```

## Logging Tool Execution

```python
import logging

logger = logging.getLogger(__name__)

def logged_tool_node(state: MessagesState):
    """Tool node with logging"""
    last_message = state["messages"][-1]
    tool_results = []

    for tool_call in last_message.tool_calls:
        tool = tool_map[tool_call["name"]]

        logger.info(
            f"Executing tool: {tool.name}",
            extra={
                "tool": tool.name,
                "args": tool_call["args"],
                "call_id": tool_call["id"]
            }
        )

        try:
            start = time.time()
            result = tool.invoke(tool_call["args"])
            duration = time.time() - start

            logger.info(
                f"Tool completed: {tool.name}",
                extra={
                    "tool": tool.name,
                    "duration": duration,
                    "success": True
                }
            )

            tool_results.append(
                ToolMessage(
                    content=str(result),
                    tool_call_id=tool_call["id"]
                )
            )

        except Exception as e:
            logger.error(
                f"Tool failed: {tool.name}",
                extra={
                    "tool": tool.name,
                    "error": str(e)
                },
                exc_info=True
            )

            tool_results.append(
                ToolMessage(
                    content=f"Error: {str(e)}",
                    tool_call_id=tool_call["id"]
                )
            )

    return {"messages": tool_results}
```

## Parallel Tool Execution

```python
from concurrent.futures import ThreadPoolExecutor

def parallel_tool_node(state: MessagesState):
    """Execute tools in parallel"""
    last_message = state["messages"][-1]

    def execute_tool(tool_call):
        tool = tool_map[tool_call["name"]]
        try:
            result = tool.invoke(tool_call["args"])
            return ToolMessage(
                content=str(result),
                tool_call_id=tool_call["id"]
            )
        except Exception as e:
            return ToolMessage(
                content=f"Error: {str(e)}",
                tool_call_id=tool_call["id"]
            )

    with ThreadPoolExecutor(max_workers=5) as executor:
        tool_results = list(executor.map(
            execute_tool,
            last_message.tool_calls
        ))

    return {"messages": tool_results}
```

## Summary

ToolNode executes tools and returns results as ToolMessage. You can add error handling, permission checks, logging, and more.

## Related Pages

- [04_tool_integration_tool_definition.md](04_tool_integration_tool_definition.md) - Tool definition
- [04_tool_integration_command_api.md](04_tool_integration_command_api.md) - Integration with Command API
- [05_advanced_features_human_in_the_loop.md](05_advanced_features_human_in_the_loop.md) - Combining with approval flows
