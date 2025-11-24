# State

Memory shared across all nodes in the graph.

## Overview

State is like a "notebook" that records everything the agent learns and decides. It is a **shared data structure** accessible to all nodes and edges in the graph.

## Definition Methods

### Using TypedDict

```python
from typing import TypedDict

class State(TypedDict):
    messages: list[str]
    user_name: str
    count: int
```

### Using Pydantic Model

```python
from pydantic import BaseModel

class State(BaseModel):
    messages: list[str]
    user_name: str
    count: int = 0  # Default value
```

## Reducer (Controlling Update Methods)

A function that specifies how each key is updated. If not specified, it defaults to **value overwrite**.

### Addition (Adding to List)

```python
from typing import Annotated
from operator import add

class State(TypedDict):
    messages: Annotated[list[str], add]  # Add to existing list
    count: int  # Overwrite
```

### Custom Reducer

```python
def concat_strings(existing: str, new: str) -> str:
    return existing + " " + new

class State(TypedDict):
    text: Annotated[str, concat_strings]
```

## MessagesState (LLM Preset)

For LLM conversations, LangChain's `MessagesState` is convenient:

```python
from langgraph.graph import MessagesState

# This is equivalent to:
class MessagesState(TypedDict):
    messages: Annotated[list[AnyMessage], add_messages]
```

The `add_messages` reducer:
- Adds new messages
- Updates existing messages (ID-based)
- Supports OpenAI format shorthand

## Important Principles

1. **Store Raw Data**: Format prompts within nodes
2. **Clear Schema**: Define types with TypedDict or Pydantic
3. **Control with Reducer**: Explicitly specify update methods

## Example

```python
from typing import Annotated, TypedDict
from operator import add

class AgentState(TypedDict):
    # Messages are added to the list
    messages: Annotated[list[str], add]

    # User information is overwritten
    user_id: str
    user_name: str

    # Counter is also overwritten
    iteration_count: int
```

## Related Pages

- [01_core_concepts_node.md](01_core_concepts_node.md) - How to use State in nodes
- [03_memory_management_overview.md](03_memory_management_overview.md) - State persistence
