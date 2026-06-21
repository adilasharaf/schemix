# Universal Guardrails

All AI agents modifying the Schemix codebase **MUST** adhere to the following strict guardrails. Failure to do so will result in broken builds, incorrect code generation, and architectural regressions.

## 1. No Unwanted Comments
- **Source Code:** Do not add conversational, obvious, or unnecessary comments to the library's Dart source code. Keep docstrings focused and professional.
- **Generated Code:** Generators must NOT emit commented-out code, "TODOs", or conversational comments in the output files (`.g.ts`, `.table.dart`, etc.). Generated code must be pristine.

## 2. Respect the 3-Phase Pipeline
- **Phase 1 (Scan):** Only extracts data. Do not emit code here.
- **Phase 2 (Generate):** Only emits code for a single file at a time. **DO NOT** attempt to read other unanalyzed files directly here; use the `TypeGraph`.
- **Phase 3 (Index):** Only groups and exports previously generated files.

## 3. Read-Only TypeGraph
- During Phase 2, the `TypeGraph` (and `ClassInfo`, `FieldInfo`) is **immutable**. Generators must never attempt to add fields, change flags, or modify the registry during the generation phase.

## 4. Strict Cross-Generator Dependencies
- Generators must not hardcode assumptions about other generators.
- When generating an import to another model's generated file, you **must** use `TypeGraph.canImport(typeName, generatorId)` (or check `targetInfo.generators.[target]`). If the target model has disabled the generator, do not emit the import. Provide an inline fallback (e.g., `unknown` in TypeScript) instead.

## 5. Do Not Modify `@Schemix` for New Generators
- The core `@Schemix` annotation must not be bloated with flags for third-party or new generators. 
- Use the `ClassInfo.extensions` map for generator-specific flags (Tier A plugin architecture).

## 6. Preserve `part` / `part of` Semantics
- Ensure that any Dart code generation targeting the source file's library uses the correct `part of` syntax.
- Do not silently generate orphaned files if the user forgets the `part` directive; instead, emit a clear `build_runner` warning.
