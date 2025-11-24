# 02. Graph Architecture

Six major graph patterns and agent design.

## Overview

LangGraph supports various architectural patterns. It's important to select the optimal pattern based on the nature of the problem.

## [Workflow vs Agent](02_graph_architecture_workflow_vs_agent.md)

First, understand the difference between Workflow and Agent:

- **Workflow**: Predetermined code paths, operates in a specific order
- **Agent**: Dynamic, defines its own processes and tool usage

## Six Major Patterns

### 1. [Prompt Chaining (Sequential Processing)](02_graph_architecture_prompt_chaining.md)
Each LLM call processes the previous output. Suitable for translation and stepwise processing.

### 2. [Parallelization (Parallel Processing)](02_graph_architecture_parallelization.md)
Execute multiple independent tasks simultaneously. Used for speed improvement and reliability verification.

### 3. [Routing (Branching Processing)](02_graph_architecture_routing.md)
Route to specialized flows based on input. Optimal for customer support.

### 4. [Orchestrator-Worker (Master-Worker)](02_graph_architecture_orchestrator_worker.md)
Orchestrator decomposes tasks and delegates to multiple workers.

### 5. [Evaluator-Optimizer (Evaluation-Improvement Loop)](02_graph_architecture_evaluator_optimizer.md)
Repeat generation and evaluation, iteratively improving until acceptable criteria are met.

### 6. [Agent (Autonomous Tool Usage)](02_graph_architecture_agent.md)
LLM dynamically determines tool selection, handling unpredictable problem-solving.

## [Subgraph](02_graph_architecture_subgraph.md)

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

For details on each pattern, refer to individual pages. We recommend starting with [02_graph_architecture_workflow_vs_agent.md](02_graph_architecture_workflow_vs_agent.md).
