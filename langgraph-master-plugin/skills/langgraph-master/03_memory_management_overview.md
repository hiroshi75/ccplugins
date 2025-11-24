# 03. Memory Management

State management through persistence and checkpoint features.

## Overview

LangGraph's **built-in persistence layer** allows you to save and restore agent state. This enables conversation continuation, error recovery, and time travel.

## Memory Types

### Short-term Memory: [Checkpointer](03_memory_management_checkpointer.md)
- Automatically saves state at each superstep
- Thread-based conversation management
- Time travel functionality

### Long-term Memory: [Store](03_memory_management_store.md)
- Share information across threads
- Persist user information
- Semantic search

## Key Features

### 1. [Persistence](03_memory_management_persistence.md)

**Checkpoints**: Save state at each superstep
- Snapshot state at each stage of graph execution
- Recoverable from failures
- Track execution history

**Threads**: Unit of conversation
- Identify conversations by `thread_id`
- Each thread maintains independent state
- Manage multiple conversations in parallel

**StateSnapshot**: Representation of checkpoints
- `values`: State at that point in time
- `next`: Nodes to execute next
- `config`: Checkpoint configuration
- `metadata`: Metadata

### 2. Human-in-the-Loop

**State Inspection**: Check state at any point
```python
state = graph.get_state(config)
print(state.values)
```

**Approval Flow**: Human approval before critical operations
```python
# Pause graph and wait for approval
```

### 3. Memory

**Conversation Memory**: Memory within a thread
```python
# Conversation continues when called with the same thread_id
config = {"configurable": {"thread_id": "conversation-1"}}
graph.invoke(input, config)
```

**Long-term Memory**: Memory across threads
```python
# Save user information in Store
store.put(("user", user_id), "preferences", user_prefs)
```

### 4. Time Travel

Replay and fork past executions:
```python
# Resume from specific checkpoint
history = graph.get_state_history(config)
for state in history:
    print(f"Checkpoint: {state.config['configurable']['checkpoint_id']}")

# Re-execute from past checkpoint
graph.invoke(input, past_checkpoint_config)
```

## Checkpointer Implementations

LangGraph provides multiple checkpointer implementations:

### InMemorySaver (For Experimentation)
```python
from langgraph.checkpoint.memory import MemorySaver

checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)
```

### SqliteSaver (For Local Development)
```python
from langgraph.checkpoint.sqlite import SqliteSaver

checkpointer = SqliteSaver.from_conn_string("checkpoints.db")
graph = builder.compile(checkpointer=checkpointer)
```

### PostgresSaver (For Production)
```python
from langgraph.checkpoint.postgres import PostgresSaver

checkpointer = PostgresSaver.from_conn_string(
    "postgresql://user:pass@localhost/db"
)
graph = builder.compile(checkpointer=checkpointer)
```

## Basic Usage Example

```python
from langgraph.checkpoint.memory import MemorySaver

# Compile with checkpointer
checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)

# Execute with thread_id
config = {"configurable": {"thread_id": "user-123"}}

# First execution
result1 = graph.invoke({"messages": [("user", "Hello")]}, config)

# Continue in same thread
result2 = graph.invoke({"messages": [("user", "How are you?")]}, config)

# Check state
state = graph.get_state(config)
print(state.values)  # All messages so far

# Check history
for state in graph.get_state_history(config):
    print(f"Step: {state.values}")
```

## Key Principles

1. **Thread ID Management**: Use unique thread_id for each conversation
2. **Checkpointer Selection**: Choose appropriate implementation for your use case
3. **State Minimization**: Save only necessary information to keep checkpoint size small
4. **Cleanup**: Periodically delete old checkpoints

## Next Steps

For details on each feature, refer to the following pages:

- [03_memory_management_persistence.md](03_memory_management_persistence.md) - Persistence details
- [03_memory_management_checkpointer.md](03_memory_management_checkpointer.md) - Checkpointer implementation
- [03_memory_management_store.md](03_memory_management_store.md) - Long-term memory management
