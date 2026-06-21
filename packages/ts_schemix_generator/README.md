# ts_schemix_generator

A [Schemix](https://github.com/adilasharaf/schemix) generator that produces TypeScript `interface` declarations and `z.enum` blocks from `@Schemix`-annotated Dart classes and enums. Intended to pair with `zod_schemix_generator`: this package provides the static type surface (`.d.ts`-style declarations), while `zod_schemix_generator` provides the runtime Zod schemas.

---

## Installation

```yaml
# pubspec.yaml
dependencies:
  schemix: any

dev_dependencies:
  schemix_builder: any
  ts_schemix_generator: any
  zod_schemix_generator: any # recommended — interfaces and schemas belong together
  build_runner: ^2.15.0
```

---

## Quick Start

```dart
import 'package:schemix/schemix.dart';

enum UserStatus { active, inactive, suspended }

@Schemix(tableName: 'users')
class User {
  @PrimaryKey(autoGenerate: true)
  final String id;

  final String email;

  final UserStatus status;

  final String? displayName;

  const User({
    required this.id,
    required this.email,
    required this.status,
    this.displayName,
  });
}
```

```bash
dart run build_runner build
```

Produces `gen/user.g.ts` (alongside the Zod schema from `zod_schemix_generator`):

```typescript
import { z } from "zod";

// ── UserStatus (Enum) ──
export const UserStatusSchema = z.enum(["active", "inactive", "suspended"]);
export type UserStatus = z.infer<typeof UserStatusSchema>;

// ── User (Type) ──
export interface User {
  id: string;
  email: string;
  status: UserStatus;
  displayName?: string | null;
}
```

---

## Configuration

No generator-specific options are currently supported. Enable the builder in your `build.yaml`:

```yaml
# build.yaml
targets:
  $default:
    builders:
      ts_schemix_generator|tsBuilder:
        enabled: true
```

---

## What Gets Generated

### Dart → TypeScript type mapping

| Dart type                    | TypeScript type                            |
| ---------------------------- | ------------------------------------------ |
| `String`                     | `string`                                   |
| `int` / `double` / `num`     | `number`                                   |
| `bool`                       | `boolean`                                  |
| `DateTime`                   | `string` (ISO-8601 via the API layer)      |
| `Uint8List`                  | `string` (base64-encoded)                  |
| `dynamic` / `Object`         | `unknown`                                  |
| `void` / `Null`              | `undefined`                                |
| `Map<K, V>`                  | `Record<string, V>`                        |
| `List<T>` / `Iterable<T>`    | `Array<T>`                                 |
| `Map` (bare)                 | `Record<string, unknown>`                  |
| Firebase `Timestamp`         | `{ seconds: number; nanoseconds: number }` |
| Firebase `GeoPoint`          | `{ latitude: number; longitude: number }`  |
| Firebase `DocumentReference` | `string` (serialized as path)              |
| Firebase `FieldValue`        | `unknown`                                  |
| Firebase `Blob`              | `string` (base64)                          |
| Known model or enum          | Type name directly (e.g. `UserStatus`)     |
| Unknown model                | `unknown`                                  |

### Nullability

Nullable fields (`T?` in Dart) are emitted as optional properties with a `null` union:

```typescript
displayName?: string | null;
```

Non-nullable fields are emitted without the optional marker:

```typescript
email: string;
```

### Enum blocks

Each Dart enum is emitted as a `z.enum([...])` constant plus a `z.infer<...>` type alias, keeping enum types compatible with the Zod schemas from `zod_schemix_generator`:

```typescript
export const UserStatusSchema = z.enum(["active", "inactive", "suspended"]);
export type UserStatus = z.infer<typeof UserStatusSchema>;
```

The `import { z } from 'zod'` line is only included when at least one enum is present in the file.

### Other features

| Feature                          | Trigger                                                      |
| -------------------------------- | ------------------------------------------------------------ |
| `@TsType(typeName)` override     | `converter.tsTypeOverride` — replaces the resolved TS type   |
| Cross-file `import type { Foo }` | Field references a model declared in a different source file |
| Fields sorted as declared        | Interface fields follow Dart declaration order               |

---

## What Gets Skipped

### Fields

| Condition      | Reason                                                                                   |
| -------------- | ---------------------------------------------------------------------------------------- |
| `@IgnoreField` | Excluded from all outputs                                                                |
| `@ZodIgnore`   | TS interfaces and Zod schemas must stay in sync; excluding from Zod excludes from TS too |
| `@OfflineOnly` | Field never reaches the server / TypeScript layer                                        |

### Classes

| Condition                                                |
| -------------------------------------------------------- |
| `manualImplementation == true` (`@ManualImplementation`) |
| `hasSchemix == false` and `isEnum == false`              |

---

## Package Structure

```
lib/
├── ts_schemix_generator.dart   ← public barrel (TsGenerator, TsInterfaceGenerator,
│                                   TsTypeResolver, TsFileAssembler, assembleFile,
│                                   tsKey, skipField)
├── builder.dart                ← builder factory; registers _TsGeneratorAdapter, returns _NoOpBuilder
└── src/
    ├── generator.dart          ← TsGenerator implements SchemixGenerator; assembleFile() top-level helper
    ├── interface_generator.dart ← TsInterfaceGenerator: ClassInfo → interface / enum block string
    ├── type_resolver.dart      ← TsTypeResolver: FieldInfo → TypeScript type string
    ├── file_assembler.dart     ← TsFileAssembler: assembles complete .d.ts content from blocks
    └── utils.dart              ← tsKey(), skipField()
```

`lib/builder.dart` is the file `build.yaml` imports. `lib/ts_schemix_generator.dart` is the public API for tests and external tooling. Everything under `src/` is internal.

---

## How It Fits Into the Build Pipeline

`tsBuilder` registers a `_TsGeneratorAdapter` shim with `GeneratorRegistry`, then returns a `_NoOpBuilder`. Unlike `zod_schemix_generator`, this generator has **no ordering constraint** — TypeScript interfaces are structural and forward references in `.d.ts` files are valid — so `TsGenerator.generate` processes classes one at a time without buffering.

```
Phase 1 — schemix_builder|schemix_scan
  Reads lib/**.dart, writes lib/schemix_registry.json

Phase 2 — ts_schemix_generator|tsBuilder  ← runs before schemix_file
  No-op; registers _TsGeneratorAdapter in GeneratorRegistry

Phase 2 — schemix_builder|schemix_file
  Dispatches to TsGenerator (id='ts') once per class
  Writes gen/{name}.g.ts  (combined with Zod output in the same file)

Phase 3 — schemix_builder|schemix_index
  Scans gen/**.g.ts, writes gen/schemix.g.ts barrel
```

`TsGenerator` never reads `schemix_registry.json` directly. The resolved `TypeGraph` is provided through `GeneratorContext` by `schemix_builder`. Cross-file import paths are resolved via `TypeGraph.relativeImportFor`.

---

## Rules This Package Must Never Break

- Does not depend on any other Schemix generator package.
- Does not depend on `schemix_builder` at runtime — only in `dev_dependencies`.
- Does not import private `src/` paths from `schemix` or `schemix_builder` (the one exception is `SchemixLogger`, imported via the public `schemix_builder.dart` barrel).
- `skipField()` must remain identical to the one in `zod_schemix_generator` — TS interfaces and Zod schemas must always include and exclude the same fields.
- Enum blocks must always use `z.enum([...])` + `z.infer<typeof ...>` so they remain compatible with the schemas emitted by `zod_schemix_generator`.
- `TsGenerator.shouldRun` and `_TsGeneratorAdapter.shouldRun` must stay in sync.
- `TsTypeResolver.resolve` must never return an empty string — fall back to `unknown` for any unresolvable type.
