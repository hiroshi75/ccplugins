# Evaluator-Optimizer（評価改善ループ）

生成と評価を繰り返し、許容基準に達するまで反復改善するパターン。

## 概要

Evaluator-Optimizerは、**生成 → 評価 → 改善**のループを繰り返し、品質基準を満たすまで継続するパターンです。

## 適用場面

- コード生成と品質検証
- 翻訳の精度向上
- コンテンツの段階的改善
- 最適化問題の反復解法

## 実装例: 翻訳品質の向上

```python
from typing import TypedDict

class State(TypedDict):
    original_text: str
    translated_text: str
    quality_score: float
    iteration: int
    max_iterations: int
    feedback: str

def generator_node(state: State):
    """翻訳を生成または改善"""
    if state.get("translated_text"):
        # 既存の翻訳を改善
        prompt = f"""
        Original: {state['original_text']}
        Current translation: {state['translated_text']}
        Feedback: {state['feedback']}

        Improve the translation based on the feedback.
        """
    else:
        # 初回翻訳
        prompt = f"Translate to Japanese: {state['original_text']}"

    translated = llm.invoke(prompt)

    return {
        "translated_text": translated,
        "iteration": state.get("iteration", 0) + 1
    }

def evaluator_node(state: State):
    """翻訳の品質を評価"""
    evaluation_prompt = f"""
    Original: {state['original_text']}
    Translation: {state['translated_text']}

    Rate the translation quality (0-1) and provide specific feedback.
    Format: SCORE: 0.X\nFEEDBACK: ...
    """

    result = llm.invoke(evaluation_prompt)

    # スコアとフィードバックを抽出
    score = extract_score(result)
    feedback = extract_feedback(result)

    return {
        "quality_score": score,
        "feedback": feedback
    }

def should_continue(state: State) -> Literal["improve", "done"]:
    """継続判定"""
    # 品質基準を満たしているか
    if state["quality_score"] >= 0.9:
        return "done"

    # 最大イテレーション数に到達したか
    if state["iteration"] >= state["max_iterations"]:
        return "done"

    return "improve"

# グラフ構築
builder = StateGraph(State)

builder.add_node("generator", generator_node)
builder.add_node("evaluator", evaluator_node)

builder.add_edge(START, "generator")
builder.add_edge("generator", "evaluator")

builder.add_conditional_edges(
    "evaluator",
    should_continue,
    {
        "improve": "generator",  # ループ
        "done": END
    }
)

graph = builder.compile()
```

## 応用パターン

### パターン1: 複数の評価基準

```python
class MultiEvalState(TypedDict):
    content: str
    scores: dict[str, float]  # 複数の評価スコア
    min_scores: dict[str, float]  # 各基準の最小値

def multi_evaluator(state: State):
    """複数の観点で評価"""
    content = state["content"]

    # 各観点で評価
    scores = {
        "accuracy": evaluate_accuracy(content),
        "readability": evaluate_readability(content),
        "completeness": evaluate_completeness(content)
    }

    return {"scores": scores}

def multi_should_continue(state: MultiEvalState):
    """すべての基準を満たしているか確認"""
    for criterion, min_score in state["min_scores"].items():
        if state["scores"][criterion] < min_score:
            return "improve"

    return "done"
```

### パターン2: 段階的な基準引き上げ

```python
def adaptive_evaluator(state: State):
    """イテレーションに応じて基準を調整"""
    iteration = state["iteration"]

    # 最初は緩い基準、徐々に厳しく
    threshold = 0.7 + (iteration * 0.05)
    threshold = min(threshold, 0.95)  # 最大0.95

    score = evaluate(state["content"])

    return {
        "quality_score": score,
        "threshold": threshold
    }

def adaptive_should_continue(state: State):
    if state["quality_score"] >= state["threshold"]:
        return "done"

    if state["iteration"] >= state["max_iterations"]:
        return "done"

    return "improve"
```

### パターン3: 複数の改善戦略

