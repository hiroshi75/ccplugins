# 評価方法とベストプラクティス

LangGraph アプリケーションのファインチューニングにおける評価戦略、メトリクス、ベストプラクティス。

**💡 Tip**: 実践的な評価スクリプトとレポートテンプレートは [examples.md](examples.md#phase-2-ベースライン評価の例) を参照してください。

## 📊 評価の重要性

ファインチューニングにおいて評価は：
- **改善の定量化**: 客観的な進捗測定
- **意思決定の根拠**: データに基づく優先順位付け
- **品質保証**: リグレッションの防止
- **ROI の証明**: ビジネス価値の可視化

## 🎯 評価指標の設計

### 主要な評価指標カテゴリ

#### 1. 品質指標（Quality Metrics）

**Accuracy（正解率）**
```python
def calculate_accuracy(predictions: List, ground_truth: List) -> float:
    """正解率を計算"""
    correct = sum(p == g for p, g in zip(predictions, ground_truth))
    return (correct / len(predictions)) * 100

# 例
predictions = ["product", "technical", "billing", "general"]
ground_truth = ["product", "billing", "billing", "general"]
accuracy = calculate_accuracy(predictions, ground_truth)
# => 50.0% (2/4が正解)
```

**F1 Score（マルチクラス分類）**
```python
from sklearn.metrics import f1_score, classification_report

def calculate_f1(predictions: List, ground_truth: List, average='weighted') -> float:
    """F1スコアを計算（マルチクラス対応）"""
    return f1_score(ground_truth, predictions, average=average)

# 詳細レポート
report = classification_report(ground_truth, predictions)
print(report)
"""
              precision    recall  f1-score   support

     product       1.00      1.00      1.00         1
   technical       0.00      0.00      0.00         1
     billing       0.50      1.00      0.67         1
     general       1.00      1.00      1.00         1

    accuracy                           0.75         4
   macro avg       0.62      0.75      0.67         4
weighted avg       0.62      0.75      0.67         4
"""
```

**Semantic Similarity（意味的類似度）**
```python
from sentence_transformers import SentenceTransformer, util

def calculate_semantic_similarity(
    generated: str,
    reference: str,
    model_name: str = "all-MiniLM-L6-v2"
) -> float:
    """生成されたテキストと参照テキストの意味的類似度を計算"""
    model = SentenceTransformer(model_name)

    embeddings = model.encode([generated, reference], convert_to_tensor=True)
    similarity = util.pytorch_cos_sim(embeddings[0], embeddings[1])

    return similarity.item()

# 例
generated = "Our premium plan costs $49 per month."
reference = "The premium subscription is $49/month."
similarity = calculate_semantic_similarity(generated, reference)
# => 0.87 (高い類似度)
```

**BLEU Score（テキスト生成品質）**
```python
from nltk.translate.bleu_score import sentence_bleu

def calculate_bleu(generated: str, reference: str) -> float:
    """BLEU スコアを計算"""
    reference_tokens = [reference.split()]
    generated_tokens = generated.split()

    return sentence_bleu(reference_tokens, generated_tokens)

# 例
generated = "The product costs forty nine dollars"
reference = "The product costs $49"
bleu = calculate_bleu(generated, reference)
# => 0.45
```

#### 2. パフォーマンス指標（Performance Metrics）

**Latency（応答時間）**
```python
import time
from typing import Dict, List

def measure_latency(test_cases: List[Dict]) -> Dict:
    """各ノードとトータルのレイテンシーを測定"""
    results = {
        "total": [],
        "by_node": {}
    }

    for case in test_cases:
        start_time = time.time()

        # ノードごとの計測
        node_times = {}

        # Node 1: analyze_intent
        node_start = time.time()
        analyze_result = analyze_intent(case["input"])
        node_times["analyze_intent"] = time.time() - node_start

        # Node 2: retrieve_context
        node_start = time.time()
        context = retrieve_context(analyze_result)
        node_times["retrieve_context"] = time.time() - node_start

        # Node 3: generate_response
        node_start = time.time()
        response = generate_response(context, case["input"])
        node_times["generate_response"] = time.time() - node_start

        total_time = time.time() - start_time

        results["total"].append(total_time)
        for node, duration in node_times.items():
            if node not in results["by_node"]:
                results["by_node"][node] = []
            results["by_node"][node].append(duration)

    # 統計計算
    import numpy as np
    summary = {
        "total": {
            "mean": np.mean(results["total"]),
            "p50": np.percentile(results["total"], 50),
            "p95": np.percentile(results["total"], 95),
            "p99": np.percentile(results["total"], 99),
        }
    }

    for node, times in results["by_node"].items():
        summary[node] = {
            "mean": np.mean(times),
            "p50": np.percentile(times, 50),
            "p95": np.percentile(times, 95),
        }

    return summary

# 使用例
latency_results = measure_latency(test_cases)
print(f"Mean latency: {latency_results['total']['mean']:.2f}s")
print(f"P95 latency: {latency_results['total']['p95']:.2f}s")
```

**Throughput（スループット）**
```python
import concurrent.futures
from typing import List, Dict

def measure_throughput(
    test_cases: List[Dict],
    max_workers: int = 10,
    duration_seconds: int = 60
) -> Dict:
    """一定時間内の処理数を測定"""
    start_time = time.time()
    completed = 0
    errors = 0

    def process_case(case):
        try:
            result = run_langgraph_app(case["input"])
            return True
        except Exception:
            return False

    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        while time.time() - start_time < duration_seconds:
            # テストケースをループ
            for case in test_cases:
                if time.time() - start_time >= duration_seconds:
                    break

                future = executor.submit(process_case, case)
                if future.result():
                    completed += 1
                else:
                    errors += 1

    elapsed = time.time() - start_time

    return {
        "completed": completed,
        "errors": errors,
        "elapsed": elapsed,
        "throughput": completed / elapsed,  # requests per second
        "error_rate": errors / (completed + errors) if (completed + errors) > 0 else 0
    }

# 使用例
throughput = measure_throughput(test_cases, max_workers=5, duration_seconds=30)
print(f"Throughput: {throughput['throughput']:.2f} req/s")
print(f"Error rate: {throughput['error_rate']*100:.2f}%")
```

#### 3. コスト指標（Cost Metrics）

**Token Usage とコスト**
```python
from typing import Dict

# モデルごとの料金表（2024年11月時点）
PRICING = {
    "claude-3-5-sonnet-20241022": {
        "input": 3.0 / 1_000_000,   # $3.00 per 1M input tokens
        "output": 15.0 / 1_000_000,  # $15.00 per 1M output tokens
    },
    "claude-3-5-haiku-20241022": {
        "input": 0.8 / 1_000_000,   # $0.80 per 1M input tokens
        "output": 4.0 / 1_000_000,   # $4.00 per 1M output tokens
    }
}

def calculate_cost(token_usage: Dict, model: str) -> Dict:
    """トークン使用量からコストを計算"""
    pricing = PRICING.get(model, PRICING["claude-3-5-sonnet-20241022"])

    input_cost = token_usage["input_tokens"] * pricing["input"]
    output_cost = token_usage["output_tokens"] * pricing["output"]
    total_cost = input_cost + output_cost

    return {
        "input_tokens": token_usage["input_tokens"],
        "output_tokens": token_usage["output_tokens"],
        "total_tokens": token_usage["input_tokens"] + token_usage["output_tokens"],
        "input_cost": input_cost,
        "output_cost": output_cost,
        "total_cost": total_cost,
        "cost_breakdown": {
            "input_pct": (input_cost / total_cost * 100) if total_cost > 0 else 0,
            "output_pct": (output_cost / total_cost * 100) if total_cost > 0 else 0
        }
    }

# 使用例
token_usage = {"input_tokens": 1500, "output_tokens": 800}
cost = calculate_cost(token_usage, "claude-3-5-sonnet-20241022")
print(f"Total cost: ${cost['total_cost']:.4f}")
print(f"Input: ${cost['input_cost']:.4f} ({cost['cost_breakdown']['input_pct']:.1f}%)")
print(f"Output: ${cost['output_cost']:.4f} ({cost['cost_breakdown']['output_pct']:.1f}%)")
```

**Cost per Request**
```python
def calculate_cost_per_request(
    test_results: List[Dict],
    model: str
) -> Dict:
    """リクエストあたりのコストを計算"""
    total_cost = 0
    total_input_tokens = 0
    total_output_tokens = 0

    for result in test_results:
        cost = calculate_cost(result["token_usage"], model)
        total_cost += cost["total_cost"]
        total_input_tokens += result["token_usage"]["input_tokens"]
        total_output_tokens += result["token_usage"]["output_tokens"]

    num_requests = len(test_results)

    return {
        "total_requests": num_requests,
        "total_cost": total_cost,
        "cost_per_request": total_cost / num_requests,
        "avg_input_tokens": total_input_tokens / num_requests,
        "avg_output_tokens": total_output_tokens / num_requests,
        "total_tokens": total_input_tokens + total_output_tokens
    }
```

#### 4. 信頼性指標（Reliability Metrics）

**Error Rate（エラー率）**
```python
def calculate_error_rate(results: List[Dict]) -> Dict:
    """エラー率とエラータイプを分析"""
    total = len(results)
    errors = [r for r in results if r.get("error")]

    error_types = {}
    for error in errors:
        error_type = error["error"]["type"]
        if error_type not in error_types:
            error_types[error_type] = 0
        error_types[error_type] += 1

    return {
        "total_requests": total,
        "total_errors": len(errors),
        "error_rate": len(errors) / total if total > 0 else 0,
        "error_types": error_types,
        "success_rate": (total - len(errors)) / total if total > 0 else 0
    }
```

**Retry Rate（リトライ率）**
```python
def calculate_retry_rate(results: List[Dict]) -> Dict:
    """リトライが必要だったケースの割合"""
    total = len(results)
    retried = [r for r in results if r.get("retry_count", 0) > 0]

    return {
        "total_requests": total,
        "retried_requests": len(retried),
        "retry_rate": len(retried) / total if total > 0 else 0,
        "avg_retries": sum(r.get("retry_count", 0) for r in retried) / len(retried) if retried else 0
    }
```

## 🧪 テストケースの設計

### 代表的なテストケースの構造

```json
{
  "test_cases": [
    {
      "id": "TC001",
      "category": "product_inquiry",
      "difficulty": "easy",
      "input": "How much does the premium plan cost?",
      "expected_intent": "product_inquiry",
      "expected_answer": "The premium plan costs $49 per month.",
      "expected_answer_semantic": ["premium", "plan", "$49", "month"],
      "metadata": {
        "user_type": "new",
        "context_required": false
      }
    },
    {
      "id": "TC002",
      "category": "technical_support",
      "difficulty": "medium",
      "input": "I can't seem to log into my account even after resetting my password",
      "expected_intent": "technical_support",
      "expected_answer": "Let me help you troubleshoot the login issue. First, please clear your browser cache and cookies, then try logging in again.",
      "expected_answer_semantic": ["troubleshoot", "clear cache", "cookies", "try again"],
      "metadata": {
        "user_type": "existing",
        "context_required": true,
        "requires_escalation": false
      }
    },
    {
      "id": "TC003",
      "category": "edge_case",
      "difficulty": "hard",
      "input": "yo whats the deal with my bill being so high lol",
      "expected_intent": "billing",
      "expected_answer": "I understand you have concerns about your bill. Let me review your account to identify any unexpected charges.",
      "expected_answer_semantic": ["concerns", "bill", "review", "charges"],
      "metadata": {
        "user_type": "existing",
        "context_required": true,
        "tone": "informal",
        "requires_empathy": true
      }
    }
  ]
}
```

### テストケースのカバレッジ

**カテゴリ別のバランス**
```python
def analyze_test_coverage(test_cases: List[Dict]) -> Dict:
    """テストケースのカバレッジを分析"""
    categories = {}
    difficulties = {}

    for case in test_cases:
        # カテゴリ
        cat = case.get("category", "unknown")
        categories[cat] = categories.get(cat, 0) + 1

        # 難易度
        diff = case.get("difficulty", "unknown")
        difficulties[diff] = difficulties.get(diff, 0) + 1

    total = len(test_cases)

    return {
        "total_cases": total,
        "by_category": {
            cat: {"count": count, "percentage": count/total*100}
            for cat, count in categories.items()
        },
        "by_difficulty": {
            diff: {"count": count, "percentage": count/total*100}
            for diff, count in difficulties.items()
        }
    }

# 推奨バランス
"""
カテゴリ別:
- 各カテゴリ: 20-30% (均等分散)
- Edge cases: 10-15% (十分な異常系カバレッジ)

難易度別:
- Easy: 40-50% (基本機能の確認)
- Medium: 30-40% (実用的なケース)
- Hard: 10-20% (エッジケースと複雑なシナリオ)
"""
```

## 📈 統計的有意性の検証

### 複数回実行の重要性

**なぜ複数回実行が必要か**:
1. **ランダム性の考慮**: LLM 出力には確率的な変動がある
2. **外れ値の検出**: 一時的なネットワーク遅延などの影響を排除
3. **信頼区間の計算**: 改善が統計的に有意かを判断

**推奨実行回数**:
- **開発中**: 3回（迅速なフィードバック）
- **評価時**: 5回（バランスの取れた信頼性）
- **本番前**: 10-20回（高い統計的信頼性）

### 統計分析

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

## 🎯 評価のベストプラクティス

### 1. 一貫性の確保

**同じ条件での評価**:
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

**小さく始めて徐々に拡大**:
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

**構造化されたログ**:
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

**結果の可視化**:
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

## まとめ

効果的な評価のために：
- ✅ **複数の指標**: 品質、パフォーマンス、コスト、信頼性
- ✅ **統計的検証**: 複数回実行と有意性検定
- ✅ **一貫性**: 同じテストケース、同じ条件
- ✅ **可視化**: グラフと表で改善を追跡
- ✅ **文書化**: 評価結果と分析を記録
