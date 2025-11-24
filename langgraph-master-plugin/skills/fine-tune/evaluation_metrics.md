# 評価指標の設計

LangGraph アプリケーションのファインチューニングにおける評価指標の定義と計算方法。

**💡 Tip**: 実践的な評価スクリプトとレポートテンプレートは [examples.md](examples.md#phase-2-ベースライン評価の例) を参照してください。

## 📊 評価の重要性

ファインチューニングにおいて評価は：
- **改善の定量化**: 客観的な進捗測定
- **意思決定の根拠**: データに基づく優先順位付け
- **品質保証**: リグレッションの防止
- **ROI の証明**: ビジネス価値の可視化

## 🎯 評価指標カテゴリ

### 1. 品質指標（Quality Metrics）

#### Accuracy（正解率）
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

#### F1 Score（マルチクラス分類）
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

#### Semantic Similarity（意味的類似度）
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

#### BLEU Score（テキスト生成品質）
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

### 2. パフォーマンス指標（Performance Metrics）

#### Latency（応答時間）
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

#### Throughput（スループット）
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

### 3. コスト指標（Cost Metrics）

#### Token Usage とコスト
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

#### Cost per Request
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

### 4. 信頼性指標（Reliability Metrics）

#### Error Rate（エラー率）
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

#### Retry Rate（リトライ率）
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

## 📋 関連ドキュメント

- [テストケースの設計](./evaluation_testcases.md) - テストケース構造とカバレッジ
- [統計的有意性の検証](./evaluation_statistics.md) - 複数回実行と統計分析
- [評価のベストプラクティス](./evaluation_practices.md) - 一貫性、可視化、レポート
