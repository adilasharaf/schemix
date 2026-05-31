# drift_schemix_generator — Plan

---

## Phase 1 — Existing Code Analysis

### What should be preserved

**`DriftColumnBuilder`** — the column dispatch logic is sound. The three-branch
structure (belongsTo FK → enum → primary key → regular column) covers all real
cases correctly. `skipField` and `fieldSkipReason` are clean and complete.

**`DriftTableBodyBuilder`** — timestamp and soft-delete injection logic is
correct. The `hasCreatedAt` / `hasUpdatedAt` / `hasDeletedAt` guards prevent
double-injection when the model declares those fields explicitly.

**`DriftTableOverridesBuilder`** — `buildEnumConverters` with the `seen` set
correctly deduplicates converters when the same enum type appears on multiple
fields. Composite PK and unique index overrides are both handled.

**`_shouldGenerate` gate** — `!isEnum && generators.drift && !abstractSchema &&
!embeddable` is exactly right for a Drift generator.

---

### What should be removed

**`CrossFileRegistry` field on `DriftGenerator`** — the generator never
actually uses `registry` in any of its methods. It was passed in but only
forwarded to sub-builders that don't use it either. Remove it; take `TypeGraph`
from `GeneratorContext` instead, same as `serializable_schemix_generator`.

**`packageName` field on `DriftGenerator`** — hardcoded to `'models'` and used
only in the file header import `"import 'package:models/models.dart';"`. The
package name must come from `GeneratorContext.options` (declared in `build.yaml`
builder options), not a constructor parameter.

**`late final` + re-assignment in `generateFile`** — `_bodyBuilder` and
`_overridesBuilder` are declared `late final` in the constructor then
immediately re-assigned in `generateFile`. This is a bug; `late final` fields
cannot be reassigned. Replace with direct constructor injection.

**`../../lib/models.dart` and `../../lib/src/logger.dart` path imports** —
same boundary violation as the old serializable generator. Replace with
`package:schemix/models.dart` and `package:schemix_builder/src/logger.dart`.

**`import 'package:schemix/src/utils.dart'`** — private path import. `snakeCase`
must either be moved to the public `schemix` API or reimplemented locally in
this package.

---

### What should be redesigned

**`DriftGenerator` as a standalone orchestrator** — like `SerializableGenerator`,
it must implement `SchemixGenerator` to integrate with `GeneratorRegistry`. The
`generateFile` method becomes `generate(ClassInfo, GeneratorContext)` and the
file header assembly moves to a `DriftHeader` class.

**`DriftTypeResolver`** — referenced in `DriftColumnBuilder` via
`import '../../lib/src/type_mapping.dart'` (a `schemix_builder` internal path).
This must be moved into this package as `lib/src/type_resolver.dart`. Its full
source wasn't provided — it needs to be shared or reimplemented before
implementation can begin.

**File header** — the `generateFile` header is hardcoded with
`"import 'package:models/models.dart';"`. The models package name must be
configurable via `build.yaml` options, with a sensible default.

---

## Phase 2 — Package Structure

```
drift_schemix_generator/
├── pubspec.yaml
├── build.yaml
├── lib/
│   ├── drift_schemix_generator.dart      ← public entry point
│   └── src/
│       ├── builder.dart                  ← registers generator, returns schemixFileBuilder
│       ├── generator.dart                ← DriftGenerator implements SchemixGenerator
│       ├── header.dart                   ← DriftHeader (file header assembly)
│       ├── column_builder.dart           ← DriftColumnBuilder
│       ├── table_body_builder.dart       ← DriftTableBodyBuilder
│       ├── table_overrides_builder.dart  ← DriftTableOverridesBuilder
│       ├── type_resolver.dart            ← DriftTypeResolver (needs source)
│       └── utils.dart                   ← DriftStringExtension (converterName, snakeCase)
└── test/
```

Public API exports only `DriftGenerator` and `driftBuilder`.

---

## Phase 3 — Metadata consumed

