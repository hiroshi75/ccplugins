# Evaluator-Optimizer (Evaluation-Improvement Loop)

A pattern that repeats generation and evaluation, continuing iterative improvement until acceptable criteria are met.

## Overview

Evaluator-Optimizer is a pattern that repeats the **generate → evaluate → improve** loop, continuing until quality standards are met.

## Use Cases

- Code generation and quality verification
- Translation accuracy improvement
- Gradual content improvement
- Iterative solution for optimization problems

## Implementation Example: Translation Quality Improvement

```python
from typing import TypedDict

class State(TypedDict):
    original_text: str
    translated_text: str
    quality_score: float
    iteration: int
    max_iterations: int
    feedback: str

def generator_node(state: State):
    """Generate or improve translation"""
    if state.get("translated_text"):
        # Improve existing translation
        prompt = f"""
        Original: {state['original_text']}
        Current translation: {state['translated_text']}
        Feedback: {state['feedback']}

        Improve the translation based on the feedback.
        """
    else:
        # Initial translation
        prompt = f"Translate to Japanese: {state['original_text']}"

    translated = llm.invoke(prompt)

    return {
        "translated_text": translated,
        "iteration": state.get("iteration", 0) + 1
    }

def evaluator_node(state: State):
    """Evaluate translation quality"""
    evaluation_prompt = f"""
    Original: {state['original_text']}
    Translation: {state['translated_text']}

    Rate the translation quality (0-1) and provide specific feedback.
    Format: SCORE: 0.X\nFEEDBACK: ...
    """

    result = llm.invoke(evaluation_prompt)

    # Extract score and feedback
    score = extract_score(result)
    feedback = extract_feedback(result)

    return {
        "quality_score": score,
        "feedback": feedback
    }

def should_continue(state: State) -> Literal["improve", "done"]:
    """Continuation decision"""
    # Check if quality standard is met
    if state["quality_score"] >= 0.9:
        return "done"

    # Check if maximum iterations reached
    if state["iteration"] >= state["max_iterations"]:
        return "done"

    return "improve"

# Build graph
builder = StateGraph(State)

builder.add_node("generator", generator_node)
builder.add_node("evaluator", evaluator_node)

builder.add_edge(START, "generator")
builder.add_edge("generator", "evaluator")

builder.add_conditional_edges(
    "evaluator",
    should_continue,
    {
        "improve": "generator",  # Loop
        "done": END
    }
)

graph = builder.compile()
```

## Advanced Patterns

### Pattern 1: Multiple Evaluation Criteria

```python
class MultiEvalState(TypedDict):
    content: str
    scores: dict[str, float]  # Multiple evaluation scores
    min_scores: dict[str, float]  # Minimum value for each criterion

def multi_evaluator(state: State):
    """Evaluate from multiple perspectives"""
    content = state["content"]

    # Evaluate each perspective
    scores = {
        "accuracy": evaluate_accuracy(content),
        "readability": evaluate_readability(content),
        "completeness": evaluate_completeness(content)
    }

    return {"scores": scores}

def multi_should_continue(state: MultiEvalState):
    """Check if all criteria are met"""
    for criterion, min_score in state["min_scores"].items():
        if state["scores"][criterion] < min_score:
            return "improve"

    return "done"
```

### Pattern 2: Progressive Criteria Increase

```python
def adaptive_evaluator(state: State):
    """Adjust criteria based on iteration"""
    iteration = state["iteration"]

    # Start with lenient criteria, gradually stricter
    threshold = 0.7 + (iteration * 0.05)
    threshold = min(threshold, 0.95)  # Maximum 0.95

    score = evaluate(state["content"])

    return {
        "quality_score": score,
        "threshold": threshold
    }

def adaptive_should_continue(state: State):
    if state["quality_score"] >= state["threshold"]:
        return "done"

    if state["iteration"] >= state["max_iterations"]:
        return "done"

    return "improve"
```

### Pattern 3: Multiple Improvement Strategies

