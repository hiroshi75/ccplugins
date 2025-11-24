# Prompt Optimization Priorities

A priority guide for applying optimization techniques in order of improvement impact.

## 📊 Optimization Priorities

In order of improvement impact:

### 1. Adding Few-Shot Examples (High Impact, Low Cost)
- **Improvement**: Accuracy +10-20%
- **Cost**: +5-10% (increased input tokens)
- **Implementation Time**: 30 minutes - 1 hour
- **Recommended**: ⭐⭐⭐⭐⭐

### 2. Output Format Structuring (High Impact, Low Cost)
- **Improvement**: Latency -10-20%, Parsing errors -90%
- **Cost**: ±0%
- **Implementation Time**: 15-30 minutes
- **Recommended**: ⭐⭐⭐⭐⭐

### 3. Temperature/Max Tokens Adjustment (Medium Impact, Zero Cost)
- **Improvement**: Latency -10-30%, Cost -20-40%
- **Cost**: Reduction
- **Implementation Time**: 10-15 minutes
- **Recommended**: ⭐⭐⭐⭐⭐

### 4. Clear Instructions and Guidelines (Medium Impact, Low Cost)
- **Improvement**: Accuracy +5-10%, Quality +15-25%
- **Cost**: +2-5%
- **Implementation Time**: 30 minutes - 1 hour
- **Recommended**: ⭐⭐⭐⭐

### 5. Model Selection Optimization (High Impact, Requires Validation)
- **Improvement**: Cost -40-60%
- **Risk**: Accuracy -2-5%
- **Implementation Time**: 2-4 hours (including validation)
- **Recommended**: ⭐⭐⭐⭐

### 6. Prompt Caching (High Impact, Medium Cost)
- **Improvement**: Cost -50-90% (on cache hit)
- **Complexity**: Medium (implementation and monitoring)
- **Implementation Time**: 1-2 hours
- **Recommended**: ⭐⭐⭐⭐

### 7. Chain-of-Thought (High Impact for Specific Tasks)
- **Improvement**: Accuracy +15-30% for complex tasks
- **Cost**: +20-40%
- **Implementation Time**: 1-2 hours
- **Recommended**: ⭐⭐⭐ (complex tasks only)

### 8. Self-Consistency (Limited Use)
- **Improvement**: Accuracy +10-20%
- **Cost**: +200-300%
- **Implementation Time**: 2-3 hours
- **Recommended**: ⭐⭐ (critical decisions only)

## 🔄 Iterative Optimization Process

```
1. Measure baseline
   ↓
2. Select the most impactful improvement
   ↓
3. Implement (one change only)
   ↓
4. Evaluate (with same test cases)
   ↓
5. Is improvement confirmed?
   ├─ Yes → Keep change, go to step 2
   └─ No → Rollback change, try different improvement
   ↓
6. Goal achieved?
   ├─ Yes → Complete
   └─ No → Go to step 2
```

## Summary

For effective prompt optimization:

1. ✅ **Clarity**: Clear role, task, and output format
2. ✅ **Few-Shot Examples**: 3-7 high-quality examples
3. ✅ **Structuring**: Structured output like JSON
4. ✅ **Parameter Tuning**: Task-appropriate temperature/max_tokens
5. ✅ **Incremental Improvement**: One change at a time, measure, validate
6. ✅ **Cost-Conscious**: Model selection, caching, max_tokens
7. ✅ **Measurement-Driven**: Evaluate all changes quantitatively
