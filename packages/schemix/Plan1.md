# Schemix — Project Handover Prompt

## 1. Project Overview

### Project Name

**Schemix**

### Vision

Schemix is a model-definition and code-generation platform built on top of Dart's `build_runner`. The goal is to define a data model once using Dart annotations and generate artifacts for multiple targets simultaneously from a single source of truth.

### Goals

- Allow developers to annotate a Dart class once with `@Schemix(...)` and receive generated output for every configured target without writing any target-specific code.
- Be fully extensible so third-party developers can publish their own generators using the Schemix public API.
- Produce zero runtime footprint. Schemix is build-time only.
- Be independently publishable as a set of focused pub.dev packages.

### Core Problems Being Solved

The original codebase was a working but architecturally flawed monolith:

- A process-global singleton registry (`CrossFileRegistry`) produced stale output on `build_runner watch` builds.
- Generator-specific logic (Zod resolvers, TypeScript type maps, Firebase imports) was hardcoded in the core package, coupling all generators together.
- `FieldInfo` carried 60+ fields including UI, audit, and analytics metadata that no generator read, inflating analysis cost and the eventual registry JSON.
- `_analyzeField` was a 350-line sequential method impossible to test per annotation category.
- `source_parser.dart` used regex over raw Dart source to extract constructor defaults — a fragile and redundant approach given the analyzer already provides full constant evaluation.
- No extension point existed for third-party generators.
- No annotation conflict validation existed, allowing illegal combinations to silently produce broken output.

### Design Philosophy

- Core package contains only annotations, trimmed metadata models, and the generator contract interface. No generator logic.
- Build infrastructure is separate from the public API.
- Generators are independent packages that depend only on `schemix` core.
- The registry is a real build artifact (`schemix_registry.json`), not in-memory shared state.
- `FieldInfo` carries only what generators actually read. Unknown metadata is carried in an open `extensions: Map<String, Object?>` slot.
- Every architectural decision must prioritize correctness on incremental builds above all other concerns.

---

## 2. Ecosystem Architecture

### Package Map

```
schemix/                          ← PUBLIC CORE (runtime + dev dep for consumers)
  annotations, models, generator contract, TypeGraph interface

schemix_builder/                    ← BUILD INFRASTRUCTURE (dev dep)
  build_runner builders, model analyzer, registry, annotation validator

schemix_zod_generator/            ← ZOD + TYPESCRIPT GENERATOR (dev dep)
schemix_drift_generator/          ← DRIFT TABLE GENERATOR (dev dep)
schemix_drizzle_generator/        ← DRIZZLE SCHEMA GENERATOR (dev dep)
schemix_serializable_generator/   ← DART JSON SERIALIZATION GENERATOR (dev dep)
schemix_firebase/                 ← FIREBASE TYPE DESCRIPTORS (optional dep)
schemix_generator_sdk/            ← TEST UTILITIES FOR GENERATOR AUTHORS (dev dep)
```

### Dependency Relationships

```
consumer app
  └─ depends on: schemix                    (runtime — annotations on models)
  └─ dev depends on: schemix_builder          (build_runner wiring)
  └─ dev depends on: schemix_zod_generator  (optional, per target)
  └─ dev depends on: schemix_drift_generator (optional, per target)
  ...

schemix_builder
  └─ depends on: schemix                    (reads ClassInfo, TypeInfo, TypeGraph)
  └─ depends on: analyzer, build, glob, path, source_gen

schemix_zod_generator
  └─ depends on: schemix                    (reads ClassInfo, FieldInfo, TypeGraph)
  └─ depends on: build

schemix_firebase
  └─ depends on: schemix                    (registers ExternalTypeDescriptor entries)

schemix_generator_sdk
  └─ depends on: schemix
  └─ depends on: build_test
```

No generator package depends on another generator package. No generator package depends on `schemix_builder`. These two rules must never be broken.

### Build Flow (Two-Phase)

