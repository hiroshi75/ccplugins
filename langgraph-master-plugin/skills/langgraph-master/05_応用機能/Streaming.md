# Streaming（ストリーミング）

リアルタイムでグラフ実行の進捗を監視する機能。

## 概要

Streamingは、グラフ実行中に**リアルタイムで更新**を受け取る機能です。LLMトークン、状態変更、カスタムイベントなどをストリーミングできます。

## stream_modeの種類

### 1. values（状態の完全なスナップショット）

各ステップ後の完全な状態：

```python
for chunk in graph.stream(input, stream_mode="values"):
    print(chunk)

# 出力例
# {"messages": [{"role": "user", "content": "Hello"}]}
# {"messages": [{"role": "user", "content": "Hello"}, {"role": "assistant", "content": "Hi!"}]}
```

### 2. updates（状態の変更のみ）

各ステップでの変更のみ：

```python
for chunk in graph.stream(input, stream_mode="updates"):
    print(chunk)

# 出力例
# {"messages": [{"role": "assistant", "content": "Hi!"}]}
```

### 3. messages（LLMトークン）

LLMのトークン単位でストリーミング：

```python
for msg, metadata in graph.stream(input, stream_mode="messages"):
    if msg.content:
        print(msg.content, end="", flush=True)

# 出力: "H" "i" "!" "␣" "H" "o" "w" ...（トークンごと）
```

### 4. debug（デバッグ情報）

グラフ実行の詳細情報：

```python
for chunk in graph.stream(input, stream_mode="debug"):
    print(chunk)

# ノード実行、エッジ遷移などの詳細
```

### 5. custom（カスタムデータ）

ノードから独自データを送信：

```python
from langgraph.config import get_stream_writer

def my_node(state: State):
    writer = get_stream_writer()

    for i in range(10):
        writer({"progress": i * 10})  # カスタムデータ

    return {"result": "done"}

for mode, chunk in graph.stream(input, stream_mode=["updates", "custom"]):
    if mode == "custom":
        print(f"Progress: {chunk['progress']}%")
```

## LLMトークンのストリーミング

### 特定のノードのみストリーミング

```python
for msg, metadata in graph.stream(input, stream_mode="messages"):
    # 特定のノードからのトークンのみ表示
    if metadata["langgraph_node"] == "chatbot":
        if msg.content:
            print(msg.content, end="", flush=True)

print()  # 改行
```

### タグでフィルタリング

```python
# LLMにタグを設定
llm = init_chat_model("gpt-4", tags=["main_llm"])

for msg, metadata in graph.stream(input, stream_mode="messages"):
    if "main_llm" in metadata.get("tags", []):
        if msg.content:
            print(msg.content, end="", flush=True)
```

## 複数モードの同時使用

```python
for mode, chunk in graph.stream(input, stream_mode=["values", "messages"]):
    if mode == "values":
        print(f"\nState: {chunk}")
    elif mode == "messages":
        if chunk[0].content:
            print(chunk[0].content, end="", flush=True)
```

## サブグラフのストリーミング

```python
# サブグラフの出力も含める
for chunk in graph.stream(
    input,
    stream_mode="updates",
    subgraphs=True  # サブグラフも含める
):
    print(chunk)
```

## 実践例: プログレスバー

```python
from tqdm import tqdm

def process_with_progress(items: list):
    """プログレスバー付き処理"""
    total = len(items)

    with tqdm(total=total) as pbar:
        for chunk in graph.stream(
            {"items": items},
            stream_mode="custom"
        ):
            if "progress" in chunk:
                pbar.update(1)

    return "Complete!"
```

## 実践例: リアルタイムUI更新

```python
import streamlit as st

def run_with_ui_updates(user_input: str):
    """Streamlit UIをリアルタイム更新"""
    status = st.empty()
    output = st.empty()

    full_response = ""

    for msg, metadata in graph.stream(
        {"messages": [{"role": "user", "content": user_input}]},
        stream_mode="messages"
    ):
        if msg.content:
            full_response += msg.content
            output.markdown(full_response + "▌")

        status.text(f"Node: {metadata['langgraph_node']}")

    output.markdown(full_response)
    status.text("Complete!")
```

## 非同期ストリーミング

```python
async def async_stream_example():
    """非同期ストリーミング"""
    async for chunk in graph.astream(input, stream_mode="updates"):
        print(chunk)
        await asyncio.sleep(0)  # 他のタスクに譲る
```

## カスタムイベントの送信

```python
from langgraph.config import get_stream_writer

def multi_step_node(state: State):
    """複数ステップの進捗を報告"""
    writer = get_stream_writer()

    # ステップ1
    writer({"status": "Analyzing..."})
    analysis = analyze_data(state["data"])

    # ステップ2
    writer({"status": "Processing..."})
    result = process_analysis(analysis)

    # ステップ3
    writer({"status": "Finalizing..."})
    final = finalize(result)

    return {"result": final}

# 受信
for mode, chunk in graph.stream(input, stream_mode=["updates", "custom"]):
    if mode == "custom":
        print(chunk["status"])
```

## まとめ

Streamingはリアルタイムで進捗を監視し、ユーザー体験を向上させます。用途に応じて適切なstream_modeを選択します。

## 関連ページ

- [02_グラフアーキテクチャ/06_Agent.md](../02_グラフアーキテクチャ/06_Agent.md) - エージェントのストリーミング
- [HumanInTheLoop.md](HumanInTheLoop.md) - ストリーミングと承認の組み合わせ
