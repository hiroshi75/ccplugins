# Store (Long-term Memory)

Long-term memory for sharing information across multiple threads.

## Overview

Checkpointer only saves state within a single thread. To share information across multiple threads, use **Store**.

## Checkpointer vs Store

| Feature | Checkpointer | Store |
|---------|-------------|-------|
| Scope | Single thread | All threads |
| Purpose | Conversation state | User information |
| Auto-save | Yes | No (manual) |
| Search | thread_id | Namespace |

## Basic Usage

```python
from langgraph.store.memory import InMemoryStore

# Create Store
store = InMemoryStore()

# Save user information
store.put(
    namespace=("users", "user-123"),
    key="preferences",
    value={
        "language": "en",
        "theme": "dark",
        "notifications": True
    }
)

# Retrieve user information
user_prefs = store.get(("users", "user-123"), "preferences")
```

## Namespace

Namespaces are grouped by **tuples**:

```python
# User information
("users", user_id)

# Session information
("sessions", session_id)

# Project information
("projects", project_id, "documents")

# Hierarchical structure
("organization", org_id, "department", dept_id)
```

## Store Operations

### Save

```python
store.put(
    namespace=("users", "alice"),
    key="profile",
    value={
        "name": "Alice",
        "email": "alice@example.com",
        "joined": "2024-01-01"
    }
)
```

### Retrieve

```python
# Single item
profile = store.get(("users", "alice"), "profile")

# All items in namespace
items = store.search(("users", "alice"))
```

### Search

```python
# Filter by namespace
all_users = store.search(("users",))

# Filter by key
profiles = store.search(("users",), filter={"key": "profile"})
```

### Delete

```python
# Single item
store.delete(("users", "alice"), "profile")

# Entire namespace
store.delete_namespace(("users", "alice"))
```

## Integration with Graph

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()

# Integrate Store with graph
graph = builder.compile(
    checkpointer=checkpointer,
    store=store
)

# Use Store within nodes
def personalized_node(state: State, *, store):
    user_id = state["user_id"]

    # Get user preferences
    prefs = store.get(("users", user_id), "preferences")

    # Process based on preferences
    if prefs and prefs.value.get("language") == "en":
        response = generate_english_response(state)
    else:
        response = generate_default_response(state)

    return {"response": response}
```

## Semantic Search

Store implementations with vector search capability:

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore(index={"embed": True})

# Save documents (automatically vectorized)
store.put(
    ("documents", "doc-1"),
    "content",
    {"text": "LangGraph is an agent framework"}
)

# Semantic search
results = store.search(
    ("documents",),
    query="agent development"
)
```

## Practical Example: User Profile

```python
class ProfileState(TypedDict):
    user_id: str
    messages: Annotated[list, add_messages]

def save_user_info(state: ProfileState, *, store):
    """Extract and save user information from conversation"""
    messages = state["messages"]
    user_id = state["user_id"]

    # Extract information with LLM
    info = extract_user_info(messages)

    if info:
        # Save to Store
        current = store.get(("users", user_id), "profile")

        if current:
            # Merge with existing information
            updated = {**current.value, **info}
        else:
            updated = info

        store.put(
            ("users", user_id),
            "profile",
            updated
        )

    return {}

def personalized_response(state: ProfileState, *, store):
    """Personalize using user information"""
    user_id = state["user_id"]

    # Get user information
    profile = store.get(("users", user_id), "profile")

    if profile:
        context = f"User context: {profile.value}"
        messages = [
            {"role": "system", "content": context},
            *state["messages"]
        ]
    else:
        messages = state["messages"]

    response = llm.invoke(messages)
    return {"messages": [response]}
```

## Practical Example: Knowledge Base

```python
def query_knowledge_base(state: State, *, store):
    """Search for knowledge related to question"""
    query = state["messages"][-1].content

    # Semantic search
    relevant_docs = store.search(
        ("knowledge",),
        query=query,
        limit=3
    )

    # Add relevant information to context
    context = "\n".join([
        doc.value["text"]
        for doc in relevant_docs
    ])

    # Pass to LLM
    response = llm.invoke([
        {"role": "system", "content": f"Context:\n{context}"},
        *state["messages"]
    ])

    return {"messages": [response]}
```

## Store Implementations

### InMemoryStore

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()
```

### Custom Store

```python
from langgraph.store.base import BaseStore

class RedisStore(BaseStore):
    def __init__(self, redis_client):
        self.redis = redis_client

    def put(self, namespace, key, value):
        ns_key = f"{':'.join(namespace)}:{key}"
        self.redis.set(ns_key, json.dumps(value))

    def get(self, namespace, key):
        ns_key = f"{':'.join(namespace)}:{key}"
        data = self.redis.get(ns_key)
        return json.loads(data) if data else None

    def search(self, namespace, filter=None):
        pattern = f"{':'.join(namespace)}:*"
        keys = self.redis.keys(pattern)
        return [self.get_by_key(k) for k in keys]
```

## Best Practices

1. **Namespace Design**: Hierarchical and meaningful structure
2. **Key Naming**: Clear and consistent naming conventions
3. **Data Size**: Store references only for large data
4. **Cleanup**: Periodic deletion of old data

## Summary

Store is long-term memory for sharing information across multiple threads. Use it for persisting user profiles, knowledge bases, settings, etc.

## Related Pages

- [03_memory_management_checkpointer.md](03_memory_management_checkpointer.md) - Differences from short-term memory
- [03_memory_management_persistence.md](03_memory_management_persistence.md) - Persistence basics
