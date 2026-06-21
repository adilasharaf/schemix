# 04: Roadmap & Known Issues

This document tracks the ongoing architectural improvements and known issues based on the original `Plan.md` audit.

## Current Architectural Priorities

### 1. Fix Cross-Generator Dependency Issues
Currently, generating cross-file imports can result in broken code if the target model has disabled a specific generator (e.g., Zod tries to import a Zod schema from a model that only generates Drift).
- **Solution:** Introduce `TypeGraph.canImport(typeName, generatorId)`. All generators must guard their cross-file imports behind this check and emit inline fallbacks (e.g., `z.unknown()`) if false.

### 2. Output Assembly Refinements
The current buffer accumulation strategy in generators like Zod is fragile (e.g., failing to flush the final file's buffer).
- **Solution:** Add `generateForFile(List<ClassInfo> classes, ...)` to the `SchemixGenerator` interface to allow generators holistic file-level assembly, replacing the per-class `generate` iteration loop.

### 3. Generator Plugin Architecture (Tier A)
To stop bloating the core `@Schemix()` annotation with flags like `generateZod`, `generateDrift`, we are moving towards a plugin architecture.
- **Solution:** Use `ClassInfo.extensions` to store generator-specific metadata. Third-party generators should provide their own annotations (like `@GenerateZod()`) that the `ModelAnalyzer` will parse into the `extensions` map.

### 4. Part Directive Enforcement
Generators like `serializable_schemix_generator` emit functions without enforcing the user source file contains the matching `part of` directive, leading to silent analysis failures.
- **Solution:** Add build-time checks in `SerializableGenerator.generate` to emit a `build_runner` warning if the source file lacks `part 'model.schemix.dart'`. Or support `output_strategy: extension` to bypass the need entirely.

### 5. Drizzle & Drift Improvements
- **Drizzle:** Ensure unused relation variables (`one`, `many`) are not destructured to prevent TypeScript warnings. Provide documentation on required npm packages (like `uuid`).
- **Drift:** Ensure `build.yaml` declares `runs_before: ["drift_dev|drift_builder"]` so the generated `.table.dart` is correctly picked up by the secondary drift builder.
