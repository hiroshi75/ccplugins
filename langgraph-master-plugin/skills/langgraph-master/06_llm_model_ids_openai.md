# OpenAI GPT モデル ID

OpenAI API で使用可能なモデル ID 一覧。

> **最終更新**: 2025-11-24

## モデル一覧

### GPT-5 シリーズ

> **リリース**: 2025年8月

| モデル ID | コンテキスト | 最大出力 | 特徴 |
|-----------|------------|---------|------|
| `gpt-5` | 400K | 128K | フル機能。高品質な汎用タスク |
| `gpt-5-pro` | 400K | 272K | 拡張推論版。複雑な企業・研究用途 |
| `gpt-5-mini` | 400K | 128K | 小型高速版。低レイテンシ |
| `gpt-5-nano` | 400K | 128K | 超軽量版。リソース最適化 |

**性能**: AIME 2025で94.6%、SWE-bench Verifiedで74.9%を達成
**注**: コンテキストウィンドウは入力+出力の合計長

### GPT-5.1 シリーズ（最新アップデート）

| モデル ID | コンテキスト | 最大出力 | 特徴 |
|-----------|------------|---------|------|
| `gpt-5.1` | 128K (ChatGPT) / 400K (API) | 128K | 知性と速度のバランス |
| `gpt-5.1-instant` | 128K / 400K | 128K | 適応的推論。速度と精度を両立 |
| `gpt-5.1-thinking` | 128K / 400K | 128K | 問題の複雑さに応じて思考時間を調整 |
| `gpt-5.1-mini` | 128K / 400K | 128K | 小型版 |
| `gpt-5.1-codex` | 400K | 128K | コード特化版（GitHub Copilot用） |
| `gpt-5.1-codex-mini` | 400K | 128K | コード特化小型版 |

## 基本的な使用方法

```python
from langchain_openai import ChatOpenAI

# 最新: GPT-5
llm = ChatOpenAI(model="gpt-5")

# 最新アップデート: GPT-5.1
llm = ChatOpenAI(model="gpt-5.1")

# 高性能: GPT-5 Pro
llm = ChatOpenAI(model="gpt-5-pro")

# コスト重視: 小型版
llm = ChatOpenAI(model="gpt-5-mini")

# 超軽量
llm = ChatOpenAI(model="gpt-5-nano")
```

### 環境変数

```bash
export OPENAI_API_KEY="sk-..."
```

## モデル選択ガイド

| 用途 | 推奨モデル |
|------|-----------|
| **最高性能** | `gpt-5-pro` |
| **汎用タスク** | `gpt-5` または `gpt-5.1` |
| **コスト重視** | `gpt-5-mini` |
| **超軽量** | `gpt-5-nano` |
| **適応的推論** | `gpt-5.1-instant` または `gpt-5.1-thinking` |
| **コード生成** | `gpt-5.1-codex` または `gpt-5` |

## GPT-5 の特徴

### 1. 大規模コンテキストウィンドウ

GPT-5 シリーズは **400K トークン**のコンテキストウィンドウを持つ：

```python
llm = ChatOpenAI(
    model="gpt-5",
    max_tokens=128000  # 最大出力: 128K
)

# GPT-5 Pro は最大出力が 272K
llm_pro = ChatOpenAI(
    model="gpt-5-pro",
    max_tokens=272000
)
```

**用途**:
- 長文ドキュメントの一括処理
- 大規模コードベースの分析
- 長期的な会話履歴の保持

### 2. ソフトウェアオンデマンド生成

```python
llm = ChatOpenAI(model="gpt-5")
response = llm.invoke("Webアプリケーションを生成して")
```

### 3. 高度な推論能力

**性能指標**:
- AIME 2025: 94.6%
- SWE-bench Verified: 74.9%
- Aider Polyglot: 88%
- MMMU: 84.2%

### 4. GPT-5.1 適応的推論

問題の複雑さに応じて思考時間を自動調整：

```python
# 速度と精度のバランス
llm = ChatOpenAI(model="gpt-5.1-instant")

# 深い思考が必要なタスク
llm = ChatOpenAI(model="gpt-5.1-thinking")
```

**Compaction 技術**: GPT-5.1 では実質的により長い文脈を扱える技術が導入されています。

### 5. GPT-5 Pro - 拡張推論

企業・研究環境向けの高度な推論。**最大出力 272K トークン**：

```python
llm = ChatOpenAI(
    model="gpt-5-pro",
    max_tokens=272000  # 他モデルより大きい出力が可能
)
# より詳細で信頼性の高い回答
```

### 6. コード特化モデル

```python
# GitHub Copilot で使用
llm = ChatOpenAI(model="gpt-5.1-codex")

# 小型版
llm = ChatOpenAI(model="gpt-5.1-codex-mini")
```

## マルチモーダル対応

GPT-5 は画像・音声に対応（詳細は[高度な機能](06_llm_model_ids_openai_advanced.md)を参照）。

## JSON モード

構造化された出力が必要な場合：

```python
llm = ChatOpenAI(
    model="gpt-5",
    model_kwargs={"response_format": {"type": "json_object"}}
)
```

## モデル一覧の取得

```python
from openai import OpenAI
import os

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
models = client.models.list()

for model in models:
    if model.id.startswith("gpt-5"):
        print(model.id)
```

## 詳細ドキュメント

高度な設定、ビジョン機能、Azure OpenAI については：
- **[OpenAI 高度な機能](06_llm_model_ids_openai_advanced.md)**

## 参考リンク

- [OpenAI GPT-5](https://openai.com/index/introducing-gpt-5/)
- [OpenAI GPT-5.1](https://openai.com/index/gpt-5-1/)
- [OpenAI Platform](https://platform.openai.com/)
- [LangChain Integration](https://docs.langchain.com/oss/python/integrations/chat/openai)
