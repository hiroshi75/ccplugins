---
name: arch-tune
description: Architecture-level tuning through parallel exploration of multiple graph structure changes
---

# LangGraph Architecture Tuning Command

Boldly modify the graph structure of LangGraph applications to improve performance. Explore multiple improvement proposals in parallel to identify the optimal configuration.

## 🎯 Purpose

Optimize graph structure according to the following objectives:

```
$ARGUMENTS
```

While the **fine-tune skill** focuses on prompt and parameter optimization, the **arch-tune command** modifies the graph structure itself:

- Add/remove nodes and edges
- Introduce subgraphs
- Add parallel processing
- Change routing strategies
- Switch architectural patterns

## 📋 Execution Flow

### Initialization: Task Registration

At the start of the arch-tune command, use the TodoWrite tool to register all Phases from the following sections as tasks. (It's recommended to include a reference to this file to avoid forgetting its contents.)

Update each Phase to `in_progress` at the start and `completed` upon completion.

### Phase 1: Analysis and Proposal (arch-analysis skill)

**Execution Steps**:

1. **Launch the `arch-analysis` skill**
   - Verify/create evaluation program (`.langgraph-master/evaluation/`)
   - Measure baseline performance (3-5 runs)
   - Analyze graph structure (using Serena MCP)
   - Identify bottlenecks
   - Consider architectural patterns
   - Generate 3-5 specific improvement proposals

**Output**:

- `analysis/baseline_performance.json` - Baseline performance (including statistics)
- `analysis/analysis_report.md` - Current state analysis and issues
- `analysis/improvement_proposals.md` - Detailed improvement proposals (Proposal 1-5)
- `.langgraph-master/evaluation/` - Evaluation program (created or verified)

→ See arch-analysis skill for detailed procedures and workflow

### Phase 2: Implementation

**Purpose**: Implement graph structure for each improvement proposal

**Execution Steps**:

1. **Create and Prepare Git Worktrees**

   Create independent working environments for each improvement proposal:

   ```bash
   # Create worktree for each Proposal 1, 2, 3
   git worktree add .worktree/proposal-1 -b proposal-1
   git worktree add .worktree/proposal-2 -b proposal-2
   git worktree add .worktree/proposal-3 -b proposal-3

   # Copy analysis results and .env to each worktree
   for dir in .worktree/*/; do
     cp -r analysis "$dir"
     cp .env "$dir"
   done

   # If evaluation program is in original directory, make it executable in each worktree
   # (No copy needed if using shared .langgraph-master/evaluation/)
   ```

   **Directory Structure**:

   ```
   project/
   ├── .worktree/
   │   ├── proposal-1/          # Independent working environment 1
   │   │   ├── analysis/        # Analysis results (copy **Copy as files after creating worktree, don't commit and pass!**)
   │   │   │   ├── baseline_performance.json
   │   │   │   ├── analysis_report.md
   │   │   │   └── improvement_proposals.md
   │   │   └── [project files]
   │   ├── proposal-2/          # Independent working environment 2
   │   └── proposal-3/          # Independent working environment 3
   ├── analysis/                # Analysis results (original)
   └── [original project files]
   ```

2. **Parallel Implementation by langgraph-engineer**

   **Launch langgraph-engineer agent for each Proposal**:

   ```markdown
   Working worktree: .worktree/proposal-X/
   Improvement proposal: Proposal X (from analysis/improvement_proposals.md)
   Task: Implement graph structure changes and test that it works correctly (add/modify nodes, edges, subgraphs)

   Complete implementation as langgraph-engineer.
   See agents/langgraph-engineer.md for details.
   ```

   **Parallel Execution Pattern**:

   - Start implementation for all Proposals (1, 2, 3, ...) in parallel
   - Each langgraph-engineer agent works independently

3. **Wait for All Implementations to Complete**
   - Parent agent confirms completion of all implementations

### Phase 3: Optimization

**Purpose**: Optimize prompts and parameters for implemented graphs

**Execution Steps**:

1. **Parallel Optimization by langgraph-tuner**

   **After Phase 2 completion, launch langgraph-tuner agent for each worktree Proposal implementation**:

   ```markdown
   Working worktree: .worktree/proposal-X/
   Improvement proposal: Proposal X (from analysis/improvement_proposals.md)
   Optimization goal: [User-specified goal]

   Note: Graph structure changes are completed in Phase 2. Skip Phase 2 and start from Phase 3 (testing).

   Result report:

   - Filename: `proposal_X_result.md` (save directly under .worktree/proposal-X/)
   - Format: Summarize experiment results and insights concisely
   - Required items: Comparison table with baseline, improvement rate, key changes, recommendations

   Execute optimization workflow as langgraph-tuner.
   See agents/langgraph-tuner.md for details.
   ```

   **Parallel Execution Pattern**:

   - Start optimization for all Proposals (1, 2, 3, ...) in parallel
   - Each langgraph-tuner agent works independently

2. **Wait for All Optimizations to Complete**
   - Parent agent confirms completion of all optimizations and result report generation

**Important**:

- Use the same evaluation program across all worktrees

### Phase 4: Results Comparison (proposal-comparator agent)

**Purpose**: Identify the best improvement proposal

**Execution Steps**:

**Launch proposal-comparator agent**:

```markdown
Implementation reports: Read `proposal_X_result.md` from each worktree

- .worktree/proposal-1/proposal_1_result.md
- .worktree/proposal-2/proposal_2_result.md
- .worktree/proposal-3/proposal_3_result.md
  Optimization goal: [User-specified goal]

Execute comparative analysis as proposal-comparator.
See agents/proposal-comparator.md for details.
```

### Phase 5: Merge Confirmation (merge-coordinator agent)

**Purpose**: Merge with user approval

**Execution Steps**:

**Launch merge-coordinator agent**:

```markdown
Comparison report: analysis/comparison_report.md
Worktree: .worktree/proposal-\*/

Execute user approval and merge as merge-coordinator.
See agents/merge-coordinator.md for details.
```

## 🔧 Technical Details

### Git Worktree Commands

**Create**:

```bash
git worktree add .worktree/<branch-name> -b <branch-name>
```

**List**:

```bash
git worktree list
```

**Remove**:

```bash
git worktree remove .worktree/<branch-name>
git branch -d <branch-name>
```

### Parallel Execution Implementation

Claude Code automatically executes in parallel by calling multiple `Task` tools in a single message.

### Subagent Constraints

- ❌ Subagents cannot call other subagents
- ✅ Subagents can call skills
- → Each subagent can directly execute the fine-tune skill

## ⚠️ Notes

### Git Worktree

1. Add `.worktree/` to `.gitignore`
2. Each worktree is an independent working directory
3. No conflicts even with parallel execution

### Evaluation

1. **Evaluation Program Location**:

   - Recommended: Place in `.langgraph-master/evaluation/` (accessible from all worktrees)
   - Each worktree references the baseline copied to `analysis/`

2. **Unified Evaluation Conditions**:

   - Use the same evaluation program across all worktrees
   - Evaluate with the same test cases
   - Share environment variables (API keys, etc.)

3. **Evaluation Execution**:
   - Each langgraph-tuner agent executes evaluation independently
   - Ensure statistical reliability with 3-5 iterations
   - Each agent compares against baseline

### Cleanup

1. Delete unnecessary worktrees after merge
2. Delete branches as well
3. Verify `.worktree/` directory

## 🎓 Usage Examples

### Basic Execution Flow

```bash
# Execute arch-tune command
/arch-tune "Improve Latency to under 2.0s and Accuracy to over 90%"
```

**Execution Flow**:

1. **Phase 1**: arch-analysis skill generates 3-5 improvement proposals

   - See [arch-analysis skill](../skills/arch-analysis/SKILL.md) for detailed improvement proposals

2. **Phase 2**: Graph Structure Implementation

   - Create independent environments with Git worktree
   - langgraph-engineer implements graph structure for each Proposal in parallel

3. **Phase 3**: Prompt and Parameter Optimization

   - langgraph-tuner optimizes each Proposal in parallel
   - Generate result reports (`proposal_X_result.md`)

4. **Phase 4**: Compare results and identify best proposal

   - Display all metrics in comparison table

5. **Phase 5**: Merge after user approval
   - Merge selected proposal to main branch
   - Clean up unnecessary worktrees

**Example**: See [arch-analysis skill improvement_proposals section](../skills/arch-analysis/SKILL.md#improvement_proposalsmd) for detailed proposal examples for customer support chatbot optimization.

## 🔗 Related Resources

- [arch-analysis skill](../skills/arch-analysis/SKILL.md) - Analysis and proposal generation (Phase 1)
- [langgraph-engineer agent](../agents/langgraph-engineer.md) - Graph structure implementation (Phase 2)
- [langgraph-tuner agent](../agents/langgraph-tuner.md) - Prompt optimization and evaluation (Phase 3)
- [proposal-comparator agent](../agents/proposal-comparator.md) - Results comparison and recommendation selection (Phase 4)
- [merge-coordinator agent](../agents/merge-coordinator.md) - User approval and merge execution (Phase 5)
- [fine-tune skill](../skills/fine-tune/SKILL.md) - Prompt optimization (used by langgraph-tuner)
- [langgraph-master skill](../skills/langgraph-master/SKILL.md) - Architectural patterns
