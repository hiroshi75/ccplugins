# Tool Definition（ツール定義）

ツールの定義方法と設計パターン。

## 基本的な定義

```python
from langchain_core.tools import tool

@tool
def search(query: str) -> str:
    """ウェブ検索を実行します。

    Args:
        query: 検索クエリ
    """
    return perform_search(query)
```

## 重要な要素

### 1. Docstring

LLMがツールを理解するための説明：

```python
@tool
def get_weather(location: str, unit: str = "celsius") -> str:
    """指定された場所の現在の天気を取得します。

    このツールは世界中の都市の最新天気情報を提供します。
    温度、湿度、天候状態などの詳細情報を含みます。

    Args:
        location: 都市名（例: "Tokyo", "New York", "London"）
        unit: 温度単位（"celsius" または "fahrenheit"）デフォルトは"celsius"

    Returns:
        天気情報を含む文字列

    Examples:
        >>> get_weather("Tokyo")
        "東京の天気: 晴れ, 気温: 25°C, 湿度: 60%"
    """
    return fetch_weather(location, unit)
```

### 2. 型アノテーション

パラメータと戻り値の型を明示：

```python
from typing import List, Dict

@tool
def search_products(
    query: str,
    max_results: int = 10,
    category: str | None = None
) -> List[Dict[str, any]]:
    """商品を検索します。

    Args:
        query: 検索キーワード
        max_results: 最大結果数
        category: カテゴリーフィルター（オプション）
    """
    return database.search(query, max_results, category)
```

## 構造化出力

Pydanticモデルを使用した構造化出力：

```python
from pydantic import BaseModel, Field

class WeatherInfo(BaseModel):
    temperature: float = Field(description="気温（摂氏）")
    humidity: int = Field(description="湿度（%）")
    condition: str = Field(description="天候状態")
    location: str = Field(description="場所")

@tool(response_format="content_and_artifact")
def get_detailed_weather(location: str) -> tuple[str, WeatherInfo]:
    """詳細な天気情報を取得します。

    Args:
        location: 都市名
    """
    data = fetch_weather_data(location)

    weather = WeatherInfo(
        temperature=data["temp"],
        humidity=data["humidity"],
        condition=data["condition"],
        location=location
    )

    summary = f"{location}の天気: {weather.condition}, {weather.temperature}°C"

    return summary, weather
```

## ツール設計のベストプラクティス

### 1. 単一責任

```python
# Good: 1つのことをうまく行う
@tool
def send_email(to: str, subject: str, body: str) -> str:
    """メールを送信"""

# Bad: 複数の責任
@tool
def send_and_log_email(to: str, subject: str, body: str, log_file: str) -> str:
    """メールを送信してログを記録"""
    # 2つの異なる責任
```

### 2. 明確なパラメータ

```python
# Good: パラメータが明確
@tool
def book_meeting(
    title: str,
    start_time: str,  # "2024-01-01 10:00"
    duration_minutes: int,
    attendees: List[str]
) -> str:
    """会議を予約"""

# Bad: 曖昧なパラメータ
@tool
def book_meeting(data: dict) -> str:
    """会議を予約"""
```

### 3. エラーハンドリング

```python
@tool
def divide(a: float, b: float) -> float:
    """2つの数を割ります。

    Args:
        a: 被除数
        b: 除数

    Raises:
        ValueError: bが0の場合
    """
    if b == 0:
        raise ValueError("0で割ることはできません")

    return a / b
```

## 動的ツール生成

APIスキーマからツールを自動生成：

```python
def create_api_tool(endpoint: str, method: str, description: str):
    """API仕様からツールを生成"""

    @tool
    def api_tool(**kwargs) -> dict:
        f"""
        {description}

        API Endpoint: {endpoint}
        Method: {method}
        """
        response = requests.request(
            method=method,
            url=endpoint,
            json=kwargs
        )
        return response.json()

    return api_tool

# 使用例
create_user_tool = create_api_tool(
    endpoint="https://api.example.com/users",
    method="POST",
    description="新しいユーザーを作成します"
)
```

## ツールのグループ化

関連するツールをグループ化：

```python
# データベースツールグループ
database_tools = [
    query_users_tool,
    update_user_tool,
    delete_user_tool
]

# 検索ツールグループ
search_tools = [
    web_search_tool,
    image_search_tool,
    news_search_tool
]

# 状況に応じて選択
if user.role == "admin":
    tools = database_tools + search_tools
else:
    tools = search_tools
```

## まとめ

ツール定義は明確で詳細なdocstring、適切な型アノテーション、エラーハンドリングが重要です。

## 関連ページ

- [Tool_Node.md](Tool_Node.md) - ツールノードでの使用
- [Command_API.md](Command_API.md) - Command APIとの統合
