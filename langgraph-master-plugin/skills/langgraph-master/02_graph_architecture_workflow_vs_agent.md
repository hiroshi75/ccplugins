# Workflow vs Agent

WorkflowとAgentの違いと使い分け。

## 基本的な違い

### Workflow（ワークフロー）
> "predetermined code paths and are designed to operate in a certain order"
> （事前決定されたコードパス、特定の順序で動作）

- **事前定義**: 処理フローが明確
- **予測可能**: 同じ入力に対して同じパスを辿る
- **制御された実行**: 開発者が制御フローを完全に管理

### Agent（エージェント）
> "dynamic and define their own processes and tool usage"
> （動的で自身のプロセスとツール使用を定義）

- **動的**: LLMが次の行動を決定
- **自律的**: ツール選択を自己判断
- **不確定**: 同じ入力でも異なるパスを辿る可能性

## 実装例の比較

### Workflow例: 翻訳パイプライン

```python
def translate_node(state: State):
    return {"text": translate(state["text"])}

def summarize_node(state: State):
    return {"summary": summarize(state["text"])}

def validate_node(state: State):
    return {"valid": check_quality(state["summary"])}

# 固定されたフロー
builder.add_edge(START, "translate")
builder.add_edge("translate", "summarize")
builder.add_edge("summarize", "validate")
builder.add_edge("validate", END)
```

### Agent例: 問題解決エージェント

```python
def agent_node(state: State):
    # LLMがツール使用を決定
    response = llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

def should_continue(state: State):
    last_message = state["messages"][-1]
    # ツール呼び出しがあれば継続
    if last_message.tool_calls:
        return "continue"
    return "end"

# LLMが動的に決定
builder.add_conditional_edges(
    "agent",
    should_continue,
    {"continue": "tools", "end": END}
)
```

## 使い分けの基準

### Workflowを選択する場合

✅ **構造が明確**
- 処理ステップが事前にわかっている
- 実行順序が固定されている

✅ **予測可能性が重要**
- コンプライアンス要件がある
- デバッグが容易である必要がある

✅ **コスト効率**
- LLM呼び出しを最小限にしたい
- トークン消費を抑えたい

**例**: データ処理パイプライン、承認ワークフロー、翻訳チェーン

### Agentを選択する場合

✅ **問題が不確定**
- どのツールが必要かわからない
- ステップ数が可変

✅ **柔軟性が必要**
- 状況に応じて異なるアプローチ
- ユーザーの質問が多様

✅ **自律性が価値**
- LLMの判断力を活かしたい
- ReAct（推論+行動）パターンが適している

**例**: カスタマーサポート、研究アシスタント、複雑な問題解決

## ハイブリッドアプローチ

多くの実用的なシステムは、両方を組み合わせます：

```python
# Workflowの中にAgentを埋め込む
builder.add_edge(START, "input_validation")  # Workflow
builder.add_edge("input_validation", "agent")  # Agent部分
builder.add_conditional_edges("agent", should_continue, {...})
builder.add_edge("tools", "agent")
builder.add_conditional_edges("agent", ..., {"end": "output_formatting"})
builder.add_edge("output_formatting", END)  # Workflow
```

## ReActパターン（Agentの基本）

Agentは**ReAct**（Reasoning + Acting）パターンに従います：

1. **Reasoning**: 「次に何をすべきか？」を考える
2. **Acting**: ツールを使って行動する
3. **Observing**: 結果を観察する
4. 繰り返し、最終回答を出すまで継続

```python
# ReActループの実装
def agent(state):
    # Reasoning: 次の行動を決定
    response = llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

def tools(state):
    # Acting: ツールを実行
    results = execute_tools(state["messages"][-1].tool_calls)
    return {"messages": results}

# Observing & Repeat
builder.add_conditional_edges("agent", should_continue, ...)
```

## まとめ

| 観点 | Workflow | Agent |
|------|----------|-------|
| 制御 | 開発者が完全制御 | LLMが動的に判断 |
| 予測可能性 | 高い | 低い |
| 柔軟性 | 低い | 高い |
| コスト | 低い | 高い |
| 適用場面 | 構造化タスク | 不確定タスク |

**重要**: どちらも LangGraphでは同じツール（State、Node、Edge）で構築できます。パターンの選択は問題の性質によって決まります。

## 関連ページ

- [01_PromptChaining.md](01_PromptChaining.md) - Workflowパターンの例
- [06_Agent.md](06_Agent.md) - Agentパターンの詳細
- [03_Routing.md](03_Routing.md) - ハイブリッドアプローチの例
