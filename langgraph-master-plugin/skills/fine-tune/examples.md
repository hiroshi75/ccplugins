# ファインチューニング実践例集

LangGraph アプリケーションのファインチューニングで使用する具体的なコード例とマークダウンテンプレート集。

## 📋 目次

- [Phase 1: 準備と分析の例](#phase-1-準備と分析の例)
- [Phase 2: ベースライン評価の例](#phase-2-ベースライン評価の例)
- [Phase 3: 反復的改善の例](#phase-3-反復的改善の例)
- [Phase 4: 完了と文書化の例](#phase-4-完了と文書化の例)

---

## Phase 1: 準備と分析の例

### Example 1.1: fine-tune.md の構造例

**ファイル**: `.langgraph-master/fine-tune.md`

```markdown
# ファインチューニング目標

## 最適化目標

- **Accuracy**: ユーザー意図の分類精度を 90%以上に向上
- **Latency**: 応答時間を 2.0 秒以下に短縮
- **Cost**: リクエストあたりのコストを $0.010 以下に削減

## 評価方法

### テストケース

- **データセット**: tests/evaluation/test_cases.json (20 ケース)
- **実行コマンド**: uv run python -m src.evaluate
- **評価スクリプト**: tests/evaluation/evaluator.py

### 評価指標

#### Accuracy（正解率）

- **計算方法**: (正解数 / 総ケース数) × 100
- **目標値**: 90%以上

#### Latency（応答時間）

- **計算方法**: 各実行の平均時間
- **目標値**: 2.0 秒以下

#### Cost（コスト）

- **計算方法**: 総 API コスト / 総リクエスト数
- **目標値**: $0.010 以下

## 合格基準

すべての評価指標が目標値を達成すること。
```

### Example 1.2: 最適化箇所リストの例

```markdown
# 最適化対象ノード

## Node: analyze_intent

### 基本情報

- **ファイル**: src/nodes/analyzer.py:25-45
- **役割**: ユーザー入力の意図を分類
- **LLM モデル**: claude-3-5-sonnet-20241022
- **現在のパラメータ**: temperature=1.0, max_tokens=default

### 現在のプロンプト

\```python
SystemMessage(content="You are an intent analyzer. Analyze user input.")
HumanMessage(content=f"Analyze: {user_input}")
\```

### 問題点

1. **曖昧な指示**: "Analyze" の具体的な基準が不明
2. **Few-shot なし**: 期待される出力例がない
3. **出力形式未定義**: 自由テキストで構造化されていない
4. **高 temperature**: 1.0 は分類タスクには高すぎる

### 改善案

1. 具体的な分類カテゴリを明記
2. Few-shot examples を 3-5 個追加
3. JSON 出力形式を指定
4. temperature を 0.3-0.5 に下げる

### 推定改善効果

- **Accuracy**: +10-15% (現状の誤分類 20% → 5-10%)
- **Latency**: ±0 (変化なし)
- **Cost**: ±0 (変化なし)

### 優先度

⭐⭐⭐⭐⭐ (最優先) - accuracy 向上への直接的な影響

---

## Node: generate_response

### 基本情報

- **ファイル**: src/nodes/generator.py:45-68
- **役割**: 最終的なユーザー向け応答を生成
- **LLM モデル**: claude-3-5-sonnet-20241022
- **現在のパラメータ**: temperature=0.7, max_tokens=default

### 現在のプロンプト

\```python
ChatPromptTemplate.from_messages([
    ("system", "Generate helpful response based on context."),
    ("human", "{context}\n\nQuestion: {question}")
])
\```

### 問題点

1. **冗長性制御なし**: 簡潔性の指示がない
2. **max_tokens 未設定**: 不必要に長い出力の可能性
3. **応答スタイル未定義**: トーンやスタイルの指定がない

### 改善案

1. "簡潔に" "2-3 文で" などの長さ指示を追加
2. max_tokens を 500 に制限
3. 応答スタイルを明確化（"親しみやすく" "専門的に" など）

### 推定改善効果

- **Accuracy**: ±0 (変化なし)
- **Latency**: -0.3-0.5s (出力トークン削減による)
- **Cost**: -20-30% (トークン数削減による)

### 優先度

⭐⭐⭐ (中) - latency と cost の改善
```

### Example 1.3: Serena MCP でのコード検索例

```python
# LLM クライアントの検索
from mcp_serena import find_symbol, find_referencing_symbols

# Step 1: ChatAnthropic の使用箇所を検索
chat_anthropic_usages = find_symbol(
    name_path="ChatAnthropic",
    substring_matching=True,
    include_body=False
)

print(f"Found {len(chat_anthropic_usages)} ChatAnthropic usages")

# Step 2: 各使用箇所の詳細を調査
for usage in chat_anthropic_usages:
    print(f"\nFile: {usage.relative_path}:{usage.line_start}")
    print(f"Context: {usage.name_path}")

    # プロンプト構築箇所を特定
    references = find_referencing_symbols(
        name_path=usage.name,
        relative_path=usage.relative_path
    )

    # プロンプトを含む可能性のある箇所を表示
    for ref in references:
        if "message" in ref.name.lower() or "prompt" in ref.name.lower():
            print(f"  - Potential prompt location: {ref.name_path}")
```

---

## Phase 2: ベースライン評価の例

### Example 2.1: 評価スクリプト

**ファイル**: `tests/evaluation/evaluator.py`

```python
import json
import time
from pathlib import Path
from typing import Dict, List

def evaluate_test_cases(test_cases: List[Dict]) -> Dict:
    """テストケースを評価"""
    results = {
        "total_cases": len(test_cases),
        "correct": 0,
        "total_latency": 0.0,
        "total_cost": 0.0,
        "case_results": []
    }

    for case in test_cases:
        start_time = time.time()

        # LangGraph アプリケーションを実行
        output = run_langgraph_app(case["input"])

        latency = time.time() - start_time

        # 正解判定
        is_correct = output["answer"] == case["expected_answer"]
        if is_correct:
            results["correct"] += 1

        # コスト計算（トークン使用量から）
        cost = calculate_cost(output["token_usage"])

        results["total_latency"] += latency
        results["total_cost"] += cost

        results["case_results"].append({
            "case_id": case["id"],
            "correct": is_correct,
            "latency": latency,
            "cost": cost
        })

    # 指標の計算
    results["accuracy"] = (results["correct"] / results["total_cases"]) * 100
    results["avg_latency"] = results["total_latency"] / results["total_cases"]
    results["avg_cost"] = results["total_cost"] / results["total_cases"]

    return results

def calculate_cost(token_usage: Dict) -> float:
    """トークン使用量からコストを計算"""
    # Claude 3.5 Sonnet の料金
    INPUT_COST_PER_1M = 3.0  # $3.00 per 1M input tokens
    OUTPUT_COST_PER_1M = 15.0  # $15.00 per 1M output tokens

    input_cost = (token_usage["input_tokens"] / 1_000_000) * INPUT_COST_PER_1M
    output_cost = (token_usage["output_tokens"] / 1_000_000) * OUTPUT_COST_PER_1M

    return input_cost + output_cost

if __name__ == "__main__":
    # テストケースを読み込み
    with open("tests/evaluation/test_cases.json") as f:
        test_cases = json.load(f)["test_cases"]

    # 評価実行
    results = evaluate_test_cases(test_cases)

    # 結果を保存
    with open("evaluation_results/baseline_run.json", "w") as f:
        json.dump(results, f, indent=2)

    print(f"Accuracy: {results['accuracy']:.1f}%")
    print(f"Avg Latency: {results['avg_latency']:.2f}s")
    print(f"Avg Cost: ${results['avg_cost']:.4f}")
```

### Example 2.2: ベースライン測定スクリプト

**ファイル**: `scripts/baseline_evaluation.sh`

```bash
#!/bin/bash

ITERATIONS=5
RESULTS_DIR="evaluation_results/baseline"
mkdir -p $RESULTS_DIR

echo "Starting baseline evaluation: $ITERATIONS iterations"

for i in $(seq 1 $ITERATIONS); do
    echo "----------------------------------------"
    echo "Iteration $i/$ITERATIONS"
    echo "----------------------------------------"

    uv run python -m tests.evaluation.evaluator \
        --output "$RESULTS_DIR/run_$i.json" \
        --verbose

    echo "Completed iteration $i"

    # API レート制限対策
    if [ $i -lt $ITERATIONS ]; then
        echo "Waiting 5 seconds before next iteration..."
        sleep 5
    fi
done

echo ""
echo "All iterations completed. Aggregating results..."

# 結果の集計
uv run python -m tests.evaluation.aggregate \
    --input-dir "$RESULTS_DIR" \
    --output "$RESULTS_DIR/summary.json"

echo "Baseline evaluation complete!"
echo "Results saved to: $RESULTS_DIR/summary.json"
```

### Example 2.3: ベースライン結果レポート

```markdown
# ベースライン評価結果

実行日時: 2024-11-24 10:00:00
実行回数: 5
テストケース数: 20

## 評価指標サマリー

| 指標     | 平均   | 標準偏差 | 最小値 | 最大値 | 目標   | ギャップ  |
| -------- | ------ | -------- | ------ | ------ | ------ | --------- |
| Accuracy | 75.0%  | 3.2%     | 70.0%  | 80.0%  | 90.0%  | **-15.0%** |
| Latency  | 2.5s   | 0.4s     | 2.1s   | 3.2s   | 2.0s   | **+0.5s**  |
| Cost/req | $0.015 | $0.002   | $0.013 | $0.018 | $0.010 | **+$0.005** |

## 詳細分析

### Accuracy の問題

- **現状**: 75.0% (目標: 90.0%)
- **主な誤答パターン**:
  1. インテント分類ミス: 12 ケース (60%の誤答)
  2. コンテキスト理解不足: 5 ケース (25%の誤答)
  3. 曖昧な質問への対応: 3 ケース (15%の誤答)

### Latency の問題

- **現状**: 2.5s (目標: 2.0s)
- **ボトルネック**:
  1. generate_response ノード: 平均 1.8s (全体の 72%)
  2. analyze_intent ノード: 平均 0.5s (全体の 20%)
  3. その他: 平均 0.2s (全体の 8%)

### Cost の問題

- **現状**: $0.015/req (目標: $0.010/req)
- **コスト内訳**:
  1. generate_response: $0.011 (73%)
  2. analyze_intent: $0.003 (20%)
  3. その他: $0.001 (7%)
- **主な要因**: 出力トークン数が多い（平均 800 tokens）

## 改善の方向性

### 優先度 1: analyze_intent の精度向上

- **影響**: Accuracy に直接影響（-15%のギャップの 60%を占める）
- **改善策**: Few-shot examples、明確な分類基準、JSON 出力形式
- **推定効果**: +10-12% accuracy

### 優先度 2: generate_response の効率化

- **影響**: Latency と Cost の両方に影響
- **改善策**: 簡潔性の指示、max_tokens 制限、temperature 調整
- **推定効果**: -0.4s latency, -$0.004 cost
```

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

## Phase 4: 完了と文書化の例

### Example 4.1: 最終評価レポート

```markdown
# LangGraph アプリケーション ファインチューニング完了レポート

プロジェクト: カスタマーサポートチャットボット
実施期間: 2024-11-24 10:00 - 2024-11-24 15:00 (5 時間)
実施者: Claude Code (fine-tune skill)

## 🎯 エグゼクティブサマリー

本ファインチューニングプロジェクトでは、LangGraph チャットボットアプリケーションのプロンプト最適化を実施し、以下の成果を達成しました：

- ✅ **Accuracy**: 75.0% → 92.0% (+17.0%, 目標 90%達成)
- ✅ **Latency**: 2.5s → 1.9s (-24.0%, 目標 2.0s 達成)
- ⚠️ **Cost**: $0.015 → $0.011 (-26.7%, 目標 $0.010 未達)

全 3 iterations を実施し、3 つの指標のうち 2 つで目標を達成しました。

## 📊 実施内容サマリー

### Iteration 数と実行時間

- **Total Iterations**: 3
- **最適化したノード数**: 2 (analyze_intent, generate_response)
- **評価実行回数**: 20 回 (ベースライン 5 回 + 各 iteration 後 5 回×3)
- **総実行時間**: 約 5 時間

### 最終結果

| 指標     | 初期値 | 最終値 | 改善   | 改善率  | 目標   | 達成状況  |
| -------- | ------ | ------ | ------ | ------- | ------ | --------- |
| Accuracy | 75.0%  | 92.0%  | +17.0% | +22.7%  | 90.0%  | ✅ 102.2% |
| Latency  | 2.5s   | 1.9s   | -0.6s  | -24.0%  | 2.0s   | ✅ 95.0%  |
| Cost/req | $0.015 | $0.011 | -$0.004| -26.7%  | $0.010 | ⚠️ 90.9%  |

## 📝 Iteration 別の詳細

### Iteration 1: analyze_intent ノードの最適化

**実施日時**: 2024-11-24 11:00
**対象ノード**: src/nodes/analyzer.py:25-45

**変更内容**:
1. temperature: 1.0 → 0.3
2. Few-shot examples を 5 個追加
3. JSON 出力形式に構造化
4. 明確な分類カテゴリ（4 つ）を定義

**結果**:
- Accuracy: 75.0% → 86.0% (+11.0%)
- Latency: 2.5s → 2.4s (-0.1s)
- Cost: $0.015 → $0.014 (-$0.001)

**学び**: Few-shot examples と明確な出力形式が accuracy 向上に最も効果的

---

### Iteration 2: generate_response ノードの最適化

**実施日時**: 2024-11-24 13:00
**対象ノード**: src/nodes/generator.py:45-68

**変更内容**:
1. 簡潔性の指示を追加（"2-3 文で回答"）
2. max_tokens: unlimited → 500
3. temperature: 0.7 → 0.5
4. 応答スタイルを明確化

**結果**:
- Accuracy: 86.0% → 88.0% (+2.0%)
- Latency: 2.4s → 2.0s (-0.4s)
- Cost: $0.014 → $0.011 (-$0.003)

**学び**: max_tokens 制限が latency と cost 削減に大きく貢献

---

### Iteration 3: analyze_intent の追加改善

**実施日時**: 2024-11-24 14:30
**対象ノード**: src/nodes/analyzer.py:25-45

**変更内容**:
1. Few-shot examples を 5 個 → 10 個に増加
2. エッジケースのハンドリング追加
3. confidence threshold による再分類ロジック

**結果**:
- Accuracy: 88.0% → 92.0% (+4.0%)
- Latency: 2.0s → 1.9s (-0.1s)
- Cost: $0.011 → $0.011 (±0)

**学び**: 追加の few-shot examples が accuracy の最後の壁を突破

## 🔧 最終的な変更内容

### src/nodes/analyzer.py

**変更行**: 25-45

**主な変更点**:
- temperature: 1.0 → 0.3
- Few-shot examples: 0 → 10
- 出力: 自由テキスト → JSON
- Confidence threshold によるフォールバック追加

---

### src/nodes/generator.py

**変更行**: 45-68

**主な変更点**:
- temperature: 0.7 → 0.5
- max_tokens: unlimited → 500
- 簡潔性の明確な指示（"2-3 sentences"）
- 応答スタイルのガイドライン追加

## 📈 評価結果の詳細

### Test Case 別の改善状況

| Case ID | Category  | Before      | After       | 改善 |
| ------- | --------- | ----------- | ----------- | ---- |
| TC001   | Product   | ❌ Wrong    | ✅ Correct  | ✅   |
| TC002   | Technical | ❌ Wrong    | ✅ Correct  | ✅   |
| TC003   | Billing   | ✅ Correct  | ✅ Correct  | -    |
| ...     | ...       | ...         | ...         | ...  |
| TC020   | Technical | ✅ Correct  | ✅ Correct  | -    |

**改善されたケース**: 15/20 (75%)
**維持されたケース**: 5/20 (25%)
**劣化したケース**: 0/20 (0%)

### Latency の内訳

| ノード             | Before | After | 変化   | 変化率 |
| ------------------ | ------ | ----- | ------ | ------ |
| analyze_intent     | 0.5s   | 0.4s  | -0.1s  | -20%   |
| retrieve_context   | 0.2s   | 0.2s  | ±0s    | 0%     |
| generate_response  | 1.8s   | 1.3s  | -0.5s  | -28%   |
| **Total**          | **2.5s** | **1.9s** | **-0.6s** | **-24%** |

### Cost の内訳

| ノード             | Before  | After   | 変化     | 変化率 |
| ------------------ | ------- | ------- | -------- | ------ |
| analyze_intent     | $0.003  | $0.003  | ±$0      | 0%     |
| retrieve_context   | $0.001  | $0.001  | ±$0      | 0%     |
| generate_response  | $0.011  | $0.007  | -$0.004  | -36%   |
| **Total**          | **$0.015** | **$0.011** | **-$0.004** | **-27%** |

## 💡 今後の推奨事項

### 短期（1-2 週間）

1. **Cost 目標の達成**: $0.011 → $0.010
   - アプローチ: Claude 3.5 Haiku への部分移行を検討
   - 推定効果: -$0.002-0.003/req

2. **Accuracy の更なる向上**: 92.0% → 95.0%
   - アプローチ: エラーケースの分析と few-shot examples の追加
   - 推定効果: +3.0%

### 中期（1-2 ヶ月）

1. **モデルの最適化**
   - simple な intent classification には Haiku を使用
   - complex な response generation のみ Sonnet を使用
   - 推定効果: -30-40% cost, latency への影響は最小

2. **プロンプトキャッシング活用**
   - System prompts と few-shot examples をキャッシュ
   - 推定効果: -50% cost（キャッシュヒット時）

### 長期（3-6 ヶ月）

1. **ファインチューニングモデルの検討**
   - 独自データでの model fine-tuning
   - Few-shot examples 不要で簡潔なプロンプト
   - 推定効果: -60% cost, +5% accuracy

## 🎓 結論

本プロジェクトでは、LangGraph アプリケーションのファインチューニングにより、以下を達成しました：

✅ **成功した点**:
1. Accuracy の大幅向上（+22.7%）- 目標を 2.2%超過達成
2. Latency の顕著な改善（-24.0%）- 目標を 5%超過達成
3. Cost の削減（-26.7%）- 目標にあと 9.1%

⚠️ **課題**:
1. Cost 目標未達（$0.011 vs $0.010 目標）- 軽量モデルへの移行で対応可能

📈 **ビジネスインパクト**:
- ユーザー満足度の向上（accuracy 向上により）
- 運用コストの削減（latency, cost 削減により）
- スケーラビリティの改善（効率的なリソース使用）

🎯 **次のステップ**:
1. Cost 削減のための軽量モデル移行の検証
2. 継続的なモニタリングと評価
3. 新しいユースケースへの展開

---

作成日時: 2024-11-24 15:00:00
作成者: Claude Code (fine-tune skill)
```

### Example 4.2: Git コミットメッセージ例

```bash
# Iteration 1 のコミット
git commit -m "feat(nodes): optimize analyze_intent prompt for accuracy

- Add temperature control (1.0 -> 0.3) for deterministic classification
- Add 5 few-shot examples for intent categories
- Implement JSON structured output format
- Add error handling for JSON parsing failures

Results:
- Accuracy: 75.0% -> 86.0% (+11.0%)
- Latency: 2.5s -> 2.4s (-0.1s)
- Cost: \$0.015 -> \$0.014 (-\$0.001)

Related: fine-tune iteration 1
See: evaluation_results/iteration_1/"

# Iteration 2 のコミット
git commit -m "feat(nodes): optimize generate_response for latency and cost

- Add conciseness guidelines (2-3 sentences)
- Set max_tokens limit to 500
- Adjust temperature (0.7 -> 0.5) for consistency
- Define response style and tone

Results:
- Accuracy: 86.0% -> 88.0% (+2.0%)
- Latency: 2.4s -> 2.0s (-0.4s, -17%)
- Cost: \$0.014 -> \$0.011 (-\$0.003, -21%)

Related: fine-tune iteration 2
See: evaluation_results/iteration_2/"

# 最終コミット
git commit -m "feat(nodes): finalize fine-tuning with additional improvements

Complete fine-tuning process with 3 iterations:
- analyze_intent: 10 few-shot examples, confidence threshold
- generate_response: conciseness and style optimization

Final Results:
- Accuracy: 75.0% -> 92.0% (+17.0%, goal 90% ✅)
- Latency: 2.5s -> 1.9s (-0.6s, -24%, goal 2.0s ✅)
- Cost: \$0.015 -> \$0.011 (-\$0.004, -27%, goal \$0.010 ⚠️)

Related: fine-tune completion
See: evaluation_results/final_report.md"

# 評価結果のコミット
git commit -m "docs: add fine-tuning evaluation results and final report

- Baseline evaluation (5 iterations)
- Iteration 1-3 results
- Final comprehensive report
- Statistical analysis and recommendations"
```

---

## 📚 関連ドキュメント

- [SKILL.md](SKILL.md) - スキルの概要
- [workflow.md](workflow.md) - ワークフローの詳細
- [evaluation.md](evaluation.md) - 評価方法
- [prompt_optimization.md](prompt_optimization.md) - 最適化テクニック
