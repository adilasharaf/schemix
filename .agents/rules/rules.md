# Schemix Coding Rules

These rules must be strictly adhered to when contributing to Schemix. 

## 1. Zero Unwanted Comments Rule
Generators must NOT emit obvious, conversational, or "TODO" comments into the generated output files.
- **Incorrect:** `// Generate relations here`
- **Correct:** Just emit the relations code directly.
The generated code should look like pristine hand-written code.

## 2. Read-Only TypeGraph
The `TypeGraph` (represented by `CrossFileRegistry`) is strictly read-only during the generation phase.
- Do not attempt to add or remove `ClassInfo` or `FieldInfo` instances while a generator is running.
- Do not mutate the `generators` map on a `ClassInfo` object.

## 3. Strict Dependency Checking
Never assume a referenced model will generate a specific file.
- If generating Drizzle schemas, check if the referenced model actually has Drizzle generation enabled before emitting an import for it.
- Use `TypeGraph.canImport` (if implemented) or manually check `targetInfo.generators.drizzle`.

## 4. No Heuristic Constructor Fallbacks
When generating Dart JSON serialization (e.g., `fromJson`):
- Trust the `ctorParamNames` list provided by the analyzer.
- Do not use heuristics to guess constructor arguments based on field nullability. If `ctorParamNames` is empty, generate a no-argument constructor invocation followed by a cascade of property assignments.

## 5. Analyzer Over String Matching
Always prefer the `analyzer` package's type representations over regex or string matching when parsing Dart source code.
- Use `DartType.isDartCoreInt` rather than checking if `typeName == 'int'`.
- Use `ConstantReader` to read annotation values cleanly.
