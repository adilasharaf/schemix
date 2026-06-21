# 03: Generators & Plugins

## Built-In Generators

Schemix provides several first-party generators:
- **`schemix_zod_generator`**: Produces `.g.ts` containing Zod schemas for validation.
- **`schemix_ts_generator`**: Often paired with Zod, produces TypeScript interfaces.
- **`schemix_drift_generator`**: Produces `.table.dart` Drift Table subclasses for local SQLite databases.
- **`schemix_drizzle_generator`**: Produces `.drizzle.ts` Drizzle ORM table schemas for remote Postgres/SQL databases.
- **`gorm_schemix_generator`**: Produces `.go` files with Go structs and Gorm ORM tags for Go backends.
- **`schemix_serializable_generator`**: Produces `.schemix.dart` containing Dart `fromJson`/`toJson` logic and `copyWith` helpers.

## Writing a Custom Generator

Any package can publish a Schemix generator. Add `schemix` as a dependency, implement `SchemixGenerator`, and declare a `build.yaml` builder.

### 1. Implement `SchemixGenerator`
```dart
import 'package:schemix/schemix.dart';

class MyCustomGenerator implements SchemixGenerator {
  @override
  String get id => 'my_custom_generator';

  @override
  List<String> get outputExtensions => ['.my.output'];

  @override
  bool shouldRun(ClassInfo classInfo) => classInfo.hasSchemix;

  @override
  GeneratorOutput generate(ClassInfo classInfo, GeneratorContext context) {
    final buf = StringBuffer();
    // Use context.typeGraph to resolve cross-file types
    for (final field in classInfo.allFields) {
      if (field.isIgnored) continue;
      buf.writeln('// field: ${field.name}');
    }
    return GeneratorOutput({'.my.output': buf.toString()});
  }
}
```

### 2. Register the Generator
In your builder factory:
```dart
Builder myCustomBuilder(BuilderOptions options) {
  GeneratorRegistry.register(MyCustomGenerator());
  return MyCustomFileBuilder(options);
}
```

### 3. Declare `build.yaml`
```yaml
builders:
  my_custom_generator:
    import: "package:my_custom_package/builder.dart"
    builder_factories: ["myCustomBuilder"]
    build_extensions:
      "^lib/{{}}.dart":
        - "gen/{{}}.my.output"
    auto_apply: dependents
    build_to: source
    required_inputs:
      - "lib/schemix_registry.json" # Mandatory
```
