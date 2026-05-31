# zod_schemix_generator

A [Schemix](https://github.com/adilasharaf/schemix) generator that produces a [Zod](https://zod.dev) schema constant for every `@Schemix`-annotated model class and enum. The schema is emitted into a `.g.ts` file alongside cross-file imports, dependency-ordered declarations, and automatic `z.lazy()` wrapping for cyclic types.

---

## Installation

```yaml
# pubspec.yaml
dependencies:
  schemix: any

dev_dependencies:
  schemix_builder: any
  zod_schemix_generator: any
  build_runner: ^2.15.0
```

---

## Quick Start

```dart
import 'package:schemix/schemix.dart';

@Schemix(tableName: 'users')
class User {
  @PrimaryKey(autoGenerate: true)
  final String id;

  @Email()
  final String email;

  @Min(0) @Max(100)
  final int? score;

  const User({required this.id, required this.email, this.score});
}
```

```bash
dart run build_runner build
```

Produces `gen/user.g.ts`:

```typescript
import { z } from 'zod';

// ── User (Schema) ──
export const UserSchema: z.ZodType<User> = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  score: z.number().int().gte(0).lte(100).nullish(),
});
```

---

## Configuration

Add options to `build.yaml` in your consuming package:

```yaml
# build.yaml
targets:
  $default:
    builders:
      zod_schemix_generator|zodBuilder:
        enabled: true
        options:
          dateTimeAsString: true   # default: true
```

| Option              | Type   | Default | Description                                               |
| ------------------- | ------ | ------- | --------------------------------------------------------- |
| `dateTimeAsString`  | `bool` | `true`  | Emit `DateTime` fields as `z.string().datetime(...)`. Currently the only supported mode; reserved for future `dateTimeAsNumber` or native `Date` variants. |

---

## What Gets Generated

### Primitive type mapping

| Dart type            | Zod expression                          |
| -------------------- | --------------------------------------- |
| `String`             | `z.string()`                            |
| `int`                | `z.number().int()`                      |
| `double` / `num`     | `z.number()`                            |
| `bool`               | `z.boolean()`                           |
| `DateTime`           | `z.string().datetime({ offset: true })` |
| `Uint8List`          | `z.string().base64()`                   |
| `dynamic` / `Object` | `z.unknown()`                           |
| `Null`               | `z.null()`                              |
| `Map<K, V>`          | `z.record(z.string(), <V expr>)`        |
| `List<T>`            | `z.array(<T expr>)`                     |
| Firebase `Timestamp` | `firestoreTimestampSchema` (+ import)   |
| Firebase `GeoPoint`  | `firestoreGeoPointSchema` (+ import)    |
| Firebase `DocumentReference` | `firestoreDocRefSchema` (+ import) |
| Unknown model        | `z.unknown()`                           |

### Validation chain mapping

| Annotation / flag          | Zod chain addition                               |
| -------------------------- | ------------------------------------------------ |
| `@Email()`                 | `.email()`                                       |
| `@Url()`                   | `.url()`                                         |
| `@Uuid()`                  | `.uuid()`                                        |
| `@IpAddress()`             | `.ip()`                                          |
| `@Regex(pattern)`          | `.regex(/pattern/u)`                             |
| `@Length(min, max)`        | `.min(n)` / `.max(n)` / both                     |
| `@Required` on String      | `.min(1)`                                        |
| `@Required` on List        | `.nonempty()`                                    |
| `@Min(n)` on number        | `.gte(n)`                                        |
| `@Max(n)` on number        | `.lte(n)`                                        |
| `@AllowedValues([...])`    | `.refine(v => [...].includes(v))`                |
| `@DisallowValues([...])`   | `.refine(v => ![...].includes(v))`               |
| Nullable field             | `.nullish()` appended after base expression      |
| `@DatabaseDefault(value)`  | `.catch(value)` appended after base expression   |

### Other features

| Feature                                 | Trigger                                                       |
| --------------------------------------- | ------------------------------------------------------------- |
| `z.lazy(() => FooSchema)`               | Type participates in a reference cycle (intra- or cross-file) |
| `z.ZodType<T>` explicit type annotation | Every schema constant                                         |
| Cross-file `import { FooSchema }` line  | Field references a model from a different source file         |
| Dependency-ordered schema constants     | Automatic topological sort; dependencies always declared first |
| `@ZodType(schema)` override             | Full Zod expression override for a field                      |
| `@TsType(zodSchema)` override           | Alternate Zod schema override via TS type annotation          |
| `@CustomConverter(tsConverter)` override | Raw TS converter string used verbatim                        |

---

## What Gets Skipped

### Fields

| Condition             | Reason                                                   |
| --------------------- | -------------------------------------------------------- |
| `@IgnoreField`        | Excluded from all outputs                                |
| `@ZodIgnore`          | Explicit Zod-only exclusion                              |
| `@OfflineOnly`        | Field never reaches the server / TypeScript layer        |

### Classes

| Condition                                                          |
| ------------------------------------------------------------------ |
| `generators.zod == false` (`generateZod: false` in `@Schemix`)    |
| `manualImplementation == true` (`@ManualImplementation`)           |
| `hasSchemix == false` and `isEnum == false`                        |

---

## Package Structure

```
lib/
├── zod_schemix_generator.dart   ← public barrel (ZodGenerator, ZodGraphResolver,
│                                   ZodSchemaGenerator, ZodTypeResolver, DefaultResolver,
│                                   ZodFileAssembler, tsKey, skipField)
├── builder.dart                 ← builder factory; registers _ZodGeneratorAdapter, returns _NoOpBuilder
└── src/
    ├── generator.dart           ← ZodGenerator implements SchemixGenerator; per-file buffering + flush
    ├── schema_generator.dart    ← ZodSchemaGenerator: ClassInfo → schema block string
    ├── type_resolver.dart       ← ZodTypeResolver: FieldInfo → Zod expression; DefaultResolver: .catch() values
    ├── graph_resolver.dart      ← ZodGraphResolver: intra-file dep graph, topo sort, cycle detection
    ├── file_assembler.dart      ← ZodFileAssembler: assembles complete .g.ts content from blocks
    └── utils.dart               ← tsKey(), skipField()
```

Everything under `src/` is internal. `lib/builder.dart` is the file `build.yaml` imports. `lib/zod_schemix_generator.dart` is the public API for tests and external tooling.

---

## How It Fits Into the Build Pipeline

`zodBuilder` registers a `_ZodGeneratorAdapter` (a lightweight `SchemixGenerator` shim) with `GeneratorRegistry`, then returns a `_NoOpBuilder`. The real generation is performed by `ZodGenerator` — but because Zod schema order matters (a schema must be declared before any schema that references it), `ZodGenerator` uses a **per-file buffer**: it accumulates all classes from a source file, runs a topological sort, and emits the full file content only once.

```
Phase 1 — schemix_builder|schemix_scan
  Reads lib/**.dart, writes lib/schemix_registry.json

Phase 2 — zod_schemix_generator|zodBuilder  ← runs before schemix_file
  No-op; registers _ZodGeneratorAdapter in GeneratorRegistry

Phase 2 — schemix_builder|schemix_file
  Dispatches to ZodGenerator (id='zod') once per class
  ZodGenerator buffers, topo-sorts, and flushes on file boundary
  Writes gen/{name}.g.ts

Phase 3 — schemix_builder|schemix_index
  Scans gen/**.g.ts, writes gen/schemix.g.ts barrel
```

`ZodGenerator` never reads `schemix_registry.json` directly. The resolved `TypeGraph` is provided through `GeneratorContext` by `schemix_builder`. Cross-file import paths are resolved via `TypeGraph.relativeImportFor`.

---

## Rules This Package Must Never Break

- Does not depend on any other Schemix generator package.
- Does not depend on `schemix_builder` at runtime — only in `dev_dependencies`.
- Does not import `CrossFileRegistry` or any private `src/` paths from `schemix` or `schemix_builder`.
- `ZodTypeResolver.resolve` must never return an empty string — fall back to `z.unknown()` for any unresolvable type.
- Cyclic types (detected by `ZodGraphResolver.findCyclicNodes`) must always be wrapped in `z.lazy()` — emitting a bare schema reference for a cyclic type produces invalid TypeScript.
- `skipField()` is the single authoritative skip-gate; field exclusion logic must not be duplicated elsewhere in the package.
- Schema constants must always be emitted in dependency order (dependencies before dependents) within a file; the topological sort in `ZodGraphResolver.topoSort` is not optional.
- The `_ZodGeneratorAdapter` registered by `zodBuilder` and the real `ZodGenerator` must keep their `shouldRun` predicates in sync.