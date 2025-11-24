# Prompt Optimization Principles

Fundamental principles for designing prompts in LangGraph nodes.

## 🎯 Prompt Optimization Principles

### 1. Clarity

**Bad Example**:
```python
SystemMessage(content="Analyze the input.")
```

**Good Example**:
```python
SystemMessage(content="""You are an intent classifier for customer support.

Task: Classify user input into one of these categories:
- product_inquiry: Questions about products or services
- technical_support: Technical issues or troubleshooting
- billing: Payment or billing questions
- general: General questions or greetings

Output only the category name.""")
```

**Improvements**:
- ✅ Clearly defined role
- ✅ Specific task description
- ✅ Enumerated categories
- ✅ Specified output format

### 2. Structure

**Bad Example**:
```python
prompt = f"Answer this: {question}"
```

**Good Example**:
```python
prompt = f"""Context:
{context}

Question:
{question}

Instructions:
1. Base your answer on the provided context
2. Be concise (2-3 sentences maximum)
3. If the answer is not in the context, say "I don't have enough information"

Answer:"""
```

**Improvements**:
- ✅ Sectioned (Context, Question, Instructions, Answer)
- ✅ Sequential instructions
- ✅ Clear separators

### 3. Specificity

**Bad Example**:
```python
"Be helpful and friendly."
```

**Good Example**:
```python
"""Tone and Style:
- Use a warm, professional tone
- Address the customer by name if available
- Acknowledge their concern explicitly
- Provide actionable next steps

Example:
"Hi Sarah, I understand your concern about the billing charge. Let me review your account and get back to you within 24 hours with a detailed explanation."
"""
```

**Improvements**:
- ✅ Specific guidelines
- ✅ Concrete examples provided
- ✅ Measurable criteria
