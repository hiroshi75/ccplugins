# ファインチューニングワークフロー詳細

LangGraph アプリケーションのファインチューニングを実行する際の詳細なワークフローと実践的なガイドライン。

**💡 Tip**: コピー&ペーストで使える具体的なコード例とテンプレートは [examples.md](examples.md) を参照してください。

## 📋 ワークフロー全体像

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: 準備と分析                                           │
├─────────────────────────────────────────────────────────────┤
│ 1. fine-tune.md 読み込み → 目標と評価基準の理解               │
│ 2. Serena で最適化対象の特定 → LLM 呼び出しノードのリスト化   │
│ 3. 最適化箇所リスト作成 → 改善可能性の評価                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 2: ベースライン評価                                     │
├─────────────────────────────────────────────────────────────┤
│ 4. 評価環境準備 → テストケース、評価スクリプト                │
│ 5. ベースライン測定 → 3-5回実行、統計情報収集                 │
│ 6. 結果分析 → 問題点の特定、改善余地の評価                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 3: 反復的改善 (Iteration Loop)                         │
├─────────────────────────────────────────────────────────────┤
│ 7. 優先順位付け → 最も効果的な改善箇所の選択                  │
│ 8. 改善実施 → プロンプト最適化、パラメータ調整                │
│ 9. 改善後評価 → 同じ条件で再評価                             │
│ 10. 結果比較 → 改善効果の測定、次のアクション決定             │
│ 11. 継続判断 → 目標達成？ Yes → Phase 4 / No → 次の iteration │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 4: 完了と文書化                                         │
├─────────────────────────────────────────────────────────────┤
│ 12. 最終評価レポート作成 → 改善内容と結果のサマリー           │
│ 13. コードコミット → バージョン管理とドキュメント更新          │
└─────────────────────────────────────────────────────────────┘
```

## Phase 1: 準備と分析

### Step 1: fine-tune.md の読み込みと理解

**目的**: 最適化の方向性を明確にする

**実行内容**:
```python
# .langgraph-master/fine-tune.md を読み込む
file_path = ".langgraph-master/fine-tune.md"
with open(file_path, "r") as f:
    fine_tune_spec = f.read()

# 以下の情報を抽出
# - 最適化目標（accuracy, latency, cost など）
# - 評価方法（テストケース、評価指標、計算方法）
# - 合格基準（各指標の目標値）
# - テストデータの場所
```

**fine-tune.md の典型的な構造**:
```markdown
# ファインチューニング目標

## 最適化目標
- **Accuracy**: ユーザー意図の分類精度を90%以上に向上
- **Latency**: 応答時間を2.0秒以下に短縮
- **Cost**: リクエストあたりのコストを$0.010以下に削減

## 評価方法
- **テストケース**: tests/evaluation/test_cases.json (20ケース)
- **実行コマンド**: uv run python -m src.evaluate
- **評価スクリプト**: tests/evaluation/evaluator.py

## 評価指標

### Accuracy
- 計算方法: (正解数 / 総ケース数) × 100
- 目標値: 90%以上

### Latency
- 計算方法: 各実行の平均時間
- 目標値: 2.0秒以下

### Cost
- 計算方法: 総API コスト / 総リクエスト数
- 目標値: $0.010以下

## 合格基準
すべての評価指標が目標値を達成すること
```

### Step 2: Serena MCP での最適化対象特定

**目的**: LLM を呼び出しているノードを網羅的に特定

**実行手順**:

1. **LLM クライアントの検索**
```python
# Serena MCP: find_symbol を使用
# ChatAnthropic, ChatOpenAI, ChatGoogleGenerativeAI などを検索

patterns = [
    "ChatAnthropic",
    "ChatOpenAI",
    "ChatGoogleGenerativeAI",
    "ChatVertexAI"
]

llm_usages = []
for pattern in patterns:
    results = serena.find_symbol(
        name_path=pattern,
        substring_matching=True,
        include_body=False
    )
    llm_usages.extend(results)
```

2. **プロンプト構築箇所の特定**
```python
# 各 LLM 呼び出しについて、プロンプトがどう構築されているか調査
for usage in llm_usages:
    # find_referencing_symbols で周辺のコンテキストを取得
    context = serena.find_referencing_symbols(
        name_path=usage.name,
        relative_path=usage.file_path
    )

    # プロンプトテンプレートやメッセージ構築ロジックを特定
    # - ChatPromptTemplate の使用
    # - SystemMessage, HumanMessage の定義
    # - f-string や format() でのプロンプト構築