```python
from typing import Literal

def strategy_router(state: State) -> Literal["minor_fix", "major_rewrite"]:
    """スコアに応じて改善戦略を選択"""
    score = state["quality_score"]

    if score >= 0.7:
        # 微調整で十分
        return "minor_fix"
    else:
        # 大幅な書き直しが必要
        return "major_rewrite"

def minor_fix_node(state: State):
    """小さな改善"""
    prompt = f"Make minor improvements: {state['content']}\n{state['feedback']}"
    return {"content": llm.invoke(prompt)}

def major_rewrite_node(state: State):
    """大幅な書き直し"""
    prompt = f"Completely rewrite: {state['content']}\n{state['feedback']}"
    return {"content": llm.invoke(prompt)}

builder.add_conditional_edges(
    "evaluator",
    strategy_router,
    {
        "minor_fix": "minor_fix",
        "major_rewrite": "major_rewrite"
    }
)
```

### パターン4: 早期終了とタイムアウト

```python
import time

class TimedState(TypedDict):
    content: str
    quality_score: float
    iteration: int
    start_time: float
    max_duration: float  # 秒

def timed_should_continue(state: TimedState):
    """品質基準とタイムアウトの両方をチェック"""
    # 品質基準を満たした
    if state["quality_score"] >= 0.9:
        return "done"

    # タイムアウト
    elapsed = time.time() - state["start_time"]
    if elapsed >= state["max_duration"]:
        return "timeout"

    # 最大イテレーション
    if state["iteration"] >= 10:
        return "max_iterations"

    return "improve"

builder.add_conditional_edges(
    "evaluator",
    timed_should_continue,
    {
        "improve": "generator",
        "done": END,
        "timeout": "timeout_handler",
        "max_iterations": "max_iter_handler"
    }
)
```

## 評価器の実装パターン

### パターン1: ルールベース評価

```python
def rule_based_evaluator(state: State):
    """ルールベースで評価"""
    content = state["content"]
    score = 0.0
    feedback = []

    # 長さチェック
    if 100 <= len(content) <= 500:
        score += 0.3
    else:
        feedback.append("Length should be 100-500 characters")

    # キーワードチェック
    required_keywords = state["required_keywords"]
    if all(kw in content for kw in required_keywords):
        score += 0.3
    else:
        missing = [kw for kw in required_keywords if kw not in content]
        feedback.append(f"Missing keywords: {missing}")

    # 構造チェック
    if has_proper_structure(content):
        score += 0.4
    else:
        feedback.append("Improve structure")

    return {
        "quality_score": score,
        "feedback": "\n".join(feedback)
    }
```

### パターン2: LLMベース評価

```python
def llm_evaluator(state: State):
    """LLMで評価"""
    evaluation_prompt = f"""
    Evaluate this content on a scale of 0-1:
    {state['content']}

    Criteria:
    - Clarity
    - Completeness
    - Accuracy

    Provide:
    1. Overall score (0-1)
    2. Specific feedback for improvement
    """

    result = llm.invoke(evaluation_prompt)

    return {
        "quality_score": parse_score(result),
        "feedback": parse_feedback(result)
    }
```

## 利点

✅ **品質保証**: 基準を満たすまで改善を継続
✅ **自動最適化**: 手動介入なしで品質向上
✅ **フィードバックループ**: 評価結果を次の改善に活用
✅ **適応的**: 問題の難易度に応じてイテレーション数が変動

## 注意点

⚠️ **無限ループ**: 終了条件を適切に設定
⚠️ **コスト**: LLM呼び出しが複数回発生
⚠️ **収束保証なし**: 必ずしも基準を満たすとは限らない
⚠️ **局所最適**: 改善が行き詰まる可能性

## ベストプラクティス

1. **明確な終了条件**: 最大イテレーション数とタイムアウトを設定
2. **段階的フィードバック**: 具体的な改善点を提示
3. **進捗の追跡**: イテレーションごとにスコアを記録
4. **フォールバック**: 基準を満たせない場合の対処

## まとめ

Evaluator-Optimizerは**品質基準を満たすまで反復改善**が必要な場合に最適です。明確な評価基準と終了条件が成功の鍵です。

## 関連ページ

- [01_PromptChaining.md](01_PromptChaining.md) - 基本的な順次処理
- [06_Agent.md](06_Agent.md) - Agentとの組み合わせ
- [05_応用機能/HumanInTheLoop.md](../05_応用機能/HumanInTheLoop.md) - 人間による評価
