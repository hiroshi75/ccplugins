# Phase 1: 準備と分析の例

実践的なコード例とテンプレート。

**📋 関連ドキュメント**: [実践例トップ](./examples.md) | [ワークフロー Phase 1](./workflow_phase1.md)

---

## Phase 1: 準備と分析の例

### Example 1.1: fine-tune.md の構造例

**ファイル**: `.langgraph-master/fine-tune.md`

```markdown
# ファインチューニング目標

## 最適化目標

- **Accuracy**: ユーザー意図の分類精度を 90%以上に向上
- **Latency**: 応答時間を 2.0 秒以下に短縮
- **Cost**: リクエストあたりのコストを $0.010 以下に削減

## 評価方法

### テストケース

- **データセット**: tests/evaluation/test_cases.json (20 ケース)
- **実行コマンド**: uv run python -m src.evaluate
- **評価スクリプト**: tests/evaluation/evaluator.py

### 評価指標

#### Accuracy（正解率）

- **計算方法**: (正解数 / 総ケース数) × 100
- **目標値**: 90%以上

#### Latency（応答時間）

- **計算方法**: 各実行の平均時間
- **目標値**: 2.0 秒以下

#### Cost（コスト）

- **計算方法**: 総 API コスト / 総リクエスト数
- **目標値**: $0.010 以下

## 合格基準

すべての評価指標が目標値を達成すること。
```

### Example 1.2: 最適化箇所リストの例

```markdown
# 最適化対象ノード

## Node: analyze_intent

### 基本情報

- **ファイル**: src/nodes/analyzer.py:25-45
- **役割**: ユーザー入力の意図を分類
- **LLM モデル**: claude-3-5-sonnet-20241022
- **現在のパラメータ**: temperature=1.0, max_tokens=default

### 現在のプロンプト

\```python
SystemMessage(content="You are an intent analyzer. Analyze user input.")
HumanMessage(content=f"Analyze: {user_input}")
\```

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

- **Accuracy**: +10-15% (現状の誤分類 20% → 5-10%)
- **Latency**: ±0 (変化なし)
- **Cost**: ±0 (変化なし)

### 優先度

⭐⭐⭐⭐⭐ (最優先) - accuracy 向上への直接的な影響

---

## Node: generate_response

### 基本情報

- **ファイル**: src/nodes/generator.py:45-68
- **役割**: 最終的なユーザー向け応答を生成
- **LLM モデル**: claude-3-5-sonnet-20241022
- **現在のパラメータ**: temperature=0.7, max_tokens=default

### 現在のプロンプト

\```python
ChatPromptTemplate.from_messages([
    ("system", "Generate helpful response based on context."),
    ("human", "{context}\n\nQuestion: {question}")
])
\```

### 問題点

1. **冗長性制御なし**: 簡潔性の指示がない
2. **max_tokens 未設定**: 不必要に長い出力の可能性
3. **応答スタイル未定義**: トーンやスタイルの指定がない

### 改善案

1. "簡潔に" "2-3 文で" などの長さ指示を追加
2. max_tokens を 500 に制限
3. 応答スタイルを明確化（"親しみやすく" "専門的に" など）

### 推定改善効果

- **Accuracy**: ±0 (変化なし)
- **Latency**: -0.3-0.5s (出力トークン削減による)
- **Cost**: -20-30% (トークン数削減による)

### 優先度

⭐⭐⭐ (中) - latency と cost の改善
```

### Example 1.3: Serena MCP でのコード検索例

```python
# LLM クライアントの検索
from mcp_serena import find_symbol, find_referencing_symbols

# Step 1: ChatAnthropic の使用箇所を検索
chat_anthropic_usages = find_symbol(
    name_path="ChatAnthropic",
    substring_matching=True,
    include_body=False
)

print(f"Found {len(chat_anthropic_usages)} ChatAnthropic usages")

# Step 2: 各使用箇所の詳細を調査
for usage in chat_anthropic_usages:
    print(f"\nFile: {usage.relative_path}:{usage.line_start}")
    print(f"Context: {usage.name_path}")

    # プロンプト構築箇所を特定
    references = find_referencing_symbols(
        name_path=usage.name,
        relative_path=usage.relative_path
    )

    # プロンプトを含む可能性のある箇所を表示
    for ref in references:
        if "message" in ref.name.lower() or "prompt" in ref.name.lower():
            print(f"  - Potential prompt location: {ref.name_path}")
```

---

