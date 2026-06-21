# Schemix Architecture

Schemix operates on a distinct three-phase build pipeline using Dart's `build_runner`. Understanding this architecture is crucial for writing or modifying generators.

## 1. The 3-Phase Pipeline

### Phase 1: Scan (`schemix_scan`)
- **Goal:** Read all `lib/**.dart` files to extract metadata and build a project-wide type graph.
- **Output:** A single `schemix_registry.json` file.
- **Mechanism:** It finds all classes annotated with `@Schemix()`, parses their fields, relationships, and metadata using the `analyzer`, and serializes it into `ClassInfo` and `FieldInfo` objects.

### Phase 2: Generate (`schemix_file`)
- **Goal:** Emits the actual generated code for each model.
- **Output:** Files like `.g.ts`, `.table.dart`, `.drizzle.ts`, `.schemix.dart`.
- **Mechanism:** It reads `schemix_registry.json` (the `TypeGraph`), then for each file, it iterates through its classes. For each class, it dispatches to all active `SchemixGenerator` instances. 

### Phase 3: Index (`schemix_index`)
- **Goal:** Creates barrel files to easily export all generated artifacts.
- **Output:** e.g., `gen/schemix.g.ts`.
- **Mechanism:** It globs the outputs of Phase 2 and writes an index file containing `export * from '...'` or equivalent Dart exports.

## 2. TypeGraph Abstraction
The `TypeGraph` (represented by `CrossFileRegistry`) is the brain of Schemix. Because `build_runner` operates on one file at a time during Phase 2, a generator cannot look at Model B's source code while generating Model A. The `TypeGraph` solves this by providing the pre-computed metadata for all models.

## 3. Plugin Architecture (Tier A)
Generators register themselves in `build.yaml` and provide a builder factory. To avoid hardcoding generator-specific flags into the core `@Schemix` annotation, Schemix uses `extensions`.
- A generator reads its configuration from `ClassInfo.extensions['my_generator_flag']`.
- Custom annotations (like `@GenerateZod()`) are parsed by `ModelAnalyzer` and stored in the `extensions` map.
