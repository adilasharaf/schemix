# 02: Annotation Reference

This document provides a summary of the most commonly used Schemix annotations. For the full exhaustive list, refer to the source `README.md`.

## 1. Schema-Level Annotations
- `@Schemix()`: The root annotation. Every generated class must carry this. Controls table name, timestamp injection, and which generators are active.
- `@SchemaGroup(String name)`: Groups a schema into a named domain for documentation.
- `@DeprecatedSchema()`: Marks the entire schema as deprecated, emitting deprecation comments in outputs.

## 2. Field Metadata
- `@SchemixField` / `@AppField`: Controls field visibility (`searchable`, `hidden`, `internal`, `readonly`).
- `@IgnoreField()`: Excludes the field entirely from all generators.

## 3. Database & Primary Keys
- `@PrimaryKey(autoGenerate: true)`: Marks the primary key. If string, emits a UUID v4 client-side default.
- `@Indexed(unique: true)`: Creates an index or enforces uniqueness.
- `@SqlType(String)`, `@DrizzleType(String)`, `@DriftType(String)`: Overrides the raw database type for specific generator targets.

## 4. Relations
- `@BelongsTo(TargetClass)`: Many-to-one. The annotated field stores the foreign-key ID.
- `@HasOne(TargetClass)`: One-to-one. The FK lives on the target model.
- `@HasMany(TargetClass)`: One-to-many. Generates a virtual relation reference.
- `@ManyToMany(TargetClass)`: Many-to-many via a junction table.

## 5. Validation (Zod/TS)
All validation annotations emit corresponding Zod schema constraints.
- `@Required()`: Emits `.min(1)` for strings or `.nonEmpty()` for arrays.
- `@Min(num)` / `@Max(num)`: Emits `.gte()` and `.lte()`.
- `@Length(min, max)`: Emits `.min().max()`.
- `@Email()`, `@Url()`, `@Uuid()`: Format validators.

## 6. Type Overrides
- `@TsType(String)`: Overrides the TypeScript type.
- `@ZodType(String)`: Overrides the full Zod expression.
- `@CustomConverter(...)`: Unified override spanning all generation targets.

## 7. Security & Sync
- `@Encrypted()` / `@Hashed()`: Marks fields as sensitive, redacting them from public API outputs.
- `@OfflineOnly()`: Never synced to the server.
- `@CloudOnly()`: Never stored locally.
