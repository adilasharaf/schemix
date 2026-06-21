# Gemini Context for Schemix

As Gemini, you have powerful code analysis and generation capabilities. When working on the Schemix repository, keep the following context in mind to maximize your effectiveness:

## High-Level Context
- **Project Goal:** Schemix is a zero-runtime Dart library that generates code for other platforms and ORMs (Zod, TypeScript, Drift, Drizzle) from a single set of annotated Dart classes.
- **Ecosystem:** `build_runner` and the `source_gen` / `analyzer` packages are central to how Schemix extracts metadata. You will often work with Dart AST components (`ClassElement`, `DartObject`, `ConstantReader`).

## Guidelines for Gemini
1. **Analyze Types Deeply:** When fixing or adding features, rely on the `analyzer` package's type system (`DartType`, `InterfaceType`) rather than string matching.
2. **Understand the 3-Phase Pipeline:**
   - **Phase 1 (Scan):** Extracts metadata into a `schemix_registry.json` (`TypeGraph`).
   - **Phase 2 (Generate):** Reads the graph and invokes specific generators (`SchemixGenerator`) per class.
   - **Phase 3 (Index):** Generates barrel files (e.g., `.g.ts`).
   When you propose a change, determine which phase it belongs to.
3. **Be Concise in Diff Contexts:** If modifying a generator's string output, ensure indentation is preserved correctly, as whitespace matters in TypeScript and Dart generated files.
4. **Tool Usage:** Leverage your file viewing and searching capabilities to find where specific annotations (like `@SchemixField` or `@PrimaryKey`) are processed before attempting to change their behavior.

## Preferred Actions
- When debugging generator logic, first check `ModelAnalyzer` and `CrossFileRegistry`.
- Ensure you review the universal [GUARDRAILS.md](GUARDRAILS.md) and [Rules](../rules/rules.md) before executing commands.
