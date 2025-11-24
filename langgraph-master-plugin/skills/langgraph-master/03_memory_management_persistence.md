# Persistence

Functionality to save and restore graph state.

## Overview

Persistence is a feature that **automatically saves** state at each stage of graph execution and allows you to restore it later.

## Basic Concepts

### Checkpoints

State is automatically saved after each **superstep** (set of nodes executed in parallel).

```python
# Superstep 1: node_a and node_b execute in parallel
# → Checkpoint 1

# Superstep 2: node_c executes
# → Checkpoint 2

# Superstep 3: node_d executes
# → Checkpoint 3
```

### Threads

A thread is an identifier containing the **accumulated state of a series of executions**:

```python
config = {"configurable": {"thread_id": "conversation-123"}}
```

Executing with the same `thread_id` continues from the previous state.

## Implementation Example

```python
from langgraph.checkpoint.memory import MemorySaver
from langgraph.graph import StateGraph, MessagesState

# Define graph
builder = StateGraph(MessagesState)
builder.add_node("chatbot", chatbot_node)
builder.add_edge(START, "chatbot")
builder.add_edge("chatbot", END)

# Compile with checkpointer
checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)

# Execute with thread ID
config = {"configurable": {"thread_id": "user-001"}}

# First execution
graph.invoke(
    {"messages": [{"role": "user", "content": "My name is Alice"}]},
    config
)

# Continue in same thread (retains previous state)
response = graph.invoke(
    {"messages": [{"role": "user", "content": "What's my name?"}]},
    config
)

# → "Your name is Alice"
```

## StateSnapshot Object

Checkpoints are represented as `StateSnapshot` objects:

```python
class StateSnapshot:
    values: dict          # State at that point in time
    next: tuple[str]      # Nodes to execute next
    config: RunnableConfig  # Checkpoint configuration
    metadata: dict        # Metadata
    tasks: tuple[PregelTask]  # Scheduled tasks
```

### Getting Latest State

```python
state = graph.get_state(config)

print(state.values)      # Current state
print(state.next)        # Next nodes
print(state.config)      # Checkpoint configuration
```

### Getting History

```python
# Get list of StateSnapshots in chronological order
for state in graph.get_state_history(config):
    print(f"Checkpoint: {state.config['configurable']['checkpoint_id']}")
    print(f"Values: {state.values}")
    print(f"Next: {state.next}")
    print("---")
```

## Time Travel Feature

Resume execution from a specific checkpoint:

```python
# Get specific checkpoint from history
history = list(graph.get_state_history(config))

# Checkpoint from 3 steps ago
past_state = history[3]

# Re-execute from that checkpoint
result = graph.invoke(
    {"messages": [{"role": "user", "content": "New question"}]},
    past_state.config
)
```

### Validating Alternative Paths

```python
# Get current state
current_state = graph.get_state(config)

# Try with different input
alt_result = graph.invoke(
    {"messages": [{"role": "user", "content": "Different question"}]},
    current_state.config
)

# Original execution is not affected
```

## Updating State

Directly update checkpoint state:

```python
# Get current state
state = graph.get_state(config)

# Update state
graph.update_state(
    config,
    {"messages": [{"role": "assistant", "content": "Updated message"}]}
)

# Resume from updated state
graph.invoke({"messages": [...]}, config)
```

## Use Cases

### 1. Conversation Continuation

```python
# Session 1
config = {"configurable": {"thread_id": "chat-1"}}
graph.invoke({"messages": [("user", "Hello")]}, config)

# Session 2 (days later)
# Remembers previous conversation
graph.invoke({"messages": [("user", "Continuing from last time")]}, config)
```

### 2. Error Recovery

```python
try:
    graph.invoke(input, config)
except Exception as e:
    # Even if error occurs, can recover from checkpoint
    print(f"Error: {e}")

    # Check latest state
    state = graph.get_state(config)

    # Fix state and re-execute
    graph.update_state(config, {"error_fixed": True})
    graph.invoke(input, config)
```

### 3. A/B Testing

```python
# Base execution
base_result = graph.invoke(input, base_config)

# Alternative execution 1
alt_config_1 = base_config.copy()
alt_result_1 = graph.invoke(modified_input_1, alt_config_1)

# Alternative execution 2
alt_config_2 = base_config.copy()
alt_result_2 = graph.invoke(modified_input_2, alt_config_2)

# Compare results
```

### 4. Debugging and Tracing

```python
# Execute
graph.invoke(input, config)

# Check each step
for i, state in enumerate(graph.get_state_history(config)):
    print(f"Step {i}:")
    print(f"  State: {state.values}")
    print(f"  Next: {state.next}")
```

## Important Considerations

### Thread ID Uniqueness

```python
# Use different thread_id per user
user_config = {"configurable": {"thread_id": f"user-{user_id}"}}

# Use different thread_id per conversation
conversation_config = {"configurable": {"thread_id": f"conv-{conv_id}"}}
```

### Checkpoint Cleanup

```python
# Delete old checkpoints (implementation-dependent)
checkpointer.cleanup(before_timestamp=old_timestamp)
```

### Multi-user Support

```python
# Combine user ID and session ID
def get_config(user_id: str, session_id: str):
    return {
        "configurable": {
            "thread_id": f"{user_id}-{session_id}"
        }
    }

config = get_config("user123", "session456")
```

## Best Practices

1. **Meaningful thread_id**: Format that can identify user, session, conversation
2. **Regular Cleanup**: Delete old checkpoints
3. **Appropriate Checkpointer**: Choose implementation based on use case
4. **Error Handling**: Properly handle errors when retrieving checkpoints

## Summary

Persistence enables **state persistence and restoration**, making conversation continuation, error recovery, and time travel possible.

## Related Pages

- [03_memory_management_checkpointer.md](03_memory_management_checkpointer.md) - Checkpointer implementation details
- [03_memory_management_store.md](03_memory_management_store.md) - Combining with long-term memory
- [05_advanced_features_human_in_the_loop.md](05_advanced_features_human_in_the_loop.md) - Applications of state inspection
