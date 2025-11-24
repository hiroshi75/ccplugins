# langgraph-master

**PROACTIVE SKILL** - Comprehensive guide for building AI agents with LangGraph. Claude invokes this skill automatically when LangGraph development is detected, providing architecture patterns, implementation guidance, and best practices.

## Installation

```
/plugin marketplace add hiroshi75/ccplugins
/plugin install langgraph-master-plugin@hiroshi75
```

## Automatic Triggers

Claude **automatically invokes** this skill when:

- **LangGraph development** - Detecting LangGraph imports or StateGraph usage
- **Agent architecture** - Planning or implementing AI agent workflows
- **Graph patterns** - Working with nodes, edges, or state management
- **Keywords detected** - When user mentions: LangGraph, StateGraph, agent workflow, node, edge, checkpointer
- **Implementation requests** - Building chatbots, RAG agents, or autonomous systems

**No manual action required** - Claude provides LangGraph expertise automatically.

## Workflow

```
Detect LangGraph context → Auto-invoke skill → Provide patterns/guidance → Implement with best practices
```

## Manual Invocation (Optional)

To manually trigger LangGraph guidance:

```
/langgraph-master-plugin:langgraph-master
```

For learning specific patterns:

```
/langgraph-master-plugin:langgraph-master "explain routing pattern"
```

## Learning Resources

The skill provides comprehensive documentation covering:

| Category | Topics | Files |
|----------|--------|-------|
| **Core Concepts** | State, Node, Edge fundamentals | 01_core_concepts_*.md |
| **Architecture** | 6 major graph patterns (Routing, Agent, etc.) | 02_graph_architecture_*.md |
| **Memory** | Checkpointer, Store, Persistence | 03_memory_management_*.md |
| **Tools** | Tool definition, Command API, Tool Node | 04_tool_integration_*.md |
| **Advanced** | Human-in-the-Loop, Streaming, Map-Reduce | 05_advanced_features_*.md |
| **Models** | Gemini, Claude, OpenAI model IDs | 06_llm_model_ids*.md |
| **Examples** | Chatbot, RAG agent implementations | example_*.md |

## Subagent: langgraph-engineer

The skill includes a specialized **langgraph-master-plugin:langgraph-engineer** subagent for efficient parallel development:

### Key Features
- **Functional Module Scope**: Implements complete features (2-5 nodes) as cohesive units
- **Parallel Execution**: Multiple subagents can develop different modules simultaneously
- **Production-Ready**: No TODOs or placeholders, fully functional code only
- **Skill-Driven**: Always references langgraph-master documentation before implementation

### When to Use
1. **Feature Module Implementation**: RAG search, intent analysis, approval workflows
2. **Subgraph Patterns**: Complete functional units with nodes, edges, and state
3. **Tool Integration**: Full tool integration modules with error handling

### Parallel Development Pattern
```
Planner → Decompose into functional modules
  ├─ langgraph-engineer 1: Intent analysis module (parallel)
  │  └─ analyze + classify + route nodes
  └─ langgraph-engineer 2: RAG search module (parallel)
     └─ retrieve + rerank + generate nodes
Orchestrator → Integrate modules into complete graph
```

## How It Works

1. **Context Detection** - Claude monitors LangGraph-related activities
2. **Trigger Evaluation** - Checks if auto-invoke conditions are met
3. **Skill Invocation** - Automatically invokes langgraph-master skill
4. **Pattern Guidance** - Provides architecture patterns and best practices
5. **Implementation Support** - Assists with code generation using documented patterns

## Example Use Cases

### Automatic Guidance
```python
# Claude detects LangGraph usage and automatically provides guidance
from langgraph.graph import StateGraph

# Skill auto-invoked → Provides state management patterns
class AgentState(TypedDict):
    messages: list[str]
```

### Pattern Implementation
```
User: "Build a RAG agent with LangGraph"
Claude: [Auto-invokes skill]
        → Provides RAG architecture pattern
        → Suggests node structure (retrieve → rerank → generate)
        → Implements with checkpointer for state persistence
```

### Subagent Delegation
```
User: "Create a chatbot with intent classification and RAG search"
Claude: → Decomposes into 2 modules
        → Spawns langgraph-engineer for each module (parallel)
        → Integrates completed modules into final graph
```

## Benefits

- **Faster Development**: Pre-validated architecture patterns reduce trial and error
- **Best Practices**: Automatically applies LangGraph best practices and conventions
- **Parallel Implementation**: Efficient development through subagent delegation
- **Complete Documentation**: 40+ documentation files covering all aspects
- **Production-Ready**: Guidance ensures robust, maintainable implementations

## Reference Links

- [LangGraph Official Docs](https://docs.langchain.com/oss/python/langgraph/overview)
- [LangGraph GitHub](https://github.com/langchain-ai/langgraph)
