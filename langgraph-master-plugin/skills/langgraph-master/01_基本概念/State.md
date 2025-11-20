# State（状態）

グラフ内のすべてのノードで共有されるメモリ。

## 概要

Stateは「ノート」のようなもので、エージェントが学習したことや決定したことをすべて記録します。グラフ内のすべてのノードとエッジがアクセスできる**共有データ構造**です。

## 定義方法

### TypedDictを使用

```python
from typing import TypedDict

class State(TypedDict):
    messages: list[str]
    user_name: str
    count: int
```

### Pydanticモデルを使用

```python
from pydantic import BaseModel

class State(BaseModel):
    messages: list[str]
    user_name: str
    count: int = 0  # デフォルト値
```

## Reducer（更新方法の制御）

各キーの更新方法を指定する関数です。指定しない場合は**値の上書き**になります。

### 追加（リストへの追加）

```python
from typing import Annotated
from operator import add

class State(TypedDict):
    messages: Annotated[list[str], add]  # 既存リストに追加
    count: int  # 上書き
```

### カスタムReducer

```python
def concat_strings(existing: str, new: str) -> str:
    return existing + " " + new

class State(TypedDict):
    text: Annotated[str, concat_strings]
```

## MessagesState（LLM用プリセット）

LLMとの対話では、LangChainの`MessagesState`が便利です：

```python
from langgraph.graph import MessagesState

# これは以下と同等
class MessagesState(TypedDict):
    messages: Annotated[list[AnyMessage], add_messages]
```

`add_messages`リデューサーは：
- 新規メッセージを追加
- 既存メッセージの更新（IDベース）
- OpenAI形式のショートハンドにも対応

## 重要な原則

1. **生データを保存**: プロンプトのフォーマットはノード内で行う
2. **スキーマを明確に**: TypedDictやPydanticで型を定義
3. **Reducerで制御**: 更新方法を明示的に指定

## 例

```python
from typing import Annotated, TypedDict
from operator import add

class AgentState(TypedDict):
    # メッセージはリストに追加
    messages: Annotated[list[str], add]

    # ユーザー情報は上書き
    user_id: str
    user_name: str

    # カウンターも上書き
    iteration_count: int
```

## 関連ページ

- [Node.md](Node.md) - ノードでStateを使用する方法
- [03_メモリ管理](../03_メモリ管理/README.md) - Stateの永続化