```python
from typing import Literal

def strategy_router(state: State) -> Literal["minor_fix", "major_rewrite"]:
    """Select improvement strategy based on score"""
    score = state["quality_score"]

    if score >= 0.7:
        # Minor adjustments sufficient
        return "minor_fix"
    else:
        # Major rewrite needed
        return "major_rewrite"

def minor_fix_node(state: State):
    """Small improvements"""
    prompt = f"Make minor improvements: {state['content']}\n{state['feedback']}"
    return {"content": llm.invoke(prompt)}

def major_rewrite_node(state: State):
    """Major rewrite"""
    prompt = f"Completely rewrite: {state['content']}\n{state['feedback']}"
    return {"content": llm.invoke(prompt)}

builder.add_conditional_edges(
    "evaluator",
    strategy_router,
    {
        "minor_fix": "minor_fix",
        "major_rewrite": "major_rewrite"
    }
)
```

### Pattern 4: Early Termination and Timeout

```python
import time

class TimedState(TypedDict):
    content: str
    quality_score: float
    iteration: int
    start_time: float
    max_duration: float  # seconds

def timed_should_continue(state: TimedState):
    """Check both quality criteria and timeout"""
    # Quality standard met
    if state["quality_score"] >= 0.9:
        return "done"

    # Timeout
    elapsed = time.time() - state["start_time"]
    if elapsed >= state["max_duration"]:
        return "timeout"

    # Maximum iterations
    if state["iteration"] >= 10:
        return "max_iterations"

    return "improve"

builder.add_conditional_edges(
    "evaluator",
    timed_should_continue,
    {
        "improve": "generator",
        "done": END,
        "timeout": "timeout_handler",
        "max_iterations": "max_iter_handler"
    }
)
```

## Evaluator Implementation Patterns

### Pattern 1: Rule-Based Evaluation

```python
def rule_based_evaluator(state: State):
    """Rule-based evaluation"""
    content = state["content"]
    score = 0.0
    feedback = []

    # Length check
    if 100 <= len(content) <= 500:
        score += 0.3
    else:
        feedback.append("Length should be 100-500 characters")

    # Keyword check
    required_keywords = state["required_keywords"]
    if all(kw in content for kw in required_keywords):
        score += 0.3
    else:
        missing = [kw for kw in required_keywords if kw not in content]
        feedback.append(f"Missing keywords: {missing}")

    # Structure check
    if has_proper_structure(content):
        score += 0.4
    else:
        feedback.append("Improve structure")

    return {
        "quality_score": score,
        "feedback": "\n".join(feedback)
    }
```

### Pattern 2: LLM-Based Evaluation

```python
def llm_evaluator(state: State):
    """LLM evaluation"""
    evaluation_prompt = f"""
    Evaluate this content on a scale of 0-1:
    {state['content']}

    Criteria:
    - Clarity
    - Completeness
    - Accuracy

    Provide:
    1. Overall score (0-1)
    2. Specific feedback for improvement
    """

    result = llm.invoke(evaluation_prompt)

    return {
        "quality_score": parse_score(result),
        "feedback": parse_feedback(result)
    }
```

## Benefits

✅ **Quality Assurance**: Continue improvement until standards are met
✅ **Automatic Optimization**: Quality improvement without manual intervention
✅ **Feedback Loop**: Use evaluation results for next improvement
✅ **Adaptive**: Iteration count varies based on problem difficulty

## Considerations

⚠️ **Infinite Loops**: Set termination conditions appropriately
⚠️ **Cost**: Multiple LLM calls occur
⚠️ **No Convergence Guarantee**: May not always meet standards
⚠️ **Local Optima**: Improvement may get stuck

## Best Practices

1. **Clear Termination Conditions**: Set maximum iterations and timeout
2. **Progressive Feedback**: Provide specific improvement points
3. **Progress Tracking**: Record scores for each iteration
4. **Fallback**: Handle cases where standards cannot be met

## Summary

Evaluator-Optimizer is optimal when **iterative improvement is needed until quality standards are met**. Clear evaluation criteria and termination conditions are key to success.

## Related Pages

- [02_graph_architecture_prompt_chaining.md](02_graph_architecture_prompt_chaining.md) - Basic sequential processing
- [02_graph_architecture_agent.md](02_graph_architecture_agent.md) - Combining with Agent
- [05_advanced_features_human_in_the_loop.md](05_advanced_features_human_in_the_loop.md) - Human evaluation