```

3. **ノードごとの分析**
```python
# 各ノード関数内での LLM 使用パターンを分析
# - プロンプトの明確性
# - Few-shot examples の有無
# - 出力フォーマットの構造化
# - パラメータ設定（temperature, max_tokens など）
```

**出力例**:
```markdown
## LLM 呼び出し箇所の分析

### 1. analyze_intent ノード
- **ファイル**: src/nodes/analyzer.py
- **行番号**: 25-45
- **LLM**: ChatAnthropic(model="claude-3-5-sonnet-20241022")
- **プロンプト構造**:
  ```python
  SystemMessage: "You are an intent analyzer..."
  HumanMessage: f"Analyze: {user_input}"
  ```
- **改善可能性**: ⭐⭐⭐⭐⭐ (高)
  - プロンプトが曖昧（"Analyze" の基準が不明確）
  - Few-shot examples なし
  - 出力フォーマットが自由テキスト
- **推定改善効果**: Accuracy +10-15%

### 2. generate_response ノード
- **ファイル**: src/nodes/generator.py
- **行番号**: 45-68
- **LLM**: ChatAnthropic(model="claude-3-5-sonnet-20241022")
- **プロンプト構造**:
  ```python
  ChatPromptTemplate.from_messages([
      ("system", "Generate helpful response..."),
      ("human", "{context}\n\nQuestion: {question}")
  ])
  ```
- **改善可能性**: ⭐⭐⭐ (中)
  - プロンプトは構造的だが、簡潔性の指示なし
  - max_tokens 制限なし → 冗長な出力の可能性
- **推定改善効果**: Latency -0.3-0.5s, Cost -20-30%
```

### Step 3: 最適化箇所リストの作成

**目的**: 改善の優先順位を決定するための情報整理

**リスト作成テンプレート**:
```markdown
# 最適化箇所リスト

## ノード: analyze_intent

### 基本情報
- **ファイル**: src/nodes/analyzer.py:25-45
- **役割**: ユーザー入力の意図を分類
- **LLM モデル**: claude-3-5-sonnet-20241022
- **現在のパラメータ**: temperature=1.0, max_tokens=default

### 現在のプロンプト
```python
SystemMessage(content="You are an intent analyzer. Analyze user input.")
HumanMessage(content=f"Analyze: {user_input}")
```

### 問題点
1. **曖昧な指示**: "Analyze" の具体的な基準が不明
2. **Few-shot なし**: 期待される出力例がない
3. **出力形式未定義**: 自由テキストで構造化されていない
4. **高 temperature**: 1.0 は分類タスクには高すぎる

### 改善案
1. 具体的な分類カテゴリを明記
2. Few-shot examples を 3-5 個追加
3. JSON 出力形式を指定
4. temperature を 0.3-0.5 に下げる

### 推定改善効果
- **Accuracy**: +10-15% (現状の誤分類20% → 5-10%)
- **Latency**: ±0 (変化なし)
- **Cost**: ±0 (変化なし)

### 優先度
⭐⭐⭐⭐⭐ (最優先) - accuracy 向上への直接的な影響

---

## ノード: generate_response

### 基本情報
- **ファイル**: src/nodes/generator.py:45-68
- **役割**: 最終的なユーザー向け応答を生成
- **LLM モデル**: claude-3-5-sonnet-20241022
- **現在のパラメータ**: temperature=0.7, max_tokens=default

### 現在のプロンプト
```python
ChatPromptTemplate.from_messages([
    ("system", "Generate helpful response based on context."),
    ("human", "{context}\n\nQuestion: {question}")
])
```

### 問題点
1. **冗長性制御なし**: 簡潔性の指示がない
2. **max_tokens 未設定**: 不必要に長い出力の可能性
3. **応答スタイル未定義**: トーンやスタイルの指定がない

### 改善案
1. "簡潔に" "2-3文で" などの長さ指示を追加
2. max_tokens を 500 に制限
3. 応答スタイルを明確化（"親しみやすく" "専門的に" など）

