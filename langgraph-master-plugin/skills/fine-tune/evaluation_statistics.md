# Statistical Significance Testing

Statistical approaches and significance testing in LangGraph application evaluation.

## 📈 Importance of Multiple Runs

### Why Multiple Runs Are Necessary

1. **Account for Randomness**: LLM outputs have probabilistic variation
2. **Detect Outliers**: Eliminate effects like temporary network latency
3. **Calculate Confidence Intervals**: Determine if improvements are statistically significant

### Recommended Number of Runs

| Phase | Runs | Purpose |
|-------|------|---------|
| **During Development** | 3 | Quick feedback |
| **During Evaluation** | 5 | Balanced reliability |
| **Before Production** | 10-20 | High statistical confidence |

## 📊 Statistical Analysis

### Basic Statistical Calculations

```python
import numpy as np
from scipy import stats

def statistical_analysis(
    baseline_results: List[float],
    improved_results: List[float],
    alpha: float = 0.05
) -> Dict:
    """Statistical comparison of baseline and improved versions"""

    # Basic statistics
    baseline_stats = {
        "mean": np.mean(baseline_results),
        "std": np.std(baseline_results),
        "median": np.median(baseline_results),
        "min": np.min(baseline_results),
        "max": np.max(baseline_results)
    }

    improved_stats = {
        "mean": np.mean(improved_results),
        "std": np.std(improved_results),
        "median": np.median(improved_results),
        "min": np.min(improved_results),
        "max": np.max(improved_results)
    }

    # Independent t-test
    t_statistic, p_value = stats.ttest_ind(improved_results, baseline_results)

    # Effect size (Cohen's d)
    pooled_std = np.sqrt(
        ((len(baseline_results) - 1) * baseline_stats["std"]**2 +
         (len(improved_results) - 1) * improved_stats["std"]**2) /
        (len(baseline_results) + len(improved_results) - 2)
    )
    cohens_d = (improved_stats["mean"] - baseline_stats["mean"]) / pooled_std

    # Improvement percentage
    improvement_pct = (
        (improved_stats["mean"] - baseline_stats["mean"]) /
        baseline_stats["mean"] * 100
    )

    # Confidence intervals (95%)
    ci_baseline = stats.t.interval(
        0.95,
        len(baseline_results) - 1,
        loc=baseline_stats["mean"],
        scale=stats.sem(baseline_results)
    )

    ci_improved = stats.t.interval(
        0.95,
        len(improved_results) - 1,
        loc=improved_stats["mean"],
        scale=stats.sem(improved_results)
    )

    # Determine statistical significance
    is_significant = p_value < alpha

    # Interpret effect size
    effect_size_interpretation = (
        "small" if abs(cohens_d) < 0.5 else
        "medium" if abs(cohens_d) < 0.8 else
        "large"
    )

    return {
        "baseline": baseline_stats,
        "improved": improved_stats,
        "comparison": {
            "improvement_pct": improvement_pct,
            "t_statistic": t_statistic,
            "p_value": p_value,
            "is_significant": is_significant,
            "cohens_d": cohens_d,
            "effect_size": effect_size_interpretation
        },
        "confidence_intervals": {
            "baseline": ci_baseline,
            "improved": ci_improved
        }
    }

# Usage example
baseline_accuracy = [73.0, 75.0, 77.0, 74.0, 76.0]  # 5 run results
improved_accuracy = [85.0, 87.0, 86.0, 88.0, 84.0]  # 5 run results after improvement

analysis = statistical_analysis(baseline_accuracy, improved_accuracy)
print(f"Improvement: {analysis['comparison']['improvement_pct']:.1f}%")
print(f"P-value: {analysis['comparison']['p_value']:.4f}")
print(f"Significant: {analysis['comparison']['is_significant']}")
print(f"Effect size: {analysis['comparison']['effect_size']}")
```

## 🎯 Interpreting Statistical Significance

### P-value Interpretation

| P-value | Interpretation | Action |
|---------|---------------|--------|
| p < 0.01 | **Highly significant** | Adopt improvement with confidence |
| p < 0.05 | **Significant** | Can adopt as improvement |
| p < 0.10 | **Marginally significant** | Consider additional validation |
| p ≥ 0.10 | **Not significant** | Judge as no improvement effect |

### Effect Size (Cohen's d) Interpretation

| Cohen's d | Effect Size | Meaning |
|-----------|------------|---------|
| d < 0.2 | **Negligible** | No substantial improvement |
| 0.2 ≤ d < 0.5 | **Small** | Slight improvement |
| 0.5 ≤ d < 0.8 | **Medium** | Clear improvement |
| d ≥ 0.8 | **Large** | Significant improvement |

## 📉 Outlier Detection and Handling

### Outlier Detection

