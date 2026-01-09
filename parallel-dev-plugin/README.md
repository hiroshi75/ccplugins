# parallel-dev-plugin

A Claude Code plugin for parallel development with multiple Claude instances.

## Overview

This plugin builds and manages a parallel development environment that leverages git worktree to enable multiple Claude instances to work on different tasks simultaneously.

### Key Features

- **Task Decomposition**: Break down feature development into independent tasks
- **Dependency Analysis**: Identify blocking relationships between tasks and calculate critical paths
- **Worktree Management**: Automatically create and manage git worktrees for each task
- **Merge Coordination**: Manage the merge order into the integration branch
- **Project Intent Management**: Maintain project-wide policies and per-worktree work context

## Usage Modes

### Mode A: Initial Parallel Development (Planning Mode)

Used immediately after project initialization to develop multiple features in parallel.

**Trigger Phrases**:
- "Create a parallel development plan"
- "I want to develop with multiple people simultaneously"
- "I want to divide work with worktree"

**Workflow**:
1. Understand requirements
2. Task decomposition
3. Dependency analysis
4. Determine parallelism
5. Branch strategy
6. Timeline creation
7. Create plan and instruction documents
8. Environment setup
9. Launch merge coordinator

### Mode B: Quick Task Mode

Mode for immediately starting bug fixes or feature additions to existing projects.

**Trigger Phrases**:
- "Fix XX in parallel"
- "Do YY with worktree"
- "Add parallel task: XX"

## Directory Structure

```
PROJECT.md               # Project-wide constitution (git-managed)

.parallel-dev/           # Parallel development management (git-managed)
├── PLAN.md              # Plan document
├── README.md            # Overall overview and progress management
├── merge-coordinator.md # Instructions for merge coordinator
└── tasks/*.md           # Instruction documents for each task

.parallel-dev-signals/   # Completion notifications (.gitignore)
.parallel-dev-issues/    # Issue reports (.gitignore)

worktrees/               # Worktrees for each task (.gitignore)
└── task-name/
    └── BRIEF.md         # Work context per worktree (.gitignore)
```

## Project Intent Management

In parallel development, context can easily be lost across multiple worktrees.
This feature maintains the higher-level context of "what we considered correct."

### File Structure

| File | Role | Commit | Update Frequency |
|---------|------|--------|---------|
| `PROJECT.md` | Project-wide constitution | ✅ Yes | Mostly immutable |
| `BRIEF.md` | Thinking notes per worktree | ❌ No | As needed |

### Setup

```bash
# Create project-wide policy
bash .claude/skills/plan-parallel-dev/scripts/init-project-intent.sh

# Create work context per worktree
bash .claude/skills/plan-parallel-dev/scripts/init-brief.sh <task-name>

# Load context
bash .claude/skills/plan-parallel-dev/scripts/load-context.sh
```

### Rules for Starting Work

When starting work in each worktree, always execute the following:

```
Please read this worktree's BRIEF.md and the project's PROJECT.md,
summarize the Mode / Focus / Non-goals / Next Bet first, then start working.
```

For details, see [skills/plan-parallel-dev/references/project-intent-guide.md](skills/plan-parallel-dev/references/project-intent-guide.md).

## Installation

```bash
# Add this plugin to the plugins directory in Claude Code settings
```

## License

MIT