| Need                          | Source                                                                                                         |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------- |
| Gate: should generate         | `ClassInfo.generators.drift`, `ClassInfo.isEnum`, `ClassInfo.abstractSchema`, `ClassInfo.embeddable`           |
| Table name                    | `ClassInfo.tableName` → snake_case of `ClassInfo.name`                                                         |
| Timestamp injection           | `ClassInfo.enableTimestamps`, `ClassInfo.enableSoftDelete`                                                     |
| Composite PK / unique indexes | `ClassInfo.compositeIndexes`                                                                                   |
| All fields                    | `ClassInfo.allFields`                                                                                          |
| Column name                   | `FieldInfo.serialization.effectiveJsonName` → snake_case                                                       |
| Skip field                    | `FieldInfo.isIgnored`, `FieldInfo.platform.driftIgnore`, `FieldInfo.sync.cloudOnly`, `FieldInfo.relation.kind` |
| Column type dispatch          | `FieldInfo.dartType`, `FieldInfo.isEnum`, `FieldInfo.isNullable`, `FieldInfo.db.*`                             |
| Enum converter                | `FieldInfo.dartType`, `FieldInfo.isEnum`                                                                       |
| FK column                     | `FieldInfo.relation.kind == RelationKind.belongsTo`                                                            |
| Lifecycle fields              | `FieldInfo.isCreatedAt`, `FieldInfo.isUpdatedAt`, `FieldInfo.isDeletedAt`                                      |
| Models package name           | `GeneratorContext.options.config['models_package']`                                                            |

---

## Phase 4 — Open blockers before implementation

**`DriftTypeResolver` source is missing.** `DriftColumnBuilder` calls
`DriftTypeResolver.resolve(field)` and `DriftTypeResolver.columnDefinition(field)`
from `schemix_builder/lib/src/type_mapping.dart`. This file must be provided
before `column_builder.dart` can be written. Without it the column type mapping
is unknown.

**`snakeCase` extension source is missing.** Used in `DriftColumnBuilder` and
`DriftGenerator` via `package:schemix/src/utils.dart`. Either:

- Move `snakeCase` to the public `schemix` API, or
- Reimplement it locally in `drift_schemix_generator/lib/src/utils.dart`

---

## Phase 5 — `build.yaml`

```yaml
builders:
  drift_schemix_generator:
    import: "package:drift_schemix_generator/drift_schemix_generator.dart"
    builder_factories: ["driftBuilder"]
    build_extensions:
      ".dart":
        - ".table.dart"
    auto_apply: dependents
    build_to: source
    required_inputs:
      - "$package$lib/schemix_registry.json"
    options:
      models_package: "models"
```

`models_package` is the only configurable option — controls the import in the
generated file header.

---

## Phase 6 — `pubspec.yaml` shape

```yaml
name: drift_schemix_generator
dependencies:
  schemix: ^1.0.24
  build: ^4.0.6
  drift: ^2.x.x        ← needed for generated code imports to resolve in tests

dev_dependencies:
  schemix_builder: ^1.0.24
  build_runner: ^2.15.0
  build_test: ^3.5.15
  test: ^1.30.0
  lints: ^6.1.0
```

---

## Implementation order

1. **Obtain `DriftTypeResolver` source** — share `type_mapping.dart` from
   `schemix_builder` or confirm it moves into this package
2. **Confirm `snakeCase` location** — public `schemix` export or local util
3. `lib/src/utils.dart` — `DriftStringExtension` + `snakeCase` if local
4. `lib/src/type_resolver.dart` — `DriftTypeResolver`
5. `lib/src/column_builder.dart` — `DriftColumnBuilder`
6. `lib/src/table_body_builder.dart` — `DriftTableBodyBuilder`
7. `lib/src/table_overrides_builder.dart` — `DriftTableOverridesBuilder`
8. `lib/src/header.dart` — `DriftHeader`
9. `lib/src/generator.dart` — `DriftGenerator implements SchemixGenerator`
10. `lib/src/builder.dart` — register + delegate
11. `lib/drift_schemix_generator.dart` — public entry point
12. `pubspec.yaml` + `build.yaml`
13. `README.md`
14. Tests
