# Persistence（永続化）

グラフの状態を保存し、復元する機能。

## 概要

Persistenceは、グラフ実行の各段階で状態を**自動的に保存**し、後で復元できるようにする機能です。

## 基本概念

### チェックポイント

各**スーパーステップ**（並列実行されるノードのセット）の後に、状態が自動保存されます。

```python
# スーパーステップ1: node_aとnode_bが並列実行
# → チェックポイント1

# スーパーステップ2: node_c実行
# → チェックポイント2

# スーパーステップ3: node_d実行
# → チェックポイント3
```

### スレッド

スレッドは**一連の実行の累積された状態**を含む識別子です：

```python
config = {"configurable": {"thread_id": "conversation-123"}}
```

同じ`thread_id`で実行すると、前回の状態から継続します。

## 実装例

```python
from langgraph.checkpoint.memory import MemorySaver
from langgraph.graph import StateGraph, MessagesState

# グラフ定義
builder = StateGraph(MessagesState)
builder.add_node("chatbot", chatbot_node)
builder.add_edge(START, "chatbot")
builder.add_edge("chatbot", END)

# チェックポインター付きでコンパイル
checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)

# スレッドIDを指定して実行
config = {"configurable": {"thread_id": "user-001"}}

# 初回実行
graph.invoke(
    {"messages": [{"role": "user", "content": "私の名前はアリスです"}]},
    config
)

# 同じスレッドで継続（前回の状態を保持）
response = graph.invoke(
    {"messages": [{"role": "user", "content": "私の名前は？"}]},
    config
)

# → "あなたの名前はアリスです"
```

## StateSnapshotオブジェクト

チェックポイントは`StateSnapshot`オブジェクトで表現されます：

```python
class StateSnapshot:
    values: dict          # その時点の状態
    next: tuple[str]      # 次に実行するノード
    config: RunnableConfig  # チェックポイント設定
    metadata: dict        # メタデータ
    tasks: tuple[PregelTask]  # 実行予定タスク
```

### 最新状態の取得

```python
state = graph.get_state(config)

print(state.values)      # 現在の状態
print(state.next)        # 次のノード
print(state.config)      # チェックポイント設定
```

### 履歴の取得

```python
# 時系列順にStateSnapshotのリストを取得
for state in graph.get_state_history(config):
    print(f"Checkpoint: {state.config['configurable']['checkpoint_id']}")
    print(f"Values: {state.values}")
    print(f"Next: {state.next}")
    print("---")
```

## タイムトラベル機能

特定のチェックポイントから実行を再開：

```python
# 履歴から特定のチェックポイントを取得
history = list(graph.get_state_history(config))

# 3つ前のチェックポイント
past_state = history[3]

# そのチェックポイントから再実行
result = graph.invoke(
    {"messages": [{"role": "user", "content": "新しい質問"}]},
    past_state.config
)
```

### 代替パスの検証

```python
# 現在の状態を取得
current_state = graph.get_state(config)

# 異なる入力で試す
alt_result = graph.invoke(
    {"messages": [{"role": "user", "content": "別の質問"}]},
    current_state.config
)

# 元の実行には影響しない
```

## 状態の更新

チェックポイントの状態を直接更新：

```python
# 現在の状態を取得
state = graph.get_state(config)

# 状態を更新
graph.update_state(
    config,
    {"messages": [{"role": "assistant", "content": "更新されたメッセージ"}]}
)

# 更新後の状態から再開
graph.invoke({"messages": [...]}, config)
```

## ユースケース

### 1. 会話の継続

```python
# セッション1
config = {"configurable": {"thread_id": "chat-1"}}
graph.invoke({"messages": [("user", "こんにちは")]}, config)

# セッション2（後日）
# 前回の会話を覚えている
graph.invoke({"messages": [("user", "前回の話の続きです")]}, config)
```

### 2. エラーからの復旧

```python
try:
    graph.invoke(input, config)
except Exception as e:
    # エラーが発生しても、チェックポイントから復旧可能
    print(f"Error: {e}")

    # 最新の状態を確認
    state = graph.get_state(config)

    # 状態を修正して再実行
    graph.update_state(config, {"error_fixed": True})
    graph.invoke(input, config)
```

### 3. A/Bテスト

```python
# 基準実行
base_result = graph.invoke(input, base_config)

# 代替実行1
alt_config_1 = base_config.copy()
alt_result_1 = graph.invoke(modified_input_1, alt_config_1)

# 代替実行2
alt_config_2 = base_config.copy()
alt_result_2 = graph.invoke(modified_input_2, alt_config_2)

# 結果を比較
```

### 4. デバッグとトレース

```python
# 実行
graph.invoke(input, config)

# 各ステップを確認
for i, state in enumerate(graph.get_state_history(config)):
    print(f"Step {i}:")
    print(f"  State: {state.values}")
    print(f"  Next: {state.next}")
```

## 重要な注意点

### スレッドIDの一意性

```python
# ユーザーごとに異なるthread_idを使用
user_config = {"configurable": {"thread_id": f"user-{user_id}"}}

# 会話ごとに異なるthread_idを使用
conversation_config = {"configurable": {"thread_id": f"conv-{conv_id}"}}
```

### チェックポイントのクリーンアップ

```python
# 古いチェックポイントを削除（実装依存）
checkpointer.cleanup(before_timestamp=old_timestamp)
```

### マルチユーザー対応

```python
# ユーザーIDとセッションIDを組み合わせ
def get_config(user_id: str, session_id: str):
    return {
        "configurable": {
            "thread_id": f"{user_id}-{session_id}"
        }
    }

config = get_config("user123", "session456")
```

## ベストプラクティス

1. **意味のあるthread_id**: ユーザー、セッション、会話を識別できる形式
2. **定期的なクリーンアップ**: 古いチェックポイントを削除
3. **適切なチェックポインター**: 用途に応じた実装を選択
4. **エラーハンドリング**: チェックポイント取得時のエラーを適切に処理

## まとめ

Persistenceは**状態の永続化と復元**を実現し、会話の継続、エラー復旧、タイムトラベルを可能にします。

## 関連ページ

- [Checkpointer.md](Checkpointer.md) - チェックポインター実装の詳細
- [Store.md](Store.md) - 長期記憶との組み合わせ
- [05_応用機能/HumanInTheLoop.md](../05_応用機能/HumanInTheLoop.md) - 状態検査の応用
