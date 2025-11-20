# 02. グラフアーキテクチャ

6つの主要なグラフパターンとエージェント設計。

## 概要

LangGraphは様々なアーキテクチャパターンをサポートしています。問題の性質に応じて最適なパターンを選択することが重要です。

## [Workflow vs Agent](Workflow_vs_Agent.md)

まず、WorkflowとAgentの違いを理解しましょう：

- **Workflow**: 事前決定されたコードパス、特定の順序で動作
- **Agent**: 動的で自身のプロセスとツール使用を定義

## 6つの主要パターン

### 1. [Prompt Chaining（順序処理）](01_PromptChaining.md)
各LLM呼び出しが前の出力を処理。翻訳や段階的な処理に適している。

### 2. [Parallelization（並列処理）](02_Parallelization.md)
複数の独立したタスクを同時実行。速度向上や信頼性検証に使用。

### 3. [Routing（分岐処理）](03_Routing.md)
入力に基づいて専門的なフローへ振り分け。カスタマーサポートなどに最適。

### 4. [Orchestrator-Worker（マスターワーカー）](04_OrchestratorWorker.md)
オーケストレーターがタスク分解し、複数のワーカーに委譲。

### 5. [Evaluator-Optimizer（評価改善ループ）](05_EvaluatorOptimizer.md)
生成と評価を繰り返し、許容基準に達するまで反復改善。

### 6. [Agent（自律的ツール使用）](06_Agent.md)
LLMがツール選択を動的に判断し、予測不可能な問題解決に対応。

## [Subgraph（サブグラフ）](Subgraph.md)

階層的なグラフ構造を構築し、複雑なシステムをモジュール化。

## パターン選択ガイド

| パターン | 使用場面 | 例 |
|---------|---------|-----|
| Prompt Chaining | 段階的な処理 | 翻訳→要約→分析 |
| Parallelization | 独立タスクの同時実行 | 複数基準での評価 |
| Routing | タイプ別の振り分け | サポート問い合わせ分類 |
| Orchestrator-Worker | タスク分解と委譲 | 複数文書の並列処理 |
| Evaluator-Optimizer | 反復改善 | 品質向上ループ |
| Agent | 動的な問題解決 | 不確定なタスク |

## 重要な原則

1. **構造が明確ならWorkflow**: タスク構造が事前定義可能な場合
2. **不確定ならAgent**: 問題や解決策が不確定でLLMの判断が必要な場合
3. **モジュール化にはSubgraph**: 複雑なシステムは階層構造で整理

## 次のステップ

各パターンの詳細については、個別のページを参照してください。まずは[Workflow_vs_Agent.md](Workflow_vs_Agent.md)から始めることをお勧めします。