### 推定改善効果
- **Accuracy**: ±0 (変化なし)
- **Latency**: -0.3-0.5s (出力トークン削減による)
- **Cost**: -20-30% (トークン数削減による)

### 優先度
⭐⭐⭐ (中) - latency と cost の改善
```

## Phase 2: ベースライン評価

### Step 4: 評価環境の準備

**チェックリスト**:
- [ ] テストケースファイルが存在する
- [ ] 評価スクリプトが実行可能
- [ ] 環境変数（API キーなど）が設定されている
- [ ] 依存パッケージがインストールされている

**実行例**:
```bash
# テストケースの確認
cat tests/evaluation/test_cases.json

# 評価スクリプトの動作確認
uv run python -m src.evaluate --dry-run

# 環境変数の確認
echo $ANTHROPIC_API_KEY
```

### Step 5: ベースライン測定

**推奨実行回数**: 3-5 回（統計的な信頼性のため）

**実行スクリプト例**:
```bash
#!/bin/bash
# baseline_evaluation.sh

ITERATIONS=5
RESULTS_DIR="evaluation_results/baseline"
mkdir -p $RESULTS_DIR

for i in $(seq 1 $ITERATIONS); do
    echo "Running baseline evaluation: iteration $i/$ITERATIONS"
    uv run python -m src.evaluate \
        --output "$RESULTS_DIR/run_$i.json" \
        --verbose

    # API レート制限対策
    sleep 5
done

# 結果の集計
uv run python -m src.aggregate_results \
    --input-dir "$RESULTS_DIR" \
    --output "$RESULTS_DIR/summary.json"
```

**評価スクリプト例** (`src/evaluate.py`):
```python
import json
import time
from pathlib import Path
from typing import Dict, List

def evaluate_test_cases(test_cases: List[Dict]) -> Dict:
    """テストケースを評価"""
    results = {
        "total_cases": len(test_cases),
        "correct": 0,
        "total_latency": 0.0,
        "total_cost": 0.0,
        "case_results": []
    }

    for case in test_cases:
        start_time = time.time()

        # LangGraph アプリケーションを実行
        output = run_langgraph_app(case["input"])

        latency = time.time() - start_time

        # 正解判定
        is_correct = output["answer"] == case["expected_answer"]
        if is_correct:
            results["correct"] += 1

        # コスト計算（トークン使用量から）
        cost = calculate_cost(output["token_usage"])

        results["total_latency"] += latency
        results["total_cost"] += cost

        results["case_results"].append({
            "case_id": case["id"],
            "correct": is_correct,
            "latency": latency,
            "cost": cost
        })

    # 指標の計算
    results["accuracy"] = (results["correct"] / results["total_cases"]) * 100
    results["avg_latency"] = results["total_latency"] / results["total_cases"]
    results["avg_cost"] = results["total_cost"] / results["total_cases"]

    return results

def calculate_cost(token_usage: Dict) -> float:
    """トークン使用量からコストを計算"""
    # Claude 3.5 Sonnet の料金
    INPUT_COST_PER_1M = 3.0  # $3.00 per 1M input tokens
    OUTPUT_COST_PER_1M = 15.0  # $15.00 per 1M output tokens

    input_cost = (token_usage["input_tokens"] / 1_000_000) * INPUT_COST_PER_1M
    output_cost = (token_usage["output_tokens"] / 1_000_000) * OUTPUT_COST_PER_1M

    return input_cost + output_cost
```

### Step 6: ベースライン結果の分析

**集計スクリプト例** (`src/aggregate_results.py`):
```python
import json
import numpy as np
from pathlib import Path
from typing import List, Dict

def aggregate_results(results_dir: Path) -> Dict:
    """複数回の実行結果を集計"""
    all_results = []

    for result_file in sorted(results_dir.glob("run_*.json")):
        with open(result_file) as f:
            all_results.append(json.load(f))

    # 各指標の統計計算
    accuracies = [r["accuracy"] for r in all_results]
    latencies = [r["avg_latency"] for r in all_results]
    costs = [r["avg_cost"] for r in all_results]

    summary = {
        "iterations": len(all_results),
        "accuracy": {
            "mean": np.mean(accuracies),
            "std": np.std(accuracies),
            "min": np.min(accuracies),
            "max": np.max(accuracies)
        },
        "latency": {
            "mean": np.mean(latencies),
            "std": np.std(latencies),
            "min": np.min(latencies),
            "max": np.max(latencies)
        },
        "cost": {
            "mean": np.mean(costs),
            "std": np.std(costs),
            "min": np.min(costs),
            "max": np.max(costs)
        }
    }

    return summary
