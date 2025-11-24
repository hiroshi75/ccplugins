# Test Case Design

Structure, coverage, and design principles for test cases used in LangGraph application evaluation.

## 🧪 Test Case Structure

### Representative Test Case Structure

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

## 📊 Test Case Coverage

### Balance by Category

```python
def analyze_test_coverage(test_cases: List[Dict]) -> Dict:
    """Analyze test case coverage"""
    categories = {}
    difficulties = {}

    for case in test_cases:
        # Category
        cat = case.get("category", "unknown")
        categories[cat] = categories.get(cat, 0) + 1

        # Difficulty
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

### Recommended Balance

```yaml
category_balance:
  description: "Recommended distribution by category"
  recommendations:
    - main_categories: "20-30% (evenly distributed)"
    - edge_cases: "10-15% (sufficient abnormal case coverage)"

difficulty_balance:
  description: "Recommended distribution by difficulty"
  recommendations:
    - easy: "40-50% (basic functionality verification)"
    - medium: "30-40% (practical cases)"
    - hard: "10-20% (edge cases and complex scenarios)"
```

## 🎯 Test Case Design Principles

### 1. Representativeness
- **Reflect Real Use Cases**: Cover actual user input patterns
- **Weight by Frequency**: Include more common cases

### 2. Diversity
- **Comprehensive Categories**: Cover all major categories
- **Difficulty Variation**: From easy to hard
- **Edge Cases**: Abnormal cases, ambiguous cases, boundary values

### 3. Clarity
- **Clear Expectations**: Be specific with expected_answer
- **Explicit Criteria**: Clearly define correctness criteria

### 4. Maintainability
- **ID-based Tracking**: Unique ID for each test case
- **Rich Metadata**: Category, difficulty, and other attributes

## 📝 Test Case Templates

### Basic Template

```json
{
  "id": "TC[number]",
  "category": "[category name]",
  "difficulty": "easy|medium|hard",
  "input": "[user input]",
  "expected_intent": "[expected intent]",
  "expected_answer": "[expected answer]",
  "expected_answer_semantic": ["keyword1", "keyword2"],
  "metadata": {
    "user_type": "new|existing",
    "context_required": true|false,
    "specific_flag": true|false
  }
}
```

### Templates by Category

#### Product Inquiry
```json
{
  "id": "TC_PRODUCT_001",
  "category": "product_inquiry",
  "difficulty": "easy",
  "input": "Question about product",
  "expected_intent": "product_inquiry",
  "expected_answer": "Answer including product information",
  "metadata": {
    "product_type": "premium|basic|enterprise",
    "question_type": "pricing|features|comparison"
  }
}
```

#### Technical Support
```json
{
  "id": "TC_TECH_001",
  "category": "technical_support",
  "difficulty": "medium",
  "input": "Technical problem report",
  "expected_intent": "technical_support",
  "expected_answer": "Troubleshooting steps",
  "metadata": {
    "issue_type": "login|performance|bug",
    "requires_escalation": false,
    "urgency": "low|medium|high"
  }
}
```

#### Billing
```json
{
  "id": "TC_BILLING_001",
  "category": "billing",
  "difficulty": "medium",
  "input": "Billing question",
  "expected_intent": "billing",
  "expected_answer": "Billing explanation and next steps",
  "metadata": {
    "billing_type": "charge|refund|subscription",
    "requires_account_access": true
  }
}
```

#### Edge Cases
```json
{
  "id": "TC_EDGE_001",
  "category": "edge_case",
  "difficulty": "hard",
  "input": "Ambiguous, non-standard, or unexpected input",
  "expected_intent": "appropriate fallback",
  "expected_answer": "Polite clarification request",
  "metadata": {
    "edge_type": "ambiguous|off_topic|malformed",
    "requires_empathy": true
  }
}
```

## 🔍 Test Case Evaluation

### Quality Checklist

```python
def validate_test_case(test_case: Dict) -> List[str]:
    """Check test case quality"""
    issues = []

    # Check required fields
    required_fields = ["id", "category", "difficulty", "input", "expected_intent"]
    for field in required_fields:
        if field not in test_case:
            issues.append(f"Missing required field: {field}")

    # ID uniqueness (requires separate check)
    # Input length check
    if len(test_case.get("input", "")) < 5:
        issues.append("Input too short (minimum 5 characters)")

    # Category validity
    valid_categories = ["product_inquiry", "technical_support", "billing", "general", "edge_case"]
    if test_case.get("category") not in valid_categories:
        issues.append(f"Invalid category: {test_case.get('category')}")

    # Difficulty validity
    valid_difficulties = ["easy", "medium", "hard"]
    if test_case.get("difficulty") not in valid_difficulties:
        issues.append(f"Invalid difficulty: {test_case.get('difficulty')}")

    return issues
```

## 📈 Coverage Report

### Coverage Analysis Script

```python
def generate_coverage_report(test_cases: List[Dict]) -> str:
    """Generate test case coverage report"""
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

## 📋 Related Documentation

- [Evaluation Metrics](./evaluation_metrics.md) - Metric definitions and calculation methods
- [Statistical Significance](./evaluation_statistics.md) - Multiple runs and statistical analysis
- [Best Practices](./evaluation_practices.md) - Practical evaluation guide
