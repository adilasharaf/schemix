# Schemix Design Patterns

When contributing to Schemix, follow these established design patterns to maintain consistency across the generation pipeline.

## 1. Generator Registry Pattern
Instead of hardcoding every possible output into a monolithic builder, Schemix uses a registry:
```dart
GeneratorRegistry.register('zod', ZodGenerator());
```
Generators must implement the `SchemixGenerator` interface and register themselves during their specific builder initialization.

## 2. Output Assembly (File Builder)
A generator is often invoked multiple times per file (once for each class). To handle this cleanly:
- **Avoid Per-Class Buffers:** Prefer implementing `generateForFile(List<ClassInfo> classes, GeneratorContext context)` on the `SchemixGenerator` interface if your generator needs a holistic view of the file (e.g., for Topological Sorting of Zod schemas).
- **String Accumulation:** For simple cases, return string blocks from `generate()` and let `_SchemixFileBuilder` concatenate them.

## 3. Cross-File Imports Strategy
When Generator A (e.g., Zod) needs to reference Generator B (e.g., Zod) in another file due to a relation (`@HasMany`):
1. Resolve the target in the `TypeGraph`.
2. Check if the target has the specific generator enabled using `TypeGraph.canImport(targetTypeName, 'generator_id')` or `targetInfo.generators.zod`.
3. If enabled, emit the import. If not, emit an inline fallback (`z.unknown()`, `any`, etc.).
4. Use a dedicated `ImportCollector` class to deduplicate import statements at the top of the file.

## 4. Part / Extension Files in Dart
For Dart generation (like JSON Serialization):
- Emitted files should use the `part of 'model.dart';` directive.
- The `schemix_scan` or `SerializableGenerator` should warn the user if they forgot to include `part 'model.schemix.dart';` in their source file.