```

**結果レポート例**:
```markdown
# ベースライン評価結果

実行日時: 2024-11-24 10:00:00
実行回数: 5
テストケース数: 20

## 評価指標サマリー

| 指標 | 平均 | 標準偏差 | 最小値 | 最大値 | 目標 | ギャップ |
|------|------|----------|--------|--------|------|----------|
| Accuracy | 75.0% | 3.2% | 70.0% | 80.0% | 90.0% | **-15.0%** |
| Latency | 2.5s | 0.4s | 2.1s | 3.2s | 2.0s | **+0.5s** |
| Cost/req | $0.015 | $0.002 | $0.013 | $0.018 | $0.010 | **+$0.005** |

## 詳細分析

### Accuracy の問題
- **現状**: 75.0% (目標: 90.0%)
- **主な誤答パターン**:
  1. インテント分類ミス: 12ケース (60%の誤答)
  2. コンテキスト理解不足: 5ケース (25%の誤答)
  3. 曖昧な質問への対応: 3ケース (15%の誤答)

### Latency の問題
- **現状**: 2.5s (目標: 2.0s)
- **ボトルネック**:
  1. generate_response ノード: 平均 1.8s (全体の72%)
  2. analyze_intent ノード: 平均 0.5s (全体の20%)
  3. その他: 平均 0.2s (全体の8%)

### Cost の問題
- **現状**: $0.015/req (目標: $0.010/req)
- **コスト内訳**:
  1. generate_response: $0.011 (73%)
  2. analyze_intent: $0.003 (20%)
  3. その他: $0.001 (7%)
- **主な要因**: 出力トークン数が多い（平均 800 tokens）

## 改善の方向性

### 優先度1: analyze_intent の精度向上
- **影響**: Accuracy に直接影響（-15%のギャップの60%を占める）
- **改善策**: Few-shot examples、明確な分類基準、JSON 出力形式
- **推定効果**: +10-12% accuracy

### 優先度2: generate_response の効率化
- **影響**: Latency と Cost の両方に影響
- **改善策**: 簡潔性の指示、max_tokens 制限、temperature 調整
- **推定効果**: -0.4s latency, -$0.004 cost
```

## Phase 3: 反復的改善

### Iteration のサイクル

各 iteration で以下を実行：

1. **優先順位付け** (Step 7)
2. **改善実施** (Step 8)
3. **改善後評価** (Step 9)
4. **結果比較** (Step 10)
5. **継続判断** (Step 11)

### Step 7: 優先順位付け

**決定基準**:
1. **目標達成への影響度**
2. **改善の実現可能性**
3. **実装コスト**

**優先順位マトリックス**:
```markdown
## 改善優先順位マトリックス

| ノード | 影響度 | 実現可能性 | 実装コスト | 総合スコア | 優先度 |
|--------|--------|-----------|-----------|----------|--------|
| analyze_intent | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 14/15 | 1位 |
| generate_response | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 12/15 | 2位 |
| retrieve_context | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | 8/15 | 3位 |

**Iteration 1 の対象**: analyze_intent ノード
```

### Step 8: 改善実施

**改善前のプロンプト** (`src/nodes/analyzer.py`):
```python
# Before
def analyze_intent(state: GraphState) -> GraphState:
    llm = ChatAnthropic(
        model="claude-3-5-sonnet-20241022",
        temperature=1.0
    )

    messages = [
        SystemMessage(content="You are an intent analyzer. Analyze user input."),
        HumanMessage(content=f"Analyze: {state['user_input']}")
    ]

    response = llm.invoke(messages)
    state["intent"] = response.content
    return state