```
Phase 1 — SchemixScanBuilder
  Trigger:  build_runner detects any lib/**.dart change
  Input:    all lib/**.dart files in the consuming package
  Action:   for each file, resolve LibraryElement, extract TypeInfo + RelationInfo
            for all enums and @Schemix-annotated classes
  Output:   lib/schemix_registry.json  (single artifact per package)
  Runs:     before Phase 2 (declared via runs_before in build.yaml)

Phase 2 — SchemixFileBuilder
  Trigger:  per lib/{name}.dart file
  Input:    lib/{name}.dart + lib/schemix_registry.json
  Action:   deserialize registry → CrossFileRegistry
            run ModelAnalyzer on the single file → List<ClassInfo>
            for each active generator, call shouldRun → generate
            run AnnotationValidator on each ClassInfo
  Outputs:  lib/{name}.schemix.dart  (Dart serialization)
            lib/{name}.table.dart    (Drift table)
            gen/{name}.g.ts          (Zod + TypeScript)
            gen/{name}.drizzle.ts    (Drizzle schema)

Phase 3 — SchemixIndexBuilder
  Trigger:  package-level, after all Phase 2 outputs exist
  Input:    gen/**.g.ts (all Zod output files)
  Output:   gen/schemix.g.ts  (barrel re-export file)
```

### Metadata Flow

```
Dart source file
  → LibraryElement (analyzer AST)
  → ModelAnalyzer
      → _analyzeClass  → ClassInfo (schema-level metadata)
      → _analyzeField (per field, composed from 8 extractor functions)
          → _extractDb         → FieldDbInfo
          → _extractRelation   → FieldRelationInfo
          → _extractSerialization → FieldSerializationInfo
          → _extractConverter  → FieldConverterInfo
          → _extractValidation → FieldValidation
          → _extractSecurity   → FieldSecurityInfo
          → _extractSync       → FieldSyncInfo
          → _extractPlatform   → FieldPlatformFlags
  → AnnotationValidator.validate(classInfo, classElement)
  → SchemixGenerator.shouldRun(classInfo) per active generator
  → SchemixGenerator.generate(classInfo, GeneratorContext) per active generator
      GeneratorContext carries:
        - TypeGraph (read-only view of CrossFileRegistry)
        - BuilderOptions
        - sourceAssetPath
  → GeneratorOutput (Map<extension, content>)
  → written to output files by SchemixFileBuilder
```

### Extension Points

Third-party generators implement `SchemixGenerator` from `schemix` core, declare their own `build.yaml` builder, and list `lib/schemix_registry.json` in `required_inputs`. They receive a fully populated `GeneratorContext` and never need to access `schemix_builder` internals. Custom annotation data is stored in `FieldInfo.extensions` keyed by the generator's `id`.

---

## 3. Current Project State

### What Has Been Built

**Tier 0 — schemix core package (COMPLETE)**

All five files have been written and are in their final form for Milestone 1/2.

**`schemix/lib/src/utils.dart`**
Contains `StringExtension` with `snakeCase` and `camelCase`. The original `camelToSnake` was an exact duplicate of `snakeCase` and has been removed. All callsites use `snakeCase`.

**`schemix/lib/src/constants.dart`**
Contains `SchemixConstants` with two sets: `dartPrimitives` (the single source of truth, eliminating the duplicate that existed in `builder.dart`) and `generatedSuffixes` (file suffixes the build system must skip). `Uint8List` was added — it existed in `type_mapping.dart`'s primitive maps but was missing from the constants set. Firebase types remain in `dartPrimitives` with a comment explaining they are opaque to core; their target-specific mappings live in `schemix_firebase`.

**`schemix/lib/annotations.dart`**
All 18 annotation categories, unchanged from the original except the removal of the 8-line internal file-header block comment. This is the stable public API surface. Nothing should change here unless new annotations are added.

**`schemix/lib/models.dart`**
Trimmed metadata structs. Key changes from original:

- `SchemixGeneratorResult` removed (build infrastructure, belongs in `schemix_builder`)
- `ConverterTransform` and `ExternalTypeDescriptor` removed (Zod generator internals, belong in `schemix_zod_generator`)
- `FieldUiInfo` and `FieldAuditInfo` removed entirely (no generator reads them)
- `FieldApiInfo` trimmed to `expose`, `readonly`, `deprecated` only
- `FieldInfo` stripped of 20+ unused scalar flags. All removed fields may be re-added when a generator that actually uses them is built.
- `extensions: Map<String, Object?>` added to `FieldInfo` as an open slot for generator-specific metadata
- `effectiveJsonName` now calls `snakeCase` (the old `camelToSnake` alias has been removed)
- `TypeGraph` interface is NOT in `models.dart` — it lives in `generator_api.dart`

