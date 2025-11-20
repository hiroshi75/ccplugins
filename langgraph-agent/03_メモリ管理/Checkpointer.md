# Checkpointer（チェックポインター）

状態を保存・復元する実装の詳細。

## 概要

Checkpointerは`BaseCheckpointSaver`インターフェースを実装し、状態の永続化を担当します。

## チェックポインター実装

### 1. MemorySaver（実験・テスト用）

メモリ内にチェックポイントを保存：

```python
from langgraph.checkpoint.memory import MemorySaver

checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)

# プロセスが終了すると全て失われる
```

**用途**: ローカルテスト、プロトタイピング

### 2. SqliteSaver（ローカル開発用）

SQLiteデータベースに保存：

```python
from langgraph.checkpoint.sqlite import SqliteSaver

# ファイルベース
checkpointer = SqliteSaver.from_conn_string("checkpoints.db")

# または接続オブジェクトから
import sqlite3
conn = sqlite3.connect("checkpoints.db")
checkpointer = SqliteSaver(conn)

graph = builder.compile(checkpointer=checkpointer)
```

**用途**: ローカル開発、シングルユーザーアプリ

### 3. PostgresSaver（本番環境用）

PostgreSQLデータベースに保存：

```python
from langgraph.checkpoint.postgres import PostgresSaver
from psycopg_pool import ConnectionPool

# 接続プール
pool = ConnectionPool(
    conninfo="postgresql://user:password@localhost:5432/db"
)

checkpointer = PostgresSaver(pool)
graph = builder.compile(checkpointer=checkpointer)
```

**用途**: 本番環境、マルチユーザーアプリ

## BaseCheckpointSaverインターフェース

全てのチェックポインターは以下のメソッドを実装：

```python
class BaseCheckpointSaver:
    def put(
        self,
        config: RunnableConfig,
        checkpoint: Checkpoint,
        metadata: dict
    ) -> RunnableConfig:
        """チェックポイントを保存"""

    def get_tuple(
        self,
        config: RunnableConfig
    ) -> CheckpointTuple | None:
        """チェックポイントを取得"""

    def list(
        self,
        config: RunnableConfig,
        *,
        before: RunnableConfig | None = None,
        limit: int | None = None
    ) -> Iterator[CheckpointTuple]:
        """チェックポイント一覧を取得"""
```

## カスタムチェックポインター

独自の永続化ロジックを実装：

```python
from langgraph.checkpoint.base import BaseCheckpointSaver

class RedisCheckpointer(BaseCheckpointSaver):
    def __init__(self, redis_client):
        self.redis = redis_client

    def put(self, config, checkpoint, metadata):
        thread_id = config["configurable"]["thread_id"]
        checkpoint_id = checkpoint["id"]

        key = f"checkpoint:{thread_id}:{checkpoint_id}"
        self.redis.set(key, serialize(checkpoint))

        return config

    def get_tuple(self, config):
        thread_id = config["configurable"]["thread_id"]
        # 最新のチェックポイントを取得
        # ...

    def list(self, config, before=None, limit=None):
        # チェックポイント一覧を返す
        # ...
```

## チェックポインター設定

### ネームスペース

複数のグラフで同じチェックポインターを共有：

```python
checkpointer = MemorySaver()

graph1 = builder1.compile(
    checkpointer=checkpointer,
    name="graph1"  # ネームスペース
)

graph2 = builder2.compile(
    checkpointer=checkpointer,
    name="graph2"  # 別のネームスペース
)
```

### 自動伝播

親グラフのチェックポインターはサブグラフに自動伝播：

```python
# 親グラフのみに設定
parent_graph = parent_builder.compile(checkpointer=checkpointer)

# 子グラフにも自動的に伝播
```

## チェックポイントの管理

### 古いチェックポイントの削除

```python
# 一定期間後に削除（実装依存）
import datetime

cutoff = datetime.datetime.now() - datetime.timedelta(days=30)

# 実装例（SQLite）
checkpointer.conn.execute(
    "DELETE FROM checkpoints WHERE created_at < ?",
    (cutoff,)
)
```

### チェックポイントサイズの最適化

```python
class State(TypedDict):
    # 大きなデータは避ける
    messages: Annotated[list, add_messages]

    # 参照のみ保存
    large_data_id: str  # 実データは別ストレージ

def node(state: State):
    # 大きなデータは外部から取得
    large_data = fetch_from_storage(state["large_data_id"])
    # ...
```

## パフォーマンス考慮

### 接続プール（PostgreSQL）

```python
from psycopg_pool import ConnectionPool

pool = ConnectionPool(
    conninfo=conn_string,
    min_size=5,
    max_size=20
)

checkpointer = PostgresSaver(pool)
```

### 非同期チェックポインター

```python
from langgraph.checkpoint.postgres import AsyncPostgresSaver

async_checkpointer = AsyncPostgresSaver(async_pool)

# 非同期実行
async for chunk in graph.astream(input, config):
    print(chunk)
```

## まとめ

Checkpointerは状態の永続化方法を決定します。用途に応じた実装を選択することが重要です。

## 関連ページ

- [Persistence.md](Persistence.md) - 永続化の使い方
- [Store.md](Store.md) - 長期記憶との違い
