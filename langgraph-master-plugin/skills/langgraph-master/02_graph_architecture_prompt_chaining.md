# Prompt Chaining（順序処理）

各LLM呼び出しが前の出力を処理する順次パターン。

## 概要

Prompt Chainingは、複数のLLM呼び出しを**順番に連鎖**させるパターンです。各ステップの出力が次のステップの入力になります。

## 適用場面

- 翻訳 → 要約 → 分析のような段階的処理
- コンテンツ生成 → 検証 → 修正のパイプライン
- データ抽出 → 変換 → 検証フロー

## 実装例

```python
from langgraph.graph import StateGraph, START, END
from typing import TypedDict

class State(TypedDict):
    text: str
    translated: str
    summarized: str
    analyzed: str

def translate_node(state: State):
    """英語→日本語に翻訳"""
    translated = llm.invoke(
        f"Translate to Japanese: {state['text']}"
    )
    return {"translated": translated}

def summarize_node(state: State):
    """翻訳されたテキストを要約"""
    summarized = llm.invoke(
        f"Summarize this text: {state['translated']}"
    )
    return {"summarized": summarized}

def analyze_node(state: State):
    """要約を分析"""
    analyzed = llm.invoke(
        f"Analyze sentiment: {state['summarized']}"
    )
    return {"analyzed": analyzed}

# グラフ構築
builder = StateGraph(State)
builder.add_node("translate", translate_node)
builder.add_node("summarize", summarize_node)
builder.add_node("analyze", analyze_node)

# 順次実行のエッジ
builder.add_edge(START, "translate")
builder.add_edge("translate", "summarize")
builder.add_edge("summarize", "analyze")
builder.add_edge("analyze", END)

graph = builder.compile()
```

## 利点

✅ **シンプル**: 処理フローが直線的でわかりやすい
✅ **予測可能**: 常に同じ順序で実行
✅ **デバッグしやすい**: 各ステップを独立してテスト可能
✅ **段階的改善**: 各ステップで品質を向上

## 注意点

⚠️ **遅延の累積**: 各ステップが順次実行されるため時間がかかる
⚠️ **エラー伝播**: 前段のエラーが後段に影響
⚠️ **柔軟性の欠如**: 動的な分岐が難しい

## 応用パターン

### パターン1: 検証付きチェーン

```python
def validate_translation(state: State):
    """翻訳の品質を検証"""
    is_valid = check_quality(state["translated"])
    return {"is_valid": is_valid}

def route_after_validation(state: State):
    if state["is_valid"]:
        return "continue"
    return "retry"

# 検証 → 継続 or 再試行
builder.add_conditional_edges(
    "validate",
    route_after_validation,
    {
        "continue": "summarize",
        "retry": "translate"
    }
)
```

### パターン2: 段階的精緻化

```python
def draft_node(state: State):
    """下書き作成"""
    draft = llm.invoke(f"Write a draft: {state['topic']}")
    return {"draft": draft}

def refine_node(state: State):
    """下書きを精緻化"""
    refined = llm.invoke(f"Improve this draft: {state['draft']}")
    return {"refined": refined}

def polish_node(state: State):
    """最終調整"""
    polished = llm.invoke(f"Polish this text: {state['refined']}")
    return {"final": polished}
```

## vs 他のパターン

| パターン | Prompt Chaining | Parallelization |
|---------|----------------|-----------------|
| 実行順序 | 順次 | 並列 |
| 依存関係 | あり | なし |
| 実行時間 | 長い | 短い |
| 適用場面 | 段階的処理 | 独立タスク |

## まとめ

Prompt Chainingは最もシンプルなパターンで、**段階的な処理が必要な場合**に最適です。各ステップが前のステップに依存する場合に使用します。

## 関連ページ

- [02_Parallelization.md](02_Parallelization.md) - 並列処理との比較
- [05_EvaluatorOptimizer.md](05_EvaluatorOptimizer.md) - 検証ループとの組み合わせ
- [01_基本概念/Edge.md](../01_基本概念/Edge.md) - エッジの基本
