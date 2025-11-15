---
name: spec-manager
description: |
  **PROACTIVE SKILL** - Automatically manage and update application specifications.

  Auto-invoke when: Starting features | Completing changes (3+ files) | Refactoring | Keywords detected (仕様/spec/design/architecture/requirements/PRD) | Session end with changes

  Workflow: Detect changes → Auto-invoke → Update .spec-manager/ docs → Notify user
---

# spec-manager Skill

This skill writes and displays the application's specification documents. It is used before implementation, before adding new features, or when design changes are made, to update the documents and notify users.

## Proactive Usage Guidelines

**IMPORTANT**: This skill should be invoked **automatically and proactively** by Claude without waiting for explicit user requests.

### When to Automatically Invoke This Skill

#### 1. Before Implementation Phase
- User requests new feature development
- Planning to add new components or modules
- Starting a new development session on the project
- **Action**: Invoke this skill to ensure specifications are current before coding

#### 2. After Significant Changes
Automatically invoke when you detect:
- ✅ **Completed implementation** of new features or components
- ✅ **Modified 3 or more files** in a single task
- ✅ **Major refactoring** that changes architecture or structure
- ✅ **New directories created** or project structure reorganized
- ✅ **User-facing features added** that affect application behavior
- **Action**: Invoke this skill immediately after completion, before marking tasks as done

#### 3. Keyword Detection
When user mentions any of these terms (in any language):
- 仕様 / spec / specification
- 設計 / design / architecture
- 要件 / requirements / PRD
- ドキュメント / documentation / docs
- **Action**: Proactively suggest or automatically update specifications

#### 4. Session Lifecycle Events
- End of development session with substantial changes
- Before creating pull requests or commits for major features
- After completing a TodoWrite task list with multiple implementation tasks
- **Action**: Invoke to synchronize code changes with specification documents

### How to Invoke Proactively

When conditions are met, Claude should:

1. **Detect the trigger condition** (e.g., completed 5 file changes for new auth feature)
2. **Automatically invoke this skill** without asking for permission first
3. **Update specification documents** in `.spec-manager/` directory
4. **Notify the user** with a summary like:
   ```
   📝 Specification documents have been automatically updated:
   - PRD.md: Added authentication feature requirements
   - TechStack.md: Updated with JWT library dependencies
   - FileStructure.md: Reflected new auth/ directory structure
   ```

### What NOT to Do

❌ **Don't wait** for explicit `/spec-manager` command after every change
❌ **Don't ask** "Should I update the specifications?" - just do it proactively
❌ **Don't ignore** completed implementations - always sync specifications
❌ **Don't skip** specification updates when user is focused on coding

### Integration with Development Workflow

```
Development Flow:
1. User requests feature → Invoke spec-manager (initialize/review specs)
2. Implement feature → Track changes
3. Complete implementation → Invoke spec-manager (auto-update specs)
4. Mark task complete → Specifications already synchronized ✅
```

## Location for Saving Specifications

Specification documents are saved in the `.spec-manager` directory at the project root.

The following documents are stored (Do not change the following file names):

- .spec-manager/PRD.md: _Required_ Product Requirements Document
- .spec-manager/AppFlow.md: _Required_ Application screen transition and flow diagrams
- .spec-manager/TechStack.md: _Required_ Description of the technologies used
- .spec-manager/FileStructure.md: Directory structure (excluding `.claude`, `node_modules`, etc.)
- .spec-manager/FrontendGuidelines.md: (If applicable) Design principles and guidelines for the frontend
- .spec-manager/BackendStructure.md: (If applicable) Design principles and guidelines for the backend, such as DB and Storage structures
- .spec-manager/DevInstructions.md: Rules file. A natural language document describing the conventions and development rules that should be followed by the AI agents in this project.

You can write other specification documents as needed, but **the documents listed above are mandatory**.

So if those files do not exist, please create them first.
