# 評価のベストプラクティス

LangGraph アプリケーションの評価を効果的に実施するための実践的なガイドライン。

## 🎯 評価のベストプラクティス

### 1. 一貫性の確保

#### 同じ条件での評価

```python
class EvaluationConfig:
    """評価設定を固定して一貫性を確保"""

    def __init__(self):
        self.test_cases_path = "tests/evaluation/test_cases.json"
        self.seed = 42  # 再現性のため
        self.iterations = 5
        self.timeout = 30  # seconds
        self.model = "claude-3-5-sonnet-20241022"

    def load_test_cases(self) -> List[Dict]:
        """同じテストケースを読み込む"""
        with open(self.test_cases_path) as f:
            data = json.load(f)
        return data["test_cases"]

# 使用
config = EvaluationConfig()
test_cases = config.load_test_cases()
# すべての評価で同じテストケースを使用
```

### 2. 段階的な評価

#### 小さく始めて徐々に拡大

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

### 3. 評価結果の記録

#### 構造化されたログ

```python
import json
from datetime import datetime
from pathlib import Path

def save_evaluation_result(
    results: Dict,
    version: str,
    output_dir: Path = Path("evaluation_results")
):
    """評価結果を保存"""
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

# 使用
save_evaluation_result(results, version="baseline")
save_evaluation_result(results, version="iteration_1")
```

### 4. 可視化

#### 結果の可視化

```python
import matplotlib.pyplot as plt

def visualize_improvement(
    baseline: Dict,
    iterations: List[Dict],
    metrics: List[str] = ["accuracy", "latency", "cost"]
):
    """改善の推移を可視化"""
    fig, axes = plt.subplots(1, len(metrics), figsize=(15, 5))

    for idx, metric in enumerate(metrics):
        ax = axes[idx]

        # データ準備
        x = ["Baseline"] + [f"Iter {i+1}" for i in range(len(iterations))]
        y = [baseline[metric]] + [it[metric] for it in iterations]

        # プロット
        ax.plot(x, y, marker='o', linewidth=2)
        ax.set_title(f"{metric.capitalize()} Progress")
        ax.set_ylabel(metric.capitalize())
        ax.grid(True, alpha=0.3)

        # 目標線
        if metric in baseline.get("goals", {}):
            goal = baseline["goals"][metric]
            ax.axhline(y=goal, color='r', linestyle='--', label='Goal')
            ax.legend()

    plt.tight_layout()
    plt.savefig("evaluation_results/improvement_progress.png")
    print("Visualization saved to: evaluation_results/improvement_progress.png")
```

## 📋 評価レポートのテンプレート

### 標準レポート形式

```markdown
# 評価レポート - [Version/Iteration]

実行日時: 2024-11-24 12:00:00
実行者: Claude Code (fine-tune skill)

## 設定

- **モデル**: claude-3-5-sonnet-20241022
- **テストケース数**: 20
- **実行回数**: 5
- **評価期間**: 10分

## 結果サマリー

| 指標 | 平均 | 標準偏差 | 95% CI | 目標 | 達成率 |
|------|------|----------|--------|------|--------|
| Accuracy | 86.0% | 2.1% | [83.9%, 88.1%] | 90.0% | 95.6% |
| Latency | 2.4s | 0.3s | [2.1s, 2.7s] | 2.0s | 83.3% |
| Cost | $0.014 | $0.001 | [$0.013, $0.015] | $0.010 | 71.4% |

## 詳細分析

### Accuracy
- **改善**: +11.0% (75.0% → 86.0%)
- **統計的有意性**: p < 0.01 ✅
- **効果量**: Cohen's d = 2.3 (large)

### Latency
- **改善**: -0.1s (2.5s → 2.4s)
- **統計的有意性**: p = 0.12 ❌（有意でない）
- **効果量**: Cohen's d = 0.3 (small)

## エラー分析

- **総エラー数**: 0
- **エラー率**: 0.0%
- **リトライ率**: 0.0%

## 次のアクション

1. ✅ Accuracy が大幅に向上 → 継続
2. ⚠️ Latency は改善が小さい → 次の iteration で focus
3. ⚠️ Cost はまだ目標未達 → max_tokens 制限を検討
```

