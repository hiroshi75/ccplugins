# Fine-Tuning Workflow Details

Detailed workflow and practical guidelines for executing fine-tuning of LangGraph applications.

**💡 Tip**: For concrete code examples and templates you can copy and paste, refer to [examples.md](examples.md).

## 📋 Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: Preparation and Analysis                           │
├─────────────────────────────────────────────────────────────┤
│ 1. Read fine-tune.md → Understand goals and criteria        │
│ 2. Identify optimization targets with Serena → List LLM nodes│
│ 3. Create optimization list → Assess improvement potential  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 2: Baseline Evaluation                                │
├─────────────────────────────────────────────────────────────┤
│ 4. Prepare evaluation environment → Test cases, scripts     │
│ 5. Measure baseline → Run 3-5 times, collect statistics     │
│ 6. Analyze results → Identify issues, assess improvement    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 3: Iterative Improvement (Iteration Loop)             │
├─────────────────────────────────────────────────────────────┤
│ 7. Prioritize → Select most effective improvement area      │
│ 8. Implement improvements → Optimize prompts, adjust params │
│ 9. Post-improvement evaluation → Re-evaluate same conditions│
│ 10. Compare results → Measure improvement, decide next step │
│ 11. Continue decision → Goal met? Yes → Phase 4 / No → Next │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 4: Completion and Documentation                       │
├─────────────────────────────────────────────────────────────┤
│ 12. Create final evaluation report → Summary of improvements│
│ 13. Commit code → Version control and documentation update  │
└─────────────────────────────────────────────────────────────┘
```

## 📚 Phase-by-Phase Detailed Guide

### [Phase 1: Preparation and Analysis](./workflow_phase1.md)
Clarify optimization direction and identify targets for improvement:
- **Step 1**: Read and understand fine-tune.md
- **Step 2**: Identify optimization targets with Serena MCP
- **Step 3**: Create optimization target list

**Time Required**: 30 minutes - 1 hour

### [Phase 2: Baseline Evaluation](./workflow_phase2.md)
Quantitatively measure current performance:
- **Step 4**: Prepare evaluation environment
- **Step 5**: Measure baseline (3-5 runs)
- **Step 6**: Analyze baseline results

**Time Required**: 1-2 hours

### [Phase 3: Iterative Improvement](./workflow_phase3.md)
Data-driven, incremental prompt optimization:
- **Step 7**: Prioritization
- **Step 8**: Implement improvements
- **Step 9**: Post-improvement evaluation
- **Step 10**: Compare results
- **Step 11**: Continue decision

**Time Required**: 1-2 hours per iteration × number of iterations (typically 3-5)

### [Phase 4: Completion and Documentation](./workflow_phase4.md)
Record final results and commit code:
- **Step 12**: Create final evaluation report
- **Step 13**: Commit code and update documentation

**Time Required**: 30 minutes - 1 hour

## 🎯 Workflow Execution Points

### For First-Time Fine-Tuning

1. **Start from Phase 1 in order**: Execute all phases without skipping
2. **Create documentation**: Record results from each phase
3. **Start small**: Experiment with a small number of test cases initially

### Continuous Fine-Tuning

1. **Start from Phase 2**: Measure new baseline
2. **Repeat Phase 3**: Continuous improvement cycle
3. **Consider automation**: Build evaluation pipeline

## 📊 Principles for Success

1. **Data-Driven**: Base all decisions on measurement results
2. **Incremental Improvement**: One change at a time, measure, verify
3. **Documentation**: Record results and learnings from each phase
4. **Statistical Verification**: Run multiple times to confirm significance

## 🔗 Related Documents

- **[Example Collection](./examples.md)** - Code examples and templates for each phase
- **[Evaluation Methods](./evaluation.md)** - Details on evaluation metrics and statistical analysis
- **[Prompt Optimization](./prompt_optimization.md)** - Detailed optimization techniques
- **[SKILL.md](./SKILL.md)** - Overview of the Fine-tune skill

## 💡 Troubleshooting

### Cannot find optimization targets in Phase 1
→ Check search patterns in [workflow_phase1.md#step-2](./workflow_phase1.md#step-2-identify-optimization-targets-with-serena-mcp)

### Evaluation script fails in Phase 2
→ Check checklist in [workflow_phase2.md#step-4](./workflow_phase2.md#step-4-prepare-evaluation-environment)

### No improvement effect in Phase 3
→ Review priority matrix in [workflow_phase3.md#step-7](./workflow_phase3.md#step-7-prioritization)

### Report creation takes too long in Phase 4
→ Utilize templates in [workflow_phase4.md#step-12](./workflow_phase4.md#step-12-create-final-evaluation-report)

---

Following this workflow enables:
- ✅ Systematic fine-tuning process execution
- ✅ Data-driven decision making
- ✅ Continuous improvement and verification
- ✅ Complete documentation and traceability
