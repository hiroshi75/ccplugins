# Routing（分岐処理）

入力に基づいて専門的なフローへ振り分けるパターン。

## 概要

Routingは、入力の特性に基づいて**適切な処理パスを選択**するパターンです。カスタマーサポートでの質問分類などに使用されます。

## 適用場面

- 顧客の質問タイプ別に専門チームへ振り分け
- ドキュメントの種類別に異なる処理パイプライン
- 緊急度・重要度による優先度付け
- 言語別の処理フロー選択

## 実装例: カスタマーサポート

```python
from typing import Literal, TypedDict

class State(TypedDict):
    query: str
    category: str
    response: str

def router_node(state: State) -> Literal["pricing", "refund", "technical"]:
    """質問を分類してルーティング"""
    query = state["query"]

    # LLMで分類
    category = llm.invoke(
        f"Classify this customer query into: pricing, refund, or technical\n"
        f"Query: {query}\n"
        f"Category:"
    )

    if "価格" in query or "料金" in query:
        return "pricing"
    elif "返金" in query or "キャンセル" in query:
        return "refund"
    else:
        return "technical"

def pricing_node(state: State):
    """料金に関する対応"""
    response = handle_pricing_query(state["query"])
    return {"response": response, "category": "pricing"}

def refund_node(state: State):
    """返金に関する対応"""
    response = handle_refund_query(state["query"])
    return {"response": response, "category": "refund"}

def technical_node(state: State):
    """技術的な問題への対応"""
    response = handle_technical_query(state["query"])
    return {"response": response, "category": "technical"}

# グラフ構築
builder = StateGraph(State)

builder.add_node("router", router_node)
builder.add_node("pricing", pricing_node)
builder.add_node("refund", refund_node)
builder.add_node("technical", technical_node)

# ルーティングエッジ
builder.add_edge(START, "router")
builder.add_conditional_edges(
    "router",
    lambda state: state.get("category", "technical"),
    {
        "pricing": "pricing",
        "refund": "refund",
        "technical": "technical"
    }
)

# 各ノードから終了
builder.add_edge("pricing", END)
builder.add_edge("refund", END)
builder.add_edge("technical", END)

graph = builder.compile()
```

## 応用パターン

### パターン1: 多段階ルーティング

```python
def first_router(state: State) -> Literal["sales", "support"]:
    """第1段階: 営業かサポートか"""
    if "購入" in state["query"] or "見積" in state["query"]:
        return "sales"
    return "support"

def support_router(state: State) -> Literal["billing", "technical"]:
    """第2段階: サポート内での分類"""
    if "請求" in state["query"]:
        return "billing"
    return "technical"

# 多段階ルーティング
builder.add_conditional_edges("first_router", first_router, {...})
builder.add_conditional_edges("support_router", support_router, {...})
```

### パターン2: 優先度ベースルーティング

```python
from typing import Literal

def priority_router(state: State) -> Literal["urgent", "normal", "low"]:
    """緊急度で振り分け"""
    query = state["query"]

    # 緊急キーワード
    if any(word in query for word in ["緊急", "至急", "すぐに"]):
        return "urgent"

    # 重要度判定
    importance = analyze_importance(query)
    if importance > 0.7:
        return "normal"

    return "low"

builder.add_conditional_edges(
    "priority_router",
    priority_router,
    {
        "urgent": "urgent_handler",    # すぐ処理
        "normal": "normal_queue",       # 通常キュー
        "low": "batch_processor"        # バッチ処理
    }
)
```

### パターン3: セマンティックルーティング（埋め込みベース）

```python
import numpy as np
from typing import Literal

def semantic_router(state: State) -> Literal["product", "account", "general"]:
    """埋め込みベースの意味的ルーティング"""
    query_embedding = embed(state["query"])

    # 各カテゴリーの代表的な埋め込み
    categories = {
        "product": embed("製品、機能、使い方"),
        "account": embed("アカウント、ログイン、パスワード"),
        "general": embed("一般的な質問")
    }

    # 最も近いカテゴリーを選択
    similarities = {
        cat: cosine_similarity(query_embedding, emb)
        for cat, emb in categories.items()
    }

    return max(similarities, key=similarities.get)
```

### パターン4: 動的ルーティング（LLM判定）

```python
def llm_router(state: State):
    """LLMに最適なルートを判定させる"""
    routes = ["expert_a", "expert_b", "expert_c", "general"]

    prompt = f"""
    この質問を最も適切に処理できる専門家を選んでください:
    - expert_a: データベースの専門家
    - expert_b: APIの専門家
    - expert_c: UIの専門家
    - general: 一般的な質問

    質問: {state['query']}

    選択: """

    route = llm.invoke(prompt).strip()
    return route if route in routes else "general"

builder.add_conditional_edges(
    "router",
    llm_router,
    {
        "expert_a": "database_expert",
        "expert_b": "api_expert",
        "expert_c": "ui_expert",
        "general": "general_handler"
    }
)
```

## 利点

✅ **専門化**: 各タイプに特化した処理が可能
✅ **効率化**: 不要な処理をスキップ
✅ **保守性**: 各ルートを独立して改善
✅ **スケーラビリティ**: 新しいルートを簡単に追加

## 注意点

⚠️ **分類精度**: ルーティングの誤りが全体に影響
⚠️ **カバレッジ**: すべてのケースをカバーする必要
⚠️ **フォールバック**: 不明なケースの処理が重要
⚠️ **バランス**: ルート間の負荷分散を考慮

## ベストプラクティス

### 1. フォールバックルートを用意

```python
def safe_router(state: State):
    try:
        route = determine_route(state)
        if route in valid_routes:
            return route
    except Exception:
        pass

    # フォールバック
    return "general_handler"
```

### 2. ルーティング理由をログに記録

```python
def logged_router(state: State):
    route = determine_route(state)

    return {
        "route": route,
        "routing_reason": f"Routed to {route} because..."
    }
```

### 3. 動的なルート追加

```python
# 設定ファイルからルートを読み込み
ROUTES = load_routes_config()

builder.add_conditional_edges(
    "router",
    determine_route,
    {route: handler for route, handler in ROUTES.items()}
)
```

## まとめ

Routingは**入力の特性に基づく適切な処理選択**に最適です。分類精度とフォールバック処理が成功の鍵です。

## 関連ページ

- [06_Agent.md](06_Agent.md) - Agentとの組み合わせ
- [01_基本概念/Edge.md](../01_基本概念/Edge.md) - 条件付きエッジの詳細
- [Workflow_vs_Agent.md](Workflow_vs_Agent.md) - パターンの使い分け
