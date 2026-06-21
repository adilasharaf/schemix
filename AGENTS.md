# Schemix Agent Guidelines

Welcome, AI Agent! This repository uses specific instructions and context files to help you work effectively with the **Schemix** codebase. Schemix is a Dart code generation framework that produces Zod schemas, TypeScript interfaces, Drift tables, and Drizzle schemas from annotated classes.

## Agent Context Files

Depending on which agent model you are, please refer to your specific instructions:

- [Gemini Context](.agents/GEMINI.md)
- [Claude Context](.agents/CLAUDE.md)

## Universal Guardrails

All agents must strictly adhere to the project guardrails before proposing changes:

- [Guardrails](.agents/GUARDRAILS.md)

## Architecture & Rules

To maintain consistency and correctness, review the following rules and architecture documents:

- **[Architecture](.agents/rules/architecture.md)**: Details the 3-phase build pipeline (Scan, Generate, Index) and `TypeGraph` abstraction.
- **[Patterns](.agents/rules/patterns.md)**: Common design patterns used in the generator registry and cross-file generation.
- **[Rules](.agents/rules/rules.md)**: Strict coding rules (e.g., no unwanted comments, read-only `TypeGraph`).
- **[Conventions](.agents/rules/conventions.md)**: Naming conventions and annotation structures.
