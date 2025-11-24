# Prompt Optimization Guide

A comprehensive guide for effectively optimizing prompts in LangGraph nodes.

## 📚 Table of Contents

This guide is divided into the following sections:

### 1. [Prompt Optimization Principles](./prompt_principles.md)
Learn the fundamental principles for designing prompts.

### 2. [Prompt Optimization Techniques](./prompt_techniques.md)
Provides a collection of practical optimization techniques (10 techniques).

### 3. [Optimization Priorities](./prompt_priorities.md)
Explains how to apply optimization techniques in order of improvement impact.

## 🎯 Quick Start

### First-Time Optimization

1. **[Understand the Principles](./prompt_principles.md)** - Learn the basics of clarity, structure, and specificity
2. **[Start with High-Impact Techniques](./prompt_priorities.md)** - Few-Shot Examples, output format structuring, parameter tuning
3. **[Review Technique Details](./prompt_techniques.md)** - Implementation methods and effects of each technique

### Improving Existing Prompts

1. **Measure Baseline** - Record current performance
2. **[Refer to Priority Guide](./prompt_priorities.md)** - Select the most impactful improvements
3. **[Apply Techniques](./prompt_techniques.md)** - Implement one at a time and measure effects
4. **Iterate** - Repeat the cycle of measure, implement, validate

## 📖 Related Documentation

- **[Prompt Optimization Examples](./examples.md)** - Before/After comparison examples and code templates
- **[SKILL.md](./SKILL.md)** - Overview and usage of the Fine-tune skill
- **[evaluation.md](./evaluation.md)** - Evaluation criteria design and measurement methods

## 💡 Best Practices

For effective prompt optimization:

1. ✅ **Measurement-Driven**: Evaluate all changes quantitatively
2. ✅ **Incremental Improvement**: One change at a time, measure, validate
3. ✅ **Cost-Conscious**: Optimize with model selection, caching, max_tokens
4. ✅ **Task-Appropriate**: Select techniques based on task complexity
5. ✅ **Iterative Approach**: Maintain continuous improvement cycles

## 🔍 Troubleshooting

### Low Prompt Quality
→ Review [Prompt Optimization Principles](./prompt_principles.md)

### Insufficient Accuracy
→ Apply [Few-Shot Examples](./prompt_techniques.md#technique-1-few-shot-examples) or [Chain-of-Thought](./prompt_techniques.md#technique-2-chain-of-thought)

### High Latency
→ Implement [Temperature/Max Tokens Adjustment](./prompt_techniques.md#technique-4-temperature-and-max-tokens-adjustment) or [Output Format Structuring](./prompt_techniques.md#technique-3-output-format-structuring)

### High Cost
→ Introduce [Model Selection Optimization](./prompt_techniques.md#technique-10-model-selection) or [Prompt Caching](./prompt_techniques.md#technique-6-prompt-caching)

---

**💡 Tip**: For before/after prompt comparison examples and code templates, refer to [examples.md](examples.md#phase-3-iterative-improvement-examples).
