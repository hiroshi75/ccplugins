# CCPlugins

A collection of Claude Code plugins for enhanced AI-assisted development workflows.

## Overview

This repository contains plugins designed to extend Claude Code's capabilities for specific development scenarios. Each plugin provides specialized skills, agents, and commands.

## Plugins

### langgraph-master-plugin (v0.0.8)

A comprehensive LangGraph specialist plugin for building AI agents with LangGraph.

**Skills:**

- **langgraph-master**: Complete guide for LangGraph application development

  - Core concepts (State, Node, Edge)
  - Graph architecture patterns (Prompt Chaining, Parallelization, Routing, Orchestrator-Worker, Evaluator-Optimizer, Agent, Subgraph)
  - Memory management (Checkpointer, Store, Persistence)
  - Tool integration (Tool Definition, Command API, Tool Node)
  - Advanced features (Human-in-the-Loop, Streaming, Map-Reduce)
  - LLM model ID references for Google Gemini, Anthropic Claude, and OpenAI GPT
  - Practical examples (Basic Chatbot, RAG Agent)

- **fine-tune**: Iterative prompt optimization for LangGraph nodes
  - Baseline evaluation and measurement
  - Prompt engineering techniques
  - Statistical evaluation and analysis
  - 4-phase workflow (Preparation -> Baseline -> Iterative Improvement -> Documentation)

**Agents:**

- `langgraph-engineer`: Specialized agent for implementing functional LangGraph modules (subgraphs, workflow patterns, tool integrations)

**Commands:**

- `/arch-tune`: Architecture-level tuning through parallel exploration of graph structure changes

### spec-manager-plugin (v1.1.0)

Proactive specification management plugin that automatically manages and updates application specifications when code changes occur.

**Skills:**

- **spec-manager**: Automatic specification document management

  - Proactive invocation on specification-related triggers
  - Interactive requirements clarification through guided questioning
  - Integration with development workflow
  - Support for reference URL analysis (documentation sites, AI conversations)

- **idea-structuring**: Requirements discovery and structuring

**Commands:**

- `/update-spec`: Manual specification update trigger

**Managed Documents:**

- PRD.md (Product Requirements Document)
- TechStack.md (Technology stack description)
- AppFlow.md (Application flow diagrams)
- FileStructure.md (Directory structure)
- BackendStructure.md (Backend design principles)
- FrontendGuidelines.md (Frontend design guidelines)
- DevInstructions.md (Development conventions)

## Installation

These plugins are designed for use with Claude Code. To use them:

1. Clone this repository
2. Reference the plugins in your Claude Code configuration
3. The plugins will be available through the marketplace configuration

## Repository Structure

```
ccplugins/
|-- .claude-plugin/
|   +-- marketplace.json          # Plugin registry
|-- langgraph-master-plugin/
|   |-- .claude-plugin/
|   |   +-- plugin.json           # Plugin metadata
|   |-- agents/
|   |   +-- langgraph-engineer.md # LangGraph implementation agent
|   |-- commands/
|   |   +-- arch-tune.md          # Architecture tuning command
|   +-- skills/
|       |-- langgraph-master/     # Core LangGraph skill
|       +-- fine-tune/            # Prompt optimization skill
+-- spec-manager-plugin/
    |-- .claude-plugin/
    |   +-- plugin.json           # Plugin metadata
    |-- commands/
    |   +-- update-spec.md        # Spec update command
    +-- skills/
        +-- spec-manager/         # Specification management skill
```

## Author

Hiroshi Ayukawa

## License

MIT License - see LICENSE.md for details.
