# Phase 1: Preparation and Analysis Examples

Practical code examples and templates.

**📋 Related Documentation**: [Examples Home](./examples.md) | [Workflow Phase 1](./workflow_phase1.md)

---

## Phase 1: Preparation and Analysis Examples

### Example 1.1: fine-tune.md Structure Example

**File**: `.langgraph-master/fine-tune.md`

```markdown
# Fine-Tuning Goals

## Optimization Objectives

- **Accuracy**: Improve user intent classification accuracy to 90% or higher
- **Latency**: Reduce response time to 2.0 seconds or less
- **Cost**: Reduce cost per request to $0.010 or less

## Evaluation Method

### Test Cases

- **Dataset**: tests/evaluation/test_cases.json (20 cases)
- **Execution Command**: uv run python -m src.evaluate
- **Evaluation Script**: tests/evaluation/evaluator.py

### Evaluation Metrics

#### Accuracy (Correctness Rate)

- **Calculation Method**: (Number of correct answers / Total cases) × 100
- **Target Value**: 90% or higher

#### Latency (Response Time)

- **Calculation Method**: Average time of each execution
- **Target Value**: 2.0 seconds or less

#### Cost

- **Calculation Method**: Total API cost / Total number of requests
- **Target Value**: $0.010 or less

## Pass Criteria

All evaluation metrics must achieve their target values.
```

### Example 1.2: Optimization Target List Example

```markdown
# Optimization Target Nodes

## Node: analyze_intent

### Basic Information

- **File**: src/nodes/analyzer.py:25-45
- **Role**: Classify user input intent
- **LLM Model**: claude-3-5-sonnet-20241022
- **Current Parameters**: temperature=1.0, max_tokens=default

### Current Prompt

\```python
SystemMessage(content="You are an intent analyzer. Analyze user input.")
HumanMessage(content=f"Analyze: {user_input}")
\```

### Issues

1. **Ambiguous instructions**: Specific criteria for "Analyze" are unclear
2. **No few-shot examples**: No expected output examples
3. **Undefined output format**: Free text, not structured
4. **High temperature**: 1.0 is too high for classification tasks

### Improvement Proposals

1. Specify concrete classification categories
2. Add 3-5 few-shot examples
3. Specify JSON output format
4. Lower temperature to 0.3-0.5

### Estimated Improvement Effect

- **Accuracy**: +10-15% (Current misclassification 20% → 5-10%)
- **Latency**: ±0 (no change)
- **Cost**: ±0 (no change)

### Priority

⭐⭐⭐⭐⭐ (Highest priority) - Direct impact on accuracy improvement

---

## Node: generate_response

### Basic Information

- **File**: src/nodes/generator.py:45-68
- **Role**: Generate final user-facing response
- **LLM Model**: claude-3-5-sonnet-20241022
- **Current Parameters**: temperature=0.7, max_tokens=default

### Current Prompt

\```python
ChatPromptTemplate.from_messages([
    ("system", "Generate helpful response based on context."),
    ("human", "{context}\n\nQuestion: {question}")
])
\```

### Issues

1. **No redundancy control**: No instructions for conciseness
2. **max_tokens not set**: Possibility of unnecessarily long output
3. **Response style undefined**: No specification of tone or style

### Improvement Proposals

1. Add length instructions like "concisely" "in 2-3 sentences"
2. Limit max_tokens to 500
3. Clarify response style ("friendly" "professional", etc.)

### Estimated Improvement Effect

- **Accuracy**: ±0 (no change)
- **Latency**: -0.3-0.5s (due to reduced output tokens)
- **Cost**: -20-30% (due to reduced token count)

### Priority

⭐⭐⭐ (Medium) - Improvement in latency and cost
```

### Example 1.3: Code Search Example with Serena MCP

```python
# Search for LLM client
from mcp_serena import find_symbol, find_referencing_symbols

# Step 1: Search for ChatAnthropic usage locations
chat_anthropic_usages = find_symbol(
    name_path="ChatAnthropic",
    substring_matching=True,
    include_body=False
)

print(f"Found {len(chat_anthropic_usages)} ChatAnthropic usages")

# Step 2: Investigate details of each usage location
for usage in chat_anthropic_usages:
    print(f"\nFile: {usage.relative_path}:{usage.line_start}")
    print(f"Context: {usage.name_path}")

    # Identify prompt construction locations
    references = find_referencing_symbols(
        name_path=usage.name,
        relative_path=usage.relative_path
    )

    # Display locations that may contain prompts
    for ref in references:
        if "message" in ref.name.lower() or "prompt" in ref.name.lower():
            print(f"  - Potential prompt location: {ref.name_path}")
```

---
