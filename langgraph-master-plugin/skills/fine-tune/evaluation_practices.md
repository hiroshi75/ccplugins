# Evaluation Best Practices

Practical guidelines for effective evaluation of LangGraph applications.

## 🎯 Evaluation Best Practices

### 1. Ensuring Consistency

#### Evaluation Under Same Conditions

```python
class EvaluationConfig:
    """Fix evaluation settings to ensure consistency"""

    def __init__(self):
        self.test_cases_path = "tests/evaluation/test_cases.json"
        self.seed = 42  # For reproducibility
        self.iterations = 5
        self.timeout = 30  # seconds
        self.model = "claude-3-5-sonnet-20241022"

    def load_test_cases(self) -> List[Dict]:
        """Load the same test cases"""
        with open(self.test_cases_path) as f:
            data = json.load(f)
        return data["test_cases"]

# Usage
config = EvaluationConfig()
test_cases = config.load_test_cases()
# Use the same test cases for all evaluations
```

### 2. Staged Evaluation

#### Start Small and Gradually Expand

```python
# Phase 1: Quick check (3 cases, 1 iteration)
quick_results = evaluate(test_cases[:3], iterations=1)

if quick_results["accuracy"] > baseline["accuracy"]:
    # Phase 2: Medium check (10 cases, 3 iterations)
    medium_results = evaluate(test_cases[:10], iterations=3)

    if medium_results["accuracy"] > baseline["accuracy"]:
        # Phase 3: Full evaluation (all cases, 5 iterations)
        full_results = evaluate(test_cases, iterations=5)
```

### 3. Recording Evaluation Results

#### Structured Logging

```python
import json
from datetime import datetime
from pathlib import Path

def save_evaluation_result(
    results: Dict,
    version: str,
    output_dir: Path = Path("evaluation_results")
):
    """Save evaluation results"""
    output_dir.mkdir(exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{version}_{timestamp}.json"

    full_results = {
        "version": version,
        "timestamp": timestamp,
        "metrics": results,
        "config": {
            "model": "claude-3-5-sonnet-20241022",
            "test_cases": len(test_cases),
            "iterations": 5
        }
    }

    with open(output_dir / filename, "w") as f:
        json.dump(full_results, f, indent=2)

    print(f"Results saved to: {output_dir / filename}")

# Usage
save_evaluation_result(results, version="baseline")
save_evaluation_result(results, version="iteration_1")
```

### 4. Visualization

#### Visualizing Results

```python
import matplotlib.pyplot as plt

def visualize_improvement(
    baseline: Dict,
    iterations: List[Dict],
    metrics: List[str] = ["accuracy", "latency", "cost"]
):
    """Visualize improvement progress"""
    fig, axes = plt.subplots(1, len(metrics), figsize=(15, 5))

    for idx, metric in enumerate(metrics):
        ax = axes[idx]

        # Prepare data
        x = ["Baseline"] + [f"Iter {i+1}" for i in range(len(iterations))]
        y = [baseline[metric]] + [it[metric] for it in iterations]

        # Plot
        ax.plot(x, y, marker='o', linewidth=2)
        ax.set_title(f"{metric.capitalize()} Progress")
        ax.set_ylabel(metric.capitalize())
        ax.grid(True, alpha=0.3)

        # Goal line
        if metric in baseline.get("goals", {}):
            goal = baseline["goals"][metric]
            ax.axhline(y=goal, color='r', linestyle='--', label='Goal')
            ax.legend()

    plt.tight_layout()
    plt.savefig("evaluation_results/improvement_progress.png")
    print("Visualization saved to: evaluation_results/improvement_progress.png")
```

## 📋 Evaluation Report Template

### Standard Report Format

