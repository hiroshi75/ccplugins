# 02. Graph Architecture

Six major graph patterns and agent design.

## Overview

LangGraph supports various architectural patterns. It's important to select the optimal pattern based on the nature of the problem.

## [Workflow vs Agent](Workflow_vs_Agent.md)

First, understand the difference between Workflow and Agent:

- **Workflow**: Predetermined code paths, operates in a specific order
- **Agent**: Dynamic, defines its own processes and tool usage

## Six Major Patterns

### 1. [Prompt Chaining (Sequential Processing)](01_PromptChaining.md)
Each LLM call processes the previous output. Suitable for translation and stepwise processing.

### 2. [Parallelization (Parallel Processing)](02_Parallelization.md)
Execute multiple independent tasks simultaneously. Used for speed improvement and reliability verification.

### 3. [Routing (Branching Processing)](03_Routing.md)
Route to specialized flows based on input. Optimal for customer support.

### 4. [Orchestrator-Worker (Master-Worker)](04_OrchestratorWorker.md)
Orchestrator decomposes tasks and delegates to multiple workers.

### 5. [Evaluator-Optimizer (Evaluation-Improvement Loop)](05_EvaluatorOptimizer.md)
Repeat generation and evaluation, iteratively improving until acceptable criteria are met.

### 6. [Agent (Autonomous Tool Usage)](06_Agent.md)
LLM dynamically determines tool selection, handling unpredictable problem-solving.

## [Subgraph](Subgraph.md)

Build hierarchical graph structures and modularize complex systems.

## Pattern Selection Guide

| Pattern | Use Case | Example |
|---------|----------|---------|
| Prompt Chaining | Stepwise processing | Translation → Summary → Analysis |
| Parallelization | Simultaneous execution of independent tasks | Evaluation by multiple criteria |
| Routing | Type-based routing | Support inquiry classification |
| Orchestrator-Worker | Task decomposition and delegation | Parallel processing of multiple documents |
| Evaluator-Optimizer | Iterative improvement | Quality improvement loop |
| Agent | Dynamic problem solving | Uncertain tasks |

## Important Principles

1. **Workflow if structure is clear**: When task structure can be predefined
2. **Agent if uncertain**: When problem or solution is uncertain and LLM judgment is needed
3. **Subgraph for modularization**: Organize complex systems with hierarchical structure

## Next Steps

For details on each pattern, refer to individual pages. We recommend starting with [Workflow_vs_Agent.md](Workflow_vs_Agent.md).
