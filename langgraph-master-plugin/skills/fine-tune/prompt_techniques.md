# プロンプト最適化テクニック

LangGraph ノードのプロンプトを効果的に最適化するための実践的なテクニック集。

**💡 Tip**: 改善前後のプロンプト比較例とコードテンプレートは [examples.md](examples.md#phase-3-反復的改善の例) を参照してください。

## 🔧 実践的な最適化テクニック

### テクニック 1: Few-Shot Examples（少数例学習）

**効果**: Accuracy +10-20%

**Before（Zero-shot）**:
```python
system_prompt = """Classify user input into: product_inquiry, technical_support, billing, or general."""

# Accuracy: ~70%
```

**After（Few-shot）**:
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

**ベストプラクティス**:
- **Examples 数**: 3-7個（それ以上は収益逓減）
- **多様性**: 各カテゴリから最低1個、edge cases を含む
- **品質**: 明確で議論の余地のない例を選択
- **フォーマット**: 一貫した Input/Output 形式

### テクニック 2: Chain-of-Thought（思考の連鎖）

**効果**: Complex reasoning tasks で Accuracy +15-30%

**Before（Direct answer）**:
```python
prompt = f"""Question: {question}

Answer:"""

# 複雑な質問で誤答が多い
```

**After（Chain-of-Thought）**:
```python
prompt = f"""Question: {question}

Think through this step by step:

1. First, identify the key information needed
2. Then, analyze the context for relevant details
3. Finally, formulate a clear answer

Reasoning:"""

# 複雑な質問でも論理的に回答
```

**適用シナリオ**:
- ✅ 複数ステップの推論が必要なタスク
- ✅ 複雑な意思決定
- ✅ 矛盾の解決
- ❌ シンプルな分類タスク（オーバーヘッド）

### テクニック 3: 出力フォーマットの構造化

**効果**: Latency -10-20%, Parsing errors -90%

**Before（自由テキスト）**:
```python
prompt = "Classify the intent and explain why."

# Output: "This looks like a technical support question because the user is having trouble logging in..."
# 問題: パースが難しい、冗長、一貫性がない
```

**After（JSON 構造化）**:
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
# 利点: 簡単にパース、簡潔、一貫性
```

**JSON パースのエラーハンドリング**:
```python
import json
import re

def parse_llm_json_output(output: str) -> dict:
    """LLM の JSON 出力を堅牢にパース"""
    try:
        # そのまま JSON としてパース
        return json.loads(output)
    except json.JSONDecodeError:
        # JSON のみを抽出（マークダウンコードブロックなどから）
        json_match = re.search(r'\{[^}]+\}', output)
        if json_match:
            try:
                return json.loads(json_match.group())
            except json.JSONDecodeError:
                pass

        # フォールバック
        return {
            "intent": "general",
            "confidence": 0.5,
            "reasoning": "Failed to parse LLM output"
        }
```

### テクニック 4: Temperature と Max Tokens の調整

**Temperature の効果**:

| タスクタイプ | 推奨 Temperature | 理由 |
|------------|-----------------|------|
| 分類・抽出 | 0.0 - 0.3 | 決定論的な出力が望ましい |
| 要約・変換 | 0.3 - 0.5 | 一定の柔軟性が必要 |
| 創作・生成 | 0.7 - 1.0 | 多様性と創造性が重要 |

**Before（デフォルト設定）**:
```python
llm = ChatAnthropic(
    model="claude-3-5-sonnet-20241022",
    temperature=1.0  # デフォルト、全タスクで使用
)
# 分類タスクで不安定な結果
```

**After（タスクごとに最適化）**:
```python
# Intent classification: 低い temperature
intent_llm = ChatAnthropic(
    model="claude-3-5-sonnet-20241022",
    temperature=0.3  # 一貫性を重視
)

# Response generation: 中程度の temperature
response_llm = ChatAnthropic(
    model="claude-3-5-sonnet-20241022",
    temperature=0.5,  # 柔軟性とバランス
    max_tokens=500    # 簡潔さを強制
)
```

**Max Tokens の効果**:

```python
# Before: 制限なし
llm = ChatAnthropic(model="claude-3-5-sonnet-20241022")
# Average output: 800 tokens, Cost: $0.012/req, Latency: 3.2s

# After: 適切な制限
llm = ChatAnthropic(
    model="claude-3-5-sonnet-20241022",
    max_tokens=500  # 必要十分な長さ
)
# Average output: 450 tokens, Cost: $0.007/req (-42%), Latency: 1.8s (-44%)
```

### テクニック 5: System Message vs Human Message の使い分け

**System Message（システムメッセージ）**:
- **用途**: 役割、ガイドライン、制約
- **特徴**: タスク全体に適用される文脈
- **キャッシュ**: 効果的（頻繁に変わらない）

**Human Message（ユーザーメッセージ）**:
- **用途**: 具体的な入力、質問
- **特徴**: リクエストごとに変わる
- **キャッシュ**: 効果が低い

**良い構造**:
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

### テクニック 6: プロンプトキャッシング（Prompt Caching）

**効果**: Cost -50-90%（キャッシュヒット時）

Anthropic Claude のプロンプトキャッシングを活用：

```python
from anthropic import Anthropic

client = Anthropic()

# キャッシュ可能な大きな system prompt
CACHED_SYSTEM_PROMPT = """You are an expert customer support agent...

[Long guidelines, examples, and context - 1000+ tokens]

Examples:
[50 few-shot examples]
"""

# キャッシュを使用
message = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=500,
    system=[
        {
            "type": "text",
            "text": CACHED_SYSTEM_PROMPT,
            "cache_control": {"type": "ephemeral"}  # キャッシュを有効化
        }
    ],
    messages=[
        {"role": "user", "content": user_input}
    ]
)

