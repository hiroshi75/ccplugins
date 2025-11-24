# Checkpointer

Implementation details for saving and restoring state.

## Overview

Checkpointer implements the `BaseCheckpointSaver` interface and is responsible for state persistence.

## Checkpointer Implementations

### 1. MemorySaver (For Experimentation & Testing)

Saves checkpoints in memory:

```python
from langgraph.checkpoint.memory import MemorySaver

checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)

# All data is lost when the process terminates
```

**Use Case**: Local testing, prototyping

### 2. SqliteSaver (For Local Development)

Saves to SQLite database:

```python
from langgraph.checkpoint.sqlite import SqliteSaver

# File-based
checkpointer = SqliteSaver.from_conn_string("checkpoints.db")

# Or from connection object
import sqlite3
conn = sqlite3.connect("checkpoints.db")
checkpointer = SqliteSaver(conn)

graph = builder.compile(checkpointer=checkpointer)
```

**Use Case**: Local development, single-user applications

### 3. PostgresSaver (For Production)

Saves to PostgreSQL database:

```python
from langgraph.checkpoint.postgres import PostgresSaver
from psycopg_pool import ConnectionPool

# Connection pool
pool = ConnectionPool(
    conninfo="postgresql://user:password@localhost:5432/db"
)

checkpointer = PostgresSaver(pool)
graph = builder.compile(checkpointer=checkpointer)
```

**Use Case**: Production environments, multi-user applications

## BaseCheckpointSaver Interface

All checkpointers implement the following methods:

```python
class BaseCheckpointSaver:
    def put(
        self,
        config: RunnableConfig,
        checkpoint: Checkpoint,
        metadata: dict
    ) -> RunnableConfig:
        """Save a checkpoint"""

    def get_tuple(
        self,
        config: RunnableConfig
    ) -> CheckpointTuple | None:
        """Retrieve a checkpoint"""

    def list(
        self,
        config: RunnableConfig,
        *,
        before: RunnableConfig | None = None,
        limit: int | None = None
    ) -> Iterator[CheckpointTuple]:
        """Get list of checkpoints"""
```

## Custom Checkpointer

Implement your own persistence logic:

```python
from langgraph.checkpoint.base import BaseCheckpointSaver

class RedisCheckpointer(BaseCheckpointSaver):
    def __init__(self, redis_client):
        self.redis = redis_client

    def put(self, config, checkpoint, metadata):
        thread_id = config["configurable"]["thread_id"]
        checkpoint_id = checkpoint["id"]

        key = f"checkpoint:{thread_id}:{checkpoint_id}"
        self.redis.set(key, serialize(checkpoint))

        return config

    def get_tuple(self, config):
        thread_id = config["configurable"]["thread_id"]
        # Retrieve the latest checkpoint
        # ...

    def list(self, config, before=None, limit=None):
        # Return list of checkpoints
        # ...
```

## Checkpointer Configuration

### Namespaces

Share the same checkpointer across multiple graphs:

```python
checkpointer = MemorySaver()

graph1 = builder1.compile(
    checkpointer=checkpointer,
    name="graph1"  # Namespace
)

graph2 = builder2.compile(
    checkpointer=checkpointer,
    name="graph2"  # Different namespace
)
```

### Automatic Propagation

Parent graph's checkpointer automatically propagates to subgraphs:

```python
# Set only on parent graph
parent_graph = parent_builder.compile(checkpointer=checkpointer)

# Automatically propagates to child graphs
```

## Checkpoint Management

### Deleting Old Checkpoints

```python
# Delete after a certain period (implementation-dependent)
import datetime

cutoff = datetime.datetime.now() - datetime.timedelta(days=30)

# Implementation example (SQLite)
checkpointer.conn.execute(
    "DELETE FROM checkpoints WHERE created_at < ?",
    (cutoff,)
)
```

### Optimizing Checkpoint Size

```python
class State(TypedDict):
    # Avoid large data
    messages: Annotated[list, add_messages]

    # Store references only
    large_data_id: str  # Actual data in separate storage

def node(state: State):
    # Retrieve large data from external source
    large_data = fetch_from_storage(state["large_data_id"])
    # ...
```

## Performance Considerations

### Connection Pool (PostgreSQL)

```python
from psycopg_pool import ConnectionPool

pool = ConnectionPool(
    conninfo=conn_string,
    min_size=5,
    max_size=20
)

checkpointer = PostgresSaver(pool)
```

### Async Checkpointer

```python
from langgraph.checkpoint.postgres import AsyncPostgresSaver

async_checkpointer = AsyncPostgresSaver(async_pool)

# Async execution
async for chunk in graph.astream(input, config):
    print(chunk)
```

## Summary

Checkpointer determines how state is persisted. It's important to choose the appropriate implementation for your use case.

## Related Pages

- [03_memory_management_persistence.md](03_memory_management_persistence.md) - How to use persistence
- [03_memory_management_store.md](03_memory_management_store.md) - Differences from long-term memory
