---
name: spec-manager
description: Initialize, manage and display the application's specifications. Step 1: **Before starting any implementation**, create or update the specification documents to reflect the current design and requirements. Step 2: When significant changes occur, update the documents and notify users. Step 3: Allow users to view the updated specifications at any time.
---

# spec-manager Skill

This skill writes and displays the application's specification documents. It is used before implementation, before adding new features, or when design changes are made, to update the documents and notify users.

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
