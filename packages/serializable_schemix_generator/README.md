# serializable_schemix_generator

Dart JSON serialization generator for the [Schemix](https://github.com/adilasharaf/schemix) ecosystem. Generates `fromJson`, `toJson`, and `_$copy` helpers from `@Schemix`-annotated classes.

This is the reference implementation for Schemix generator packages. Future generators (`schemix_zod_generator`, `schemix_drift_generator`, etc.) follow the same architecture.

---

## Installation

This package is a build-time tool. Add it to `dev_dependencies`:

```yaml
dependencies:
  schemix: ^1.0.24

dev_dependencies:
  serializable_schemix_generator: ^0.1.0
  build_runner: ^2.15.0
```

This package uses workspace resolution. Ensure your root `pubspec.yaml` includes it in the workspace.

---

## Usage

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

This produces `user.schemix.dart` as a part file containing:

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

## Supported field types

| Type                                     | `fromJson`                            | `toJson`                    |
| ---------------------------------------- | ------------------------------------- | --------------------------- |
| `String`, `int`, `double`, `num`, `bool` | direct cast                           | passthrough                 |
| `DateTime`                               | `DateTime.parse(src)`                 | `.toIso8601String()`        |
| Enum                                     | `.values.byName(src)`                 | `.name`                     |
| Enum with `@EnumFallback`                | `_$safeByName(values, src, fallback)` | `.name`                     |
| Nested `@Schemix` model                  | `T.fromJson(src)`                     | `.toJson()`                 |
| `@Embedded` model                        | same as nested                        | same as nested              |
| `List<T>`                                | `.map((e) => ...).toList()`           | `.map((e) => ...).toList()` |
| `Map<String, T>`                         | `.cast<String, T>()`                  | passthrough                 |
| Nullable variants                        | null-guarded form of the above        | null-aware operators        |

---

## Serialization annotations

| Annotation          | Effect                                                   |
| ------------------- | -------------------------------------------------------- |
| `@JsonField('key')` | Uses `key` as the JSON field name instead of the default |
| `@IgnoreField()`    | Excludes the field from all serialization output         |
| `@ReadOnlyField()`  | Field appears in `fromJson` but is skipped in `toJson`   |
| `@WriteOnlyField()` | Field appears in `toJson` but is skipped in `fromJson`   |

JSON key names default to the Dart field name. Snake case fallback applies when the class uses manual serialization.

---

## Constructor strategies

The generator reads `ClassInfo.ctorParamNames` (populated by `schemix_builder`) to determine how to construct instances in `fromJson` and `_$copy`.

**Named constructor parameters** — fields that appear in the primary constructor are emitted as named arguments:

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

## Package layout

```
serializable_schemix_generator/
├── pubspec.yaml
├── build.yaml
├── lib/
│   ├── serializable_schemix_generator.dart   ← public API
│   └── src/
│       ├── builder.dart       ← registers the generator and returns the builder
│       ├── generator.dart     ← SerializableGenerator implements SchemixGenerator
│       ├── header.dart        ← emits the part file header and _$safeByName helper
│       ├── expr_builder.dart  ← type-dispatch logic for fromJson/toJson expressions
│       ├── from_json.dart     ← generates _$NameFromJson
│       ├── to_json.dart       ← generates _$NameToJson
│       ├── copy.dart          ← generates _$NameCopy
│       └── ctor_params.dart   ← resolves constructor parameter names
└── test/
```

The public API exports only `SerializableGenerator` and `serializableBuilder`. Everything under `src/` is internal.

---

## How it fits into the build pipeline

```
Phase 1 — schemix_builder scan builder
  Reads all lib/**.dart files, emits lib/schemix_registry.json

Phase 2 — schemix_builder file builder
  Reads one .dart file + schemix_registry.json
  Dispatches to registered generators by id
  serializable_schemix_generator handles id='serializable'
  Writes lib/{name}.schemix.dart

Phase 3 — schemix_builder index builder
  Reads all gen/**.g.ts, emits gen/schemix.g.ts barrel
```

`serializable_schemix_generator` runs in Phase 2. It never reads the registry directly — `schemix_builder` passes a resolved `TypeGraph` through `GeneratorContext`.

---

## Writing a generator that follows this pattern

This package is the reference implementation. The layout, naming conventions, and contracts below apply to all Schemix generator packages.

**Rules**

- Implement `SchemixGenerator` from `package:schemix/src/generator_api.dart`
- Register via `GeneratorRegistry.register(MyGenerator())` in the builder factory, then return `schemixFileBuilder(options)`
- Never depend on `schemix_builder` in `dependencies` — only in `dev_dependencies`
- Never import `analyzer` or `source_gen` directly
- One file per concern under `lib/src/`
- Export only the generator class and builder factory from the public entry point

**`build.yaml` template**

```yaml
builders:
  my_generator:
    import: "package:my_generator/my_generator.dart"
    builder_factories: ["myBuilder"]
    build_extensions:
      ".dart":
        - ".my.dart"
    auto_apply: dependents
    build_to: source
    required_inputs:
      - "$package$lib/schemix_registry.json"
```

`required_inputs` on `schemix_registry.json` is mandatory — it ensures the scan phase completes first and that `build_runner` invalidates outputs when the type graph changes.
