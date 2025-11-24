# Phase 2: ベースライン評価の例

評価スクリプトと結果レポートの例。

**📋 関連ドキュメント**: [実践例トップ](./examples.md) | [ワークフロー Phase 2](./workflow_phase2.md) | [評価方法](./evaluation.md)

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

