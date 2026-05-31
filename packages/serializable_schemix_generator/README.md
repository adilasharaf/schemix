# serializable_schemix_generator

Dart JSON serialization generator for the [Schemix](https://github.com/adilasharaf/schemix) ecosystem. Generates `_$NameFromJson`, `_$NameToJson`, and `_$NameCopy` helpers as a `part` file from every `@Schemix`-annotated class.

This is the reference implementation for Schemix generator packages. Its layout, naming conventions, and contracts are the pattern all other generators follow.

---

## Installation

This package is a build-time tool. Add it to `dev_dependencies` only:

```yaml
# pubspec.yaml
dependencies:
  schemix: ^1.0.24

dev_dependencies:
  serializable_schemix_generator: any
  build_runner: ^2.15.0
```

---

## Quick Start

Annotate your model with `@Schemix` and run the build:

```dart
import 'package:schemix/schemix.dart';

part 'user.schemix.dart';

@Schemix(tableName: 'users')
class User {
  @PrimaryKey(autoGenerate: true)
  final String id;

  @Email()
  final String email;

  @Hashed()
  final String passwordHash;

  const User({
    required this.id,
    required this.email,
    required this.passwordHash,
  });
}
```

```bash
dart run build_runner build
```

This produces `lib/user.schemix.dart` as a part file containing:

```dart
User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String,
  passwordHash: json['password_hash'] as String,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'password_hash': instance.passwordHash,
};

User _$UserCopy(User src) => User(
  id: src.id,
  email: src.email,
  passwordHash: src.passwordHash,
);
```

---

## Configuration

No generator-specific `build.yaml` options are required. The generator is enabled automatically when the package is in `dev_dependencies`.

---

## What Gets Generated

### Field type mapping

| Dart type                                | `fromJson`                                | `toJson`                    |
| ---------------------------------------- | ----------------------------------------- | --------------------------- |
| `String`, `int`, `double`, `num`, `bool` | direct cast (`as T`)                      | passthrough                 |
| `DateTime`                               | `DateTime.parse(src as String)`           | `.toIso8601String()`        |
| `DateTime` (nullable)                    | null-guard + `DateTime.parse(...)`        | `?.toIso8601String()`       |
| Enum                                     | `T.values.byName(src as String)`          | `.name`                     |
| Enum with `@EnumFallback`                | `_$safeByName(values, src, fallback)`     | `.name`                     |
| Nested `@Schemix` model                  | `T.fromJson(src as Map<String, dynamic>)` | `.toJson()`                 |
| `@Embedded` model                        | same as nested model                      | same as nested model        |
| `List<T>`                                | `.map((e) => e as T).toList()`            | `.map((e) => ...).toList()` |
| `Map<String, T>`                         | `.cast<String, T>()`                      | passthrough                 |
| Nullable variants                        | null-guard form of the above              | null-aware operators (`?.`) |

### Serialization annotations

| Annotation          | Effect                                                           |
| ------------------- | ---------------------------------------------------------------- |
| `@JsonField('key')` | Uses `key` as the JSON field name instead of the Dart field name |
| `@IgnoreField()`    | Excludes the field from all serialization output                 |
| `@ReadOnlyField()`  | Field appears in `fromJson` but is skipped in `toJson`           |
| `@WriteOnlyField()` | Field appears in `toJson` but is skipped in `fromJson`           |

JSON key names default to the Dart field name. Snake case fallback applies when the class uses manual serialization (has `fromJson`/`toJson` methods but no `@JsonSerializable`).

### Constructor strategies

The generator reads `ClassInfo.ctorParamNames` to determine how to construct instances in `fromJson` and `_$Copy`.

**Named constructor parameters** — fields in the primary constructor are emitted as named arguments:

```dart
User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String,
);
```

**Cascade assignment** — fields not in the constructor are assigned via cascade:

```dart
Event _$EventFromJson(Map<String, dynamic> json) => Event(
  id: json['id'] as String,
)..cachedLabel = json['cached_label'] as String?;
```

**No-arg constructor** — when the class has no constructor parameters, all fields use cascade:

```dart
Config _$ConfigFromJson(Map<String, dynamic> json) => Config()
  ..debug = json['debug'] as bool
  ..timeout = json['timeout'] as int;
```

---

## What Gets Skipped

### Fields

| Condition         | Skipped from                   | Reason                                       |
| ----------------- | ------------------------------ | -------------------------------------------- |
| `@IgnoreField`    | `fromJson` + `toJson` + `copy` | Excluded from all serialization output       |
| `@ReadOnlyField`  | `toJson`                       | Field is read-only; not written back to JSON |
| `@WriteOnlyField` | `fromJson`                     | Field is write-only; not read from JSON      |

### Classes

| Condition                | Reason                                                            |
| ------------------------ | ----------------------------------------------------------------- |
| `isEnum == true`         | Enums have no `fromJson`/`toJson` to generate                     |
| `abstractSchema == true` | Abstract schemas are base types only; never instantiated directly |
| `hasSchemix == false`    | Class has no `@Schemix` annotation                                |

---

## Package Structure

```
lib/
├── serializable_schemix_generator.dart   ← public barrel (SerializableGenerator, serializableBuilder)
├── builder.dart                          ← builder factory; registers SerializableGenerator
└── src/
    ├── generator.dart       ← SerializableGenerator implements SchemixGenerator; assembleFile() helper
    ├── header.dart          ← part file header + _$safeByName helper emission
    ├── expr_builder.dart    ← JsonExprBuilder: FieldInfo → fromJson / toJson expression strings
    ├── from_json.dart       ← FromJsonGenerator: ClassInfo → _$NameFromJson function
    ├── to_json.dart         ← ToJsonGenerator: ClassInfo → _$NameToJson function
    ├── copy.dart            ← CopyGenerator: ClassInfo → _$NameCopy function
    └── ctor_params.dart     ← CtorParamResolver: determines constructor vs. cascade strategy
```

The public API exports only `SerializableGenerator` and `serializableBuilder`. Everything under `src/` is internal.

---

## How It Fits Into the Build Pipeline

```
Phase 1 — schemix_builder|schemix_scan
  Reads lib/**.dart, writes lib/schemix_registry.json

Phase 2 — schemix_builder|schemix_file
  Dispatches to SerializableGenerator (id='serializable') once per class
  Writes lib/{name}.schemix.dart as a Dart part file
```

`SerializableGenerator` never reads `schemix_registry.json` directly. The resolved `TypeGraph` is provided through `GeneratorContext` by `schemix_builder`. Constructor parameter names are resolved from `ClassInfo.ctorParamNames`, which is populated by `ModelAnalyzer` during Phase 2.

The part file header includes a `part of '{filename}.dart'` directive and a `_$safeByName` helper (used for enums with `@EnumFallback`). The header is emitted once per file by `assembleFile`, not per class.

---

## Rules This Package Must Never Break

- Does not depend on any other Schemix generator package.
- Does not depend on `schemix_builder` at runtime — only in `dev_dependencies`.
- Does not import private `src/` paths from `schemix` or `schemix_builder`.
- The generated part file must always begin with `// GENERATED BY SCHEMIX — DO NOT EDIT.` and a `part of '...'` directive — omitting either breaks `dart analyze`.
- `_$safeByName` must always be emitted in the file header regardless of whether any field uses `@EnumFallback`, so the generated code compiles without conditional imports.
- `JsonExprBuilder` is the single source of truth for `fromJson`/`toJson` expression logic; `FromJsonGenerator`, `ToJsonGenerator`, and `CopyGenerator` must not contain their own type-dispatch logic.