```markdown
# Evaluation Report - [Version/Iteration]

Execution Date: 2024-11-24 12:00:00
Executed by: Claude Code (fine-tune skill)

## Configuration

- **Model**: claude-3-5-sonnet-20241022
- **Number of Test Cases**: 20
- **Number of Runs**: 5
- **Evaluation Duration**: 10 minutes

## Results Summary

| Metric | Mean | Std Dev | 95% CI | Goal | Achievement |
|--------|------|---------|--------|------|-------------|
| Accuracy | 86.0% | 2.1% | [83.9%, 88.1%] | 90.0% | 95.6% |
| Latency | 2.4s | 0.3s | [2.1s, 2.7s] | 2.0s | 83.3% |
| Cost | $0.014 | $0.001 | [$0.013, $0.015] | $0.010 | 71.4% |

## Detailed Analysis

### Accuracy
- **Improvement**: +11.0% (75.0% → 86.0%)
- **Statistical Significance**: p < 0.01 ✅
- **Effect Size**: Cohen's d = 2.3 (large)

### Latency
- **Improvement**: -0.1s (2.5s → 2.4s)
- **Statistical Significance**: p = 0.12 ❌ (not significant)
- **Effect Size**: Cohen's d = 0.3 (small)

## Error Analysis

- **Total Errors**: 0
- **Error Rate**: 0.0%
- **Retry Rate**: 0.0%

## Next Actions

1. ✅ Accuracy significantly improved → Continue
2. ⚠️ Latency improvement is small → Focus in next iteration
3. ⚠️ Cost still below goal → Consider max_tokens limit
```

## 🔍 Troubleshooting

### Common Problems and Solutions

#### 1. Large Variance in Evaluation Results

**Symptom**: Standard deviation > 20% of mean

**Causes**:
- LLM temperature is too high
- Test cases are uneven
- Network latency effects

**Solutions**:
```python
# Lower temperature
llm = ChatAnthropic(
    model="claude-3-5-sonnet-20241022",
    temperature=0.3  # Set lower
)

# Increase number of runs
iterations = 10  # 5 → 10

# Remove outliers
results_clean = remove_outliers(results)
```

#### 2. Evaluation Takes Too Long

**Symptom**: Evaluation takes over 1 hour

**Causes**:
- Too many test cases
- Not running in parallel
- Timeout setting too long

**Solutions**:
```python
# Subset evaluation
quick_test_cases = test_cases[:10]  # First 10 cases only

# Parallel execution
import concurrent.futures
with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
    futures = [executor.submit(evaluate_case, case) for case in test_cases]
    results = [f.result() for f in futures]

# Timeout setting
timeout = 10  # 30s → 10s
```

#### 3. No Statistical Significance

**Symptom**: p-value ≥ 0.05

**Causes**:
- Improvement effect is small
- Insufficient sample size
- High data variance

**Solutions**:
```python
# Aim for larger improvements
# - Apply multiple optimizations simultaneously
# - Choose more effective techniques

# Increase sample size
iterations = 20  # 5 → 20

# Reduce variance
# - Lower temperature
# - Stabilize evaluation environment
```

## 📊 Continuous Evaluation

### Scheduled Evaluation

```yaml
evaluation_schedule:
  daily:
    - quick_check: 3 test cases, 1 iteration
    - purpose: Detect major regressions

  weekly:
    - medium_check: 10 test cases, 3 iterations
    - purpose: Continuous quality monitoring

  before_release:
    - full_evaluation: all test cases, 5-10 iterations
    - purpose: Release quality assurance

  after_major_changes:
    - comprehensive_evaluation: all test cases, 10+ iterations
    - purpose: Impact assessment of major changes
```

### Automated Evaluation Pipeline

```bash
#!/bin/bash
# continuous_evaluation.sh

# Daily evaluation script

DATE=$(date +%Y%m%d)
RESULTS_DIR="evaluation_results/continuous/$DATE"
mkdir -p $RESULTS_DIR

# Quick check
echo "Running quick evaluation..."
uv run python -m tests.evaluation.evaluator \
    --test-cases 3 \
    --iterations 1 \
    --output "$RESULTS_DIR/quick.json"

# Compare with previous results
uv run python -m tests.evaluation.compare \
    --baseline "evaluation_results/baseline/summary.json" \
    --current "$RESULTS_DIR/quick.json" \
    --threshold 0.05

# Notify if regression detected
if [ $? -ne 0 ]; then
    echo "⚠️ Regression detected! Sending notification..."
    # Notification process (Slack, Email, etc.)
fi
```

## Summary

For effective evaluation:
- ✅ **Multiple Metrics**: Quality, performance, cost, reliability
- ✅ **Statistical Validation**: Multiple runs and significance testing
- ✅ **Consistency**: Same test cases, same conditions
- ✅ **Visualization**: Track improvements with graphs and tables
- ✅ **Documentation**: Record evaluation results and analysis

## 📋 Related Documentation

- [Evaluation Metrics](./evaluation_metrics.md) - Metric definitions and calculation methods
- [Test Case Design](./evaluation_testcases.md) - Test case structure
- [Statistical Significance](./evaluation_statistics.md) - Statistical analysis methods
