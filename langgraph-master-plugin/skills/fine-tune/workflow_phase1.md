# Phase 1: Preparation and Analysis

Preparation phase to clarify optimization direction and identify targets for improvement.

**Time Required**: 30 minutes - 1 hour

**📋 Related Documents**: [Overall Workflow](./workflow.md) | [Practical Examples](./examples.md)

---

## Phase 1: Preparation and Analysis

### Step 1: Read and Understand fine-tune.md

**Purpose**: Clarify optimization direction

**Execution**:
```python
# Read .langgraph-master/fine-tune.md
file_path = ".langgraph-master/fine-tune.md"
with open(file_path, "r") as f:
    fine_tune_spec = f.read()

# Extract the following information:
# - Optimization goals (accuracy, latency, cost, etc.)
# - Evaluation methods (test cases, metrics, calculation methods)
# - Passing criteria (target values for each metric)
# - Test data location
```

**Typical fine-tune.md structure**:
```markdown
# Fine-Tuning Goals

## Optimization Objectives
- **Accuracy**: Improve user intent classification accuracy to 90% or higher
- **Latency**: Reduce response time to 2.0 seconds or less
- **Cost**: Reduce cost per request to $0.010 or less

## Evaluation Methods
- **Test Cases**: tests/evaluation/test_cases.json (20 cases)
- **Execution Command**: uv run python -m src.evaluate
- **Evaluation Script**: tests/evaluation/evaluator.py

## Evaluation Metrics

### Accuracy
- Calculation method: (Correct count / Total cases) × 100
- Target value: 90% or higher

### Latency
- Calculation method: Average time per execution
- Target value: 2.0 seconds or less

### Cost
- Calculation method: Total API cost / Total requests
- Target value: $0.010 or less

## Passing Criteria
All evaluation metrics must achieve their target values
```

### Step 2: Identify Optimization Targets with Serena MCP

**Purpose**: Comprehensively identify nodes calling LLMs

**Execution Steps**:

1. **Search for LLM clients**
```python
# Use Serena MCP: find_symbol
# Search for ChatAnthropic, ChatOpenAI, ChatGoogleGenerativeAI, etc.

patterns = [
    "ChatAnthropic",
    "ChatOpenAI",
    "ChatGoogleGenerativeAI",
    "ChatVertexAI"
]

llm_usages = []
for pattern in patterns:
    results = serena.find_symbol(
        name_path=pattern,
        substring_matching=True,
        include_body=False
    )
    llm_usages.extend(results)
```

2. **Identify prompt construction locations**
```python
# For each LLM call, investigate how prompts are constructed
for usage in llm_usages:
    # Get surrounding context with find_referencing_symbols
    context = serena.find_referencing_symbols(
        name_path=usage.name,
        relative_path=usage.file_path
    )

    # Identify prompt templates and message construction logic
    # - Use of ChatPromptTemplate
    # - SystemMessage, HumanMessage definitions
    # - Prompt construction with f-strings or format()
```

3. **Per-node analysis**
```python
# Analyze LLM usage patterns within each node function
# - Prompt clarity
# - Presence of few-shot examples
# - Structured output format
# - Parameter settings (temperature, max_tokens, etc.)
```

**Example Output**:
```markdown
## LLM Call Location Analysis

### 1. analyze_intent node
- **File**: src/nodes/analyzer.py
- **Line numbers**: 25-45
- **LLM**: ChatAnthropic(model="claude-3-5-sonnet-20241022")
- **Prompt structure**:
  ```python
  SystemMessage: "You are an intent analyzer..."
  HumanMessage: f"Analyze: {user_input}"
  ```
- **Improvement potential**: ⭐⭐⭐⭐⭐ (High)
  - Prompt is vague ("Analyze" criteria unclear)
  - No few-shot examples
  - Output format is free text
- **Estimated improvement effect**: Accuracy +10-15%

### 2. generate_response node
- **File**: src/nodes/generator.py
- **Line numbers**: 45-68
- **LLM**: ChatAnthropic(model="claude-3-5-sonnet-20241022")
- **Prompt structure**:
  ```python
  ChatPromptTemplate.from_messages([
      ("system", "Generate helpful response..."),
      ("human", "{context}\n\nQuestion: {question}")
  ])
  ```
- **Improvement potential**: ⭐⭐⭐ (Medium)
  - Prompt is structured but lacks conciseness instructions
  - No max_tokens limit → possibility of verbose output
- **Estimated improvement effect**: Latency -0.3-0.5s, Cost -20-30%
```

### Step 3: Create Optimization Target List

**Purpose**: Organize information to determine improvement priorities

**List Creation Template**:
```markdown
# Optimization Target List

## Node: analyze_intent

### Basic Information
- **File**: src/nodes/analyzer.py:25-45
- **Role**: Classify user input intent
- **LLM Model**: claude-3-5-sonnet-20241022
- **Current Parameters**: temperature=1.0, max_tokens=default

### Current Prompt
```python
SystemMessage(content="You are an intent analyzer. Analyze user input.")
HumanMessage(content=f"Analyze: {user_input}")
```

### Issues
1. **Vague instructions**: Specific criteria for "Analyze" unclear
2. **No few-shot**: No expected output examples
3. **Undefined output format**: Unstructured free text
4. **High temperature**: 1.0 is too high for classification tasks

### Improvement Ideas
1. Specify concrete classification categories
2. Add 3-5 few-shot examples
3. Specify JSON output format
4. Lower temperature to 0.3-0.5

### Estimated Improvement Effect
- **Accuracy**: +10-15% (Current misclassification 20% → 5-10%)
- **Latency**: ±0 (No change)
- **Cost**: ±0 (No change)

### Priority
⭐⭐⭐⭐⭐ (Highest) - Direct impact on accuracy improvement

---

## Node: generate_response

### Basic Information
- **File**: src/nodes/generator.py:45-68
- **Role**: Generate final user-facing response
- **LLM Model**: claude-3-5-sonnet-20241022
- **Current Parameters**: temperature=0.7, max_tokens=default

### Current Prompt
```python
ChatPromptTemplate.from_messages([
    ("system", "Generate helpful response based on context."),
    ("human", "{context}\n\nQuestion: {question}")
])
```

### Issues
1. **No verbosity control**: No conciseness instructions
2. **max_tokens not set**: Possibility of unnecessarily long output
3. **Undefined response style**: No tone or style specifications

### Improvement Ideas
1. Add length instructions like "be concise" "in 2-3 sentences"
2. Limit max_tokens to 500
3. Clarify response style ("friendly" "professional" etc.)

### Estimated Improvement Effect
- **Accuracy**: ±0 (No change)
- **Latency**: -0.3-0.5s (Due to reduced output tokens)
- **Cost**: -20-30% (Due to reduced token count)

### Priority
⭐⭐⭐ (Medium) - Improvement in latency and cost
```
