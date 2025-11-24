---
name: langgraph-master
description: Use when specifying or implementing LangGraph applications - from architecture planning and specification writing to actual code implementation. Also use for designing agent workflows or learning LangGraph patterns. This is a comprehensive guide for building AI agents with LangGraph, covering core concepts, architecture patterns, memory management, tool integration, and advanced features.
---

# LangGraph エージェント構築スキル

LangGraph を使った AI エージェントを構成するための包括的なガイド。

## 📚 学習コンテンツ

### [01. 基本概念](01_core_concepts_overview.md)

LangGraph の核となる 3 つの要素を理解する

- [State（状態）](01_core_concepts_state.md)
- [Node（ノード）](01_core_concepts_node.md)
- [Edge（エッジ）](01_core_concepts_edge.md)
- グラフベースアプローチの利点

### [02. グラフアーキテクチャ](02_graph_architecture_overview.md)

6 つの主要なグラフパターンとエージェント設計

- [Workflow vs Agent の違い](02_graph_architecture_workflow_vs_agent.md)
- [Prompt Chaining（順序処理）](02_graph_architecture_prompt_chaining.md)
- [Parallelization（並列処理）](02_graph_architecture_parallelization.md)
- [Routing（分岐処理）](02_graph_architecture_routing.md)
- [Orchestrator-Worker](02_graph_architecture_orchestrator_worker.md)
- [Evaluator-Optimizer](02_graph_architecture_evaluator_optimizer.md)
- [Agent（自律的ツール使用）](02_graph_architecture_agent.md)
- [Subgraph（サブグラフ）](02_graph_architecture_subgraph.md)

### [03. メモリ管理](03_memory_management_overview.md)

永続化とチェックポイント機能

- [Checkpointer（チェックポイント）](03_memory_management_checkpointer.md)
- [Store（長期記憶）](03_memory_management_store.md)
- [Persistence（永続化）](03_memory_management_persistence.md)

### [04. ツール統合](04_tool_integration_overview.md)

外部ツールの統合と実行制御

- [Tool Definition（ツールの定義）](04_tool_integration_tool_definition.md)
- [Command API（制御 API）](04_tool_integration_command_api.md)
- [Tool Node（ツールノード）](04_tool_integration_tool_node.md)

### [05. 応用機能](05_advanced_features_overview.md)

高度な機能と実装パターン

- [Human-in-the-Loop（承認フロー）](05_advanced_features_human_in_the_loop.md)
- [Streaming（ストリーミング）](05_advanced_features_streaming.md)
- [Map-Reduce パターン](05_advanced_features_map_reduce.md)

### [06. LLM モデル ID](06_llm_model_ids.md)

主要な LLM プロバイダーのモデル ID リファレンス。モデル ID は必ずこの文書を参考にして選んでください。この文書にないものを使ってはいけません。

- Google Gemini モデル一覧
- Anthropic Claude モデル一覧
- OpenAI GPT モデル一覧
- LangGraph での使用例とベストプラクティス

### 実装例

実践的なエージェント実装例

- [基本的なチャットボット](example_basic_chatbot.md)
- [RAG エージェント](example_rag_agent.md)

## 📖 使い方

各セクションは独立して読めますが、順番に読むことを推奨します：

1. まず「基本概念」で LangGraph の基礎を理解
2. 「グラフアーキテクチャ」で設計パターンを学習
3. 「メモリ管理」「ツール統合」で実装の詳細を把握
4. 「応用機能」で高度な機能を習得
5. 「実装例」で実践的な使い方を確認

各ファイルは短く簡潔にまとめており、必要な部分だけを参照できます。

## 🤖 効率的な実装：Subagent 活用

LangGraph アプリケーションの開発を高速化するため、専用の subagent `langgraph-master-plugin:langgraph-engineer` を活用する。

### Subagent の特徴

**langgraph-master-plugin:langgraph-engineer** は機能モジュール単位の実装に特化したエージェント：

