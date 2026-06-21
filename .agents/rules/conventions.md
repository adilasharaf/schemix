# Schemix Conventions

Adhere to the following conventions to keep the Schemix codebase clean and predictable.

## 1. Naming Conventions

### Generators
- Generator classes should be suffixed with `Generator` (e.g., `ZodGenerator`, `TsGenerator`).
- Generator packages should be named `[target]_schemix_generator` (e.g., `zod_schemix_generator`, `drift_schemix_generator`).

### Generated Files
Outputs should be predictable and easily globbed by `schemix_index`.
- Zod/TS: `.g.ts`
- Drizzle: `.drizzle.ts`
- Drift: `.table.dart`
- Dart Schemix (JSON): `.schemix.dart`

## 2. Annotation Structure
- All core configurations should reside in `@Schemix()`.
- However, to avoid bloating the core annotation with third-party flags, use specific generator annotations when applicable (e.g., `@GenerateZod()`). These should be parsed into the `ClassInfo.extensions` map.

## 3. Builder Configuration (`build.yaml`)
- Registration builders (Phase 1/1.5) must declare `runs_before: ["schemix_builder|schemix_file"]`.
- Generators that depend on other generators (e.g., Drift's `table.dart` needing `drift_dev`) must clearly document these pipeline requirements.

## 4. Error Handling and Diagnostics
- When a user makes an error (e.g., missing `part` directive, conflicting annotations), do not fail silently.
- Emit a clear, actionable warning using `SchemixLogger.outputWarning` or via `build_runner`'s `log` instance. Explain exactly how the user can fix the issue.
