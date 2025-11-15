# spec-manager

**PROACTIVE SKILL** - Automatically manage and update application specification documents. Claude invokes this skill automatically when code changes occur or specifications need updating, keeping your documentation synchronized with your codebase.

## Installation

```
/plugin marketplace add hiroshi75/ccplugins
/plugin install spec-manager-plugin@hiroshi75
```

## Automatic Triggers

Claude **automatically invokes** this skill when:

- **Starting features** - Before implementing new functionality
- **Completing changes** - After modifying 3+ files or major features
- **Refactoring** - When architecture or project structure changes
- **Keywords detected** - When user mentions: 仕様, spec, design, architecture, requirements, PRD
- **Session end** - After development sessions with substantial changes

**No manual action required** - Claude keeps specifications synchronized automatically.

## Workflow

```
Detect changes → Auto-invoke skill → Update .spec-manager/ docs → Notify user
```

## Manual Invocation (Optional)

To manually trigger specification updates:

```
/spec-manager-plugin:update-spec
```

With language preference:

```
/spec-manager-plugin:update-spec 日本語で
```

## Specification Documents

The following documents are maintained in `.spec-manager/`:

| Document | Required | Description |
|----------|----------|-------------|
| **PRD.md** | Yes | Product Requirements Document |
| **AppFlow.md** | Yes | Application flow and screen transitions |
| **TechStack.md** | Yes | Technologies and dependencies used |
| **FileStructure.md** | No | Project directory structure |
| **FrontendGuidelines.md** | No | Frontend design principles |
| **BackendStructure.md** | No | Backend architecture and DB/Storage |
| **DevInstructions.md** | No | Development conventions and rules |

## How It Works

1. **Change Detection** - Claude monitors development activities
2. **Trigger Evaluation** - Checks if auto-invoke conditions are met
3. **Skill Invocation** - Automatically invokes spec-manager skill
4. **Document Update** - Updates relevant specification documents
5. **User Notification** - Reports what was updated with summary

## Example Notification

After automatic invocation, you'll see:

```
Specification documents have been automatically updated:
- PRD.md: Added authentication feature requirements
- TechStack.md: Updated with JWT library dependencies
- FileStructure.md: Reflected new auth/ directory structure
```
