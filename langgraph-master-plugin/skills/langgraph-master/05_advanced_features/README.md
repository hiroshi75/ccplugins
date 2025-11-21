# 05. 応用機能

高度な機能と実装パターン。

## 概要

LangGraphの高度な機能を活用することで、より洗練されたエージェントシステムを構築できます。

## 主要機能

### 1. [Human-in-the-Loop（承認フロー）](HumanInTheLoop.md)

グラフ実行を一時停止して人間の介入を求める：
- 動的インタラプト
- 静的インタラプト
- 承認・編集・却下フロー

### 2. [Streaming（ストリーミング）](Streaming.md)

リアルタイムで進捗を監視：
- LLMトークンのストリーミング
- 状態更新のストリーミング
- カスタムイベントのストリーミング

### 3. [Map-Reduce（並列処理パターン）](MapReduce.md)

大量データの並列処理：
- Send APIによる動的ワーカー生成
- Reducerによる結果集約
- 階層的な並列処理

## 機能比較

| 機能 | 用途 | 実装の複雑さ |
|------|------|-------------|
| Human-in-the-Loop | 承認フロー、品質管理 | 中 |
| Streaming | リアルタイム監視、UX向上 | 低 |
| Map-Reduce | 大量データ処理 | 高 |

## 組み合わせパターン

### Human-in-the-Loop + Streaming

```python
# ストリーミングしながら承認を求める
for chunk in graph.stream(input, config, stream_mode="values"):
    print(chunk)

    # インタラプトで一時停止
    if chunk.get("__interrupt__"):
        approval = input("Approve? (y/n): ")
        graph.invoke(None, config, resume=approval == "y")
```

### Map-Reduce + Streaming

```python
# 並列処理の進捗をストリーミング
for chunk in graph.stream(
    {"items": large_dataset},
    stream_mode="updates",
    subgraphs=True  # ワーカーの進捗も表示
):
    print(f"Progress: {chunk}")
```

## 次のステップ

各機能の詳細については、以下のページを参照してください：

- [HumanInTheLoop.md](HumanInTheLoop.md) - 承認フローの実装
- [Streaming.md](Streaming.md) - ストリーミングの使い方
- [MapReduce.md](MapReduce.md) - Map-Reduceパターン