**`schemix/lib/src/generator_api.dart`**
Defines the complete generator contract:

- `TypeGraph` — read-only interface over the registry. Methods: `isEnum`, `isModel`, `isEmbeddable`, `resolve`, `cyclicTypes` (getter), `relativeImportFor`, `relativeDrizzleImportFor`.
- `GeneratorContext` — carries `TypeGraph`, `BuilderOptions`, `sourceAssetPath`.
- `GeneratorOutput` — `Map<String, String?>` keyed by extension. `GeneratorOutput.empty()` for cheap no-op.
- `SchemixGenerator` — the interface. `id`, `outputExtensions`, `shouldRun(ClassInfo)`, `generate(ClassInfo, GeneratorContext)`.

**`schemix/lib/schemix.dart`**
Three exports only: `annotations.dart`, `models.dart`, `src/generator_api.dart`. No build infrastructure exported.

**Tier 1 — schemix_builder package (PARTIAL — 3 of 8 files complete)**

**`schemix_builder/lib/src/logger.dart`**
Identical to original except `preScanStart/preScanAsset/preScanSkip` renamed to `scanStart/scanAsset/scanSkip` to reflect the two-phase build naming.

**`schemix_builder/lib/src/registry.dart`**
Complete rewrite of `CrossFileRegistry`:

- Singleton pattern fully removed. Plain instantiable class.
- Implements `TypeGraph` interface from `schemix` core directly. No adapter needed.
- `register(TypeInfo)`, `registerRelation(RelationInfo)`, `seal()` for Phase 1 population.
- `toJson()` / `fromJson(String)` for registry artifact serialization. All `TypeInfo`, `RelationInfo`, `GeneratorFlags`, `SyncMeta` fields round-trip correctly.
- `seal()` replaces `markInitialized()` — logs cyclic warning, no boolean flag.
- Dead code removed: `topologicalOrder`, `groupByNamespace`, `debugSummary`, `typesInNamespace`, `relationsFrom`, `relationsTo`, `allRelations`, `allTypeNames`, `allTypes`.
- Convenience accessors kept: `allModels`, `allEnums`.

**`schemix_builder/lib/src/annotation_validator.dart`**
New file. `AnnotationValidator.validate(ClassInfo, ClassElement)` runs after `_analyzeField` in `ModelAnalyzer`. Throws `InvalidGenerationSourceError` (from `source_gen`) on five conflict types:

1. `@OfflineOnly` + `@CloudOnly` on same field
2. `@PrimaryKey` on nullable field
3. `@CreatedAt` + `@UpdatedAt` on same field
4. `@Encrypted` + `@ZodIgnore` on same field
5. `@IgnoreField` combined with `@PrimaryKey`, validation constraints, or relations

### What Has NOT Been Built Yet

**Tier 1 remaining (5 files):**

- `schemix_builder/lib/src/model_analyzer.dart` — Step 9
- `schemix_builder/lib/src/scan_builder.dart` — Step 10
- `schemix_builder/lib/src/file_builder.dart` — Step 11
- `schemix_builder/lib/src/index_builder.dart` — Step 12
- `schemix_builder/lib/builder.dart` — Step 13

**Tier 2 (all 7 generator files):**

- `schemix_serializable_generator` — Steps 14
- `schemix_zod_generator` — Steps 15–16
- `schemix_drift_generator` — Steps 17–18
- `schemix_drizzle_generator` — Steps 19–20

**Tier 3 (optional, future):**

- `schemix_firebase` — Step 21
- `schemix_generator_sdk` — Step 22

---

## 4. Architecture Memory Graph

