# Subgraph（サブグラフ）

階層的なグラフ構造を構築し、複雑なシステムをモジュール化するパターン。

## 概要

Subgraphは、**グラフをノードとして別のグラフに組み込む**ことで、複雑なシステムを階層的に整理するパターンです。

## 適用場面

- 大規模なエージェントシステムのモジュール化
- 複数の専門エージェントの統合
- 再利用可能なワークフローコンポーネント
- マルチレベルの階層構造

## 2つの実装アプローチ

### アプローチ1: グラフをノードとして追加

**状態キーを共有**する場合に使用します。

```python
# サブグラフの定義
class SubState(TypedDict):
    messages: Annotated[list, add_messages]
    sub_result: str

def sub_node_a(state: SubState):
    return {"messages": [{"role": "assistant", "content": "Sub A"}]}

def sub_node_b(state: SubState):
    return {"sub_result": "Sub B completed"}

# サブグラフを構築
sub_builder = StateGraph(SubState)
sub_builder.add_node("sub_a", sub_node_a)
sub_builder.add_node("sub_b", sub_node_b)
sub_builder.add_edge(START, "sub_a")
sub_builder.add_edge("sub_a", "sub_b")
sub_builder.add_edge("sub_b", END)

sub_graph = sub_builder.compile()

# 親グラフでサブグラフをノードとして使用
class ParentState(TypedDict):
    messages: Annotated[list, add_messages]  # 共有キー
    sub_result: str  # 共有キー
    parent_data: str

parent_builder = StateGraph(ParentState)

# サブグラフを直接ノードとして追加
parent_builder.add_node("subgraph", sub_graph)

parent_builder.add_edge(START, "subgraph")
parent_builder.add_edge("subgraph", END)

parent_graph = parent_builder.compile()
```

### アプローチ2: ノード内からグラフを呼び出し

**異なる状態スキーマ**を持つ場合に使用します。

```python
# サブグラフ（独自の状態）
class SubGraphState(TypedDict):
    input_text: str
    output_text: str

def process_node(state: SubGraphState):
    return {"output_text": process(state["input_text"])}

sub_builder = StateGraph(SubGraphState)
sub_builder.add_node("process", process_node)
sub_builder.add_edge(START, "process")
sub_builder.add_edge("process", END)

sub_graph = sub_builder.compile()

# 親グラフ（異なる状態）
class ParentState(TypedDict):
    user_query: str
    result: str

def invoke_subgraph_node(state: ParentState):
    """ノード内でサブグラフを呼び出し"""
    # 親の状態をサブグラフの状態に変換
    sub_input = {"input_text": state["user_query"]}

    # サブグラフを実行
    sub_output = sub_graph.invoke(sub_input)

    # サブグラフの出力を親の状態に変換
    return {"result": sub_output["output_text"]}

parent_builder = StateGraph(ParentState)
parent_builder.add_node("call_subgraph", invoke_subgraph_node)
parent_builder.add_edge(START, "call_subgraph")
parent_builder.add_edge("call_subgraph", END)

parent_graph = parent_builder.compile()
```

## 多階層のサブグラフ

複数レベルのサブグラフ（親 → 子 → 孫）も実装可能です：

```python
# 孫グラフ
class GrandchildState(TypedDict):
    data: str

grandchild_builder = StateGraph(GrandchildState)
grandchild_builder.add_node("process", lambda s: {"data": f"Processed: {s['data']}"})
grandchild_builder.add_edge(START, "process")
grandchild_builder.add_edge("process", END)
grandchild_graph = grandchild_builder.compile()

# 子グラフ（孫グラフを含む）
class ChildState(TypedDict):
    data: str

child_builder = StateGraph(ChildState)
child_builder.add_node("grandchild", grandchild_graph)  # 孫グラフを追加
child_builder.add_edge(START, "grandchild")
child_builder.add_edge("grandchild", END)
child_graph = child_builder.compile()

# 親グラフ（子グラフを含む）
class ParentState(TypedDict):
    data: str

parent_builder = StateGraph(ParentState)
parent_builder.add_node("child", child_graph)  # 子グラフを追加
parent_builder.add_edge(START, "child")
parent_builder.add_edge("child", END)
parent_graph = parent_builder.compile()
```