```

**改善後のプロンプト**:
```python
# After - Iteration 1
def analyze_intent(state: GraphState) -> GraphState:
    llm = ChatAnthropic(
        model="claude-3-5-sonnet-20241022",
        temperature=0.3  # 分類タスクには低めの temperature
    )

    # 明確な分類カテゴリと few-shot examples
    system_prompt = """You are an intent classifier for a customer support chatbot.

Classify user input into one of these categories:
- "product_inquiry": Questions about products or services
- "technical_support": Technical issues or troubleshooting
- "billing": Payment, invoicing, or billing questions
- "general": General questions or chitchat

Output ONLY a valid JSON object with this structure:
{
  "intent": "<category>",
  "confidence": <0.0-1.0>,
  "reasoning": "<brief explanation>"
}

Examples:

Input: "How much does the premium plan cost?"
Output: {"intent": "product_inquiry", "confidence": 0.95, "reasoning": "Question about product pricing"}

Input: "I can't log into my account"
Output: {"intent": "technical_support", "confidence": 0.9, "reasoning": "Authentication issue"}

Input: "Why was I charged twice?"
Output: {"intent": "billing", "confidence": 0.95, "reasoning": "Question about billing charges"}

Input: "Hello, how are you?"
Output: {"intent": "general", "confidence": 0.85, "reasoning": "General greeting"}

Input: "What's the return policy?"
Output: {"intent": "product_inquiry", "confidence": 0.9, "reasoning": "Question about product policy"}
"""

    messages = [
        SystemMessage(content=system_prompt),
        HumanMessage(content=f"Input: {state['user_input']}\nOutput:")
    ]

    response = llm.invoke(messages)

    # JSON パース（エラーハンドリング付き）
    try:
        intent_data = json.loads(response.content)
        state["intent"] = intent_data["intent"]
        state["confidence"] = intent_data["confidence"]
    except json.JSONDecodeError:
        # フォールバック
        state["intent"] = "general"
        state["confidence"] = 0.5

    return state
```

**変更内容サマリー**:
1. ✅ temperature: 1.0 → 0.3（分類タスクに適した設定）
2. ✅ 明確な分類カテゴリ（4つのインテント）
3. ✅ Few-shot examples（5個追加）
4. ✅ JSON 出力形式（構造化された出力）
5. ✅ エラーハンドリング（JSON パース失敗時のフォールバック）

### Step 9: 改善後評価

**実行**:
```bash
# 改善後の評価を同じ条件で実行
./evaluation_after_iteration1.sh
```

### Step 10: 結果比較

**比較レポート例**:
```markdown
# Iteration 1 評価結果

実行日時: 2024-11-24 12:00:00
変更内容: analyze_intent ノードの最適化

## 結果比較

| 指標 | ベースライン | Iteration 1 | 変化 | 変化率 | 目標 | 達成率 |
|------|-------------|-------------|------|--------|------|--------|
| **Accuracy** | 75.0% | **86.0%** | **+11.0%** | +14.7% | 90.0% | 95.6% |
| **Latency** | 2.5s | 2.4s | -0.1s | -4.0% | 2.0s | 80.0% |
| **Cost/req** | $0.015 | $0.014 | -$0.001 | -6.7% | $0.010 | 71.4% |

## 詳細分析

### Accuracy の改善
- **向上**: +11.0% (75.0% → 86.0%)
- **残りギャップ**: 4.0% (目標90.0%)
- **改善できたケース**: インテント分類ミスが 12 → 3 ケースに減少
- **まだ改善が必要**: コンテキスト理解不足のケース（5ケース）

### Latency の若干改善
- **向上**: -0.1s (2.5s → 2.4s)
- **主な要因**: analyze_intent の温度下降により出力が簡潔になった
- **残りボトルネック**: generate_response (平均 1.8s)

### Cost の若干削減
- **削減**: -$0.001 (6.7%削減)
- **要因**: analyze_intent の出力トークン削減
- **主なコスト**: generate_response が依然として73%を占める

## 次の Iteration の方針

### 優先度1: generate_response の最適化
- **目標**: Latency を 1.8s → 1.4s、Cost を $0.011 → $0.007
- **アプローチ**:
  1. 簡潔性の指示追加
  2. max_tokens を 500 に制限
  3. temperature を 0.7 → 0.5 に調整

### 優先度2: Accuracy の最後の4%向上
- **目標**: 86.0% → 90.0%以上
- **アプローチ**: コンテキスト理解を改善（retrieve_context ノード）

