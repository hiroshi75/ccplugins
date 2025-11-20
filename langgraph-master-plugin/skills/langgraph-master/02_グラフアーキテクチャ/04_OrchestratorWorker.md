# Orchestrator-Worker（マスターワーカー）

オーケストレーターがタスク分解し、複数のワーカーに委譲するパターン。

## 概要

Orchestrator-Workerは、**マスターノード**がタスクを複数のサブタスクに分解し、**ワーカーノード**に並列に委譲するパターンです。Map-Reduceパターンとも呼ばれます。

## 適用場面

- 複数の文書を並列処理
- 大きなタスクを小さなサブタスクに分割
- データセットの分散処理
- 複数のAPIを並列呼び出し

## 実装例: 複数文書の要約

```python
from langgraph.types import Send
from typing import TypedDict, Annotated
from operator import add

class State(TypedDict):
    documents: list[str]
    summaries: Annotated[list[str], add]
    final_summary: str

class WorkerState(TypedDict):
    document: str
    summary: str

def orchestrator_node(state: State):
    """タスクを分解してワーカーに委譲"""
    # 各文書をワーカーに送信
    return [
        Send("worker", {"document": doc})
        for doc in state["documents"]
    ]

def worker_node(state: WorkerState):
    """個別の文書を要約"""
    summary = llm.invoke(f"Summarize: {state['document']}")
    return {"summaries": [summary]}

def reducer_node(state: State):
    """すべての要約を統合"""
    all_summaries = "\n".join(state["summaries"])
    final = llm.invoke(f"Create final summary from:\n{all_summaries}")
    return {"final_summary": final}

# グラフ構築
builder = StateGraph(State)

builder.add_node("orchestrator", orchestrator_node)
builder.add_node("worker", worker_node)
builder.add_node("reducer", reducer_node)

# オーケストレーターからワーカーへ（動的）
builder.add_edge(START, "orchestrator")

# ワーカーから集約ノードへ
builder.add_edge("worker", "reducer")
builder.add_edge("reducer", END)

graph = builder.compile()
```

## Send APIの使用

`Send`オブジェクトで**動的にノードインスタンスを生成**します：

```python
def orchestrator(state: State):
    # 各アイテムごとにワーカーインスタンスを生成
    return [
        Send("worker", {"item": item, "index": i})
        for i, item in enumerate(state["items"])
    ]
```

## 応用パターン

### パターン1: 階層的処理

```python
def master_orchestrator(state: State):
    """マスターが複数のサブオーケストレーターに委譲"""
    return [
        Send("sub_orchestrator", {"category": cat, "items": items})
        for cat, items in group_by_category(state["all_items"])
    ]

def sub_orchestrator(state: SubState):
    """サブオーケストレーターが個別ワーカーに委譲"""
    return [
        Send("worker", {"item": item})
        for item in state["items"]
    ]
```

### パターン2: 条件付きワーカー選択

```python
def smart_orchestrator(state: State):
    """タスクの特性に応じて異なるワーカーを選択"""
    tasks = []

    for item in state["items"]:
        if is_complex(item):
            tasks.append(Send("advanced_worker", {"item": item}))
        else:
            tasks.append(Send("simple_worker", {"item": item}))

    return tasks
```

### パターン3: バッチ処理

```python
def batch_orchestrator(state: State):
    """アイテムをバッチに分割"""
    batch_size = 10
    batches = [
        state["items"][i:i+batch_size]
        for i in range(0, len(state["items"]), batch_size)
    ]

    return [
        Send("batch_worker", {"batch": batch, "batch_id": i})
        for i, batch in enumerate(batches)
    ]

def batch_worker(state: BatchState):
    """バッチを処理"""
    results = [process(item) for item in state["batch"]]
    return {"results": results}
```

### パターン4: エラー処理とリトライ

```python
class WorkerState(TypedDict):
    item: str
    retry_count: int
    result: str
    error: str | None

def robust_worker(state: WorkerState):
    """エラー処理付きワーカー"""
    try:
        result = process_item(state["item"])
        return {"result": result, "error": None}
    except Exception as e:
        if state.get("retry_count", 0) < 3:
            # リトライ
            return Send("worker", {
                "item": state["item"],
                "retry_count": state.get("retry_count", 0) + 1
            })
        else:
            # 最大リトライ数に到達
            return {"error": str(e)}
```

## 動的な並列度制御

```python
import os

def adaptive_orchestrator(state: State):
    """システムリソースに応じて並列度を調整"""
    max_workers = int(os.getenv("MAX_WORKERS", "5"))

    # アイテムをチャンクに分割
    items = state["items"]
    chunk_size = max(1, len(items) // max_workers)

    chunks = [
        items[i:i+chunk_size]
        for i in range(0, len(items), chunk_size)
    ]

    return [
        Send("worker", {"chunk": chunk})
        for chunk in chunks
    ]
```

## Reducer の実装パターン

### パターン1: 単純な集約

```python
from operator import add

class State(TypedDict):
    results: Annotated[list, add]

def reducer(state: State):
    """結果をシンプルに集約"""
    return {"total": sum(state["results"])}
```

### パターン2: 複雑な集約

```python
def advanced_reducer(state: State):
    """統計情報を計算"""
    results = state["results"]

    return {
        "total": sum(results),
        "average": sum(results) / len(results),
        "min": min(results),
        "max": max(results)
    }
```

### パターン3: LLMによる統合

```python
def llm_reducer(state: State):
    """LLMで複数の結果を統合"""
    all_results = "\n".join(state["summaries"])

    final = llm.invoke(
        f"Synthesize these summaries into one:\n{all_results}"
    )

    return {"final_summary": final}
```

## 利点

✅ **スケーラビリティ**: タスク数に応じて自動的にワーカー生成
✅ **並列処理**: 大量のデータを高速処理
✅ **柔軟性**: 動的にワーカー数を調整可能
✅ **分散処理**: 複数のサーバーに分散可能

## 注意点

⚠️ **メモリ消費**: 多数のワーカーインスタンスが生成される
⚠️ **Reducer設計**: 結果の集約方法を適切に設計
⚠️ **エラーハンドリング**: 一部のワーカーが失敗した場合の対処
⚠️ **リソース管理**: 並列度の制限が必要な場合がある

## ベストプラクティス

1. **バッチサイズの調整**: 小さすぎるとオーバーヘッド、大きすぎると並列性が低下
2. **エラーの分離**: 1つの失敗が全体に影響しないように
3. **進捗の追跡**: 大量タスクの場合、進捗を可視化
4. **リソースの制限**: 並列度の上限を設定

## まとめ

Orchestrator-Workerは**大量のタスクを並列処理**する場合に最適です。Send APIで動的にワーカーを生成し、Reducerで結果を集約します。

## 関連ページ

- [02_Parallelization.md](02_Parallelization.md) - 静的な並列処理との比較
- [05_応用機能/MapReduce.md](../05_応用機能/MapReduce.md) - Map-Reduce詳細
- [01_基本概念/State.md](../01_基本概念/State.md) - Reducerの詳細
