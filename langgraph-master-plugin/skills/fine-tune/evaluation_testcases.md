# テストケースの設計

LangGraph アプリケーションの評価に使用するテストケースの構造、カバレッジ、設計原則。

## 🧪 テストケースの構造

### 代表的なテストケースの構造

```json
{
  "test_cases": [
    {
      "id": "TC001",
      "category": "product_inquiry",
      "difficulty": "easy",
      "input": "How much does the premium plan cost?",
      "expected_intent": "product_inquiry",
      "expected_answer": "The premium plan costs $49 per month.",
      "expected_answer_semantic": ["premium", "plan", "$49", "month"],
      "metadata": {
        "user_type": "new",
        "context_required": false
      }
    },
    {
      "id": "TC002",
      "category": "technical_support",
      "difficulty": "medium",
      "input": "I can't seem to log into my account even after resetting my password",
      "expected_intent": "technical_support",
      "expected_answer": "Let me help you troubleshoot the login issue. First, please clear your browser cache and cookies, then try logging in again.",
      "expected_answer_semantic": ["troubleshoot", "clear cache", "cookies", "try again"],
      "metadata": {
        "user_type": "existing",
        "context_required": true,
        "requires_escalation": false
      }
    },
    {
      "id": "TC003",
      "category": "edge_case",
      "difficulty": "hard",
      "input": "yo whats the deal with my bill being so high lol",
      "expected_intent": "billing",
      "expected_answer": "I understand you have concerns about your bill. Let me review your account to identify any unexpected charges.",
      "expected_answer_semantic": ["concerns", "bill", "review", "charges"],
      "metadata": {
        "user_type": "existing",
        "context_required": true,
        "tone": "informal",
        "requires_empathy": true
      }
    }
  ]
}
```

## 📊 テストケースのカバレッジ

### カテゴリ別のバランス

```python
def analyze_test_coverage(test_cases: List[Dict]) -> Dict:
    """テストケースのカバレッジを分析"""
    categories = {}
    difficulties = {}

    for case in test_cases:
        # カテゴリ
        cat = case.get("category", "unknown")
        categories[cat] = categories.get(cat, 0) + 1

        # 難易度
        diff = case.get("difficulty", "unknown")
        difficulties[diff] = difficulties.get(diff, 0) + 1

    total = len(test_cases)

    return {
        "total_cases": total,
        "by_category": {
            cat: {"count": count, "percentage": count/total*100}
            for cat, count in categories.items()
        },
        "by_difficulty": {
            diff: {"count": count, "percentage": count/total*100}
            for diff, count in difficulties.items()
        }
    }
```

### 推奨バランス

```yaml
category_balance:
  description: "各カテゴリの推奨分布"
  recommendations:
    - main_categories: "20-30% (均等分散)"
    - edge_cases: "10-15% (十分な異常系カバレッジ)"

difficulty_balance:
  description: "難易度別の推奨分布"
  recommendations:
    - easy: "40-50% (基本機能の確認)"
    - medium: "30-40% (実用的なケース)"
    - hard: "10-20% (エッジケースと複雑なシナリオ)"
```

## 🎯 テストケース設計原則

### 1. 代表性（Representativeness）
- **実際のユースケースを反映**: 実際のユーザー入力パターンをカバー
- **頻度による重み付け**: よくあるケースを多く含める

### 2. 多様性（Diversity）
- **カテゴリの網羅**: すべての主要カテゴリをカバー
- **難易度のバリエーション**: Easy から Hard まで
- **エッジケース**: 異常系、曖昧なケース、境界値

### 3. 明確性（Clarity）
- **期待値の明確化**: expected_answer を具体的に
- **判定基準の明示**: 正解判定の基準を明確に

### 4. 保守性（Maintainability）
- **ID による追跡**: テストケースごとにユニークな ID
- **メタデータの充実**: カテゴリ、難易度、その他の属性

## 📝 テストケーステンプレート

### 基本テンプレート