## 判定
✅ 継続 → Iteration 2 に進む
```

### Step 11: 継続判断

**判断基準**:
```python
def should_continue_iteration(results: Dict, goals: Dict) -> bool:
    """Iteration を継続すべきか判断"""
    all_goals_met = True

    for metric, goal in goals.items():
        if metric == "accuracy":
            if results[metric] < goal:
                all_goals_met = False
        elif metric in ["latency", "cost"]:
            if results[metric] > goal:
                all_goals_met = False

    return not all_goals_met

# 例
goals = {"accuracy": 90.0, "latency": 2.0, "cost": 0.010}
results = {"accuracy": 86.0, "latency": 2.4, "cost": 0.014}

if should_continue_iteration(results, goals):
    print("次の Iteration に進む")
else:
    print("目標達成 - Phase 4 へ")
```

**Iteration の上限**:
- **推奨**: 3-5 iterations
- **理由**: それ以上は収益逓減の法則が働く可能性が高い
- **例外**: Critical なアプリケーションでは 10+ iterations も可

## Phase 4: 完了と文書化

### Step 12: 最終評価レポート作成

**レポートテンプレート**:
```markdown
# LangGraph アプリケーション ファインチューニング完了レポート

プロジェクト: [プロジェクト名]
実施期間: 2024-11-24 10:00 - 2024-11-24 15:00 (5時間)
実施者: Claude Code with fine-tune skill

## エグゼクティブサマリー

本ファインチューニングプロジェクトでは、LangGraph チャットボットアプリケーションのプロンプト最適化を実施し、以下の成果を達成しました：

- ✅ **Accuracy**: 75.0% → 92.0% (+17.0%, 目標90%達成)
- ✅ **Latency**: 2.5s → 1.9s (-24.0%, 目標2.0s達成)
- ⚠️ **Cost**: $0.015 → $0.011 (-26.7%, 目標$0.010未達)

全3 iterations を実施し、3つの指標のうち2つで目標を達成しました。

## 実施内容サマリー

### Iteration 数と実行時間
- **Total Iterations**: 3
- **最適化したノード数**: 2 (analyze_intent, generate_response)
- **評価実行回数**: 20回 (ベースライン5回 + 各iteration後5回×3)
- **総実行時間**: 約5時間

### 最終結果

| 指標 | 初期値 | 最終値 | 改善 | 改善率 | 目標 | 達成状況 |
|------|--------|--------|------|--------|------|---------|
| Accuracy | 75.0% | 92.0% | +17.0% | +22.7% | 90.0% | ✅ 102.2% 達成 |
| Latency | 2.5s | 1.9s | -0.6s | -24.0% | 2.0s | ✅ 95.0% 達成 |
| Cost/req | $0.015 | $0.011 | -$0.004 | -26.7% | $0.010 | ⚠️ 90.9% 達成 |

## Iteration 別の詳細

### Iteration 1: analyze_intent ノードの最適化

**実施日時**: 2024-11-24 11:00
**対象ノード**: src/nodes/analyzer.py:25-45

**変更内容**:
1. temperature: 1.0 → 0.3
2. Few-shot examples を5個追加
3. JSON 出力形式に構造化
4. 明確な分類カテゴリ（4つ）を定義

**結果**:
- Accuracy: 75.0% → 86.0% (+11.0%)
- Latency: 2.5s → 2.4s (-0.1s)
- Cost: $0.015 → $0.014 (-$0.001)

**学び**: Few-shot examples と明確な出力形式が accuracy 向上に最も効果的

---

### Iteration 2: generate_response ノードの最適化

**実施日時**: 2024-11-24 13:00
**対象ノード**: src/nodes/generator.py:45-68

**変更内容**:
1. 簡潔性の指示を追加（"2-3文で回答"）
2. max_tokens: unlimited → 500
3. temperature: 0.7 → 0.5
4. 応答スタイルを明確化

**結果**:
- Accuracy: 86.0% → 88.0% (+2.0%)
- Latency: 2.4s → 2.0s (-0.4s)
- Cost: $0.014 → $0.011 (-$0.003)

**学び**: max_tokens 制限が latency と cost 削減に大きく貢献

---

### Iteration 3: analyze_intent の追加改善

**実施日時**: 2024-11-24 14:30
**対象ノード**: src/nodes/analyzer.py:25-45

**変更内容**:
1. Few-shot examples を 5個 → 10個に増加
2. エッジケースのハンドリング追加
3. confidence threshold による再分類ロジック

