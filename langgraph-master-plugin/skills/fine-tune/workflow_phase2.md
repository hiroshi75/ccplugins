# Phase 2: Baseline Evaluation

Phase to quantitatively measure current performance.

**Time Required**: 1-2 hours

**📋 Related Documents**: [Overall Workflow](./workflow.md) | [Evaluation Methods](./evaluation.md)

---

## Phase 2: Baseline Evaluation

### Step 4: Prepare Evaluation Environment

**Checklist**:
- [ ] Test case files exist
- [ ] Evaluation script is executable
- [ ] Environment variables (API keys, etc.) are set
- [ ] Dependency packages are installed

**Execution Example**:
```bash
# Check test cases
cat tests/evaluation/test_cases.json

# Verify evaluation script works
uv run python -m src.evaluate --dry-run

# Verify environment variables
echo $ANTHROPIC_API_KEY
```

### Step 5: Measure Baseline

**Recommended Run Count**: 3-5 times (for statistical reliability)

**Execution Script Example**:
```bash
#!/bin/bash
# baseline_evaluation.sh

ITERATIONS=5
RESULTS_DIR="evaluation_results/baseline"
mkdir -p $RESULTS_DIR

for i in $(seq 1 $ITERATIONS); do
    echo "Running baseline evaluation: iteration $i/$ITERATIONS"
    uv run python -m src.evaluate \
        --output "$RESULTS_DIR/run_$i.json" \
        --verbose

    # API rate limit countermeasure
    sleep 5
done

# Aggregate results
uv run python -m src.aggregate_results \
    --input-dir "$RESULTS_DIR" \
    --output "$RESULTS_DIR/summary.json"
```

**Evaluation Script Example** (`src/evaluate.py`):
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

        # Execute LangGraph application
        output = run_langgraph_app(case["input"])

        latency = time.time() - start_time

        # Correct answer judgment
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
```

### Step 6: Analyze Baseline Results

**Aggregation Script Example** (`src/aggregate_results.py`):
```python
import json
import numpy as np
from pathlib import Path
from typing import List, Dict

def aggregate_results(results_dir: Path) -> Dict:
    """Aggregate multiple execution results"""
    all_results = []

    for result_file in sorted(results_dir.glob("run_*.json")):
        with open(result_file) as f:
            all_results.append(json.load(f))

    # Calculate statistics for each metric
    accuracies = [r["accuracy"] for r in all_results]
    latencies = [r["avg_latency"] for r in all_results]
    costs = [r["avg_cost"] for r in all_results]

    summary = {
        "iterations": len(all_results),
        "accuracy": {
            "mean": np.mean(accuracies),
            "std": np.std(accuracies),
            "min": np.min(accuracies),
            "max": np.max(accuracies)
        },
        "latency": {
            "mean": np.mean(latencies),
            "std": np.std(latencies),
            "min": np.min(latencies),
            "max": np.max(latencies)
        },
        "cost": {
            "mean": np.mean(costs),
            "std": np.std(costs),
            "min": np.min(costs),
            "max": np.max(costs)
        }
    }

    return summary
```

**Results Report Example**:
```markdown
# Baseline Evaluation Results

Execution Date: 2024-11-24 10:00:00
Run Count: 5
Test Case Count: 20

## Evaluation Metrics Summary

| Metric | Mean | Std Dev | Min | Max | Target | Gap |
|--------|------|---------|-----|-----|--------|-----|
| Accuracy | 75.0% | 3.2% | 70.0% | 80.0% | 90.0% | **-15.0%** |
| Latency | 2.5s | 0.4s | 2.1s | 3.2s | 2.0s | **+0.5s** |
| Cost/req | $0.015 | $0.002 | $0.013 | $0.018 | $0.010 | **+$0.005** |

## Detailed Analysis

### Accuracy Issues
- **Current**: 75.0% (Target: 90.0%)
- **Main error patterns**:
  1. Intent classification errors: 12 cases (60% of errors)
  2. Context understanding deficiency: 5 cases (25% of errors)
  3. Handling ambiguous questions: 3 cases (15% of errors)

### Latency Issues
- **Current**: 2.5s (Target: 2.0s)
- **Bottlenecks**:
  1. generate_response node: avg 1.8s (72% of total)
  2. analyze_intent node: avg 0.5s (20% of total)
  3. Other: avg 0.2s (8% of total)

### Cost Issues
- **Current**: $0.015/req (Target: $0.010/req)
- **Cost breakdown**:
  1. generate_response: $0.011 (73%)
  2. analyze_intent: $0.003 (20%)
  3. Other: $0.001 (7%)
- **Main factor**: High output token count (avg 800 tokens)

## Improvement Directions

### Priority 1: Improve analyze_intent accuracy
- **Impact**: Direct impact on accuracy (accounts for 60% of -15% gap)
- **Improvements**: Few-shot examples, clear classification criteria, JSON output format
- **Estimated effect**: +10-12% accuracy

### Priority 2: Optimize generate_response efficiency
- **Impact**: Affects both latency and cost
- **Improvements**: Conciseness instructions, max_tokens limit, temperature adjustment
- **Estimated effect**: -0.4s latency, -$0.004 cost
```