## 🔍 トラブルシューティング

### よくある問題と解決策

#### 1. 評価結果のばらつきが大きい

**症状**: 標準偏差が平均の 20% 以上

**原因**:
- LLM の temperature が高すぎる
- テストケースが不均一
- ネットワーク遅延の影響

**解決策**:
```python
# temperature を下げる
llm = ChatAnthropic(
    model="claude-3-5-sonnet-20241022",
    temperature=0.3  # 低めに設定
)

# 実行回数を増やす
iterations = 10  # 5 → 10

# 外れ値を除外
results_clean = remove_outliers(results)
```

#### 2. 評価時間が長すぎる

**症状**: 評価に 1時間以上かかる

**原因**:
- テストケース数が多すぎる
- 並列実行していない
- タイムアウト設定が長すぎる

**解決策**:
```python
# サブセット評価
quick_test_cases = test_cases[:10]  # 最初の10ケースのみ

# 並列実行
import concurrent.futures
with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
    futures = [executor.submit(evaluate_case, case) for case in test_cases]
    results = [f.result() for f in futures]

# タイムアウト設定
timeout = 10  # 30s → 10s
```

#### 3. 統計的有意性が出ない

**症状**: p値が 0.05 以上

**原因**:
- 改善効果が小さい
- サンプルサイズが不足
- データのばらつきが大きい

**解決策**:
```python
# より大きな改善を目指す
# - 複数の最適化を同時に適用
# - より効果的なテクニックを選択

# サンプルサイズを増やす
iterations = 20  # 5 → 20

# ばらつきを減らす
# - temperature を下げる
# - 評価環境を安定化
```

## 📊 継続的評価

### 定期評価スケジュール

```yaml
evaluation_schedule:
  daily:
    - quick_check: 3 test cases, 1 iteration
    - purpose: 大きな regression の検出

  weekly:
    - medium_check: 10 test cases, 3 iterations
    - purpose: 継続的な品質モニタリング

  before_release:
    - full_evaluation: all test cases, 5-10 iterations
    - purpose: リリース品質の保証

  after_major_changes:
    - comprehensive_evaluation: all test cases, 10+ iterations
    - purpose: 大規模変更の影響評価
```

### 自動評価パイプライン

```bash
#!/bin/bash
# continuous_evaluation.sh

# 毎日実行される評価スクリプト

DATE=$(date +%Y%m%d)
RESULTS_DIR="evaluation_results/continuous/$DATE"
mkdir -p $RESULTS_DIR

# Quick check
echo "Running quick evaluation..."
uv run python -m tests.evaluation.evaluator \
    --test-cases 3 \
    --iterations 1 \
    --output "$RESULTS_DIR/quick.json"

# 前回の結果と比較
uv run python -m tests.evaluation.compare \
    --baseline "evaluation_results/baseline/summary.json" \
    --current "$RESULTS_DIR/quick.json" \
    --threshold 0.05

# regression が検出されたら通知
if [ $? -ne 0 ]; then
    echo "⚠️ Regression detected! Sending notification..."
    # 通知処理（Slack, Email など）
fi
```

## まとめ

効果的な評価のために：
- ✅ **複数の指標**: 品質、パフォーマンス、コスト、信頼性
- ✅ **統計的検証**: 複数回実行と有意性検定
- ✅ **一貫性**: 同じテストケース、同じ条件
- ✅ **可視化**: グラフと表で改善を追跡
- ✅ **文書化**: 評価結果と分析を記録

## 📋 関連ドキュメント

- [評価指標](./evaluation_metrics.md) - 指標の定義と計算方法
- [テストケース設計](./evaluation_testcases.md) - テストケース構造
- [統計的有意性](./evaluation_statistics.md) - 統計分析の方法