**結果**:
- Accuracy: 88.0% → 92.0% (+4.0%)
- Latency: 2.0s → 1.9s (-0.1s)
- Cost: $0.011 → $0.011 (±0)

**学び**: 追加の few-shot examples が accuracy の最後の壁を突破

## 最終的な変更内容

### src/nodes/analyzer.py (analyze_intent ノード)

#### Before
```python
def analyze_intent(state: GraphState) -> GraphState:
    llm = ChatAnthropic(model="claude-3-5-sonnet-20241022", temperature=1.0)
    messages = [
        SystemMessage(content="You are an intent analyzer. Analyze user input."),
        HumanMessage(content=f"Analyze: {state['user_input']}")
    ]
    response = llm.invoke(messages)
    state["intent"] = response.content
    return state
```

#### After
```python
def analyze_intent(state: GraphState) -> GraphState:
    llm = ChatAnthropic(model="claude-3-5-sonnet-20241022", temperature=0.3)

    system_prompt = """You are an intent classifier for a customer support chatbot.
Classify user input into: product_inquiry, technical_support, billing, or general.
Output JSON: {"intent": "<category>", "confidence": <0.0-1.0>, "reasoning": "<explanation>"}

[10 few-shot examples...]
"""

    messages = [
        SystemMessage(content=system_prompt),
        HumanMessage(content=f"Input: {state['user_input']}\nOutput:")
    ]

    response = llm.invoke(messages)
    intent_data = json.loads(response.content)

    # Low confidence → re-classify as general
    if intent_data["confidence"] < 0.7:
        intent_data["intent"] = "general"

    state["intent"] = intent_data["intent"]
    state["confidence"] = intent_data["confidence"]
    return state
```

**主な変更点**:
- temperature: 1.0 → 0.3
- Few-shot examples: 0 → 10
- 出力: 自由テキスト → JSON
- Confidence threshold によるフォールバック追加

---

### src/nodes/generator.py (generate_response ノード)

#### Before
```python
def generate_response(state: GraphState) -> GraphState:
    llm = ChatAnthropic(model="claude-3-5-sonnet-20241022", temperature=0.7)
    prompt = ChatPromptTemplate.from_messages([
        ("system", "Generate helpful response based on context."),
        ("human", "{context}\n\nQuestion: {question}")
    ])
    chain = prompt | llm
    response = chain.invoke({"context": state["context"], "question": state["user_input"]})
    state["response"] = response.content
    return state
```

#### After
```python
def generate_response(state: GraphState) -> GraphState:
    llm = ChatAnthropic(
        model="claude-3-5-sonnet-20241022",
        temperature=0.5,
        max_tokens=500  # 出力長制限
    )

    system_prompt = """You are a helpful customer support assistant.

Guidelines:
- Be concise: Answer in 2-3 sentences
- Be friendly: Use a warm, professional tone
- Be accurate: Base your answer on the provided context
- If uncertain: Acknowledge and offer to escalate

Format: Direct answer followed by one optional clarifying sentence.
"""

    prompt = ChatPromptTemplate.from_messages([
        ("system", system_prompt),
        ("human", "Context: {context}\n\nQuestion: {question}\n\nAnswer:")
    ])

    chain = prompt | llm
    response = chain.invoke({"context": state["context"], "question": state["user_input"]})
    state["response"] = response.content
    return state
```

**主な変更点**:
- temperature: 0.7 → 0.5
- max_tokens: unlimited → 500
- 簡潔性の明確な指示（"2-3 sentences"）
- 応答スタイルのガイドライン追加

## 評価結果の詳細

### Test Case 別の改善状況

| Case ID | Category | Before | After | 改善 |
|---------|----------|--------|-------|------|
| TC001 | Product | ❌ Wrong | ✅ Correct | ✅ |
| TC002 | Technical | ❌ Wrong | ✅ Correct | ✅ |
| TC003 | Billing | ✅ Correct | ✅ Correct | - |
| TC004 | General | ✅ Correct | ✅ Correct | - |
| TC005 | Product | ❌ Wrong | ✅ Correct | ✅ |
| ... | ... | ... | ... | ... |
| TC020 | Technical | ✅ Correct | ✅ Correct | - |

