# Phase 3: Iterative Improvement Examples

Examples of before/after prompt comparisons and result reports.

**📋 Related Documentation**: [Examples Home](./examples.md) | [Workflow Phase 3](./workflow_phase3.md) | [Prompt Optimization](./prompt_optimization.md)

---

## Phase 3: Iterative Improvement Examples

### Example 3.1: Before/After Prompt Comparison

**Node**: analyze_intent

#### Before (Baseline)

```python
def analyze_intent(state: GraphState) -> GraphState:
    llm = ChatAnthropic(
        model="claude-3-5-sonnet-20241022",
        temperature=1.0
    )

    messages = [
        SystemMessage(content="You are an intent analyzer. Analyze user input."),
        HumanMessage(content=f"Analyze: {state['user_input']}")
    ]

    response = llm.invoke(messages)
    state["intent"] = response.content
    return state
```

**Issues**:
- Ambiguous instructions
- No few-shot examples
- Free text output
- High temperature

**Result**: Accuracy 75%

#### After (Iteration 1)

```python
def analyze_intent(state: GraphState) -> GraphState:
    llm = ChatAnthropic(
        model="claude-3-5-sonnet-20241022",
        temperature=0.3  # Lower temperature for classification tasks
    )

    # Clear classification categories and few-shot examples
    system_prompt = """You are an intent classifier for a customer support chatbot.

Classify user input into one of these categories:
- "product_inquiry": Questions about products or services
- "technical_support": Technical issues or troubleshooting
- "billing": Payment, invoicing, or billing questions
- "general": General questions or chitchat

Output ONLY a valid JSON object with this structure:
{
  "intent": "<category>",
  "confidence": <0.0-1.0>,
  "reasoning": "<brief explanation>"
}

Examples:

Input: "How much does the premium plan cost?"
Output: {"intent": "product_inquiry", "confidence": 0.95, "reasoning": "Question about product pricing"}

Input: "I can't log into my account"
Output: {"intent": "technical_support", "confidence": 0.9, "reasoning": "Authentication issue"}

Input: "Why was I charged twice?"
Output: {"intent": "billing", "confidence": 0.95, "reasoning": "Question about billing charges"}

Input: "Hello, how are you?"
Output: {"intent": "general", "confidence": 0.85, "reasoning": "General greeting"}

Input: "What's the return policy?"
Output: {"intent": "product_inquiry", "confidence": 0.9, "reasoning": "Question about product policy"}
"""

    messages = [
        SystemMessage(content=system_prompt),
        HumanMessage(content=f"Input: {state['user_input']}\nOutput:")
    ]

    response = llm.invoke(messages)

    # JSON parsing (with error handling)
    try:
        intent_data = json.loads(response.content)
        state["intent"] = intent_data["intent"]
        state["confidence"] = intent_data["confidence"]
    except json.JSONDecodeError:
        # Fallback
        state["intent"] = "general"
        state["confidence"] = 0.5

    return state
```

**Improvements**:
- ✅ temperature: 1.0 → 0.3
- ✅ Clear classification categories (4 intents)
- ✅ Few-shot examples (5 added)
- ✅ JSON output format (structured output)
- ✅ Error handling (fallback for JSON parsing failures)

**Result**: Accuracy 86% (+11%)

### Example 3.2: Prioritization Matrix

```markdown
## Improvement Prioritization Matrix

| Node              | Impact       | Feasibility  | Implementation Cost | Total Score | Priority |
| ----------------- | ------------ | ------------ | ------------------- | ----------- | -------- |
| analyze_intent    | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐          | 14/15       | 1st      |
| generate_response | ⭐⭐⭐⭐   | ⭐⭐⭐⭐   | ⭐⭐⭐⭐          | 12/15       | 2nd      |
| retrieve_context  | ⭐⭐       | ⭐⭐⭐     | ⭐⭐⭐           | 8/15        | 3rd      |

### Detailed Analysis

#### 1st: analyze_intent Node

- **Impact**: ⭐⭐⭐⭐⭐
  - Direct impact on Accuracy (accounts for 60% of -15% gap)
  - Also affects downstream nodes (chain errors from misclassification)

- **Feasibility**: ⭐⭐⭐⭐⭐
  - Improvement expected from few-shot examples
  - Similar cases show +10-15% improvement

- **Implementation Cost**: ⭐⭐⭐⭐
  - Implementation time: 30-60 minutes
  - Testing time: 30 minutes
  - Risk: Low

**Iteration 1 target**: analyze_intent node

#### 2nd: generate_response Node

- **Impact**: ⭐⭐⭐⭐
  - Main contributor to Latency and Cost (over 70% of total)
  - Small direct impact on Accuracy

- **Feasibility**: ⭐⭐⭐⭐
  - max_tokens limit ensures improvement
  - Quality can be maintained with conciseness instructions

- **Implementation Cost**: ⭐⭐⭐⭐
  - Implementation time: 20-30 minutes
  - Testing time: 30 minutes
  - Risk: Low

**Iteration 2 target**: generate_response node
```

### Example 3.3: Iteration Results Report

```markdown
# Iteration 1 Evaluation Results

Execution Date/Time: 2024-11-24 12:00:00
Changes: analyze_intent node optimization

## Result Comparison

| Metric       | Baseline | Iteration 1 | Change     | Change Rate | Target | Achievement |
| ------------ | -------- | ----------- | ---------- | ----------- | ------ | ----------- |
| **Accuracy** | 75.0%    | **86.0%**   | **+11.0%** | +14.7%      | 90.0%  | 95.6%       |
| **Latency**  | 2.5s     | 2.4s        | -0.1s      | -4.0%       | 2.0s   | 80.0%       |
| **Cost/req** | $0.015   | $0.014      | -$0.001    | -6.7%       | $0.010 | 71.4%       |

## Detailed Analysis

### Accuracy Improvement

- **Improvement**: +11.0% (75.0% → 86.0%)
- **Remaining gap**: 4.0% (Target 90.0%)
- **Improved cases**: Intent classification errors reduced from 12 → 3 cases
- **Still needs improvement**: Context understanding cases (5 cases)

### Slight Latency Improvement

- **Improvement**: -0.1s (2.5s → 2.4s)
- **Main factor**: analyze_intent output became more concise due to lower temperature
- **Remaining bottleneck**: generate_response (average 1.8s)

### Slight Cost Reduction

- **Reduction**: -$0.001 (6.7% reduction)
- **Factor**: analyze_intent output token reduction
- **Main cost**: generate_response still accounts for 73%

## Statistical Significance

- **t-test**: p < 0.01 ✅ (statistically significant)
- **Effect size**: Cohen's d = 2.3 (large effect)
- **Confidence interval**: [83.9%, 88.1%] (95% CI)

## Next Iteration Strategy

### Priority 1: Optimize generate_response

- **Goal**: Latency from 1.8s → 1.4s, Cost from $0.011 → $0.007
- **Approach**:
  1. Add conciseness instructions
  2. Limit max_tokens to 500
  3. Adjust temperature from 0.7 → 0.5

### Priority 2: Final 4% Accuracy improvement

- **Goal**: 86.0% → 90.0% or higher
- **Approach**: Improve context understanding (retrieve_context node)

## Decision

✅ **Continue** → Proceed to Iteration 2

Reasons:
- Accuracy improved significantly but still hasn't reached target
- Latency and Cost still have room for improvement
- Clear improvement strategy is in place
```

---
