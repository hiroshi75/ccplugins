# Human-in-the-Loop (Approval Flow)

A feature to pause graph execution and request human intervention.

## Overview

Human-in-the-Loop is a feature that requests **human approval or input** before important decisions or actions.

## Dynamic Interrupt (Recommended)

### Basic Usage

```python
from langgraph.types import interrupt

def approval_node(state: State):
    """Request approval"""
    approved = interrupt("Do you approve this action?")

    if approved:
        return {"status": "approved"}
    else:
        return {"status": "rejected"}
```

### Execution

```python
# Initial execution (stops at interrupt)
result = graph.invoke(input, config)

# Check interrupt information
print(result["__interrupt__"])  # "Do you approve this action?"

# Approve and resume
graph.invoke(None, config, resume=True)

# Or reject
graph.invoke(None, config, resume=False)
```

## Application Patterns

### Pattern 1: Approve or Reject

```python
def action_approval(state: State):
    """Approval before action execution"""
    action_details = prepare_action(state)

    approved = interrupt({
        "question": "Approve this action?",
        "details": action_details
    })

    if approved:
        result = execute_action(action_details)
        return {"result": result, "approved": True}
    else:
        return {"result": None, "approved": False}
```

### Pattern 2: Editable Approval

```python
def review_and_edit(state: State):
    """Review and edit generated content"""
    generated = generate_content(state)

    edited_content = interrupt({
        "instruction": "Review and edit this content",
        "content": generated
    })

    return {"final_content": edited_content}

# Resume with edited version
graph.invoke(None, config, resume=edited_version)
```

### Pattern 3: Tool Execution Approval

```python
@tool
def send_email(to: str, subject: str, body: str):
    """Send email (with approval)"""
    response = interrupt({
        "action": "send_email",
        "to": to,
        "subject": subject,
        "body": body,
        "message": "Approve sending this email?"
    })

    if response.get("action") == "approve":
        # When approved, parameters can also be edited
        final_to = response.get("to", to)
        final_subject = response.get("subject", subject)
        final_body = response.get("body", body)

        return actually_send_email(final_to, final_subject, final_body)
    else:
        return "Email cancelled by user"
```

### Pattern 4: Input Validation Loop

```python
def get_valid_input(state: State):
    """Loop until valid input is obtained"""
    prompt = "Enter a positive number:"

    while True:
        answer = interrupt(prompt)

        if isinstance(answer, (int, float)) and answer > 0:
            break

        prompt = f"'{answer}' is invalid. Enter a positive number:"

    return {"value": answer}
```

## Static Interrupt (For Debugging)

Set breakpoints at compile time:

```python
graph = builder.compile(
    checkpointer=checkpointer,
    interrupt_before=["risky_node"],  # Stop before node execution
    interrupt_after=["generate_content"]  # Stop after node execution
)

# Execute (stops before specified node)
graph.invoke(input, config)

# Check state
state = graph.get_state(config)

# Resume
graph.invoke(None, config)
```

## Practical Example: Multi-Stage Approval Workflow

```python
from langgraph.types import interrupt, Command

class ApprovalState(TypedDict):
    request: str
    draft: str
    reviewed: str
    approved: bool

def draft_node(state: ApprovalState):
    """Create draft"""
    draft = create_draft(state["request"])
    return {"draft": draft}

def review_node(state: ApprovalState):
    """Review and edit"""
    reviewed = interrupt({
        "type": "review",
        "content": state["draft"],
        "instruction": "Review and improve the draft"
    })

    return {"reviewed": reviewed}

def approval_node(state: ApprovalState):
    """Final approval"""
    approved = interrupt({
        "type": "approval",
        "content": state["reviewed"],
        "question": "Approve for publication?"
    })

    if approved:
        return Command(
            update={"approved": True},
            goto="publish"
        )
    else:
        return Command(
            update={"approved": False},
            goto="draft"  # Return to draft
        )

def publish_node(state: ApprovalState):
    """Publish"""
    publish(state["reviewed"])
    return {"status": "published"}

# Build graph
builder.add_node("draft", draft_node)
builder.add_node("review", review_node)
builder.add_node("approval", approval_node)
builder.add_node("publish", publish_node)

builder.add_edge(START, "draft")
builder.add_edge("draft", "review")
builder.add_edge("review", "approval")
# approval node determines control flow with Command
builder.add_edge("publish", END)
```

## Important Rules

### ✅ Recommendations

- Pass values in JSON format
- Keep `interrupt()` call order consistent
- Make processing before `interrupt()` idempotent

### ❌ Prohibitions

- Don't catch `interrupt()` with `try-except`
- Don't skip `interrupt()` conditionally
- Don't pass non-serializable objects

## Use Cases

### 1. High-Risk Operation Approval

```python
def delete_data(state: State):
    """Delete data (approval required)"""
    approved = interrupt({
        "action": "delete_data",
        "warning": "This cannot be undone!",
        "data_count": len(state["data_to_delete"])
    })

    if approved:
        execute_delete(state["data_to_delete"])
        return {"deleted": True}
    return {"deleted": False}
```

### 2. Creative Work Review

```python
def creative_generation(state: State):
    """Creative content generation and review"""
    versions = []

    for _ in range(3):
        version = generate_creative(state["prompt"])
        versions.append(version)

    selected = interrupt({
        "type": "select_version",
        "versions": versions,
        "instruction": "Select the best version or request regeneration"
    })

    return {"final_version": selected}
```

### 3. Incremental Data Input

```python
def collect_user_info(state: State):
    """Collect user information incrementally"""
    name = interrupt("What is your name?")

    age = interrupt(f"Hello {name}, what is your age?")

    city = interrupt("What city do you live in?")

    return {
        "user_info": {
            "name": name,
            "age": age,
            "city": city
        }
    }
```

## Summary

Human-in-the-Loop is a feature for incorporating human judgment in important decisions. Dynamic interrupt is flexible and recommended.

## Related Pages

- [03_memory_management_persistence.md](03_memory_management_persistence.md) - Checkpointer is required
- [02_graph_architecture_agent.md](02_graph_architecture_agent.md) - Combination with agents
- [04_tool_integration_tool_node.md](04_tool_integration_tool_node.md) - Approval before tool execution
