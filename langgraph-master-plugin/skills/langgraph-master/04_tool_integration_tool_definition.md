# Tool Definition

How to define tools and design patterns.

## Basic Definition

```python
from langchain_core.tools import tool

@tool
def search(query: str) -> str:
    """Perform a web search.

    Args:
        query: Search query
    """
    return perform_search(query)
```

## Key Elements

### 1. Docstring

Description for the LLM to understand the tool:

```python
@tool
def get_weather(location: str, unit: str = "celsius") -> str:
    """Get the current weather for a specified location.

    This tool provides up-to-date weather information for cities around the world.
    It includes detailed information such as temperature, humidity, and weather conditions.

    Args:
        location: City name (e.g., "Tokyo", "New York", "London")
        unit: Temperature unit ("celsius" or "fahrenheit"), default is "celsius"

    Returns:
        A string containing weather information

    Examples:
        >>> get_weather("Tokyo")
        "Tokyo weather: Sunny, Temperature: 25°C, Humidity: 60%"
    """
    return fetch_weather(location, unit)
```

### 2. Type Annotations

Explicitly specify parameter and return value types:

```python
from typing import List, Dict

@tool
def search_products(
    query: str,
    max_results: int = 10,
    category: str | None = None
) -> List[Dict[str, any]]:
    """Search for products.

    Args:
        query: Search keywords
        max_results: Maximum number of results
        category: Category filter (optional)
    """
    return database.search(query, max_results, category)
```

## Structured Output

Structured output using Pydantic models:

```python
from pydantic import BaseModel, Field

class WeatherInfo(BaseModel):
    temperature: float = Field(description="Temperature in Celsius")
    humidity: int = Field(description="Humidity (%)")
    condition: str = Field(description="Weather condition")
    location: str = Field(description="Location")

@tool(response_format="content_and_artifact")
def get_detailed_weather(location: str) -> tuple[str, WeatherInfo]:
    """Get detailed weather information.

    Args:
        location: City name
    """
    data = fetch_weather_data(location)

    weather = WeatherInfo(
        temperature=data["temp"],
        humidity=data["humidity"],
        condition=data["condition"],
        location=location
    )

    summary = f"{location} weather: {weather.condition}, {weather.temperature}°C"

    return summary, weather
```

## Best Practices for Tool Design

### 1. Single Responsibility

```python
# Good: Does one thing well
@tool
def send_email(to: str, subject: str, body: str) -> str:
    """Send an email"""

# Bad: Multiple responsibilities
@tool
def send_and_log_email(to: str, subject: str, body: str, log_file: str) -> str:
    """Send an email and log it"""
    # Two different responsibilities
```

### 2. Clear Parameters

```python
# Good: Clear parameters
@tool
def book_meeting(
    title: str,
    start_time: str,  # "2024-01-01 10:00"
    duration_minutes: int,
    attendees: List[str]
) -> str:
    """Book a meeting"""

# Bad: Ambiguous parameters
@tool
def book_meeting(data: dict) -> str:
    """Book a meeting"""
```

### 3. Error Handling

```python
@tool
def divide(a: float, b: float) -> float:
    """Divide two numbers.

    Args:
        a: Dividend
        b: Divisor

    Raises:
        ValueError: If b is 0
    """
    if b == 0:
        raise ValueError("Cannot divide by zero")

    return a / b
```

## Dynamic Tool Generation

Automatically generate tools from API schemas:

```python
def create_api_tool(endpoint: str, method: str, description: str):
    """Generate tools from API specifications"""

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

# Example usage
create_user_tool = create_api_tool(
    endpoint="https://api.example.com/users",
    method="POST",
    description="Create a new user"
)
```

## Grouping Tools

Group related tools together:

```python
# Database tool group
database_tools = [
    query_users_tool,
    update_user_tool,
    delete_user_tool
]

# Search tool group
search_tools = [
    web_search_tool,
    image_search_tool,
    news_search_tool
]

# Select based on context
if user.role == "admin":
    tools = database_tools + search_tools
else:
    tools = search_tools
```

## Summary

Tool definitions require clear and detailed docstrings, appropriate type annotations, and error handling.

## Related Pages

- [04_tool_integration_tool_node.md](04_tool_integration_tool_node.md) - Using tools in tool nodes
- [04_tool_integration_command_api.md](04_tool_integration_command_api.md) - Integration with Command API
