# Map-Reduce（並列処理パターン）

大量データを並列処理して集約するパターン。

## 概要

Map-Reduceは、**Map**（並列処理）と**Reduce**（集約）を組み合わせたパターンです。LangGraphではSend APIで実現します。

## 基本的な実装

```python
from langgraph.types import Send
from typing import Annotated
from operator import add

class MapReduceState(TypedDict):
    items: list[str]
    results: Annotated[list[str], add]
    final_result: str

def map_node(state: MapReduceState):
    """Map: 各アイテムをワーカーに送信"""
    return [
        Send("worker", {"item": item})
        for item in state["items"]
    ]

def worker_node(item_state: dict):
    """個別アイテムを処理"""
    result = process_item(item_state["item"])
    return {"results": [result]}

def reduce_node(state: MapReduceState):
    """Reduce: 結果を集約"""
    final = aggregate_results(state["results"])
    return {"final_result": final}

# グラフ構築
builder = StateGraph(MapReduceState)
builder.add_node("map", map_node)
builder.add_node("worker", worker_node)
builder.add_node("reduce", reduce_node)

builder.add_edge(START, "map")
builder.add_edge("worker", "reduce")
builder.add_edge("reduce", END)

graph = builder.compile()
```

## Reducerの種類

### 加算（リスト結合）

```python
from operator import add

class State(TypedDict):
    results: Annotated[list, add]  # リストを結合

# [1, 2] + [3, 4] = [1, 2, 3, 4]
```

### カスタムReducer

```python
def merge_dicts(left: dict, right: dict) -> dict:
    """辞書をマージ"""
    return {**left, **right}

class State(TypedDict):
    data: Annotated[dict, merge_dicts]
```

## 応用パターン

### パターン1: 文書の並列要約

```python
class DocSummaryState(TypedDict):
    documents: list[str]
    summaries: Annotated[list[str], add]
    final_summary: str

def map_documents(state: DocSummaryState):
    """各文書をワーカーに送信"""
    return [
        Send("summarize_worker", {"doc": doc, "index": i})
        for i, doc in enumerate(state["documents"])
    ]

def summarize_worker(worker_state: dict):
    """個別の文書を要約"""
    summary = llm.invoke(f"Summarize: {worker_state['doc']}")
    return {"summaries": [summary]}

def final_summary_node(state: DocSummaryState):
    """全ての要約を統合"""
    combined = "\n".join(state["summaries"])
    final = llm.invoke(f"Create final summary from:\n{combined}")
    return {"final_summary": final}
```

### パターン2: 階層的Map-Reduce

```python
def level1_map(state: State):
    """第1レベル: データをチャンクに分割"""
    chunks = create_chunks(state["data"], chunk_size=100)
    return [
        Send("level1_worker", {"chunk": chunk})
        for chunk in chunks
    ]

def level1_worker(worker_state: dict):
    """第1レベルワーカー: チャンク内で集約"""
    partial_result = aggregate_chunk(worker_state["chunk"])
    return {"level1_results": [partial_result]}

def level2_map(state: State):
    """第2レベル: 部分結果をさらに集約"""
    return [
        Send("level2_worker", {"partial": result})
        for result in state["level1_results"]
    ]

def level2_worker(worker_state: dict):
    """第2レベルワーカー: 最終集約"""
    final = final_aggregate(worker_state["partial"])
    return {"final_result": final}
```

### パターン3: 動的な並列度制御

```python
import os

def adaptive_map(state: State):
    """システムリソースに応じて並列度を調整"""
    max_workers = int(os.getenv("MAX_WORKERS", "10"))
    items = state["items"]

    # アイテムをバッチに分割
    batch_size = max(1, len(items) // max_workers)
    batches = [
        items[i:i+batch_size]
        for i in range(0, len(items), batch_size)
    ]

    return [
        Send("batch_worker", {"batch": batch})
        for batch in batches
    ]

def batch_worker(worker_state: dict):
    """バッチを処理"""
    results = [process_item(item) for item in worker_state["batch"]]
    return {"results": results}
```

### パターン4: エラー耐性のあるMap-Reduce

```python
class RobustState(TypedDict):
    items: list[str]
    successes: Annotated[list, add]
    failures: Annotated[list, add]

def robust_worker(worker_state: dict):
    """エラー処理付きワーカー"""
    try:
        result = process_item(worker_state["item"])
        return {"successes": [{"item": worker_state["item"], "result": result}]}

    except Exception as e:
        return {"failures": [{"item": worker_state["item"], "error": str(e)}]}

def error_handler(state: RobustState):
    """失敗したアイテムを処理"""
    if state["failures"]:
        # 失敗したアイテムを再試行またはログ
        log_failures(state["failures"])

    return {"final_result": aggregate(state["successes"])}
```

## パフォーマンス最適化

### バッチサイズの調整

```python
def optimal_batching(items: list, target_batch_time: float = 1.0):
    """最適なバッチサイズを計算"""
    # 1アイテムあたりの処理時間を推定
    sample_time = estimate_processing_time(items[0])

    # 目標時間に到達するバッチサイズ
    batch_size = max(1, int(target_batch_time / sample_time))

    batches = [
        items[i:i+batch_size]
        for i in range(0, len(items), batch_size)
    ]

    return batches
```

### 進捗の追跡

```python
from langgraph.config import get_stream_writer

def map_with_progress(state: State):
    """進捗を報告するMap"""
    writer = get_stream_writer()
    total = len(state["items"])

    sends = []
    for i, item in enumerate(state["items"]):
        sends.append(Send("worker", {"item": item}))
        writer({"progress": f"{i+1}/{total}"})

    return sends
```

## 集約パターン

### 統計集約

```python
def statistical_reduce(state: State):
    """統計情報を計算"""
    results = state["results"]

    return {
        "total": sum(results),
        "average": sum(results) / len(results),
        "min": min(results),
        "max": max(results),
        "count": len(results)
    }
```

### LLMによる統合

```python
def llm_reduce(state: State):
    """LLMで複数の結果を統合"""
    all_results = "\n\n".join([
        f"Result {i+1}:\n{r}"
        for i, r in enumerate(state["results"])
    ])

    final = llm.invoke(
        f"Synthesize these results into a comprehensive answer:\n\n{all_results}"
    )

    return {"final_result": final}
```

## 利点

✅ **スケーラビリティ**: 大量データを効率的に処理
✅ **並列性**: 独立したタスクを同時実行
✅ **柔軟性**: 動的にワーカー数を調整
✅ **エラー分離**: 1つの失敗が全体に影響しない

## 注意点

⚠️ **メモリ消費**: 多数のワーカーインスタンス
⚠️ **順序不定**: ワーカーの実行順序は保証されない
⚠️ **オーバーヘッド**: 小さなタスクでは非効率
⚠️ **Reducer設計**: 結果の集約方法を適切に設計

## まとめ

Map-ReduceはSend APIで大量データを並列処理し、Reducerで集約するパターンです。大規模データ処理に最適です。

## 関連ページ

- [02_グラフアーキテクチャ/04_OrchestratorWorker.md](../02_グラフアーキテクチャ/04_OrchestratorWorker.md) - Orchestrator-Workerパターン
- [02_グラフアーキテクチャ/02_Parallelization.md](../02_グラフアーキテクチャ/02_Parallelization.md) - 静的並列処理との比較
- [01_基本概念/State.md](../01_基本概念/State.md) - Reducerの詳細
