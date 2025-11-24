# Prompt Optimization Techniques

A collection of practical techniques for effectively optimizing prompts in LangGraph nodes.

**💡 Tip**: For before/after prompt comparison examples and code templates, refer to [examples.md](examples.md#phase-3-iterative-improvement-examples).

## 🔧 Practical Optimization Techniques

### Technique 1: Few-Shot Examples

**Effect**: Accuracy +10-20%

**Before (Zero-shot)**:
```python
system_prompt = """Classify user input into: product_inquiry, technical_support, billing, or general."""

# Accuracy: ~70%
```

**After (Few-shot)**:
```python
system_prompt = """Classify user input into: product_inquiry, technical_support, billing, or general.

Examples:

Input: "How much does the premium plan cost?"
Output: product_inquiry

Input: "I can't log into my account"
Output: technical_support

Input: "Why was I charged twice this month?"
Output: billing

Input: "Hello, how are you today?"
Output: general

Input: "What features are included in the basic plan?"
Output: product_inquiry"""

# Accuracy: ~85-90%
```

**Best Practices**:
- **Number of Examples**: 3-7 (diminishing returns beyond this)
- **Diversity**: At least one from each category, including edge cases
- **Quality**: Select clear and unambiguous examples
- **Format**: Consistent Input/Output format

### Technique 2: Chain-of-Thought

**Effect**: Accuracy +15-30% for complex reasoning tasks

**Before (Direct answer)**:
```python
prompt = f"""Question: {question}

Answer:"""

# Many incorrect answers for complex questions
```

**After (Chain-of-Thought)**:
```python
prompt = f"""Question: {question}

Think through this step by step:

1. First, identify the key information needed
2. Then, analyze the context for relevant details
3. Finally, formulate a clear answer

Reasoning:"""

# Logical answers even for complex questions
```

**Application Scenarios**:
- ✅ Tasks requiring multi-step reasoning
- ✅ Complex decision making
- ✅ Resolving contradictions
- ❌ Simple classification tasks (overhead)

### Technique 3: Output Format Structuring

**Effect**: Latency -10-20%, Parsing errors -90%

**Before (Free text)**:
```python
prompt = "Classify the intent and explain why."

# Output: "This looks like a technical support question because the user is having trouble logging in..."
# Problems: Hard to parse, verbose, inconsistent
```

**After (JSON structured)**:
```python
prompt = """Classify the intent.

Output ONLY a valid JSON object:
{
  "intent": "<category>",
  "confidence": <0.0-1.0>,
  "reasoning": "<brief explanation in one sentence>"
}

Example output:
{"intent": "technical_support", "confidence": 0.95, "reasoning": "User reports authentication issue"}"""

# Output: {"intent": "technical_support", "confidence": 0.95, "reasoning": "User reports authentication issue"}
# Benefits: Easy to parse, concise, consistent
```

**JSON Parsing Error Handling**:
```python
import json
import re

def parse_llm_json_output(output: str) -> dict:
    """Robustly parse LLM JSON output"""
    try:
        # Parse as JSON directly
        return json.loads(output)
    except json.JSONDecodeError:
        # Extract JSON only (from markdown code blocks, etc.)
        json_match = re.search(r'\{[^}]+\}', output)
        if json_match:
            try:
                return json.loads(json_match.group())
            except json.JSONDecodeError:
                pass

        # Fallback
        return {
            "intent": "general",
            "confidence": 0.5,
            "reasoning": "Failed to parse LLM output"
        }
```

### Technique 4: Temperature and Max Tokens Adjustment

**Temperature Effects**:

| Task Type | Recommended Temperature | Reason |
|-----------|------------------------|--------|
| Classification/Extraction | 0.0 - 0.3 | Deterministic output desired |
| Summarization/Transformation | 0.3 - 0.5 | Some flexibility needed |
| Creative/Generation | 0.7 - 1.0 | Diversity and creativity important |

**Before (Default settings)**:
```python
llm = ChatAnthropic(
    model="claude-3-5-sonnet-20241022",
    temperature=1.0  # Default, used for all tasks
)
# Unstable results for classification tasks
```

**After (Optimized per task)**:
```python
# Intent classification: Low temperature
intent_llm = ChatAnthropic(
    model="claude-3-5-sonnet-20241022",
    temperature=0.3  # Emphasize consistency
)

# Response generation: Medium temperature
response_llm = ChatAnthropic(
    model="claude-3-5-sonnet-20241022",
    temperature=0.5,  # Balance flexibility
    max_tokens=500    # Enforce conciseness
)
```

**Max Tokens Effects**:

```python
# Before: No limit
llm = ChatAnthropic(model="claude-3-5-sonnet-20241022")
# Average output: 800 tokens, Cost: $0.012/req, Latency: 3.2s

# After: Appropriate limit
llm = ChatAnthropic(
    model="claude-3-5-sonnet-20241022",
    max_tokens=500  # Necessary and sufficient length
)
# Average output: 450 tokens, Cost: $0.007/req (-42%), Latency: 1.8s (-44%)
```

### Technique 5: System Message vs Human Message Usage

**System Message**:
- **Use**: Role, guidelines, constraints
- **Characteristics**: Context applied to entire task
- **Caching**: Effective (doesn't change frequently)

**Human Message**:
- **Use**: Specific input, questions
- **Characteristics**: Changes per request
- **Caching**: Less effective

**Good Structure**:
```python
messages = [
    SystemMessage(content="""You are a customer support assistant.

Guidelines:
- Be concise: 2-3 sentences maximum
- Be empathetic: Acknowledge customer concerns
- Be actionable: Provide clear next steps

Response format:
1. Acknowledgment
2. Answer or solution
3. Next steps (if applicable)"""),

    HumanMessage(content=f"""Customer question: {user_input}

Context: {context}

Generate a helpful response:""")
]
```

### Technique 6: Prompt Caching

**Effect**: Cost -50-90% (on cache hit)

Leverage Anthropic Claude's prompt caching:

```python
from anthropic import Anthropic

client = Anthropic()

# Large cacheable system prompt
CACHED_SYSTEM_PROMPT = """You are an expert customer support agent...

[Long guidelines, examples, and context - 1000+ tokens]

Examples:
[50 few-shot examples]
"""

# Use cache
message = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=500,
    system=[
        {
            "type": "text",
            "text": CACHED_SYSTEM_PROMPT,
            "cache_control": {"type": "ephemeral"}  # Enable caching
        }
    ],
    messages=[
        {"role": "user", "content": user_input}
    ]
)

# First time: Full cost
# 2nd+ time (within 5 minutes): Input tokens -90% discount
```

**Caching Strategy**:
- ✅ Large system prompts (>1024 tokens)
- ✅ Sets of few-shot examples
- ✅ Long context (RAG documents)
- ❌ Frequently changing content
- ❌ Small prompts (<1024 tokens)

### Technique 7: Progressive Refinement

Break complex tasks into multiple steps:

**Before (1 step)**:
```python
# Execute everything in one node
prompt = f"""Analyze user input, retrieve relevant info, and generate response.

Input: {user_input}"""

# Problems: Too complex, low quality, hard to debug
```

**After (Multiple steps)**:
```python
# Step 1: Intent classification
intent = classify_intent(user_input)

# Step 2: Information retrieval (based on intent)
context = retrieve_context(intent, user_input)

# Step 3: Response generation (using intent and context)
response = generate_response(intent, context, user_input)

# Benefits: Each step optimizable, easy to debug, improved quality
```

### Technique 8: Negative Instructions

**Effect**: Edge case errors -30-50%

```python
prompt = """Generate a customer support response.

DO:
- Be concise (2-3 sentences)
- Acknowledge the customer's concern
- Provide actionable next steps

DO NOT:
- Apologize excessively (one apology maximum)
- Make promises you can't keep (e.g., "immediate resolution")
- Use technical jargon without explanation
- Provide information not in the context
- Generate placeholder text like "XXX" or "[insert here]"

Customer question: {question}
Context: {context}

Response:"""
```

### Technique 9: Self-Consistency

**Effect**: Accuracy +10-20% for complex reasoning, Cost +200-300%

Generate multiple reasoning paths and use majority voting:

```python
def self_consistency_reasoning(question: str, num_samples: int = 5) -> str:
    """Generate multiple reasoning paths and select the most consistent answer"""

    llm = ChatAnthropic(
        model="claude-3-5-sonnet-20241022",
        temperature=0.7  # Higher temperature for diversity
    )

    prompt = f"""Question: {question}

Think through this step by step and provide your reasoning:

Reasoning:"""

    # Generate multiple reasoning paths
    responses = []
    for _ in range(num_samples):
        response = llm.invoke([HumanMessage(content=prompt)])
        responses.append(response.content)

    # Extract the most consistent answer (simplified)
    # In practice, extract final answer from each response and use majority voting
    from collections import Counter
    final_answers = [extract_final_answer(r) for r in responses]
    most_common = Counter(final_answers).most_common(1)[0][0]

    return most_common

# Trade-offs:
# - Accuracy: +10-20%
# - Cost: +200-300% (5x API calls)
# - Latency: +200-300% (if not parallelized)
# Use: Critical decisions only
```

### Technique 10: Model Selection

**Model Selection Based on Task Complexity**:

| Task Type | Recommended Model | Reason |
|-----------|------------------|--------|
| Simple classification | Claude 3.5 Haiku | Fast, low cost, sufficient accuracy |
| Complex reasoning | Claude 3.5 Sonnet | Balanced performance |
| Highly complex tasks | Claude Opus | Best performance (high cost) |

```python
# Select optimal model per task
class LLMSelector:
    def __init__(self):
        self.haiku = ChatAnthropic(model="claude-3-5-haiku-20241022")
        self.sonnet = ChatAnthropic(model="claude-3-5-sonnet-20241022")
        self.opus = ChatAnthropic(model="claude-opus-20240229")

    def get_llm(self, task_complexity: str):
        if task_complexity == "simple":
            return self.haiku  # ~$0.001/req
        elif task_complexity == "complex":
            return self.sonnet  # ~$0.005/req
        else:  # very_complex
            return self.opus  # ~$0.015/req

# Usage example
selector = LLMSelector()

# Simple intent classification → Haiku
intent_llm = selector.get_llm("simple")

# Complex response generation → Sonnet
response_llm = selector.get_llm("complex")
```

**Hybrid Approach**:
```python
def hybrid_classification(user_input: str) -> dict:
    """Try Haiku first, use Sonnet if confidence is low"""

    # Step 1: Classify with Haiku
    haiku_result = classify_with_haiku(user_input)

    if haiku_result["confidence"] >= 0.8:
        # High confidence → Use Haiku result
        return haiku_result
    else:
        # Low confidence → Re-classify with Sonnet
        sonnet_result = classify_with_sonnet(user_input)
        return sonnet_result

# Effects:
# - 80% of cases use Haiku (low cost)
# - 20% of cases use Sonnet (high accuracy)
# - Average cost: -60%
# - Average accuracy: -2% (acceptable range)
```