**改善されたケース**: 15/20 (75%)
**維持されたケース**: 5/20 (25%)
**劣化したケース**: 0/20 (0%)

### Latency の内訳

| ノード | Before | After | 変化 | 変化率 |
|--------|--------|-------|------|--------|
| analyze_intent | 0.5s | 0.4s | -0.1s | -20% |
| retrieve_context | 0.2s | 0.2s | ±0s | 0% |
| generate_response | 1.8s | 1.3s | -0.5s | -28% |
| **Total** | **2.5s** | **1.9s** | **-0.6s** | **-24%** |

### Cost の内訳

| ノード | Before | After | 変化 | 変化率 |
|--------|--------|-------|------|--------|
| analyze_intent | $0.003 | $0.003 | ±$0 | 0% |
| retrieve_context | $0.001 | $0.001 | ±$0 | 0% |
| generate_response | $0.011 | $0.007 | -$0.004 | -36% |
| **Total** | **$0.015** | **$0.011** | **-$0.004** | **-27%** |

## 今後の推奨事項

### 短期（1-2週間）
1. **Cost 目標の達成**: $0.011 → $0.010
   - アプローチ: Claude 3.5 Haiku への部分移行を検討
   - 推定効果: -$0.002-0.003/req

2. **Accuracy の更なる向上**: 92.0% → 95.0%
   - アプローチ: エラーケースの分析と few-shot examples の追加
   - 推定効果: +3.0%

### 中期（1-2ヶ月）
1. **モデルの最適化**
   - simple な intent classification には Haiku を使用
   - complex な response generation のみ Sonnet を使用
   - 推定効果: -30-40% cost, latency への影響は最小

2. **プロンプトキャッシング活用**
   - System prompts と few-shot examples をキャッシュ
   - 推定効果: -50% cost（キャッシュヒット時）

### 長期（3-6ヶ月）
1. **ファインチューニングモデルの検討**
   - 独自データでの model fine-tuning
   - Few-shot examples 不要で簡潔なプロンプト
   - 推定効果: -60% cost, +5% accuracy

## 結論

本プロジェクトでは、LangGraph アプリケーションのファインチューニングにより、以下を達成しました：

✅ **成功した点**:
1. Accuracy の大幅向上（+22.7%）- 目標を2.2%超過達成
2. Latency の顕著な改善（-24.0%）- 目標を5%超過達成
3. Cost の削減（-26.7%）- 目標にあと9.1%

⚠️ **課題**:
1. Cost 目標未達（$0.011 vs $0.010目標）- 軽量モデルへの移行で対応可能

📈 **ビジネスインパクト**:
- ユーザー満足度の向上（accuracy向上により）
- 運用コストの削減（latency, cost削減により）
- スケーラビリティの改善（効率的なリソース使用）

🎯 **次のステップ**:
1. Cost 削減のための軽量モデル移行の検証
2. 継続的なモニタリングと評価
3. 新しいユースケースへの展開

---

作成日時: 2024-11-24 15:00:00
作成者: Claude Code (fine-tune skill)
```

### Step 13: コードコミットとドキュメント更新

**Git コミット例**:
```bash
# 変更をコミット
git add src/nodes/analyzer.py src/nodes/generator.py
git commit -m "feat: optimize LangGraph prompts for accuracy and latency

Iteration 1-3 of fine-tuning process:
- analyze_intent: added few-shot examples, JSON output, lower temperature
- generate_response: added conciseness guidelines, max_tokens limit

Results:
- Accuracy: 75.0% → 92.0% (+17.0%, goal 90% ✅)
- Latency: 2.5s → 1.9s (-0.6s, goal 2.0s ✅)
- Cost: $0.015 → $0.011 (-$0.004, goal $0.010 ⚠️)

Full report: evaluation_results/final_report.md"

# 評価結果もコミット
git add evaluation_results/
git commit -m "docs: add fine-tuning evaluation results and final report"

# タグを付ける
git tag -a fine-tune-v1.0 -m "Fine-tuning completed: 92% accuracy achieved"
```

## まとめ

このワークフローに従うことで：
- ✅ 体系的なファインチューニングプロセスを実行
- ✅ データ駆動の意思決定
- ✅ 継続的な改善と検証
- ✅ 完全な文書化とトレーサビリティ

が実現できます。
