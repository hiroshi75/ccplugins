# Phase 2: Baseline Evaluation Examples

Examples of evaluation scripts and result reports.

**📋 Related Documentation**: [Examples Home](./examples.md) | [Workflow Phase 2](./workflow_phase2.md) | [Evaluation Methods](./evaluation.md)

---

## Phase 2: Baseline Evaluation Examples

### Example 2.1: Evaluation Script

**File**: `tests/evaluation/evaluator.py`

```python
import json
import time
from pathlib import Path
from typing import Dict, List

def evaluate_test_cases(test_cases: List[Dict]) -> Dict:
    """Evaluate test cases"""
    results = {
        "total_cases": len(test_cases),
        "correct": 0,
        "total_latency": 0.0,
        "total_cost": 0.0,
        "case_results": []
    }

    for case in test_cases:
        start_time = time.time()

        # Run LangGraph application
        output = run_langgraph_app(case["input"])

        latency = time.time() - start_time

        # Correctness judgment
        is_correct = output["answer"] == case["expected_answer"]
        if is_correct:
            results["correct"] += 1

        # Cost calculation (from token usage)
        cost = calculate_cost(output["token_usage"])

        results["total_latency"] += latency
        results["total_cost"] += cost

        results["case_results"].append({
            "case_id": case["id"],
            "correct": is_correct,
            "latency": latency,
            "cost": cost
        })

    # Calculate metrics
    results["accuracy"] = (results["correct"] / results["total_cases"]) * 100
    results["avg_latency"] = results["total_latency"] / results["total_cases"]
    results["avg_cost"] = results["total_cost"] / results["total_cases"]

    return results

def calculate_cost(token_usage: Dict) -> float:
    """Calculate cost from token usage"""
    # Claude 3.5 Sonnet pricing
    INPUT_COST_PER_1M = 3.0  # $3.00 per 1M input tokens
    OUTPUT_COST_PER_1M = 15.0  # $15.00 per 1M output tokens

    input_cost = (token_usage["input_tokens"] / 1_000_000) * INPUT_COST_PER_1M
    output_cost = (token_usage["output_tokens"] / 1_000_000) * OUTPUT_COST_PER_1M

    return input_cost + output_cost

if __name__ == "__main__":
    # Load test cases
    with open("tests/evaluation/test_cases.json") as f:
        test_cases = json.load(f)["test_cases"]

    # Execute evaluation
    results = evaluate_test_cases(test_cases)

    # Save results
    with open("evaluation_results/baseline_run.json", "w") as f:
        json.dump(results, f, indent=2)

    print(f"Accuracy: {results['accuracy']:.1f}%")
    print(f"Avg Latency: {results['avg_latency']:.2f}s")
    print(f"Avg Cost: ${results['avg_cost']:.4f}")
```

### Example 2.2: Baseline Measurement Script

**File**: `scripts/baseline_evaluation.sh`

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

    # API rate limit mitigation
    if [ $i -lt $ITERATIONS ]; then
        echo "Waiting 5 seconds before next iteration..."
        sleep 5
    fi
done

echo ""
echo "All iterations completed. Aggregating results..."

# Aggregate results
uv run python -m tests.evaluation.aggregate \
    --input-dir "$RESULTS_DIR" \
    --output "$RESULTS_DIR/summary.json"

echo "Baseline evaluation complete!"
echo "Results saved to: $RESULTS_DIR/summary.json"
```

### Example 2.3: Baseline Results Report

```markdown
# Baseline Evaluation Results

Execution Date/Time: 2024-11-24 10:00:00
Number of Runs: 5
Number of Test Cases: 20

## Evaluation Metrics Summary

| Metric   | Average | Std Dev | Min    | Max    | Target | Gap        |
| -------- | ------- | ------- | ------ | ------ | ------ | ---------- |
| Accuracy | 75.0%   | 3.2%    | 70.0%  | 80.0%  | 90.0%  | **-15.0%** |
| Latency  | 2.5s    | 0.4s    | 2.1s   | 3.2s   | 2.0s   | **+0.5s**  |
| Cost/req | $0.015  | $0.002  | $0.013 | $0.018 | $0.010 | **+$0.005** |

## Detailed Analysis

### Accuracy Issues

- **Current**: 75.0% (Target: 90.0%)
- **Main incorrect answer patterns**:
  1. Intent classification errors: 12 cases (60% of errors)
  2. Insufficient context understanding: 5 cases (25% of errors)
  3. Ambiguous question handling: 3 cases (15% of errors)

### Latency Issues

- **Current**: 2.5s (Target: 2.0s)
- **Bottlenecks**:
  1. generate_response node: Average 1.8s (72% of total)
  2. analyze_intent node: Average 0.5s (20% of total)
  3. Other: Average 0.2s (8% of total)

### Cost Issues

- **Current**: $0.015/req (Target: $0.010/req)
- **Cost breakdown**:
  1. generate_response: $0.011 (73%)
  2. analyze_intent: $0.003 (20%)
  3. Other: $0.001 (7%)
- **Main factor**: High output token count (average 800 tokens)

## Improvement Directions

### Priority 1: Improve analyze_intent accuracy

- **Impact**: Direct impact on Accuracy (accounts for 60% of the -15% gap)
- **Improvement measures**: Few-shot examples, clear classification criteria, JSON output format
- **Estimated effect**: +10-12% accuracy

### Priority 2: Optimize generate_response efficiency

- **Impact**: Affects both Latency and Cost
- **Improvement measures**: Conciseness instructions, max_tokens limit, temperature adjustment
- **Estimated effect**: -0.4s latency, -$0.004 cost
```

---
