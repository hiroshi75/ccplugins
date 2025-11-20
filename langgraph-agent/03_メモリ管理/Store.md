# Store（長期記憶）

複数スレッド間で情報を共有する長期記憶。

## 概要

Checkpointerは単一スレッド内の状態のみを保存します。複数スレッド間で情報を共有するには**Store**を使用します。

## Checkpointer vs Store

| 機能 | Checkpointer | Store |
|------|-------------|-------|
| スコープ | 単一スレッド | 全スレッド |
| 用途 | 会話状態 | ユーザー情報 |
| 自動保存 | Yes | No（手動） |
| 検索 | thread_id | 名前空間 |

## 基本的な使用

```python
from langgraph.store.memory import InMemoryStore

# Storeの作成
store = InMemoryStore()

# ユーザー情報を保存
store.put(
    namespace=("users", "user-123"),
    key="preferences",
    value={
        "language": "ja",
        "theme": "dark",
        "notifications": True
    }
)

# ユーザー情報を取得
user_prefs = store.get(("users", "user-123"), "preferences")
```

## 名前空間（Namespace）

名前空間は**タプル**でグループ化：

```python
# ユーザー情報
("users", user_id)

# セッション情報
("sessions", session_id)

# プロジェクト情報
("projects", project_id, "documents")

# 階層的な構造
("organization", org_id, "department", dept_id)
```

## Storeの操作

### 保存

```python
store.put(
    namespace=("users", "alice"),
    key="profile",
    value={
        "name": "Alice",
        "email": "alice@example.com",
        "joined": "2024-01-01"
    }
)
```

### 取得

```python
# 単一アイテム
profile = store.get(("users", "alice"), "profile")

# 名前空間内の全アイテム
items = store.search(("users", "alice"))
```

### 検索

```python
# 名前空間でフィルタ
all_users = store.search(("users",))

# キーでフィルタ
profiles = store.search(("users",), filter={"key": "profile"})
```

### 削除

```python
# 単一アイテム
store.delete(("users", "alice"), "profile")

# 名前空間全体
store.delete_namespace(("users", "alice"))
```

## グラフとの統合

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()

# Storeをグラフに統合
graph = builder.compile(
    checkpointer=checkpointer,
    store=store
)

# ノード内でStoreを使用
def personalized_node(state: State, *, store):
    user_id = state["user_id"]

    # ユーザー設定を取得
    prefs = store.get(("users", user_id), "preferences")

    # 設定に基づいて処理
    if prefs and prefs.value.get("language") == "ja":
        response = generate_japanese_response(state)
    else:
        response = generate_english_response(state)

    return {"response": response}
```

## セマンティック検索

ベクトル検索機能を持つStore実装：

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore(index={"embed": True})

# ドキュメントを保存（自動的にベクトル化）
store.put(
    ("documents", "doc-1"),
    "content",
    {"text": "LangGraphはエージェントフレームワークです"}
)

# セマンティック検索
results = store.search(
    ("documents",),
    query="エージェント開発"
)
```

## 実践例: ユーザープロファイル

```python
class ProfileState(TypedDict):
    user_id: str
    messages: Annotated[list, add_messages]

def save_user_info(state: ProfileState, *, store):
    """会話からユーザー情報を抽出して保存"""
    messages = state["messages"]
    user_id = state["user_id"]

    # LLMで情報抽出
    info = extract_user_info(messages)

    if info:
        # Storeに保存
        current = store.get(("users", user_id), "profile")

        if current:
            # 既存情報と統合
            updated = {**current.value, **info}
        else:
            updated = info

        store.put(
            ("users", user_id),
            "profile",
            updated
        )

    return {}

def personalized_response(state: ProfileState, *, store):
    """ユーザー情報を使って個別化"""
    user_id = state["user_id"]

    # ユーザー情報を取得
    profile = store.get(("users", user_id), "profile")

    if profile:
        context = f"User context: {profile.value}"
        messages = [
            {"role": "system", "content": context},
            *state["messages"]
        ]
    else:
        messages = state["messages"]

    response = llm.invoke(messages)
    return {"messages": [response]}
```

## 実践例: 知識ベース

```python
def query_knowledge_base(state: State, *, store):
    """質問に関連する知識を検索"""
    query = state["messages"][-1].content

    # セマンティック検索
    relevant_docs = store.search(
        ("knowledge",),
        query=query,
        limit=3
    )

    # 関連情報をコンテキストに追加
    context = "\n".join([
        doc.value["text"]
        for doc in relevant_docs
    ])

    # LLMに渡す
    response = llm.invoke([
        {"role": "system", "content": f"Context:\n{context}"},
        *state["messages"]
    ])

    return {"messages": [response]}
```

## Store実装

### InMemoryStore

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()
```

### カスタムStore

```python
from langgraph.store.base import BaseStore

class RedisStore(BaseStore):
    def __init__(self, redis_client):
        self.redis = redis_client

    def put(self, namespace, key, value):
        ns_key = f"{':'.join(namespace)}:{key}"
        self.redis.set(ns_key, json.dumps(value))

    def get(self, namespace, key):
        ns_key = f"{':'.join(namespace)}:{key}"
        data = self.redis.get(ns_key)
        return json.loads(data) if data else None

    def search(self, namespace, filter=None):
        pattern = f"{':'.join(namespace)}:*"
        keys = self.redis.keys(pattern)
        return [self.get_by_key(k) for k in keys]
```

## ベストプラクティス

1. **名前空間の設計**: 階層的で意味のある構造
2. **キーの命名**: 明確で一貫性のある命名規則
3. **データサイズ**: 大きなデータは参照のみ保存
4. **クリーンアップ**: 古いデータの定期削除

## まとめ

Storeは複数スレッド間で情報を共有する長期記憶です。ユーザープロファイル、知識ベース、設定などの永続化に使用します。

## 関連ページ

- [Checkpointer.md](Checkpointer.md) - 短期記憶との違い
- [Persistence.md](Persistence.md) - 永続化の基本
