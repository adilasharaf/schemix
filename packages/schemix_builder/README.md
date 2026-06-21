# schemix_builder

Build infrastructure for the [Schemix](https://github.com/adilasharaf/schemix) ecosystem. Provides the three `build_runner` builders that power all code generation — scan, file, and index — plus the analyzer integration, registry, validation, and logger that every Schemix generator package depends on.

This package is **not a generator**. It coordinates generators; generators are registered separately by packages such as `serializable_schemix_generator` or `drift_schemix_generator`.

---

## Installation

This package is a build-time dependency. Add it to `dev_dependencies` only:

```yaml
# pubspec.yaml
dependencies:
  schemix: any

dev_dependencies:
  schemix_builder: any
  build_runner: ^2.15.0
```

> **Note**: Never add `schemix_builder` to `dependencies`. It is a build-time
> tool; adding it at runtime violates the package architecture invariant.

---

## Quick Start

1. Annotate a model class with `@Schemix` (from `package:schemix`).
2. Add the generator packages you need to `dev_dependencies`.
3. Run the build:

```bash
dart run build_runner build
```

`schemix_builder` runs three phases automatically. Given a class like:

```dart
// lib/user.dart
import 'package:schemix/schemix.dart';

class User {
  @PrimaryKey(autoGenerate: true)
  final String id;
  final String email;
  const User({required this.id, required this.email});
}
```

The build produces:

```
lib/user.schemix.dart    ← Dart JSON serialization (via serializable_schemix_generator)
lib/user.table.dart      ← Drift Table subclass   (via drift_schemix_generator)
gen/user.g.ts            ← Zod schema + TS types  (via zod_schemix_generator)
gen/schemix.g.ts         ← Barrel re-export of all .g.ts files
```

---

## Build Pipeline

`schemix_builder` exposes three builders, which `build_runner` runs in dependency order:

### Phase 1 — `schemix_scan` (scan builder)

Reads every `lib/**.dart` file in the package, extracts class and enum metadata without full AST analysis, and writes a cross-file registry to `lib/schemix_registry.json`. This JSON artifact is the single source of truth for type relationships, relation deps, and `@Schemix` configuration used in Phase 2.

```
Input:  lib/**.dart  (whole package, via Glob)
Output: lib/schemix_registry.json  (build cache)
```

### Phase 2 — `schemix_file` (file builder)

Runs once per `lib/{name}.dart` file that has not been generated. Loads the registry from Phase 1, performs full `analyzer` AST resolution on the file, and dispatches to every registered `SchemixGenerator` by its `id`. Writes the outputs declared in `buildExtensions`:

```
Input:  lib/{name}.dart + lib/schemix_registry.json
Output: lib/{name}.schemix.dart
        lib/{name}.table.dart
        gen/{name}.g.ts
        gen/{name}.drizzle.ts
```

Generators must be registered before this builder runs. Registration happens in generator packages' builder factories (e.g. `GeneratorRegistry.register(DriftGenerator())`).

### Phase 3 — `schemix_index` (index builder)

Scans all `gen/**.g.ts` files (excluding `.drizzle.ts`) and writes a barrel re-export file at `gen/schemix.g.ts`. The barrel filename and the import prefix can be configured via `BuilderOptions`.

```
Input:  gen/**.g.ts  (whole package, via Glob)
Output: gen/schemix.g.ts
```

---

## Configuration

Configure the builders per consuming package in its `build.yaml`:

```yaml
# build.yaml
targets:
  $default:
    builders:
      schemix_builder|schemix_scan:
        enabled: true
      schemix_builder|schemix_file:
        enabled: true
      schemix_builder|schemix_index:
        options:
          package_name: "my_app" # used in barrel file usage comment
```

The `package_name` option controls the import path shown in the barrel file header comment. It defaults to `"schemix"`.

---

## What Gets Generated

| Builder         | Trigger                                | Output                                                 |
| --------------- | -------------------------------------- | ------------------------------------------------------ |
| `schemix_scan`  | Any `lib/**.dart` file in the package  | `lib/schemix_registry.json`                            |
| `schemix_file`  | Each `lib/{name}.dart` (non-generated) | `.schemix.dart`, `.table.dart`, `.g.ts`, `.drizzle.ts` |
| `schemix_index` | Package-level trigger (runs once)      | `gen/schemix.g.ts`                                     |

The file builder dispatches to generators by `id`. If no generator is registered for an output slot (e.g. no `drift_schemix_generator` in `dev_dependencies`), that output file is silently skipped.

---

## What Gets Skipped

| Condition                                         | Reason                                  |
| ------------------------------------------------- | --------------------------------------- |
| File path ends with a generated suffix            | Avoids re-processing generated outputs  |
| File cannot be read by `buildStep`                | Asset may not exist at build time       |
| `lib/schemix_registry.json` missing               | Scan phase has not run yet              |
| Library source URI does not match the input asset | Part files are processed by their owner |
| No `@Schemix`-annotated or enum classes found     | No-op; no output files written          |
| Generator produces empty output for all classes   | Output file is not written              |

---

## Package Structure

```
lib/
├── builder.dart             ← Entry point declared in build.yaml; exports the three builder factories
├── schemix_builder.dart     ← Full public API: builders, logger, scan/index builders
└── src/
    ├── scan_builder.dart    ← Phase 1: whole-package scan, emits schemix_registry.json
    ├── file_builder.dart    ← Phase 2: per-file build, dispatches to generators; defines GeneratorRegistry
    ├── index_builder.dart   ← Phase 3: barrel file writer for gen/schemix.g.ts
    ├── model_analyzer.dart  ← Full analyzer-based ClassInfo + FieldInfo extraction
    ├── registry.dart        ← CrossFileRegistry (implements TypeGraph); JSON round-trip
    ├── annotation_validator.dart  ← Detects conflicting annotation combinations; throws InvalidGenerationSourceError
    └── logger.dart          ← SchemixLogger: structured build log methods over package:build log
```

`lib/builder.dart` exports only the three builder factory functions — it is the file `build.yaml` imports. `lib/schemix_builder.dart` is the wider public API used by generator packages.

---

## Writing a Generator That Integrates With This Package

All Schemix generator packages follow the same registration contract:

1. Implement `SchemixGenerator` from `package:schemix/schemix.dart`:
   - `String get id` — unique identifier (e.g. `'drift'`, `'zod'`)
   - `List<String> get outputExtensions` — extensions this generator writes
   - `bool shouldRun(ClassInfo)` — allocation-free, I/O-free eligibility check
   - `GeneratorOutput generate(ClassInfo, GeneratorContext)` — returns output keyed by extension

2. In the generator package's `lib/builder.dart` factory, call `GeneratorRegistry.register(MyGenerator())` before returning `schemixFileBuilder(options)` (or a `_NoOpBuilder` if the generator is dispatch-only):

```dart
Builder myBuilder(BuilderOptions options) {
  GeneratorRegistry.register(MyGenerator());
  return schemixFileBuilder(options);
}
```

3. Declare `schemix_builder: any` under `dev_dependencies` only — never under `dependencies`.

4. In `build.yaml`, import `lib/builder.dart` and set `required_inputs` on `lib/schemix_registry.json`:

```yaml
builders:
  my_generator:
    import: "package:my_generator/builder.dart"
    builder_factories: ["myBuilder"]
    build_extensions:
      "^lib/{{}}.dart":
        - "lib/{{}}.my.dart"
    auto_apply: dependents
    build_to: source
    required_inputs:
      - "lib/schemix_registry.json"
```

---

## Rules This Package Must Never Break

1. Does not import `analyzer` or `source_gen` in any file that generators may use directly.
2. `CrossFileRegistry` is never passed to generator code — only `TypeGraph` (the read-only interface) is exposed via `GeneratorContext`.
3. `SchemixLogger` uses `package:build`'s `log` exclusively; it never writes to `stdout`/`stderr` directly.
4. `AnnotationValidator.validate` throws `InvalidGenerationSourceError` (from `source_gen`) for every documented conflict — the set of checked conflicts must never silently shrink.
5. `schemix_registry.json` is always written to the build cache (`build_to: cache`) in Phase 1 and read from cache in Phase 2. Generator packages must never write to this file.
6. `GeneratorRegistry` is a flat in-process map. Re-registering with the same `id` silently overwrites the previous entry — generator packages must use stable, unique `id` values.
7. All three builder factories (`schemixScanBuilder`, `schemixFileBuilder`, `schemixIndexBuilder`) must remain exported from `lib/builder.dart` without renaming.
