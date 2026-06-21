# 01: Architecture & Design

Schemix relies on a distinct three-phase build pipeline to work around the limitations of Dart's `build_runner`, specifically the inability to read un-built source files across different packages seamlessly during a single generation pass.

## 1. The 3-Phase Build Pipeline

```
Phase 1 — SchemixScanBuilder
  Input:   all lib/**.dart
  Output:  lib/schemix_registry.json  (build_to: cache)
  Purpose: builds the cross-file type graph once per package

Phase 2 — SchemixFileBuilder  (+ any custom generators)
  Input:   one lib/{name}.dart + lib/schemix_registry.json
  Output:  lib/{name}.schemix.dart
           lib/{name}.table.dart
           gen/{name}.g.ts
           gen/{name}.drizzle.ts
  Purpose: full per-file code generation using the type graph

Phase 3 — SchemixIndexBuilder
  Input:   all gen/**.g.ts
  Output:  gen/schemix.g.ts  (barrel re-export)
  Purpose: single import point for all Zod schemas
```

### Builder Ordering
All five generator registration builders (Zod, TS, Serializable, Drift, Drizzle) must declare `runs_before: ["schemix_builder|schemix_file"]` in their `build.yaml`.

## 2. The TypeGraph Abstraction
Because `build_runner` processes one file at a time during Phase 2, a generator looking at `User.dart` cannot directly analyze `Post.dart` to understand an `@HasMany(Post)` relationship.

To solve this, Phase 1 creates a `TypeGraph` (represented by `CrossFileRegistry`). The graph is serialized to JSON and loaded in Phase 2, providing a complete, read-only view of every `ClassInfo` and `FieldInfo` in the project.

**Rule:** The `TypeGraph` is strictly immutable during generation. Generators must never mutate the registry or add/remove fields.

## 3. The Generator Registry Pattern
Instead of hardcoding every generator directly into the `schemix_builder`, Schemix relies on a plugin architecture using a central registry:
```dart
GeneratorRegistry.register('zod', ZodGenerator());
```

To avoid polluting the core `@Schemix()` annotation with specific flags for every possible third-party generator, Schemix uses the `ClassInfo.extensions` map. Generator-specific annotations (e.g., `@GenerateZod()`) are parsed by `ModelAnalyzer` and stored in this map for individual generators to read.
