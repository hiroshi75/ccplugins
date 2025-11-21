# Parallelization（並列処理）

複数の独立したタスクを同時実行するパターン。

## 概要

Parallelizationは、**互いに依存しない複数のタスク**を同時に実行し、速度向上や信頼性検証を実現するパターンです。

## 適用場面

- 複数の評価基準でドキュメントを採点
- 異なる観点からの分析（技術的/ビジネス的/法的）
- 複数の翻訳エンジンで結果を比較
- Map-Reduceパターンの実装

## 実装例

```python
from typing import Annotated, TypedDict
from operator import add

class State(TypedDict):
    document: str
    scores: Annotated[list[dict], add]  # 複数の結果を集約

def technical_review(state: State):
    """技術的観点からレビュー"""
    score = llm.invoke(
        f"Technical review: {state['document']}"
    )
    return {"scores": [{"type": "technical", "score": score}]}

def business_review(state: State):
    """ビジネス観点からレビュー"""
    score = llm.invoke(
        f"Business review: {state['document']}"
    )
    return {"scores": [{"type": "business", "score": score}]}

def legal_review(state: State):
    """法的観点からレビュー"""
    score = llm.invoke(
        f"Legal review: {state['document']}"
    )
    return {"scores": [{"type": "legal", "score": score}]}

def aggregate_scores(state: State):
    """スコアを集計"""
    total = sum(s["score"] for s in state["scores"])
    return {"final_score": total / len(state["scores"])}

# グラフ構築
builder = StateGraph(State)

# 並列実行されるノード
builder.add_node("technical", technical_review)
builder.add_node("business", business_review)
builder.add_node("legal", legal_review)
builder.add_node("aggregate", aggregate_scores)

# 並列実行のエッジ
builder.add_edge(START, "technical")
builder.add_edge(START, "business")
builder.add_edge(START, "legal")

# 集約ノードへ
builder.add_edge("technical", "aggregate")
builder.add_edge("business", "aggregate")
builder.add_edge("legal", "aggregate")
builder.add_edge("aggregate", END)

graph = builder.compile()
```

## 重要な概念: Reducer

並列実行の結果を集約するには、**Reducer**が必須です：

```python
from operator import add

class State(TypedDict):
    # 複数のノードからの結果を追加で集約
    results: Annotated[list, add]

    # 最大値を保持
    max_score: Annotated[int, max]

    # カスタムReducer
    combined: Annotated[dict, combine_dicts]
```

## 利点

✅ **高速化**: タスクが並列実行されるため時間短縮
✅ **信頼性**: 複数の結果を比較して検証
✅ **スケーラビリティ**: タスク数に応じて並列度を調整
✅ **ロバスト性**: 一部が失敗しても他が成功すれば継続可能

## 注意点

⚠️ **Reducerが必要**: 結果の集約方法を明示的に定義
⚠️ **リソース消費**: 並列実行によるメモリ・API呼び出しの増加
⚠️ **順序不定**: 実行順序が保証されない
⚠️ **デバッグの複雑さ**: 並列実行のトラブルシューティングが難しい

## 応用パターン

### パターン1: Fan-out / Fan-in

```python
# Fan-out: 1つのノードから複数へ
builder.add_edge("router", "task_a")
builder.add_edge("router", "task_b")
builder.add_edge("router", "task_c")

# Fan-in: 複数から1つへ集約
builder.add_edge("task_a", "aggregator")
builder.add_edge("task_b", "aggregator")
builder.add_edge("task_c", "aggregator")
```

### パターン2: バランシング（defer=True）

長さの異なるブランチを待機：

```python
from operator import add

def add_with_defer(left: list, right: list) -> list:
    return left + right

class State(TypedDict):
    results: Annotated[list, add_with_defer]

# コンパイル時にdefer=Trueを指定
graph = builder.compile(
    checkpointer=checkpointer,
    # 全てのブランチが完了するまで待機
)
```

### パターン3: 冗長性による信頼性

```python
def provider_a(state: State):
    """プロバイダーA"""
    return {"responses": [call_api_a(state["query"])]}

def provider_b(state: State):
    """プロバイダーB（バックアップ）"""
    return {"responses": [call_api_b(state["query"])]}

def provider_c(state: State):
    """プロバイダーC（バックアップ）"""
    return {"responses": [call_api_c(state["query"])]}

def select_best(state: State):
    """最良の応答を選択"""
    responses = state["responses"]
    best = max(responses, key=lambda r: r.confidence)
    return {"result": best}
```

## vs 他のパターン

| パターン | Parallelization | Prompt Chaining |
|---------|----------------|-----------------|
| 実行順序 | 並列 | 順次 |
| 依存関係 | なし | あり |
| 実行時間 | 短い | 長い |
| 結果の集約 | Reducer必須 | 不要 |

## まとめ

Parallelizationは**独立したタスクの同時実行**に最適です。Reducerを使って結果を適切に集約することが重要です。

## 関連ページ

- [04_OrchestratorWorker.md](04_OrchestratorWorker.md) - 動的な並列処理
- [05_応用機能/MapReduce.md](../05_応用機能/MapReduce.md) - Map-Reduceパターン
- [01_基本概念/State.md](../01_基本概念/State.md) - Reducerの詳細
