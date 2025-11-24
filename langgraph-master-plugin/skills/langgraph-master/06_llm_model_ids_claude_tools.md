# Claude Tool Use Guide

Implementation methods for Claude's tool use (Function Calling).

## Basic Tool Definition

```python
from langchain_anthropic import ChatAnthropic
from langchain_core.tools import tool

@tool
def get_weather(location: str) -> str:
    """Get weather for a specified location.

    Args:
        location: Location to check weather (e.g., "Tokyo")
    """
    return f"The weather in {location} is sunny"

@tool
def calculate(expression: str) -> float:
    """Calculate a mathematical expression.

    Args:
        expression: Mathematical expression to calculate (e.g., "2 + 2")
    """
    return eval(expression)

# Bind tools
llm = ChatAnthropic(model="claude-sonnet-4-5")
llm_with_tools = llm.bind_tools([get_weather, calculate])

# Usage
response = llm_with_tools.invoke("Tell me Tokyo's weather and 2+2")
print(response.tool_calls)
```

## Tool Integration with LangGraph

```python
from langgraph.prebuilt import create_react_agent
from langchain_anthropic import ChatAnthropic
from langchain_core.tools import tool

@tool
def search_database(query: str) -> str:
    """Search the database.

    Args:
        query: Search query
    """
    return f"Search results for '{query}'"

# Create agent
llm = ChatAnthropic(model="claude-sonnet-4-5")
tools = [search_database]

agent = create_react_agent(llm, tools)

# Execute
result = agent.invoke({
    "messages": [("user", "Search for user information")]
})
```

## Custom Tool Node Implementation

```python
from langgraph.graph import StateGraph
from langchain_anthropic import ChatAnthropic
from typing import TypedDict, Annotated
from langgraph.graph.message import add_messages

class State(TypedDict):
    messages: Annotated[list, add_messages]

@tool
def get_stock_price(symbol: str) -> float:
    """Get stock price"""
    return 150.25

llm = ChatAnthropic(model="claude-sonnet-4-5")
llm_with_tools = llm.bind_tools([get_stock_price])

def agent_node(state: State):
    response = llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

def tool_node(state: State):
    # Execute tool calls
    last_message = state["messages"][-1]
    tool_calls = last_message.tool_calls

    results = []
    for tool_call in tool_calls:
        tool_result = get_stock_price.invoke(tool_call["args"])
        results.append({
            "tool_call_id": tool_call["id"],
            "output": tool_result
        })

    return {"messages": results}

# Build graph
graph = StateGraph(State)
graph.add_node("agent", agent_node)
graph.add_node("tools", tool_node)
# ... Add edges, etc.
```

## Streaming + Tool Use

```python
from langchain_anthropic import ChatAnthropic
from langchain_core.tools import tool

@tool
def get_info(topic: str) -> str:
    """Get information"""
    return f"Information about {topic}"

llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    streaming=True
)
llm_with_tools = llm.bind_tools([get_info])

for chunk in llm_with_tools.stream("Tell me about Python"):
    if hasattr(chunk, 'tool_calls') and chunk.tool_calls:
        print(f"Tool: {chunk.tool_calls}")
    elif chunk.content:
        print(chunk.content, end="", flush=True)
```

## Error Handling

```python
from langchain_anthropic import ChatAnthropic
from langchain_core.tools import tool
import anthropic

@tool
def risky_operation(data: str) -> str:
    """Risky operation"""
    if not data:
        raise ValueError("Data is required")
    return f"Processing complete: {data}"

try:
    llm = ChatAnthropic(model="claude-sonnet-4-5")
    llm_with_tools = llm.bind_tools([risky_operation])
    response = llm_with_tools.invoke("Execute operation")
except anthropic.BadRequestError as e:
    print(f"Invalid request: {e}")
except Exception as e:
    print(f"Error: {e}")
```

## Tool Best Practices

### 1. Clear Documentation

```python
@tool
def analyze_sentiment(text: str, language: str = "en") -> dict:
    """Perform sentiment analysis on text.

    Args:
        text: Text to analyze (max 1000 characters)
        language: Language of text ("ja", "en", etc.) defaults to English

    Returns:
        {"sentiment": "positive|negative|neutral", "score": 0.0-1.0}
    """
    # Implementation
    return {"sentiment": "positive", "score": 0.8}
```

### 2. Use Type Hints

```python
from typing import List, Dict

@tool
def batch_process(items: List[str]) -> Dict[str, int]:
    """Batch process multiple items.

    Args:
        items: List of items to process

    Returns:
        Dictionary of processing results for each item
    """
    return {item: len(item) for item in items}
```

### 3. Proper Error Handling

```python
@tool
def safe_operation(data: str) -> str:
    """Safe operation"""
    try:
        # Execute operation
        result = process(data)
        return result
    except ValueError as e:
        return f"Input error: {e}"
    except Exception as e:
        return f"Unexpected error: {e}"
```

## Reference Links

- [Claude Tool Use Guide](https://docs.anthropic.com/en/docs/tool-use)
- [LangGraph Tools Documentation](https://langchain-ai.github.io/langgraph/concepts/agentic_concepts/)
