# プロンプト最適化の原則

LangGraph ノードのプロンプトを設計する際の基本原則。

## 🎯 プロンプト最適化の原則

### 1. 明確性（Clarity）

**悪い例**:
```python
SystemMessage(content="Analyze the input.")
```

**良い例**:
```python
SystemMessage(content="""You are an intent classifier for customer support.

Task: Classify user input into one of these categories:
- product_inquiry: Questions about products or services
- technical_support: Technical issues or troubleshooting
- billing: Payment or billing questions
- general: General questions or greetings

Output only the category name.""")
```

**改善ポイント**:
- ✅ 役割を明確に定義
- ✅ タスクを具体的に説明
- ✅ カテゴリを列挙
- ✅ 出力形式を指定

### 2. 構造化（Structure）

**悪い例**:
```python
prompt = f"Answer this: {question}"
```

**良い例**:
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

**改善ポイント**:
- ✅ セクション分け（Context, Question, Instructions, Answer）
- ✅ 順序だった指示
- ✅ 明確な区切り

### 3. 具体性（Specificity）

**悪い例**:
```python
"Be helpful and friendly."
```

**良い例**:
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

**改善ポイント**:
- ✅ 具体的なガイドライン
- ✅ 実例の提供
- ✅ 測定可能な基準
