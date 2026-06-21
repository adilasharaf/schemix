# Claude Context for Schemix

As Claude, your deep reasoning and large context window make you highly effective at understanding cross-generator dependencies in Schemix.

## High-Level Context
- **Project Goal:** Schemix acts as the single source of truth for full-stack applications. A developer writes a Dart class annotated with `@Schemix()`, and Schemix generates the equivalent schema in Drift (Dart SQL), Drizzle (TypeScript SQL), Zod (Validation), and TypeScript interfaces.
- **Dependency Graph:** The most complex part of Schemix is cross-file imports. For example, if Model A has a `@HasMany(ModelB)` relationship, the Zod and Drizzle generators must emit correct import statements depending on whether Model B actually has those generators enabled.

## Guidelines for Claude
1. **Focus on Architectural Invariants:** Before modifying a generator, consider if the change breaks the `TypeGraph` invariant. Generators should never mutate the `TypeGraph` or internal `ClassInfo` state; they should only read from it.
2. **Cross-Generator Impact:** If you change how an annotation is parsed in `ModelAnalyzer`, remember that it will impact *all* downstream generators. Always check `zod_schemix_generator`, `drizzle_schemix_generator`, and `drift_schemix_generator` to see how the parsed field is utilized.
3. **Use the Plugin Architecture:** When adding a new generator feature, prefer the Tier A plugin model (using `ClassInfo.extensions`) rather than hardcoding new flags into the core `@Schemix` annotation.
4. **Code Generation Purity:** Ensure that any string buffers (`StringBuffer`) used for generation don't include unnecessary comments unless explicitly required. The generated code should be as clean as hand-written code.

## Preferred Actions
- When suggesting refactoring, refer to the [Patterns](../rules/patterns.md) and [Architecture](../rules/architecture.md) documents.
- Always cross-reference the [GUARDRAILS.md](GUARDRAILS.md) before writing code.
