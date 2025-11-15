# spec-manager

This skill manages and displays the application's specification documents. **Claude automatically invokes this skill** when specifications become clearer during development or when major code changes occur, keeping your documentation synchronized with your codebase.

## Installation

```
/plugin marketplace add hiroshi75/ccplugins
/plugin install spec-manager-plugin@hiroshi75
```

## Automatic Usage

**This skill works automatically!** Claude will invoke it proactively when:

- 🚀 Starting new feature development
- ✅ Completing significant code changes (3+ files modified)
- 🏗️ Making architectural or structural changes
- 📝 Detecting specification-related keywords in conversation
- 🔄 Ending development sessions with substantial changes

You don't need to manually trigger it - Claude will keep your specifications up-to-date automatically.

## Manual Usage (Optional)

If you want to manually trigger specification updates:

```
/spec-manager-plugin:update-spec
```

Or if you prefer other languages:

```
/spec-manager-plugin:update-spec 日本語で
```

## How It Works

1. **Automatic Detection**: Claude monitors your development activities
2. **Smart Triggering**: When trigger conditions are met, Claude automatically invokes this skill
3. **Specification Sync**: Documents in `.spec-manager/` are updated to reflect code changes
4. **User Notification**: You receive a summary of what was updated

## Specification Documents

The following documents are automatically maintained in `.spec-manager/`:

- **PRD.md** - Product Requirements Document
- **AppFlow.md** - Application flow and screen transitions
- **TechStack.md** - Technologies and dependencies used
- **FileStructure.md** - Project directory structure
- **FrontendGuidelines.md** - Frontend design principles (if applicable)
- **BackendStructure.md** - Backend architecture (if applicable)
- **DevInstructions.md** - Development conventions and rules