```python
def detect_outliers(data: List[float], method: str = "iqr") -> List[int]:
    """Detect outlier indices"""
    data_array = np.array(data)

    if method == "iqr":
        # IQR method (Interquartile Range)
        q1 = np.percentile(data_array, 25)
        q3 = np.percentile(data_array, 75)
        iqr = q3 - q1
        lower_bound = q1 - 1.5 * iqr
        upper_bound = q3 + 1.5 * iqr

        outliers = [
            i for i, val in enumerate(data)
            if val < lower_bound or val > upper_bound
        ]

    elif method == "zscore":
        # Z-score method
        mean = np.mean(data_array)
        std = np.std(data_array)
        z_scores = np.abs((data_array - mean) / std)

        outliers = [i for i, z in enumerate(z_scores) if z > 3]

    return outliers

# Usage example
results = [75.0, 76.0, 74.0, 77.0, 95.0]  # 95.0 may be an outlier
outliers = detect_outliers(results, method="iqr")
print(f"Outlier indices: {outliers}")  # => [4]
```

### Outlier Handling Policy

1. **Investigation**: Identify why outliers occurred
2. **Removal Decision**:
   - Clear errors (network failure, etc.) → Remove
   - Actual performance variation → Keep
3. **Documentation**: Document cause and handling of outliers

## 🔄 Considerations for Repeated Measurements

### Sample Size Calculation

```python
from scipy.stats import ttest_ind_from_stats

def required_sample_size(
    baseline_mean: float,
    baseline_std: float,
    expected_improvement_pct: float,
    alpha: float = 0.05,
    power: float = 0.8
) -> int:
    """Estimate required sample size"""
    improved_mean = baseline_mean * (1 + expected_improvement_pct / 100)

    # Calculate effect size
    effect_size = abs(improved_mean - baseline_mean) / baseline_std

    # Simple estimation (use statsmodels.stats.power for more accuracy)
    if effect_size < 0.2:
        return 100  # Small effect requires many samples
    elif effect_size < 0.5:
        return 50
    elif effect_size < 0.8:
        return 30
    else:
        return 20

# Usage example
sample_size = required_sample_size(
    baseline_mean=75.0,
    baseline_std=3.0,
    expected_improvement_pct=10.0
)
print(f"Required sample size: {sample_size}")
```

## 📊 Visualizing Confidence Intervals

```python
import matplotlib.pyplot as plt

def plot_confidence_intervals(
    baseline_results: List[float],
    improved_results: List[float],
    labels: List[str] = ["Baseline", "Improved"]
):
    """Plot confidence intervals"""
    fig, ax = plt.subplots(figsize=(10, 6))

    # Statistical calculations
    baseline_mean = np.mean(baseline_results)
    baseline_ci = stats.t.interval(
        0.95,
        len(baseline_results) - 1,
        loc=baseline_mean,
        scale=stats.sem(baseline_results)
    )

    improved_mean = np.mean(improved_results)
    improved_ci = stats.t.interval(
        0.95,
        len(improved_results) - 1,
        loc=improved_mean,
        scale=stats.sem(improved_results)
    )

    # Plot
    positions = [1, 2]
    means = [baseline_mean, improved_mean]
    cis = [
        (baseline_mean - baseline_ci[0], baseline_ci[1] - baseline_mean),
        (improved_mean - improved_ci[0], improved_ci[1] - improved_mean)
    ]

    ax.errorbar(positions, means, yerr=np.array(cis).T, fmt='o', markersize=10, capsize=10)
    ax.set_xticks(positions)
    ax.set_xticklabels(labels)
    ax.set_ylabel("Metric Value")
    ax.set_title("Comparison with 95% Confidence Intervals")
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig("confidence_intervals.png")
    print("Plot saved: confidence_intervals.png")
```

## 📋 Statistical Report Template

```markdown
## Statistical Analysis Results

### Basic Statistics

| Metric | Baseline | Improved | Improvement |
|--------|----------|----------|-------------|
| Mean | 75.0% | 86.0% | +11.0% |
| Std Dev | 3.2% | 2.1% | -1.1% |
| Median | 75.0% | 86.0% | +11.0% |
| Min | 70.0% | 84.0% | +14.0% |
| Max | 80.0% | 88.0% | +8.0% |

### Statistical Tests

- **t-statistic**: 8.45
- **P-value**: 0.0001 (p < 0.01)
- **Statistical Significance**: ✅ Highly significant
- **Effect Size (Cohen's d)**: 2.3 (large)

### Confidence Intervals (95%)

- **Baseline**: [72.8%, 77.2%]
- **Improved**: [84.9%, 87.1%]

### Conclusion

The improvement is statistically highly significant (p < 0.01), with a large effect size (Cohen's d = 2.3).
There is no overlap in confidence intervals, confirming the improvement effect is certain.
```

## 📋 Related Documentation

- [Evaluation Metrics](./evaluation_metrics.md) - Metric definitions and calculation methods
- [Test Case Design](./evaluation_testcases.md) - Test case structure
- [Best Practices](./evaluation_practices.md) - Practical evaluation guide