# 初回: フルコスト
# 2回目以降（5分以内）: Input tokens が -90% 割引
```

**キャッシング戦略**:
- ✅ 大きな system prompts（>1024 tokens）
- ✅ Few-shot examples の集合
- ✅ 長いコンテキスト（RAG のドキュメント）
- ❌ 頻繁に変わる内容
- ❌ 小さなプロンプト（<1024 tokens）

### テクニック 7: 段階的な詳細化（Progressive Refinement）

複雑なタスクを複数のステップに分解：

**Before（1ステップ）**:
```python
# 1つのノードで全てを実行
prompt = f"""Analyze user input, retrieve relevant info, and generate response.

Input: {user_input}"""

# 問題: 複雑すぎて品質が低い、デバッグが困難
```

**After（複数ステップ）**:
```python
# Step 1: Intent classification
intent = classify_intent(user_input)

# Step 2: Information retrieval (intent に基づく)
context = retrieve_context(intent, user_input)

# Step 3: Response generation (intent と context を使用)
response = generate_response(intent, context, user_input)

# 利点: 各ステップが最適化可能、デバッグが容易、品質が向上
```

### テクニック 8: Negative Instructions（禁止事項の明示）

**効果**: エッジケースのエラー -30-50%

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

### テクニック 9: Self-Consistency（自己一貫性）

**効果**: Complex reasoning で Accuracy +10-20%、Cost +200-300%

複数の推論パスを生成して多数決：

```python
def self_consistency_reasoning(question: str, num_samples: int = 5) -> str:
    """複数の推論を生成して最も一貫した答えを選択"""

    llm = ChatAnthropic(
        model="claude-3-5-sonnet-20241022",
        temperature=0.7  # 多様性のために高めの temperature
    )

    prompt = f"""Question: {question}

Think through this step by step and provide your reasoning:

Reasoning:"""

    # 複数の推論パスを生成
    responses = []
    for _ in range(num_samples):
        response = llm.invoke([HumanMessage(content=prompt)])
        responses.append(response.content)

    # 最も一貫した答えを抽出（簡略化）
    # 実際には、各レスポンスから最終的な答えを抽出して多数決
    from collections import Counter
    final_answers = [extract_final_answer(r) for r in responses]
    most_common = Counter(final_answers).most_common(1)[0][0]

    return most_common

# トレードオフ:
# - Accuracy: +10-20%
# - Cost: +200-300% (5x API calls)
# - Latency: +200-300% (並列化しない場合)
# 使用: Critical decisions のみ
```

### テクニック 10: モデルの選択

**タスクの複雑度に応じたモデル選択**:

| タスクタイプ | 推奨モデル | 理由 |
|------------|-----------|------|
| Simple classification | Claude 3.5 Haiku | 高速、低コスト、十分な精度 |
| Complex reasoning | Claude 3.5 Sonnet | バランスの取れた性能 |
| Highly complex tasks | Claude Opus | 最高の性能（コスト高） |

```python
# タスクごとに最適なモデルを選択
class LLMSelector:
    def __init__(self):
        self.haiku = ChatAnthropic(model="claude-3-5-haiku-20241022")
        self.sonnet = ChatAnthropic(model="claude-3-5-sonnet-20241022")
        self.opus = ChatAnthropic(model="claude-opus-20240229")

    def get_llm(self, task_complexity: str):
        if task_complexity == "simple":
            return self.haiku  # $0.001/req 相当
        elif task_complexity == "complex":
            return self.sonnet  # $0.005/req 相当
        else:  # very_complex
            return self.opus  # $0.015/req 相当

# 使用例
selector = LLMSelector()

# Simple intent classification → Haiku
intent_llm = selector.get_llm("simple")

# Complex response generation → Sonnet
response_llm = selector.get_llm("complex")
```

**ハイブリッドアプローチ**:
```python
def hybrid_classification(user_input: str) -> dict:
    """まず Haiku で試し、confidence が低ければ Sonnet を使用"""

    # Step 1: Haiku で分類
    haiku_result = classify_with_haiku(user_input)

    if haiku_result["confidence"] >= 0.8:
        # 高い confidence → Haiku の結果を使用
        return haiku_result
    else:
        # 低い confidence → Sonnet で再分類
        sonnet_result = classify_with_sonnet(user_input)
        return sonnet_result

# 効果:
# - 80%のケースで Haiku を使用（低コスト）
# - 20%のケースで Sonnet を使用（高精度）
# - 平均コスト: -60%
# - 平均精度: -2%（許容範囲）
```
