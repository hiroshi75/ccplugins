# 03. メモリ管理

永続化とチェックポイント機能による状態管理。

## 概要

LangGraphの**組み込み永続化レイヤー**により、エージェントの状態を保存・復元できます。これにより、会話の継続、エラーからの復旧、タイムトラベルが可能になります。

## メモリの種類

### 短期記憶: [Checkpointer（チェックポインター）](Checkpointer.md)
- 各スーパーステップで状態を自動保存
- スレッドベースの会話管理
- タイムトラベル機能

### 長期記憶: [Store（ストア）](Store.md)
- 複数スレッド間で情報共有
- ユーザー情報の永続化
- セマンティック検索

## 主要機能

### 1. [Persistence（永続化）](Persistence.md)

**チェックポイント**: 各スーパーステップで状態を保存
- グラフ実行の各段階で状態をスナップショット
- 失敗時に復旧可能
- 実行履歴の追跡

**スレッド**: 会話の単位
- `thread_id`で会話を識別
- 各スレッドは独立した状態を保持
- 複数の会話を並行管理

**StateSnapshot**: チェックポイントの表現
- `values`: その時点の状態
- `next`: 次に実行するノード
- `config`: チェックポイント設定
- `metadata`: メタデータ

### 2. Human-in-the-Loop

**状態の検査**: 任意の時点で状態を確認
```python
state = graph.get_state(config)
print(state.values)
```

**承認フロー**: 重要な操作前に人間の承認
```python
# グラフを一時停止して承認を待つ
```

### 3. Memory（記憶）

**会話記憶**: スレッド内での記憶
```python
# 同じthread_idで呼び出すと会話が継続
config = {"configurable": {"thread_id": "conversation-1"}}
graph.invoke(input, config)
```

**長期記憶**: スレッドを超えた記憶
```python
# Storeでユーザー情報を保存
store.put(("user", user_id), "preferences", user_prefs)
```

### 4. Time Travel（タイムトラベル）

過去の実行を再生・フォーク：
```python
# 特定のチェックポイントから再開
history = graph.get_state_history(config)
for state in history:
    print(f"Checkpoint: {state.config['configurable']['checkpoint_id']}")

# 過去のチェックポイントから再実行
graph.invoke(input, past_checkpoint_config)
```

## チェックポインター実装

LangGraphは複数のチェックポインター実装を提供：

### InMemorySaver（実験用）
```python
from langgraph.checkpoint.memory import MemorySaver

checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)
```

### SqliteSaver（ローカル開発用）
```python
from langgraph.checkpoint.sqlite import SqliteSaver

checkpointer = SqliteSaver.from_conn_string("checkpoints.db")
graph = builder.compile(checkpointer=checkpointer)
```

### PostgresSaver（本番環境用）
```python
from langgraph.checkpoint.postgres import PostgresSaver

checkpointer = PostgresSaver.from_conn_string(
    "postgresql://user:pass@localhost/db"
)
graph = builder.compile(checkpointer=checkpointer)
```

## 基本的な使用例

```python
from langgraph.checkpoint.memory import MemorySaver

# チェックポインター付きでコンパイル
checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)

# thread_idを指定して実行
config = {"configurable": {"thread_id": "user-123"}}

# 初回実行
result1 = graph.invoke({"messages": [("user", "Hello")]}, config)

# 同じスレッドで継続
result2 = graph.invoke({"messages": [("user", "How are you?")]}, config)

# 状態を確認
state = graph.get_state(config)
print(state.values)  # これまでの全メッセージ

# 履歴を確認
for state in graph.get_state_history(config):
    print(f"Step: {state.values}")
```

## 重要な原則

1. **スレッドID管理**: 会話ごとに一意のthread_idを使用
2. **チェックポインター選択**: 用途に応じた適切な実装を選択
3. **状態の最小化**: チェックポイントサイズを抑えるため、必要な情報のみ保存
4. **クリーンアップ**: 古いチェックポイントの定期的な削除

## 次のステップ

各機能の詳細については、以下のページを参照してください：

- [Persistence.md](Persistence.md) - 永続化の詳細
- [Checkpointer.md](Checkpointer.md) - チェックポインターの実装
- [Store.md](Store.md) - 長期記憶の管理
