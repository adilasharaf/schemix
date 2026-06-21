# 00: Overview & Quick Start

## What is Schemix?

Schemix is a zero-runtime Dart library that acts as a single source of truth for full-stack application models. 
You define a Dart model once, and Schemix generates:
- Zod schemas (for validation)
- TypeScript interfaces (for the frontend/Node backend)
- Drift tables (for local Dart SQL databases)
- Drizzle schemas (for TypeScript SQL ORMs)
- JSON serialization (for Dart models)

## How It Works

Schemix operates purely as a `build_runner` plugin in three distinct phases:

1. **Scan** — reads every `lib/**.dart` file and builds a complete type graph (`schemix_registry.json`).
2. **Generate** — reads the registry and analyzes annotations to call each active generator on a per-file basis.
3. **Index** — emits a barrel file (e.g., `gen/schemix.g.ts`) that re-exports every generated schema.

There is **no runtime dependency**. You only add `schemix` to your regular `dependencies` for the annotations, and `schemix_builder` to your `dev_dependencies`.

## Package Map

Schemix is split into a core package and several generator plugins. 

| Package                          | Role                                                                | Add as                      |
| -------------------------------- | ------------------------------------------------------------------- | --------------------------- |
| `schemix`                        | Annotations, `ClassInfo`, `FieldInfo`, `SchemixGenerator` interface | `dependency`                |
| `schemix_builder`                | Build infrastructure, scan/file/index builders                      | `dev_dependency`            |
| `schemix_zod_generator`          | Zod + TypeScript output                                             | `dev_dependency`            |
| `schemix_drift_generator`        | Drift table classes                                                 | `dev_dependency`            |
| `schemix_drizzle_generator`      | Drizzle ORM schemas                                                 | `dev_dependency`            |
| `schemix_serializable_generator` | Dart JSON serialization                                             | `dev_dependency`            |
| `schemix_firebase`               | Firebase type descriptors (Timestamp, GeoPoint, etc.)               | `dependency` (optional)     |
| `schemix_generator_sdk`          | Test utilities for generator authors                                | `dev_dependency` (optional) |

*Important:* No generator package depends on another generator package, and no generator package depends on `schemix_builder`.
