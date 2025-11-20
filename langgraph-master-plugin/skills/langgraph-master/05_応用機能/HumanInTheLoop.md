# Human-in-the-Loop（承認フロー）

グラフ実行を一時停止して人間の介入を求める機能。

## 概要

Human-in-the-Loopは、重要な決定やアクションの前に**人間の承認や入力**を求める機能です。

## 動的インタラプト（推奨）

### 基本的な使用

```python
from langgraph.types import interrupt

def approval_node(state: State):
    """承認を求める"""
    approved = interrupt("Do you approve this action?")

    if approved:
        return {"status": "approved"}
    else:
        return {"status": "rejected"}
```

### 実行

```python
# 初回実行（インタラプトで停止）
result = graph.invoke(input, config)

# インタラプト情報を確認
print(result["__interrupt__"])  # "Do you approve this action?"

# 承認して再開
graph.invoke(None, config, resume=True)

# または却下
graph.invoke(None, config, resume=False)
```

## 応用パターン

### パターン1: 承認または却下

```python
def action_approval(state: State):
    """アクション実行前に承認"""
    action_details = prepare_action(state)

    approved = interrupt({
        "question": "Approve this action?",
        "details": action_details
    })

    if approved:
        result = execute_action(action_details)
        return {"result": result, "approved": True}
    else:
        return {"result": None, "approved": False}
```

### パターン2: 編集可能な承認

```python
def review_and_edit(state: State):
    """生成内容を確認・編集"""
    generated = generate_content(state)

    edited_content = interrupt({
        "instruction": "Review and edit this content",
        "content": generated
    })

    return {"final_content": edited_content}

# 編集して再開
graph.invoke(None, config, resume=edited_version)
```

### パターン3: ツール実行前の承認

```python
@tool
def send_email(to: str, subject: str, body: str):
    """メールを送信（承認付き）"""
    response = interrupt({
        "action": "send_email",
        "to": to,
        "subject": subject,
        "body": body,
        "message": "Approve sending this email?"
    })

    if response.get("action") == "approve":
        # 承認された場合、パラメータの編集も可能
        final_to = response.get("to", to)
        final_subject = response.get("subject", subject)
        final_body = response.get("body", body)

        return actually_send_email(final_to, final_subject, final_body)
    else:
        return "Email cancelled by user"
```

### パターン4: 入力の検証ループ

```python
def get_valid_input(state: State):
    """有効な入力を得るまでループ"""
    prompt = "Enter a positive number:"

    while True:
        answer = interrupt(prompt)

        if isinstance(answer, (int, float)) and answer > 0:
            break

        prompt = f"'{answer}' is invalid. Enter a positive number:"

    return {"value": answer}
```

## 静的インタラプト（デバッグ用）

コンパイル時にブレークポイントを設定：

```python
graph = builder.compile(
    checkpointer=checkpointer,
    interrupt_before=["risky_node"],  # ノード実行前に停止
    interrupt_after=["generate_content"]  # ノード実行後に停止
)

# 実行（指定ノード前で停止）
graph.invoke(input, config)

# 状態を確認
state = graph.get_state(config)

# 再開
graph.invoke(None, config)
```

## 実践例: 段階的承認ワークフロー

```python
from langgraph.types import interrupt, Command

class ApprovalState(TypedDict):
    request: str
    draft: str
    reviewed: str
    approved: bool

def draft_node(state: ApprovalState):
    """下書き作成"""
    draft = create_draft(state["request"])
    return {"draft": draft}

def review_node(state: ApprovalState):
    """レビューと編集"""
    reviewed = interrupt({
        "type": "review",
        "content": state["draft"],
        "instruction": "Review and improve the draft"
    })

    return {"reviewed": reviewed}

def approval_node(state: ApprovalState):
    """最終承認"""
    approved = interrupt({
        "type": "approval",
        "content": state["reviewed"],
        "question": "Approve for publication?"
    })

    if approved:
        return Command(
            update={"approved": True},
            goto="publish"
        )
    else:
        return Command(
            update={"approved": False},
            goto="draft"  # 下書きに戻る
        )

def publish_node(state: ApprovalState):
    """公開"""
    publish(state["reviewed"])
    return {"status": "published"}

# グラフ構築
builder.add_node("draft", draft_node)
builder.add_node("review", review_node)
builder.add_node("approval", approval_node)
builder.add_node("publish", publish_node)

builder.add_edge(START, "draft")
builder.add_edge("draft", "review")
builder.add_edge("review", "approval")
# approvalノードがCommandで制御フロー決定
builder.add_edge("publish", END)
```

## 重要なルール

### ✅ 推奨事項

- JSON形式で値を渡す
- `interrupt()`の呼び出し順序を一貫させる
- `interrupt()`前の処理は冪等的にする

### ❌ 禁止事項

- `interrupt()`を`try-except`でキャッチしない
- 条件で`interrupt()`をスキップしない
- 非シリアライズ可能なオブジェクトを渡さない

## ユースケース

### 1. 高リスク操作の承認

```python
def delete_data(state: State):
    """データ削除（承認必須）"""
    approved = interrupt({
        "action": "delete_data",
        "warning": "This cannot be undone!",
        "data_count": len(state["data_to_delete"])
    })

    if approved:
        execute_delete(state["data_to_delete"])
        return {"deleted": True}
    return {"deleted": False}
```

### 2. クリエイティブ作業のレビュー

```python
def creative_generation(state: State):
    """クリエイティブコンテンツ生成とレビュー"""
    versions = []

    for _ in range(3):
        version = generate_creative(state["prompt"])
        versions.append(version)

    selected = interrupt({
        "type": "select_version",
        "versions": versions,
        "instruction": "Select the best version or request regeneration"
    })

    return {"final_version": selected}
```

### 3. 段階的なデータ入力

```python
def collect_user_info(state: State):
    """ユーザー情報を段階的に収集"""
    name = interrupt("What is your name?")

    age = interrupt(f"Hello {name}, what is your age?")

    city = interrupt("What city do you live in?")

    return {
        "user_info": {
            "name": name,
            "age": age,
            "city": city
        }
    }
```

## まとめ

Human-in-the-Loopは重要な決定で人間の判断を組み込む機能です。動的インタラプトが柔軟で推奨されます。

## 関連ページ

- [03_メモリ管理/Persistence.md](../03_メモリ管理/Persistence.md) - チェックポインターが必須
- [02_グラフアーキテクチャ/06_Agent.md](../02_グラフアーキテクチャ/06_Agent.md) - エージェントとの組み合わせ
- [04_ツール統合/Tool_Node.md](../04_ツール統合/Tool_Node.md) - ツール実行前の承認
