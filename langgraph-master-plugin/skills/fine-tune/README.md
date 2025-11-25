# LangGraph Fine-Tune Skill

A comprehensive skill for iteratively optimizing prompts and processing logic in LangGraph applications based on evaluation criteria.

## Overview

The fine-tune skill helps you improve the performance of existing LangGraph applications through systematic prompt optimization without modifying the graph structure (nodes, edges configuration).

## Key Features

- **Iterative Optimization**: Data-driven improvement cycles with measurable results
- **Graph Structure Preservation**: Only optimize prompts and node logic, not the graph architecture
- **Statistical Evaluation**: Multiple runs with statistical analysis for reliable results
- **MCP Integration**: Leverages Serena MCP for codebase analysis and target identification

## When to Use

- LLM output quality needs improvement
- Response latency is too high
- Cost optimization is required
- Error rates need reduction
- Prompt engineering improvements are expected to help

## 4-Phase Workflow

### Phase 1: Preparation and Analysis

Understand optimization targets and current state.

- Load objectives from `.langgraph-master/fine-tune.md`
- Identify optimization targets using Serena MCP
- Create prioritized optimization target list

### Phase 2: Baseline Evaluation

Quantitatively measure current performance.

- Prepare evaluation environment (test cases, scripts)
- Measure baseline (3-5 runs recommended)
- Analyze results and identify problems

### Phase 3: Iterative Improvement

Data-driven incremental improvement cycle.

- Prioritize improvement areas by impact
- Implement prompt optimizations
- Re-evaluate under same conditions
- Compare results and decide next steps
- Repeat until goals are achieved

### Phase 4: Completion and Documentation

Record achievements and provide recommendations.

- Create final evaluation report
- Commit code changes
- Update documentation

## Key Optimization Techniques

| Technique                         | Expected Impact             |
| --------------------------------- | --------------------------- |
| Few-Shot Examples                 | Accuracy +10-20%            |
| Structured Output Format          | Parsing errors -90%         |
| Temperature/Max Tokens Adjustment | Cost -20-40%                |
| Model Selection Optimization      | Cost -40-60%                |
| Prompt Caching                    | Cost -50-90% (on cache hit) |

## Best Practices

1. **Start Small**: Begin with the most impactful node
2. **Measurement-Driven**: Always quantify before and after improvements
3. **Incremental Changes**: Validate one change at a time
4. **Document Everything**: Record reasons and results for each change
5. **Iterate**: Continue improving until goals are achieved

## Important Constraints

- **Preserve Graph Structure**: Do not add/remove nodes or edges
- **Maintain Data Flow**: Do not change data flow between nodes
- **Keep State Schema**: Maintain the existing state schema
- **Evaluation Consistency**: Use same test cases and metrics throughout