- **機能単位のスコープ**: 完全な機能を実現する複数のノード、エッジ、状態定義をセットで実装
- **並列実行最適化**: 複数のエージェントが同時に異なる機能モジュールを開発可能な設計
- **スキル駆動**: 実装前に必ずこの langgraph-master スキルを参照
- **完全な実装**: 機能として完全に動作するモジュールを生成（TODO やプレースホルダーなし）
- **適切なサイズ**: 2-5 ノード程度の機能的なまとまり（サブグラフ、ワークフローパターン、ツール統合など）

### 使用タイミング

以下の場合に langgraph-master-plugin:langgraph-engineer を活用する：

1. **機能モジュールの実装が必要な場合**

   - アプリケーションを機能単位に分解
   - 各機能を並列実行で効率的に開発

2. **サブグラフやパターンの実装**

   - RAG 検索機能（retrieve → rerank → generate）
   - Human-in-the-Loop 承認フロー（propose → wait_approval → execute）
   - インテント分析機能（analyze → classify → route）

3. **ツール統合やメモリ設定**
   - 完全なツール統合モジュール（定義 → 実行 → 処理 → エラーハンドリング）
   - メモリ管理モジュール（チェックポイント設定 → 永続化 → 復元）

### 実践例

**タスク**: インテント分析と RAG 検索を含むチャットボットを構築

**並列実行パターン**:

```
Planner → 機能単位に分解
  ├─ langgraph-master-plugin:langgraph-engineer 1: インテント分析モジュール（並列）
  │  └─ analyze + classify + route ノード + 条件分岐エッジ
  └─ langgraph-master-plugin:langgraph-engineer 2: RAG 検索モジュール（並列）
     └─ retrieve + rerank + generate ノード + 状態管理
Orchestrator → モジュールを統合してグラフ組み立て
```

### 使用方法

1. **機能モジュールへの分解**

   - 大きな LangGraph アプリケーションを機能単位に分解
   - 各モジュールが独立して実装・テスト可能か確認
   - モジュールサイズが適切か確認（2-5 ノード程度）

2. 共通部分を先に実装

   - グラフ全体で使う状態(State)
   - 全体で使う共通のツール定義、共通ノードなど

3. **並列実行**

   langgraph-master-plugin:langgraph-engineer エージェントに 1 つの機能モジュール実装を割り当て並列実行

   - 独立した機能モジュールは同時に実装

4. **統合**
   - 完成したモジュールをグラフに組み込み
   - 統合テストで動作確認

### テスト方法

- 各機能モジュールごとにユニットテストを実施
- 統合後に全体の動作確認を実施。多くの場合.env に API キーがあるのでそれを読み込んで最低でも１回は正常系を通す
  - 正常系がうまく動かない場合、コードレビューも大事だが、おおまかに狙いをつけた箇所に適切にログを追加して原因を見極めて、よく考えた上で修正をしてください。

### 機能モジュールの例

**適切なサイズ（langgraph-master-plugin:langgraph-engineer の担当範囲）**:

- RAG 検索機能: retrieve + rerank + generate（3 ノード）
- インテント分析: analyze + classify + route（2-3 ノード）
- 承認ワークフロー: propose + wait_approval + execute（3 ノード）
- ツール統合: tool_call + execute + process + error_handling（3-4 ノード）

**小さすぎる（個別実装で十分）**:

- 単一ノードのみ
- 単一エッジのみ
- 状態フィールド定義のみ

**大きすぎる（さらに分解が必要）**:

- 完全なチャットボットアプリケーション
- 複数の独立した機能を含むシステム全体

### 注意点

- **適切なスコープ設定**: 各タスクが 1 つの機能モジュールに限定されているか確認
- **機能の独立性**: モジュール間の依存関係を最小化
- **インターフェース設計**: モジュール間の状態契約を明確に文書化
- **統合計画**: モジュール実装後の統合方法を事前に計画

## 🔗 参考リンク

- [LangGraph 公式ドキュメント](https://docs.langchain.com/oss/python/langgraph/overview)
- [LangGraph GitHub](https://github.com/langchain-ai/langgraph)
