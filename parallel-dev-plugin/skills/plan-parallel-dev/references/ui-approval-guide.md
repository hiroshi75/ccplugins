# UI Specification Approval

Approval flow guide for determining UI specifications.

**Important**: Always get human confirmation when determining UI specifications.

## UI Decisions Requiring Confirmation

Following items must not be finalized without human approval:

| Category      | Items Requiring Confirmation                                |
| ------------- | ----------------------------------------------------------- |
| Layout        | Page composition, component placement, grid design          |
| Design        | Color usage, fonts, icon selection, styling policy          |
| Interaction   | Button placement, form design, navigation structure         |
| UX Flow       | Screen transitions, operation procedures, error display     |
| Components    | New UI component design, changes to existing components     |

## Confirmation Flow

```
1. Create UI Specification Proposal
   └─→ Claude creates UI spec proposal
   └─→ Present multiple options if available

2. Request Human Confirmation
   └─→ Use AskUserQuestion tool
   └─→ Explain spec proposal concretely (wireframe-style description OK)
   └─→ Present info needed for decision (trade-offs, etc.)

3. Start Implementation After Approval
   └─→ Describe in task instruction document after human approval
   └─→ Record approved content in .parallel-dev/PLAN.md
```

## Confirmation Request Template

```markdown
【UI Specification Confirmation Request】{Feature Name}

## Overview

{What UI this confirmation is about}

## Proposed Specifications

### Option A: {Option Name}

- Layout: {Placement description}
- Behavior: {Interaction description}
- Pros: {Advantages}
- Cons: {Disadvantages}

### Option B: {Option Name} (if applicable)

...

## Decision Points

- {Points to consider when user makes decision}

## Recommendation

{Claude's recommended option and reasoning (optional)}
```

## UI Specification Confirmation for Worker Claude

When worker Claude needs to determine UI spec during task execution:

1. **Pause implementation**
2. **Record confirmation request in `.parallel-dev-issues/{branch-name}.md`**
3. **Confirm with human via merge coordinator**
4. **Resume implementation after receiving human response**

```markdown
<!-- .parallel-dev-issues/{branch-name}.md -->

【Waiting for UI Spec Confirmation】{branch-name}

## Situation

During implementation of {branch-name}, need decision on the following UI specification.

## Confirmation Items

{Confirmation content following above template}

## Current Status

- Implementation: Paused
- Waiting: UI specification approval from human
```

## Rules

- **Don't decide arbitrarily**: Human approval is mandatory for decisions about UI appearance and behavior
- **Present choices**: Present multiple options whenever possible, not single proposal
- **Explain rationale**: Clearly state pros/cons of each option
- **State recommendation explicitly**: If Claude has recommendation, state it with reasoning
- **Record approval**: Record human decision content in PLAN.md for future reference
