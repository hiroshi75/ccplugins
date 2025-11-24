# Streaming

A feature to monitor graph execution progress in real-time.

## Overview

Streaming is a feature that receives **real-time updates** during graph execution. You can stream LLM tokens, state changes, custom events, and more.

## Types of stream_mode

### 1. values (Complete State Snapshot)

Complete state after each step:

```python
for chunk in graph.stream(input, stream_mode="values"):
    print(chunk)

# Example output
# {"messages": [{"role": "user", "content": "Hello"}]}
# {"messages": [{"role": "user", "content": "Hello"}, {"role": "assistant", "content": "Hi!"}]}
```

### 2. updates (Only State Changes)

Only changes at each step:

```python
for chunk in graph.stream(input, stream_mode="updates"):
    print(chunk)

# Example output
# {"messages": [{"role": "assistant", "content": "Hi!"}]}
```

### 3. messages (LLM Tokens)

Stream at token level from LLM:

```python
for msg, metadata in graph.stream(input, stream_mode="messages"):
    if msg.content:
        print(msg.content, end="", flush=True)

# Output: "H" "i" "!" " " "H" "o" "w" ... (token by token)
```

### 4. debug (Debug Information)

Detailed graph execution information:

```python
for chunk in graph.stream(input, stream_mode="debug"):
    print(chunk)

# Details like node execution, edge transitions, etc.
```

### 5. custom (Custom Data)

Send custom data from nodes:

```python
from langgraph.config import get_stream_writer

def my_node(state: State):
    writer = get_stream_writer()

    for i in range(10):
        writer({"progress": i * 10})  # Custom data

    return {"result": "done"}

for mode, chunk in graph.stream(input, stream_mode=["updates", "custom"]):
    if mode == "custom":
        print(f"Progress: {chunk['progress']}%")
```

## LLM Token Streaming

### Stream Only Specific Nodes

```python
for msg, metadata in graph.stream(input, stream_mode="messages"):
    # Display tokens only from specific node
    if metadata["langgraph_node"] == "chatbot":
        if msg.content:
            print(msg.content, end="", flush=True)

print()  # Newline
```

### Filter by Tags

```python
# Set tags on LLM
llm = init_chat_model("gpt-5", tags=["main_llm"])

for msg, metadata in graph.stream(input, stream_mode="messages"):
    if "main_llm" in metadata.get("tags", []):
        if msg.content:
            print(msg.content, end="", flush=True)
```

## Using Multiple Modes Simultaneously

```python
for mode, chunk in graph.stream(input, stream_mode=["values", "messages"]):
    if mode == "values":
        print(f"\nState: {chunk}")
    elif mode == "messages":
        if chunk[0].content:
            print(chunk[0].content, end="", flush=True)
```

## Subgraph Streaming

```python
# Include subgraph outputs
for chunk in graph.stream(
    input,
    stream_mode="updates",
    subgraphs=True  # Include subgraphs
):
    print(chunk)
```

## Practical Example: Progress Bar

```python
from tqdm import tqdm

def process_with_progress(items: list):
    """Processing with progress bar"""
    total = len(items)

    with tqdm(total=total) as pbar:
        for chunk in graph.stream(
            {"items": items},
            stream_mode="custom"
        ):
            if "progress" in chunk:
                pbar.update(1)

    return "Complete!"
```

## Practical Example: Real-time UI Updates

```python
import streamlit as st

def run_with_ui_updates(user_input: str):
    """Update Streamlit UI in real-time"""
    status = st.empty()
    output = st.empty()

    full_response = ""

    for msg, metadata in graph.stream(
        {"messages": [{"role": "user", "content": user_input}]},
        stream_mode="messages"
    ):
        if msg.content:
            full_response += msg.content
            output.markdown(full_response + "▌")

        status.text(f"Node: {metadata['langgraph_node']}")

    output.markdown(full_response)
    status.text("Complete!")
```

## Async Streaming

```python
async def async_stream_example():
    """Async streaming"""
    async for chunk in graph.astream(input, stream_mode="updates"):
        print(chunk)
        await asyncio.sleep(0)  # Yield to other tasks
```

## Sending Custom Events

```python
from langgraph.config import get_stream_writer

def multi_step_node(state: State):
    """Report progress of multiple steps"""
    writer = get_stream_writer()

    # Step 1
    writer({"status": "Analyzing..."})
    analysis = analyze_data(state["data"])

    # Step 2
    writer({"status": "Processing..."})
    result = process_analysis(analysis)

    # Step 3
    writer({"status": "Finalizing..."})
    final = finalize(result)

    return {"result": final}

# Receive
for mode, chunk in graph.stream(input, stream_mode=["updates", "custom"]):
    if mode == "custom":
        print(chunk["status"])
```

## Summary

Streaming monitors progress in real-time and improves user experience. Choose the appropriate stream_mode based on your use case.

## Related Pages

- [02_graph_architecture_agent.md](02_graph_architecture_agent.md) - Agent streaming
- [05_advanced_features_human_in_the_loop.md](05_advanced_features_human_in_the_loop.md) - Combining streaming and approval
