# parallel-dev-plugin

**Turn one Claude into a development team.**

Run 5 features in parallel. Merge automatically. Ship faster.

---

## The Problem

You have 10 tasks to complete. With traditional development:

- You work on them **one by one**
- Context switching kills productivity
- A single blocker stalls everything
- "I'll review your PR tomorrow" delays compound

What if you could run them all **at the same time**?

---

## The Solution

This plugin orchestrates **multiple Claude instances** working in parallel, each in its own git worktree, with automatic coordination and merging.

```
You: "Build user auth, payment integration, and admin dashboard in parallel"

Claude: Creates 3 worktrees, launches 3 worker instances,
        coordinates dependencies, merges completed work automatically
```

### Key Features

| Feature                     | What it does                                                    |
| --------------------------- | --------------------------------------------------------------- |
| **Task Decomposition**      | Breaks features into parallelizable units                       |
| **Dependency Analysis**     | Calculates critical path, identifies blockers                   |
| **Worktree Isolation**      | Each task gets its own git worktree                             |
| **Environment Setup**       | Copies `.env`, assigns unique ports per worktree (no conflicts) |
| **Auto-Merge Coordination** | Handles merge order and conflicts                               |

---

## Design Philosophy

### AI-First, No PRs

This plugin deliberately **skips pull requests**.

Traditional PRs are designed for human review cycles:

- Create PR → Wait for review → Address comments → Wait again → Merge

But when AI handles everything, this overhead becomes waste.

**Our approach:**

- Worker Claude completes implementation → Creates a `.done` file (a simple text file signaling completion)
- Merge Coordinator detects the file → Runs tests → Merges directly to integration branch
- Issues? Creates a new task, not a review thread

This enables **continuous integration at AI speed** — no human bottlenecks in the loop.

> Human oversight happens at the planning stage (approving the task breakdown) and the final stage (reviewing the integrated result), not at every merge.

### Full-Power Workers, Not Limited Subagents

Claude Code's built-in Task tool has a critical limitation: **subagents cannot spawn their own subagents**. This creates a shallow execution tree where complex tasks must be handled by a single agent.

This plugin takes a different approach:

```
Regular subagent:        This plugin:

Parent                   Merge Coordinator
  └── Subagent ✗           └── Worker (full Claude Code)
        └── (blocked)            ├── Subagent A
                                 ├── Subagent B
                                 └── Subagent C
```

Each worker is a **full Claude Code instance** launched via tmux, not a subagent. This means:

- **Workers can use the Task tool** to spawn their own subagents
- **Parallel exploration within each task** — search, analyze, implement simultaneously
- **No depth limits** — workers have the same capabilities as the parent
- **Full tool access** — every worker can use all available MCP tools and skills

The result: each parallel task gets the full power of Claude Code, not a watered-down subprocess.

---

## Quick Start

### 1. Install the plugin

```bash
# Clone to your Claude Code plugins directory
git clone https://github.com/yourrepo/parallel-dev-plugin ~/.claude/plugins/parallel-dev-plugin
```

### 2. Launch Claude Code inside tmux

Workers are spawned as new tmux windows, so you must start from within tmux:

```bash
tmux new -s dev
cd your-project
claude
```

### 3. Start parallel development

**Option A: MVP Build Mode** (build a complete product from scratch)

```
"Build an MVP with user authentication, payment processing, and notification system"
```

**Option B: Quick task mode** (for immediate tasks)

```
"Fix the login bug and add logout button in parallel"
```

### 4. Watch it work

Claude will:

1. Decompose tasks and analyze dependencies
2. Create worktrees for each task
3. Launch worker instances via tmux
4. Monitor completion signals
5. Merge in correct order
6. Report final status

---

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    Merge Coordinator                        │
│  (monitors .done signals, manages merge order, runs tests)  │
└─────────────────────┬───────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   ┌─────────┐   ┌─────────┐   ┌─────────┐
   │Worker 1 │   │Worker 2 │   │Worker 3 │
   │(auth)   │   │(payment)│   │(admin)  │
   └────┬────┘   └────┬────┘   └────┬────┘
        │             │             │
   worktree/        worktree/          worktree/
   feat-auth/       feat-payment/      feat-admin/
```

**Worker Claude**: Focuses only on implementation. No commits, no pushes — just code.

**Merge Coordinator**: Handles all git operations, testing, and integration.

---

## Usage Modes

### Mode A: MVP Build Mode

For building a complete product from scratch to working MVP in one shot.

**Trigger phrases:**

- "Build an MVP with these features"
- "Create a parallel development plan for this project"
- "Develop the entire system from scratch"

**What happens:**

1. Requirements analysis and architecture design
2. Task decomposition with dependency mapping
3. Critical path calculation for optimal parallelism
4. Worktree and branch setup for all tasks
5. Worker launch, coordination, and automatic merging
6. Integrated MVP ready for review

### Mode B: Quick Task Mode

For immediate bug fixes or small features.

**Trigger phrases:**

- "Fix X and Y in parallel"
- "Add these tasks to parallel development"
- "Run these with worktree"

**What happens:**

1. Instant worktree creation
2. Minimal task instruction generation
3. Worker launch
4. Merge on completion

---

## Directory Structure

```
your-project/
├── src/                        # Your existing source code
│   └── ...
├── package.json                # Your existing config files
├── ...                         # (other project files)
│
├── .parallel-dev/              # Git-tracked planning docs
│   ├── PLAN.md                 # Overall development plan
│   ├── README.md               # Progress dashboard
│   ├── merge-coordinator.md    # Coordinator instructions
│   └── tasks/
│       ├── auth-system.md      # Task: Authentication
│       ├── payment-api.md      # Task: Payment
│       └── admin-panel.md      # Task: Admin
│
├── .parallel-dev-signals/      # Gitignored, file-based signals
│   └── auth-system.done        # Simple text file: "I'm done, here's what I did"
│
├── .parallel-dev-issues/       # Gitignored issue reports
│   └── payment-api.md          # Issue requiring attention
│
└── worktree/                   # Gitignored worktrees
    ├── feat-auth-system/       # Full copy of project + isolated branch
    │   ├── src/
    │   ├── package.json
    │   ├── .env                # Copied from parent
    │   ├── .env.local          # Unique ports for this worktree
    │   └── ...
    ├── feat-payment-api/
    └── feat-admin-panel/
```

---

## When to Use This

**Good fit:**

- Multiple independent features to build
- Bug fixes that don't conflict
- Refactoring across different modules
- Any work that can be parallelized

**Not ideal for:**

- Highly interdependent changes to the same files
- Tasks requiring extensive human deliberation
- Single, focused changes (just use regular Claude)

---

## FAQ

**Q: What if two workers edit the same file?**  
A: The merge coordinator handles conflicts.

**Q: How many workers can run in parallel?**  
A: Practically 3-5 works well. More workers = more coordination overhead.

**Q: Can I intervene during parallel development?**  
A: Yes. Check `.parallel-dev/README.md` for status. Stop workers with `tmux kill-window -t <task-name>`.

**Q: What about code review?**  
A: Review the integrated result on the integration branch. The AI handles task-level verification.

---

## License

MIT

---

## See Also

- [SKILL.md](skills/plan-parallel-dev/SKILL.md) — Detailed skill specification
- [Worktree Guide](skills/plan-parallel-dev/references/worktree-guide.md) — Git worktree deep dive
- [Quick Mode Guide](skills/plan-parallel-dev/references/quick-mode-guide.md) — Mode B details