```
╔══════════════════════════════════════════════════════════════════════╗
║  CONSUMER PACKAGE                                                    ║
║  lib/models/user.dart  (@Schemix annotated Dart classes)            ║
╚══════════════════════╦═══════════════════════════════════════════════╝
                       │ dart source
                       ▼
╔══════════════════════════════════════════════════════════════════════╗
║  schemix_builder  (build infrastructure)                               ║
║                                                                      ║
║  ┌─────────────────────┐    Phase 1                                  ║
║  │  SchemixScanBuilder  │──────────────────────────────────────┐     ║
║  │  (scan_builder.dart) │  reads all lib/**.dart               │     ║
║  └─────────────────────┘  writes schemix_registry.json         │     ║
║           │                                                     │     ║
║           │ uses                                                │     ║
║           ▼                                                     │     ║
║  ┌─────────────────────┐                                        │     ║
║  │   ModelAnalyzer      │  LibraryElement → ClassInfo           │     ║
║  │  (model_analyzer)    │  8 per-category extractor fns         │     ║
║  └─────────────────────┘                                        │     ║
║           │                                                     │     ║
║           │ produces                                            │     ║
║           ▼                                                     │     ║
║  ┌─────────────────────┐                                        │     ║
║  │  CrossFileRegistry   │◄───────────────────────────────────────     ║
║  │    (registry.dart)   │  populated in Phase 1                 │     ║
║  │  implements TypeGraph│  serialized to JSON                   │     ║
║  └─────────────────────┘  deserialized in Phase 2              │     ║
║           │                          ▲                          │     ║
║           │                          │ fromJson()               │     ║
║           │              ┌─────────────────────┐               │     ║
║           │              │  schemix_registry    │◄──────────────     ║
║           │              │       .json          │  build artifact    ║
║           │              └─────────────────────┘                     ║
║           │                                                           ║
║  ┌─────────────────────┐    Phase 2                                  ║
║  │  SchemixFileBuilder  │  reads registry + single .dart file        ║
║  │  (file_builder.dart) │  runs ModelAnalyzer (per-file)             ║
║  └────────┬────────────┘  runs AnnotationValidator                   ║
║           │                calls each SchemixGenerator               ║
║           │                                                           ║
║  ┌─────────────────────┐                                             ║
║  │ AnnotationValidator  │  validates ClassInfo post-analysis         ║
║  └─────────────────────┘  throws InvalidGenerationSourceError        ║
╚══════════════════════╦═══════════════════════════════════════════════╝
                       │ passes GeneratorContext (TypeGraph, options, path)
                       ▼
╔══════════════════════════════════════════════════════════════════════╗
║  GENERATOR PACKAGES  (each independent)                              ║
║                                                                      ║
║  schemix_serializable_generator                                      ║
║    SchemixGenerator → .schemix.dart                                  ║
║                                                                      ║
║  schemix_zod_generator                                               ║
║    ZodTypeResolver + TsTypeResolver → .g.ts                          ║
║                                                                      ║
║  schemix_drift_generator                                             ║
║    DriftTypeResolver → .table.dart                                   ║
║                                                                      ║
║  schemix_drizzle_generator                                           ║
║    DrizzleTypeResolver → .drizzle.ts                                 ║
╚══════════════════════╦═══════════════════════════════════════════════╝
                       │ all depend on
                       ▼
╔══════════════════════════════════════════════════════════════════════╗
║  schemix  (core — the only runtime dep)                              ║
║                                                                      ║
║  annotations.dart      — @Schemix, @PrimaryKey, @Email, etc.        ║
║  models.dart           — ClassInfo, FieldInfo, TypeInfo, sub-structs ║
║  src/generator_api.dart — SchemixGenerator, TypeGraph, GeneratorContext ║
║  src/utils.dart        — StringExtension (snakeCase, camelCase)      ║
║  src/constants.dart    — dartPrimitives, generatedSuffixes           ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

## 5. Current Milestone

### Phase

Milestone 1 — Refactor In-Place. The goal is correctness and clean separation before any package split.

### Current Milestone Tasks Status

| #                                                  | Task                                     | Status      |
| -------------------------------------------------- | ---------------------------------------- | ----------- |
| Delete `source_parser.dart`                        | Planned for model_analyzer step          | Pending     |
| Decompose `_analyzeField` into extractor functions | Next implementation target               | Pending     |
| Trim `FieldInfo`                                   | Done in Step 3                           | ✅ Complete |
| Add `extensions` map to `FieldInfo`                | Done in Step 3                           | ✅ Complete |
| Deduplicate `dartPrimitives`                       | Done in Step 1                           | ✅ Complete |
| Add `AnnotationValidator`                          | Done in Step 8                           | ✅ Complete |
| Fix `CrossFileRegistry` singleton                  | Done in Step 7 (full two-phase approach) | ✅ Complete |
| Implement `TypeGraph` interface                    | Done in Steps 4 + 7                      | ✅ Complete |
| `SchemixScanBuilder`                               | Step 10                                  | Pending     |
| `SchemixFileBuilder`                               | Step 11                                  | Pending     |
| Golden-file tests                                  | After all builders complete              | Pending     |

### Current Task

**Step 9 — `schemix_builder/lib/src/model_analyzer.dart`**

This is the most complex remaining file in Tier 1. It replaces the original monolithic `model_analyzer.dart` with a decomposed, extractor-based design.

### Why It Is Important

`ModelAnalyzer` is the bridge between the Dart analyzer AST and `ClassInfo`. Every downstream component — both builders and every generator — depends on `ClassInfo` being correct. If this file has a bug or missing field extraction, the error propagates silently to all outputs. It is also the file that must delete all references to `source_parser.dart`, completing Fix 2 from the plan.

---

## 6. Next Implementation Target

### What: `schemix_builder/lib/src/model_analyzer.dart`

### Why Now

It is the direct dependency of both `scan_builder.dart` (Step 10) and `file_builder.dart` (Step 11). Neither builder can be written without it.

### Inputs

- Original `model_analyzer.dart` from the project source (available at `/mnt/project/model_analyzer.dart`)
- Original `source_parser.dart` (to be deleted — its callsites in `_analyzeField` must be replaced with `_readConstantValue` / `computeConstantValue()` calls that already exist in the original analyzer)
- `schemix/lib/models.dart` (the trimmed `FieldInfo` and sub-structs produced in Step 3)
- `schemix/lib/src/constants.dart` (for `dartPrimitives` and `generatedSuffixes`)
- `schemix_builder/lib/src/registry.dart` (for `CrossFileRegistry` registration calls)
- `schemix_builder/lib/src/annotation_validator.dart` (called from `_analyzeClass`)
- `schemix_builder/lib/src/logger.dart`

### Outputs

Single file: `schemix_builder/lib/src/model_analyzer.dart`

Public API surface:

```dart
class ModelAnalyzer {
  ModelAnalyzer(CrossFileRegistry registry);
  List<ClassInfo> analyzeLibrary(LibraryElement library, String assetPath);
}
```

### Design Constraints

**`_analyzeField` must be decomposed into 8 private extractor functions:**

```dart
FieldDbInfo _extractDb(FieldElement field)
FieldRelationInfo _extractRelation(FieldElement field)
FieldSerializationInfo _extractSerialization(FieldElement field, bool useSnakeCase)
FieldConverterInfo _extractConverter(FieldElement field)
FieldValidation _extractValidation(FieldElement field)
FieldSecurityInfo _extractSecurity(FieldElement field)
FieldSyncInfo _extractSync(FieldElement field)
FieldPlatformFlags _extractPlatform(FieldElement field)
```

`_analyzeField` itself becomes a composition of these 8 calls, plus the handful of top-level `FieldInfo` scalar fields (name, dartType, isNullable, isList, isMap, etc.).

**`source_parser.dart` must not be imported.** All constructor default extraction via regex must be removed. The only way to read annotation values is via `computeConstantValue()` → field accessor methods (`toBoolValue()`, `toStringValue()`, `toIntValue()`, `toDoubleValue()`).

**`AnnotationValidator.validate` must be called** inside `_analyzeClass` after all fields are extracted, passing the completed `ClassInfo` and the `ClassElement`.

**Inherited field collection** must be preserved. The original `_collectInheritedFields` recursion (depth-guarded at 8) is correct and must be carried over unchanged.

**`@JsonKey` interop** must be preserved. The analyzer checks `@JsonKey(ignore:)`, `@JsonKey(name:)`, `@JsonKey(includeFromJson:)`, `@JsonKey(includeToJson:)` in addition to schemix's own `@JsonField` and `@IgnoreField`.

**The `FieldInfo` fields removed in Step 3 must not be extracted.** Do not extract `FieldUiInfo`, `FieldAuditInfo`, or any of the 20+ removed scalar flags. The original model_analyzer extracts them — they must be dropped.

### Risks

- The original `_analyzeField` has implicit ordering dependencies (e.g. `isIgnored` is checked early to short-circuit). The decomposed version must preserve early return on ignored fields before running extractors.
- `_typeFieldFromAnnotation` (which resolves `Type` annotation parameters like `@BelongsTo(User)`) relies on `toTypeValue()` — this must be preserved as-is since it is the only way to get relation target names.
- Inherited fields from abstract base classes that are not themselves `@Schemix` annotated must still be included. The `_collectInheritedFields` logic handles this by not requiring `hasSchemix` on the superclass.

---

## 7. Critical Architectural Decisions

### What Belongs in `schemix` (core)

- All annotation classes (`@Schemix`, `@PrimaryKey`, `@Email`, etc.)
- `ClassInfo`, `FieldInfo`, and all field sub-structs (`FieldDbInfo`, `FieldRelationInfo`, etc.)
- `TypeInfo`, `RelationInfo`, `GeneratorFlags`, `SyncMeta`, `CompositeIndexInfo`
- `TypeGraph` interface (read-only, for generators)
- `SchemixGenerator` interface
- `GeneratorContext`, `GeneratorOutput`
- `StringExtension`, `SchemixConstants`
- Nothing else. No analyzer imports. No build imports (except `BuilderOptions` in `GeneratorContext`).

### What Belongs in `schemix_builder`

- `CrossFileRegistry` (mutable, implements `TypeGraph`)
- `ModelAnalyzer` (analyzer AST → `ClassInfo`)
- `AnnotationValidator`
- `SchemixScanBuilder` (Phase 1)
- `SchemixFileBuilder` (Phase 2)
- `SchemixIndexBuilder` (barrel)
- `SchemixLogger`
- All `build.yaml` builder declarations

### What Belongs in Generator Packages

- All type mapping tables (primitive Zod types, TS types, Drift column types, Drizzle column types)
- All type resolver logic (`ZodTypeResolver`, `TsTypeResolver`, `DriftTypeResolver`, `DrizzleTypeResolver`)
- `ConverterTransform`, `ExternalTypeDescriptor` and any Firebase-specific type knowledge
- Generator-specific `build.yaml` declarations

### What Belongs in `schemix_firebase`

- `ExternalTypeDescriptor` entries for `Timestamp`, `GeoPoint`, `DocumentReference`, `FieldValue`, `Blob`
- The Firebase import strings
- Registration mechanism that injects these descriptors into generator configuration

### Separation of Concerns Rules

- No generator package may import another generator package.
- No generator package may import `schemix_builder`.
- `schemix` core may not import `analyzer`, `build_runner`, or any build package (except `build` for `BuilderOptions`).
- `CrossFileRegistry` is internal to `schemix_builder`. It is never exported. Generators only see `TypeGraph`.

### Metadata Ownership

- `FieldInfo` is owned by `schemix` core. Its fields represent the union of what all first-party generators need.
- Generator-specific metadata that does not belong in core goes in `FieldInfo.extensions` keyed by `SchemixGenerator.id`.
- Adding a field to `FieldInfo` is a breaking change once packages are split. The `extensions` map exists precisely to avoid this.

### API Boundaries

- `TypeGraph` is the only view of the registry that crosses the `schemix_builder` → generator boundary. Generators never see `CrossFileRegistry`.
- `ClassInfo` / `FieldInfo` are value objects. They are immutable once constructed. Generators read them; they never modify them.
- `SchemixGenerator.shouldRun` must be cheap — no allocation, no I/O. It is called before `generate` to allow fast opt-out.

### Extensibility Strategy

1. Add `schemix` as a dependency.
2. Implement `SchemixGenerator`.
3. Declare a `build.yaml` builder that lists `lib/schemix_registry.json` in `required_inputs`.
4. Read the registry via `CrossFileRegistry.fromJson(await buildStep.readAsString(...))` and construct a `GeneratorContext`.
5. Publish independently.

---

## 8. Open Questions

### Registry Artifact Location

The plan specifies `lib/schemix_registry.json` as the output path for the scan builder. This means the JSON file will appear in the consumer's `lib/` directory on source builds. An alternative is `build_to: cache` which keeps it out of source control. The current `build.yaml` design uses `build_to: cache` for the scan builder. This must be verified — if `required_inputs` in `schemix_file` can read from cache outputs of `schemix_scan`.

### `build_runner` Isolate Safety

The two-phase approach resolves the singleton hazard, but it has not been tested under `build_runner watch` with concurrent file changes. The assumption is that `build_runner`'s dependency tracking on `schemix_registry.json` will correctly invalidate Phase 2 outputs when Phase 1 re-runs. This needs integration testing.

### `@JsonSerializable` Interop

`ModelAnalyzer` currently detects `@JsonSerializable` and `hasManualSerialization` (classes with `fromJson`/`toJson` methods) as triggers for analysis even without `@Schemix`. The intended behavior in the split architecture is unclear — should `schemix_builder` continue to analyze non-`@Schemix` classes for these annotations, or should this be the responsibility of `schemix_serializable_generator`?

### Generator Registration

Currently the file builder hardcodes calls to four specific generators. The long-term architecture calls for a registered generator list that the file builder iterates. How generators register themselves with the file builder — whether via `build.yaml` `required_inputs`, a config file, or explicit consumer configuration — is not yet designed.

### `schemix_firebase` Registration Mechanism

Firebase type descriptors must be injected into the Zod generator's type resolver at build time. The mechanism for this injection (builder options in `build.yaml`, a Dart registration call, a separate config artifact) has not been specified.

### `source_gen` Dependency in `schemix_builder`

`AnnotationValidator` uses `InvalidGenerationSourceError` from `source_gen`. The `pubspec.yaml` already lists `source_gen: ^4.2.3` as a dependency. This is correct but should be verified when the `schemix_builder` `pubspec.yaml` is written.

---

## 9. Recommended Next Steps

### Immediate (complete Tier 1)

**Step 9 — `model_analyzer.dart`**
Highest priority. The remaining four Tier 1 files all depend on it.

- Decompose `_analyzeField` into 8 extractor functions
- Remove all `source_parser.dart` imports and callsites
- Call `AnnotationValidator.validate` from `_analyzeClass`
- Drop extraction of the 20+ `FieldInfo` fields removed in Step 3

**Step 10 — `scan_builder.dart`**
Phase 1 builder. Scans all `lib/**.dart`, populates `CrossFileRegistry`, calls `registry.seal()`, writes `registry.toJson()` to the output artifact. Sequential asset processing (not concurrent) to avoid analyzer contention.

**Step 11 — `file_builder.dart`**
Phase 2 builder. Reads `schemix_registry.json` via `CrossFileRegistry.fromJson`, runs `ModelAnalyzer` on the single input file, dispatches to each active generator, writes outputs.

**Step 12 — `index_builder.dart`**
Barrel builder. Mostly identical to the original `index_builder.dart` with updated imports.

**Step 13 — `builder.dart`**
Factory function exports and `build.yaml` entrypoint for `schemix_builder`.

### After Tier 1 (Tier 2 generators)

**Step 14 — `schemix_serializable_generator`**
Extract the serializable generator from the original codebase. No type mapping complexity — pure Dart output.

**Steps 15–16 — `schemix_zod_generator`**
Extract `ZodTypeResolver`, `TsTypeResolver`, `ConverterTransform`, `ExternalTypeDescriptor` from `type_mapping.dart`. Move Firebase descriptors to a stub in `schemix_firebase`. Implement `SchemixGenerator`.

**Steps 17–18 — `schemix_drift_generator`**
Extract `DriftTypeResolver` and `DriftGenerator`.

**Steps 19–20 — `schemix_drizzle_generator`**
Extract `DrizzleTypeResolver` and `DrizzleGenerator`.

### After Tier 2

**Golden file tests** for all four generators using `build_test`.

**Milestone 3 — Package split**: write individual `pubspec.yaml` files for each package, configure workspace, verify cross-package resolution.

---

## 10. Instructions for the Next AI

### How to Continue Development

1. The next task is **Step 9: `schemix_builder/lib/src/model_analyzer.dart`**.
2. Read the original `model_analyzer.dart` at `/mnt/project/model_analyzer.dart` before writing any code.
3. Read the trimmed `FieldInfo` at `/mnt/user-data/outputs/schemix/lib/models.dart` to know exactly which fields exist and which were removed.
4. Read `annotation_validator.dart` at `/mnt/user-data/outputs/schemix_builder/lib/src/annotation_validator.dart` to know the exact call signature for `AnnotationValidator.validate`.
5. The output file goes to `/mnt/user-data/outputs/schemix_builder/lib/src/model_analyzer.dart`.

### Assumptions That Must Not Be Broken

- **No singleton registry.** `CrossFileRegistry` is instantiated fresh per build phase. Never use a static instance.
- **No `source_parser.dart`.** Regex over source strings is deleted. All annotation values come from `computeConstantValue()`.
- **`TypeGraph` is the generator boundary.** Generators never receive `CrossFileRegistry` directly.
- **`FieldInfo` fields are final.** Do not add fields back to `FieldInfo` unless a generator currently in scope reads them.
- **`extensions: Map<String, Object?>` on `FieldInfo`** is the escape hatch for generator-specific metadata. Use it instead of adding fields to core.
- **No generator depends on another generator.** This must never happen.
- **`schemix` core has no `analyzer` import.** The analyzer package is a `schemix_builder` concern only.

### Architectural Principles to Preserve

- The two-phase build pipeline is the foundation of all correctness guarantees. Phase 1 must complete before Phase 2 starts.
- `shouldRun(ClassInfo)` is always called before `generate`. A generator that does not apply to a class must return `false` from `shouldRun` cheaply.
- Annotation extraction is per-category. Each extractor function is independently readable and testable.
- `AnnotationValidator.validate` is always called after analysis, before generation.
- Log messages follow the existing format: `'   verb         | detail'` with aligned pipes.

### What to Review Before Making Changes

- Before modifying `models.dart`: check all 7 generator files (once written) for any field they read from `FieldInfo`. Removing a field from `models.dart` after generators exist is a breaking change.
- Before modifying `generator_api.dart`: the `TypeGraph` interface is implemented by `CrossFileRegistry`. Any change to `TypeGraph` requires a matching change in `registry.dart`.
- Before adding to `schemix` core: ask whether the new code is needed by generators or by build infrastructure. If infrastructure only, it belongs in `schemix_builder`.
- Before adding a new annotation: add it to `annotations.dart` first, then add extraction in the appropriate `_extract*` function in `model_analyzer.dart`, then add the field to the appropriate sub-struct in `models.dart` or to `FieldInfo.extensions`.

### Comment Style

Only two types of comments are used in this codebase:

- Doc comments (`///`) on public API members describing what they are or do.
- Section separator comments (`// ── Label ───`) to divide large files into logical regions.

Do not add implementation comments, `// TODO`, inline explanations of obvious code, or file-header block comments.

### File Naming and Output Paths

All output files go under `/mnt/user-data/outputs/`. The package structure mirrors:

```
/mnt/user-data/outputs/schemix/lib/...          ← schemix core files
/mnt/user-data/outputs/schemix_builder/lib/...    ← schemix_builder files
/mnt/user-data/outputs/schemix_zod_generator/   ← (future)
```

Source files for reference are at `/mnt/project/`.

### Build Step Sequence

Steps must be built in the order defined in the plan (Tier 0 → Tier 1 → Tier 2 → Tier 3) because each tier depends on the previous. Do not skip steps or build out of order.

The complete ordered list:

1. ✅ `schemix/lib/src/utils.dart` + `constants.dart`
2. ✅ `schemix/lib/annotations.dart`
3. ✅ `schemix/lib/models.dart`
4. ✅ `schemix/lib/src/generator_api.dart`
5. ✅ `schemix/lib/schemix.dart`

6. ✅ `schemix_builder/lib/src/logger.dart`
7. ✅ `schemix_builder/lib/src/registry.dart`
8. ✅ `schemix_builder/lib/src/annotation_validator.dart`
9. ⬜ `schemix_builder/lib/src/model_analyzer.dart` ← **NEXT**
10. ⬜ `schemix_builder/lib/src/scan_builder.dart`
11. ⬜ `schemix_builder/lib/src/file_builder.dart`
12. ⬜ `schemix_builder/lib/src/index_builder.dart`
13. ⬜ `schemix_builder/lib/builder.dart`

14. ⬜ `schemix_serializable_generator/lib/src/generator.dart`
15. ⬜ `schemix_zod_generator/lib/src/type_resolver.dart`
16. ⬜ `schemix_zod_generator/lib/src/generator.dart`
17. ⬜ `schemix_drift_generator/lib/src/type_resolver.dart`
18. ⬜ `schemix_drift_generator/lib/src/generator.dart`
19. ⬜ `schemix_drizzle_generator/lib/src/type_resolver.dart`
20. ⬜ `schemix_drizzle_generator/lib/src/generator.dart`
21. ⬜ `schemix_firebase/lib/schemix_firebase.dart`
22. ⬜ `schemix_generator_sdk/lib/schemix_generator_sdk.dart`
