# Phase 3: 反復的改善

データ駆動で段階的にプロンプトを最適化するフェーズ。

**所要時間**: 各 iteration 1-2時間 × iterations 数（通常 3-5回）

**📋 関連ドキュメント**: [ワークフロー全体](./workflow.md) | [プロンプト最適化](./prompt_optimization.md)

---

## Phase 3: 反復的改善

### Iteration のサイクル

各 iteration で以下を実行：

1. **優先順位付け** (Step 7)
2. **改善実施** (Step 8)
3. **改善後評価** (Step 9)
4. **結果比較** (Step 10)
5. **継続判断** (Step 11)

### Step 7: 優先順位付け

**決定基準**:
1. **目標達成への影響度**
2. **改善の実現可能性**
3. **実装コスト**

**優先順位マトリックス**:
```markdown
## 改善優先順位マトリックス

| ノード | 影響度 | 実現可能性 | 実装コスト | 総合スコア | 優先度 |
|--------|--------|-----------|-----------|----------|--------|
| analyze_intent | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 14/15 | 1位 |
| generate_response | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 12/15 | 2位 |
| retrieve_context | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | 8/15 | 3位 |

**Iteration 1 の対象**: analyze_intent ノード
```

### Step 8: 改善実施

**改善前のプロンプト** (`src/nodes/analyzer.py`):
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

**改善後のプロンプト**:
```python
# After - Iteration 1
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

**変更内容サマリー**:
1. ✅ temperature: 1.0 → 0.3（分類タスクに適した設定）
2. ✅ 明確な分類カテゴリ（4つのインテント）
3. ✅ Few-shot examples（5個追加）
4. ✅ JSON 出力形式（構造化された出力）
5. ✅ エラーハンドリング（JSON パース失敗時のフォールバック）

### Step 9: 改善後評価

**実行**:
```bash
# 改善後の評価を同じ条件で実行
./evaluation_after_iteration1.sh
```

### Step 10: 結果比較

**比較レポート例**:
```markdown
# Iteration 1 評価結果

実行日時: 2024-11-24 12:00:00
変更内容: analyze_intent ノードの最適化

## 結果比較

| 指標 | ベースライン | Iteration 1 | 変化 | 変化率 | 目標 | 達成率 |
|------|-------------|-------------|------|--------|------|--------|
| **Accuracy** | 75.0% | **86.0%** | **+11.0%** | +14.7% | 90.0% | 95.6% |
| **Latency** | 2.5s | 2.4s | -0.1s | -4.0% | 2.0s | 80.0% |
| **Cost/req** | $0.015 | $0.014 | -$0.001 | -6.7% | $0.010 | 71.4% |

## 詳細分析

### Accuracy の改善
- **向上**: +11.0% (75.0% → 86.0%)
- **残りギャップ**: 4.0% (目標90.0%)
- **改善できたケース**: インテント分類ミスが 12 → 3 ケースに減少
- **まだ改善が必要**: コンテキスト理解不足のケース（5ケース）

### Latency の若干改善
- **向上**: -0.1s (2.5s → 2.4s)
- **主な要因**: analyze_intent の温度下降により出力が簡潔になった
- **残りボトルネック**: generate_response (平均 1.8s)

### Cost の若干削減
- **削減**: -$0.001 (6.7%削減)
- **要因**: analyze_intent の出力トークン削減
- **主なコスト**: generate_response が依然として73%を占める

## 次の Iteration の方針

### 優先度1: generate_response の最適化
- **目標**: Latency を 1.8s → 1.4s、Cost を $0.011 → $0.007
- **アプローチ**:
  1. 簡潔性の指示追加
  2. max_tokens を 500 に制限
  3. temperature を 0.7 → 0.5 に調整

### 優先度2: Accuracy の最後の4%向上
- **目標**: 86.0% → 90.0%以上
- **アプローチ**: コンテキスト理解を改善（retrieve_context ノード）

## 判定
✅ 継続 → Iteration 2 に進む
```

### Step 11: 継続判断

**判断基準**:
```python
def should_continue_iteration(results: Dict, goals: Dict) -> bool:
    """Iteration を継続すべきか判断"""
    all_goals_met = True

    for metric, goal in goals.items():
        if metric == "accuracy":
            if results[metric] < goal:
                all_goals_met = False
        elif metric in ["latency", "cost"]:
            if results[metric] > goal:
                all_goals_met = False

    return not all_goals_met

# 例
goals = {"accuracy": 90.0, "latency": 2.0, "cost": 0.010}
results = {"accuracy": 86.0, "latency": 2.4, "cost": 0.014}

if should_continue_iteration(results, goals):
    print("次の Iteration に進む")
else:
    print("目標達成 - Phase 4 へ")
```

**Iteration の上限**:
- **推奨**: 3-5 iterations
- **理由**: それ以上は収益逓減の法則が働く可能性が高い
- **例外**: Critical なアプリケーションでは 10+ iterations も可