## サブグラフ間のナビゲーション

サブグラフから親グラフの別のノードへ遷移：

```python
from langgraph.types import Command

def sub_node_with_navigation(state: SubState):
    """サブグラフのノードから親グラフへナビゲート"""
    result = process(state["data"])

    if need_parent_intervention(result):
        # 親グラフの別のノードへ遷移
        return Command(
            update={"result": result},
            goto="parent_handler",
            graph=Command.PARENT
        )

    return {"result": result}
```

## 永続化とデバッグ

### チェックポインターの自動伝播

```python
from langgraph.checkpoint.memory import MemorySaver

# 親グラフのみにチェックポインターを設定
checkpointer = MemorySaver()

parent_graph = parent_builder.compile(
    checkpointer=checkpointer  # 子グラフに自動伝播
)
```

### サブグラフの出力を含めたストリーミング

```python
# サブグラフの詳細も含めてストリーミング
for chunk in parent_graph.stream(
    inputs,
    stream_mode="values",
    subgraphs=True  # サブグラフの出力も含める
):
    print(chunk)
```

## 実践例: マルチエージェントシステム

```python
# 研究エージェント（サブグラフ）
class ResearchState(TypedDict):
    messages: Annotated[list, add_messages]
    research_result: str

research_builder = StateGraph(ResearchState)
research_builder.add_node("search", search_node)
research_builder.add_node("analyze", analyze_node)
research_builder.add_edge(START, "search")
research_builder.add_edge("search", "analyze")
research_builder.add_edge("analyze", END)
research_graph = research_builder.compile()

# コーディングエージェント（サブグラフ）
class CodingState(TypedDict):
    messages: Annotated[list, add_messages]
    code: str

coding_builder = StateGraph(CodingState)
coding_builder.add_node("generate", generate_code_node)
coding_builder.add_node("test", test_code_node)
coding_builder.add_edge(START, "generate")
coding_builder.add_edge("generate", "test")
coding_builder.add_edge("test", END)
coding_graph = coding_builder.compile()

# 統合システム（親グラフ）
class SystemState(TypedDict):
    messages: Annotated[list, add_messages]
    research_result: str
    code: str
    task_type: str

def router(state: SystemState):
    if "研究" in state["messages"][-1].content:
        return "research"
    return "coding"

system_builder = StateGraph(SystemState)

# サブグラフを追加
system_builder.add_node("research_agent", research_graph)
system_builder.add_node("coding_agent", coding_graph)

# ルーティング
system_builder.add_conditional_edges(
    START,
    router,
    {
        "research": "research_agent",
        "coding": "coding_agent"
    }
)

system_builder.add_edge("research_agent", END)
system_builder.add_edge("coding_agent", END)

system_graph = system_builder.compile()
```

## 利点

✅ **モジュール化**: 複雑なシステムを小さな部分に分割
✅ **再利用性**: サブグラフを複数の親グラフで使用
✅ **保守性**: 各サブグラフを独立して改善
✅ **テスト容易性**: サブグラフを個別にテスト

## 注意点

⚠️ **状態の共有**: どのキーを共有するか慎重に設計
⚠️ **デバッグの複雑さ**: 階層が深いと追跡が困難
⚠️ **パフォーマンス**: 多階層だとオーバーヘッドが増加
⚠️ **循環参照**: サブグラフ間の循環依存に注意

## ベストプラクティス

1. **浅い階層**: 可能な限り階層を浅く保つ（2-3レベル）
2. **明確な責任**: 各サブグラフの役割を明確に定義
3. **状態の最小化**: 共有する状態キーを必要最小限に
4. **独立性**: サブグラフはできるだけ独立して動作するように

## まとめ

Subgraphは**複雑なシステムの階層的な整理**に最適です。状態の共有方法に応じて2つのアプローチを使い分けます。

## 関連ページ

- [06_Agent.md](06_Agent.md) - マルチエージェントとの組み合わせ
- [01_基本概念/State.md](../01_基本概念/State.md) - 状態の設計
- [03_メモリ管理/Persistence.md](../03_メモリ管理/Persistence.md) - チェックポインターの伝播
