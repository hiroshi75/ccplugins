# Fine-Tuning Practical Examples Collection

A collection of specific code examples and markdown templates used for LangGraph application fine-tuning.

## 📋 Table of Contents

This guide is divided by Phase:

### [Phase 1: Preparation and Analysis Examples](./examples_phase1.md)
Templates and code examples used in the optimization preparation phase:
- **Example 1.1**: fine-tune.md structure example
- **Example 1.2**: Optimization target list example
- **Example 1.3**: Code search example with Serena MCP

**Estimated Time**: 30 minutes - 1 hour

### [Phase 2: Baseline Evaluation Examples](./examples_phase2.md)
Scripts and report examples used for current performance measurement:
- **Example 2.1**: Evaluation script (evaluator.py)
- **Example 2.2**: Baseline measurement script (baseline_evaluation.sh)
- **Example 2.3**: Baseline results report

**Estimated Time**: 1-2 hours

### [Phase 3: Iterative Improvement Examples](./examples_phase3.md)
Practical examples of prompt optimization and result comparison:
- **Example 3.1**: Before/After prompt comparison
- **Example 3.2**: Prioritization matrix
- **Example 3.3**: Iteration results report

**Estimated Time**: 1-2 hours per iteration × number of iterations

### [Phase 4: Completion and Documentation Examples](./examples_phase4.md)
Examples of recording final results and version control:
- **Example 4.1**: Final evaluation report (complete version)
- **Example 4.2**: Git commit message examples

**Estimated Time**: 30 minutes - 1 hour

## 🎯 How to Use

### For First-Time Implementation

1. **Start with [Phase 1 examples](./examples_phase1.md)** - Copy and use templates
2. **Set up [Phase 2 evaluation scripts](./examples_phase2.md)** - Customize for your environment
3. **Iterate using [Phase 3 comparison examples](./examples_phase3.md)** - Record Before/After
4. **Document with [Phase 4 report](./examples_phase4.md)** - Summarize final results

### Copy & Paste Ready

Each example includes complete code and templates:
- Python scripts → Ready to execute as-is
- Bash scripts → Set environment variables and run
- Markdown templates → Fill in content and use
- JSON structures → Templates for test cases and reports

## 📊 Types of Examples

### Code Scripts
- **Evaluation scripts** (Phase 2): evaluator.py, aggregate_results.py
- **Measurement scripts** (Phase 2): baseline_evaluation.sh
- **Analysis scripts** (Phase 1): Serena MCP search examples

### Markdown Templates
- **fine-tune.md** (Phase 1): Goal setting
- **Optimization target list** (Phase 1): Organizing improvement targets
- **Baseline results report** (Phase 2): Current state analysis
- **Iteration results report** (Phase 3): Improvement effect measurement
- **Final evaluation report** (Phase 4): Overall summary

### Comparison Examples
- **Before/After prompts** (Phase 3): Specific improvement examples
- **Prioritization matrix** (Phase 3): Decision-making records

## 🔍 Finding Examples

### By Purpose

| Purpose | Phase | Example |
|---------|-------|---------|
| Set goals | Phase 1 | [Example 1.1](./examples_phase1.md#example-11-fine-tunemd-structure-example) |
| Find optimization targets | Phase 1 | [Example 1.3](./examples_phase1.md#example-13-code-search-example-with-serena-mcp) |
| Create evaluation scripts | Phase 2 | [Example 2.1](./examples_phase2.md#example-21-evaluation-script) |
| Measure baseline | Phase 2 | [Example 2.2](./examples_phase2.md#example-22-baseline-measurement-script) |
| Improve prompts | Phase 3 | [Example 3.1](./examples_phase3.md#example-31-beforeafter-prompt-comparison) |
| Determine priorities | Phase 3 | [Example 3.2](./examples_phase3.md#example-32-prioritization-matrix) |
| Write final report | Phase 4 | [Example 4.1](./examples_phase4.md#example-41-final-evaluation-report) |
| Git commit | Phase 4 | [Example 4.2](./examples_phase4.md#example-42-git-commit-message-examples) |

## 🔗 Related Documentation

- **[Workflow](./workflow.md)** - Detailed procedures for each Phase
- **[Evaluation Methods](./evaluation.md)** - Evaluation metrics and statistical analysis
- **[Prompt Optimization](./prompt_optimization.md)** - Detailed optimization techniques
- **[SKILL.md](./SKILL.md)** - Overview of the Fine-tune skill

## 💡 Tips

### Customization Points

1. **Number of test cases**: Examples use 20 cases, but adjust according to your project
2. **Number of runs**: 3-5 runs recommended for baseline measurement, but adjust based on time constraints
3. **Target values**: Set Accuracy, Latency, and Cost targets according to project requirements
4. **Model**: Adjust pricing if using models other than Claude 3.5 Sonnet

### Frequently Asked Questions

**Q: Can I use the example code as-is?**
A: Yes, it's executable once you set environment variables (API keys, etc.).

**Q: Can I edit the templates?**
A: Yes, please customize freely according to your project.

**Q: Can I skip phases?**
A: We recommend executing all phases on the first run. From the second run onward, you can start from Phase 2.

---

**💡 Tip**: For detailed procedures of each Phase, refer to the [Workflow](./workflow.md).
