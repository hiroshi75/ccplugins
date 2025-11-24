# 統計的有意性の検証

LangGraph アプリケーションの評価における統計的アプローチと有意性検定。

## 📈 複数回実行の重要性

### なぜ複数回実行が必要か

1. **ランダム性の考慮**: LLM 出力には確率的な変動がある
2. **外れ値の検出**: 一時的なネットワーク遅延などの影響を排除
3. **信頼区間の計算**: 改善が統計的に有意かを判断

### 推奨実行回数

| フェーズ | 実行回数 | 目的 |
|---------|---------|------|
| **開発中** | 3回 | 迅速なフィードバック |
| **評価時** | 5回 | バランスの取れた信頼性 |
| **本番前** | 10-20回 | 高い統計的信頼性 |

## 📊 統計分析

### 基本統計量の計算

```python
import numpy as np
from scipy import stats

def statistical_analysis(
    baseline_results: List[float],
    improved_results: List[float],
    alpha: float = 0.05
) -> Dict:
    """ベースラインと改善版の統計的比較"""

    # 基本統計量
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

    # t検定（対応なし）
    t_statistic, p_value = stats.ttest_ind(improved_results, baseline_results)

    # 効果量（Cohen's d）
    pooled_std = np.sqrt(
        ((len(baseline_results) - 1) * baseline_stats["std"]**2 +
         (len(improved_results) - 1) * improved_stats["std"]**2) /
        (len(baseline_results) + len(improved_results) - 2)
    )
    cohens_d = (improved_stats["mean"] - baseline_stats["mean"]) / pooled_std

    # 改善率
    improvement_pct = (
        (improved_stats["mean"] - baseline_stats["mean"]) /
        baseline_stats["mean"] * 100
    )

    # 信頼区間（95%）
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

    # 統計的有意性の判定
    is_significant = p_value < alpha

    # 効果の大きさの解釈
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

# 使用例
baseline_accuracy = [73.0, 75.0, 77.0, 74.0, 76.0]  # 5回の実行結果
improved_accuracy = [85.0, 87.0, 86.0, 88.0, 84.0]  # 改善後の5回の実行結果

analysis = statistical_analysis(baseline_accuracy, improved_accuracy)
print(f"Improvement: {analysis['comparison']['improvement_pct']:.1f}%")
print(f"P-value: {analysis['comparison']['p_value']:.4f}")
print(f"Significant: {analysis['comparison']['is_significant']}")
print(f"Effect size: {analysis['comparison']['effect_size']}")
```

## 🎯 統計的有意性の解釈

### P値の解釈

| P値 | 解釈 | アクション |
|-----|------|-----------|
| p < 0.01 | **非常に有意** | 改善を確信して採用 |
| p < 0.05 | **有意** | 改善として採用可能 |
| p < 0.10 | **やや有意** | 追加検証を検討 |
| p ≥ 0.10 | **有意でない** | 改善効果なしと判断 |

### 効果量（Cohen's d）の解釈

| Cohen's d | 効果の大きさ | 意味 |
|-----------|------------|------|
| d < 0.2 | **無視できる** | 実質的な改善なし |
| 0.2 ≤ d < 0.5 | **小** | わずかな改善 |
| 0.5 ≤ d < 0.8 | **中** | 明確な改善 |
| d ≥ 0.8 | **大** | 大幅な改善 |

## 📉 外れ値の検出と処理

### 外れ値検出

```python
def detect_outliers(data: List[float], method: str = "iqr") -> List[int]:
    """外れ値のインデックスを検出"""
    data_array = np.array(data)

    if method == "iqr":
        # IQR法（四分位範囲）
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
        # Z-score法
        mean = np.mean(data_array)
        std = np.std(data_array)
        z_scores = np.abs((data_array - mean) / std)

        outliers = [i for i, z in enumerate(z_scores) if z > 3]

    return outliers

# 使用例
results = [75.0, 76.0, 74.0, 77.0, 95.0]  # 95.0 が外れ値の可能性
outliers = detect_outliers(results, method="iqr")
print(f"Outlier indices: {outliers}")  # => [4]
```

### 外れ値の処理方針

1. **調査**: なぜ外れ値が発生したか原因を特定
2. **除外判断**:
   - 明らかなエラー（ネットワーク障害など）→ 除外
   - 実際の性能変動 → 保持
3. **記録**: 外れ値の原因と処理を文書化

## 🔄 反復測定における注意点

### サンプルサイズの計算

```python
from scipy.stats import ttest_ind_from_stats

def required_sample_size(
    baseline_mean: float,
    baseline_std: float,
    expected_improvement_pct: float,
    alpha: float = 0.05,
    power: float = 0.8
) -> int:
    """必要なサンプルサイズを推定"""
    improved_mean = baseline_mean * (1 + expected_improvement_pct / 100)

    # 効果量の計算
    effect_size = abs(improved_mean - baseline_mean) / baseline_std

    # 簡易的な推定（より正確には statsmodels.stats.power を使用）
    if effect_size < 0.2:
        return 100  # 小さい効果には多くのサンプルが必要
    elif effect_size < 0.5:
        return 50
    elif effect_size < 0.8:
        return 30
    else:
        return 20

# 使用例
sample_size = required_sample_size(
    baseline_mean=75.0,
    baseline_std=3.0,
    expected_improvement_pct=10.0
)
print(f"Required sample size: {sample_size}")
```

## 📊 信頼区間の可視化

```python
import matplotlib.pyplot as plt

def plot_confidence_intervals(
    baseline_results: List[float],
    improved_results: List[float],
    labels: List[str] = ["Baseline", "Improved"]
):
    """信頼区間をプロット"""
    fig, ax = plt.subplots(figsize=(10, 6))

    # 統計計算
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

    # プロット
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

## 📋 統計レポートテンプレート

```markdown
## 統計的分析結果

### 基本統計量

| 指標 | ベースライン | 改善版 | 改善 |
|-----|------------|-------|------|
| 平均 | 75.0% | 86.0% | +11.0% |
| 標準偏差 | 3.2% | 2.1% | -1.1% |
| 中央値 | 75.0% | 86.0% | +11.0% |
| 最小値 | 70.0% | 84.0% | +14.0% |
| 最大値 | 80.0% | 88.0% | +8.0% |

### 統計的検定

- **t統計量**: 8.45
- **P値**: 0.0001 (p < 0.01)
- **統計的有意性**: ✅ 非常に有意
- **効果量（Cohen's d）**: 2.3 (large)

### 信頼区間（95%）

- **ベースライン**: [72.8%, 77.2%]
- **改善版**: [84.9%, 87.1%]

### 結論

改善は統計的に非常に有意であり（p < 0.01）、効果量も大きい（Cohen's d = 2.3）。
信頼区間の重なりもなく、改善効果は確実と判断できる。
```

## 📋 関連ドキュメント

- [評価指標](./evaluation_metrics.md) - 指標の定義と計算方法
- [テストケース設計](./evaluation_testcases.md) - テストケース構造
- [ベストプラクティス](./evaluation_practices.md) - 評価の実践的なガイド
