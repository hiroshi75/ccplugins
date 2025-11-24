# Phase 3: Iterative Improvement

Phase for data-driven, incremental prompt optimization.

**Time Required**: 1-2 hours per iteration × number of iterations (typically 3-5)

**📋 Related Documents**: [Overall Workflow](./workflow.md) | [Prompt Optimization](./prompt_optimization.md)

---

## Phase 3: Iterative Improvement

### Iteration Cycle

Execute the following in each iteration:

1. **Prioritization** (Step 7)
2. **Implement Improvements** (Step 8)
3. **Post-Improvement Evaluation** (Step 9)
4. **Compare Results** (Step 10)
5. **Continue Decision** (Step 11)

### Step 7: Prioritization

**Decision Criteria**:
1. **Impact on goal achievement**
2. **Feasibility of improvement**
3. **Implementation cost**

**Priority Matrix**:
```markdown
## Improvement Priority Matrix

| Node | Impact | Feasibility | Impl Cost | Total Score | Priority |
|------|--------|-------------|-----------|-------------|----------|
| analyze_intent | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 14/15 | 1st |
| generate_response | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 12/15 | 2nd |
| retrieve_context | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | 8/15 | 3rd |

**Iteration 1 Target**: analyze_intent node
```

### Step 8: Implement Improvements

**Pre-Improvement Prompt** (`src/nodes/analyzer.py`):
```python
# Before
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

**Post-Improvement Prompt**:
```python
# After - Iteration 1
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

**Summary of Changes**:
1. ✅ temperature: 1.0 → 0.3 (appropriate for classification tasks)
2. ✅ Clear classification categories (4 intents)
3. ✅ Few-shot examples (added 5)
4. ✅ JSON output format (structured output)
5. ✅ Error handling (fallback for JSON parse failures)

### Step 9: Post-Improvement Evaluation

**Execution**:
```bash
# Execute post-improvement evaluation under same conditions
./evaluation_after_iteration1.sh
```

### Step 10: Compare Results

**Comparison Report Example**:
```markdown
# Iteration 1 Evaluation Results

Execution Date: 2024-11-24 12:00:00
Changes: Optimization of analyze_intent node

## Results Comparison

| Metric | Baseline | Iteration 1 | Change | % Change | Target | Achievement |
|--------|----------|-------------|--------|----------|--------|-------------|
| **Accuracy** | 75.0% | **86.0%** | **+11.0%** | +14.7% | 90.0% | 95.6% |
| **Latency** | 2.5s | 2.4s | -0.1s | -4.0% | 2.0s | 80.0% |
| **Cost/req** | $0.015 | $0.014 | -$0.001 | -6.7% | $0.010 | 71.4% |

## Detailed Analysis

### Accuracy Improvement
- **Improvement**: +11.0% (75.0% → 86.0%)
- **Remaining gap**: 4.0% (target 90.0%)
- **Improved cases**: Intent classification errors reduced from 12 → 3 cases
- **Still needs improvement**: Context understanding deficiency cases (5 cases)

### Slight Latency Improvement
- **Improvement**: -0.1s (2.5s → 2.4s)
- **Main factor**: Lower temperature in analyze_intent made output more concise
- **Remaining bottleneck**: generate_response (avg 1.8s)

### Slight Cost Reduction
- **Reduction**: -$0.001 (6.7% reduction)
- **Factor**: Reduced output tokens in analyze_intent
- **Main cost**: generate_response still accounts for 73%

## Next Iteration Strategy

### Priority 1: Optimize generate_response
- **Goal**: Latency 1.8s → 1.4s, Cost $0.011 → $0.007
- **Approach**:
  1. Add conciseness instructions
  2. Limit max_tokens to 500
  3. Adjust temperature from 0.7 → 0.5

### Priority 2: Final 4% accuracy improvement
- **Goal**: 86.0% → 90.0% or higher
- **Approach**: Improve context understanding (retrieve_context node)

## Decision
✅ Continue → Proceed to Iteration 2
```

### Step 11: Continue Decision

**Decision Criteria**:
```python
def should_continue_iteration(results: Dict, goals: Dict) -> bool:
    """Determine if iteration should continue"""
    all_goals_met = True

    for metric, goal in goals.items():
        if metric == "accuracy":
            if results[metric] < goal:
                all_goals_met = False
        elif metric in ["latency", "cost"]:
            if results[metric] > goal:
                all_goals_met = False

    return not all_goals_met

# Example
goals = {"accuracy": 90.0, "latency": 2.0, "cost": 0.010}
results = {"accuracy": 86.0, "latency": 2.4, "cost": 0.014}

if should_continue_iteration(results, goals):
    print("Proceed to next iteration")
else:
    print("Goals achieved - Move to Phase 4")
```

**Iteration Limit**:
- **Recommended**: 3-5 iterations
- **Reason**: Beyond this, law of diminishing returns likely applies
- **Exception**: Critical applications may require 10+ iterations
