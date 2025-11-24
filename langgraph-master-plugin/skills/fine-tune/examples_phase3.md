# Phase 3: 反復的改善の例

改善前後のプロンプト比較と結果レポートの例。

**📋 関連ドキュメント**: [実践例トップ](./examples.md) | [ワークフロー Phase 3](./workflow_phase3.md) | [プロンプト最適化](./prompt_optimization.md)

---

## Phase 3: 反復的改善の例

### Example 3.1: 改善前後のプロンプト比較

**ノード**: analyze_intent

#### Before（ベースライン）

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

**問題点**:
- 曖昧な指示
- Few-shot なし
- 自由テキスト出力
- 高い temperature

**結果**: Accuracy 75%

#### After（Iteration 1）

```python
def analyze_intent(state: GraphState) -> GraphState:
    llm = ChatAnthropic(
        model="claude-3-5-sonnet-20241022",
        temperature=0.3  # 分類タスクには低めの temperature
    )

    # 明確な分類カテゴリと few-shot examples
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

    # JSON パース（エラーハンドリング付き）
    try:
        intent_data = json.loads(response.content)
        state["intent"] = intent_data["intent"]
        state["confidence"] = intent_data["confidence"]
    except json.JSONDecodeError:
        # フォールバック
        state["intent"] = "general"
        state["confidence"] = 0.5

    return state
```

**改善点**:
- ✅ temperature: 1.0 → 0.3
- ✅ 明確な分類カテゴリ（4 つのインテント）
- ✅ Few-shot examples（5 個追加）
- ✅ JSON 出力形式（構造化された出力）
- ✅ エラーハンドリング（JSON パース失敗時のフォールバック）

**結果**: Accuracy 86% (+11%)

### Example 3.2: 優先順位付けマトリックス

```markdown
## 改善優先順位マトリックス

| ノード             | 影響度       | 実現可能性   | 実装コスト   | 総合スコア | 優先度 |
| ------------------ | ------------ | ------------ | ------------ | ---------- | ------ |
| analyze_intent     | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐   | 14/15      | 1 位   |
| generate_response  | ⭐⭐⭐⭐   | ⭐⭐⭐⭐   | ⭐⭐⭐⭐   | 12/15      | 2 位   |
| retrieve_context   | ⭐⭐       | ⭐⭐⭐     | ⭐⭐⭐     | 8/15       | 3 位   |

### 詳細分析

#### 1 位: analyze_intent ノード

- **影響度**: ⭐⭐⭐⭐⭐
  - Accuracy に直接影響（-15%ギャップの 60%を占める）
  - 下流のノードにも影響（誤分類による連鎖エラー）

- **実現可能性**: ⭐⭐⭐⭐⭐
  - Few-shot examples による改善が期待できる
  - 類似事例で +10-15%の改善実績あり

- **実装コスト**: ⭐⭐⭐⭐
  - 実装時間: 30-60 分
  - テスト時間: 30 分
  - リスク: 低

**Iteration 1 の対象**: analyze_intent ノード

#### 2 位: generate_response ノード

- **影響度**: ⭐⭐⭐⭐
  - Latency と Cost の主要因（全体の 70%以上）
  - Accuracy への直接影響は小さい

- **実現可能性**: ⭐⭐⭐⭐
  - max_tokens 制限で確実に改善
  - 簡潔性の指示で品質維持可能

- **実装コスト**: ⭐⭐⭐⭐
  - 実装時間: 20-30 分
  - テスト時間: 30 分
  - リスク: 低

**Iteration 2 の対象**: generate_response ノード
```

### Example 3.3: Iteration 結果レポート

```markdown
# Iteration 1 評価結果

実行日時: 2024-11-24 12:00:00
変更内容: analyze_intent ノードの最適化

## 結果比較

| 指標     | ベースライン | Iteration 1 | 変化    | 変化率  | 目標   | 達成率  |
| -------- | ------------ | ----------- | ------- | ------- | ------ | ------- |
| **Accuracy** | 75.0%        | **86.0%**   | **+11.0%** | +14.7%  | 90.0%  | 95.6%   |
| **Latency**  | 2.5s         | 2.4s        | -0.1s   | -4.0%   | 2.0s   | 80.0%   |
| **Cost/req** | $0.015       | $0.014      | -$0.001 | -6.7%   | $0.010 | 71.4%   |

## 詳細分析

### Accuracy の改善

- **向上**: +11.0% (75.0% → 86.0%)
- **残りギャップ**: 4.0% (目標 90.0%)
- **改善できたケース**: インテント分類ミスが 12 → 3 ケースに減少
- **まだ改善が必要**: コンテキスト理解不足のケース（5 ケース）

### Latency の若干改善

- **向上**: -0.1s (2.5s → 2.4s)
- **主な要因**: analyze_intent の温度下降により出力が簡潔になった
- **残りボトルネック**: generate_response (平均 1.8s)

### Cost の若干削減

- **削減**: -$0.001 (6.7%削減)
- **要因**: analyze_intent の出力トークン削減
- **主なコスト**: generate_response が依然として 73%を占める

## 統計的有意性

- **t 検定**: p < 0.01 ✅（統計的に有意）
- **効果量**: Cohen's d = 2.3 (large effect)
- **信頼区間**: [83.9%, 88.1%] (95% CI)

## 次の Iteration の方針

### 優先度 1: generate_response の最適化

- **目標**: Latency を 1.8s → 1.4s、Cost を $0.011 → $0.007
- **アプローチ**:
  1. 簡潔性の指示追加
  2. max_tokens を 500 に制限
  3. temperature を 0.7 → 0.5 に調整

### 優先度 2: Accuracy の最後の 4%向上

- **目標**: 86.0% → 90.0%以上
- **アプローチ**: コンテキスト理解を改善（retrieve_context ノード）

## 判定

✅ **継続** → Iteration 2 に進む

理由:
- Accuracy が大幅に向上したが、まだ目標未達
- Latency と Cost も改善の余地あり
- 明確な改善方針が立っている
```

---