```json
{
  "id": "TC[番号]",
  "category": "[カテゴリ名]",
  "difficulty": "easy|medium|hard",
  "input": "[ユーザー入力]",
  "expected_intent": "[期待されるインテント]",
  "expected_answer": "[期待される回答]",
  "expected_answer_semantic": ["キーワード1", "キーワード2"],
  "metadata": {
    "user_type": "new|existing",
    "context_required": true|false,
    "特定のフラグ": true|false
  }
}
```

### カテゴリ別テンプレート

#### Product Inquiry（製品問い合わせ）
```json
{
  "id": "TC_PRODUCT_001",
  "category": "product_inquiry",
  "difficulty": "easy",
  "input": "製品に関する質問",
  "expected_intent": "product_inquiry",
  "expected_answer": "製品情報を含む回答",
  "metadata": {
    "product_type": "premium|basic|enterprise",
    "question_type": "pricing|features|comparison"
  }
}
```

#### Technical Support（技術サポート）
```json
{
  "id": "TC_TECH_001",
  "category": "technical_support",
  "difficulty": "medium",
  "input": "技術的な問題の報告",
  "expected_intent": "technical_support",
  "expected_answer": "トラブルシューティング手順",
  "metadata": {
    "issue_type": "login|performance|bug",
    "requires_escalation": false,
    "urgency": "low|medium|high"
  }
}
```

#### Billing（請求）
```json
{
  "id": "TC_BILLING_001",
  "category": "billing",
  "difficulty": "medium",
  "input": "請求に関する質問",
  "expected_intent": "billing",
  "expected_answer": "請求説明と次のステップ",
  "metadata": {
    "billing_type": "charge|refund|subscription",
    "requires_account_access": true
  }
}
```

#### Edge Cases（エッジケース）
```json
{
  "id": "TC_EDGE_001",
  "category": "edge_case",
  "difficulty": "hard",
  "input": "曖昧、非標準、または予期しない入力",
  "expected_intent": "適切なフォールバック",
  "expected_answer": "丁寧な clarification 要求",
  "metadata": {
    "edge_type": "ambiguous|off_topic|malformed",
    "requires_empathy": true
  }
}
```

## 🔍 テストケースの評価

### 品質チェックリスト

```python
def validate_test_case(test_case: Dict) -> List[str]:
    """テストケースの品質をチェック"""
    issues = []

    # 必須フィールドの確認
    required_fields = ["id", "category", "difficulty", "input", "expected_intent"]
    for field in required_fields:
        if field not in test_case:
            issues.append(f"Missing required field: {field}")

    # ID のユニーク性（別途チェック必要）
    # 入力の長さチェック
    if len(test_case.get("input", "")) < 5:
        issues.append("Input too short (minimum 5 characters)")

    # カテゴリの妥当性
    valid_categories = ["product_inquiry", "technical_support", "billing", "general", "edge_case"]
    if test_case.get("category") not in valid_categories:
        issues.append(f"Invalid category: {test_case.get('category')}")

    # 難易度の妥当性
    valid_difficulties = ["easy", "medium", "hard"]
    if test_case.get("difficulty") not in valid_difficulties:
        issues.append(f"Invalid difficulty: {test_case.get('difficulty')}")

    return issues
```

## 📈 カバレッジレポート

### カバレッジ分析スクリプト

```python
def generate_coverage_report(test_cases: List[Dict]) -> str:
    """テストケースのカバレッジレポートを生成"""
    coverage = analyze_test_coverage(test_cases)

    report = f"""# Test Case Coverage Report

## Summary
- **Total Test Cases**: {coverage['total_cases']}

## By Category
"""
    for cat, data in coverage['by_category'].items():
        report += f"- **{cat}**: {data['count']} cases ({data['percentage']:.1f}%)\n"

    report += "\n## By Difficulty\n"
    for diff, data in coverage['by_difficulty'].items():
        report += f"- **{diff}**: {data['count']} cases ({data['percentage']:.1f}%)\n"

    return report
```

## 📋 関連ドキュメント

- [評価指標](./evaluation_metrics.md) - 指標の定義と計算方法
- [統計的有意性](./evaluation_statistics.md) - 複数回実行と統計分析
- [ベストプラクティス](./evaluation_practices.md) - 評価の実践的なガイド
