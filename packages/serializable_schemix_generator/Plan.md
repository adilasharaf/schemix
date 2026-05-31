# Schemix Serializable Generator Design Prompt

You are helping build the first official generator package in the Schemix ecosystem:

`serializable_schemix_generator`

Before proposing architecture or writing code, fully analyze the project context already available to you.

I will additionally provide:

- Schemix README.md
- Existing serializable generator source code
- Existing model definitions
- Existing generated outputs
- Existing architecture files
- Any related documentation

Your job is not to rewrite everything.

Your job is to extract the useful parts, identify what should be preserved, and redesign it to fit the new Schemix ecosystem.

---

# Context

Schemix has been split into multiple packages.

## schemix

Contains:

- Annotations
- Metadata models
- Generator contracts
- Shared utilities
- Shared constants

No analyzer logic.

No code generation logic.

No target-specific functionality.

---

## schemix_builder

Contains:

- Analyzer integration
- Metadata extraction
- Validation
- Registry
- Build infrastructure

Responsible for converting Dart source into normalized Schemix metadata.

No target-specific generation logic.

---

## Generator Packages

Examples:

- serializable_schemix_generator
- schemix_interface_generator
- schemix_zod_generator
- schemix_drift_generator
- schemix_drizzle_generator

Generators consume metadata produced by Schemix.

Generators should not depend on each other.

---

# Goal

Build the first generator package:

`serializable_schemix_generator`

This package should generate Dart serialization code from Schemix metadata.

The package should serve as the reference implementation for future generators.

Future generators should be able to follow its architecture.

---

# Phase 1 — Existing Generator Analysis

Analyze the old serializable generator.

Create a report containing:

## What should be preserved?

- Good design decisions
- Reusable logic
- Useful abstractions
- Stable APIs

## What should be removed?

- Tight coupling
- Legacy assumptions
- Generator-specific hacks
- Code that no longer fits Schemix

## What should be redesigned?

- Architecture
- Contracts
- Extension points
- Metadata consumption

---

# Phase 2 — Generator Architecture

Design the package structure.

Define:

## Public API

What should be exposed?

What should remain internal?

## Internal Modules

Possible examples:

- builder
- generator
- emitter
- serializer
- type_resolver
- metadata_mapper
- templates
- diagnostics

Do not blindly use these.

Create only what is necessary.

---

# Phase 3 — Metadata Integration

Assume metadata is produced by:

- schemix
- schemix_builder

Design how:

- Models are consumed
- Fields are consumed
- Types are consumed
- Enums are consumed
- Generics are consumed
- Inheritance is consumed

The generator must depend only on stable metadata contracts.

It must never access analyzer internals directly.

---

# Phase 4 — Serializable Generation Design

Define:

## Supported Output

- fromJson
- toJson
- nested models
- nullable fields
- lists
- maps
- enums
- generics
- inheritance

## Future Support

- custom converters
- field aliases
- ignored fields
- default values
- union types
- sealed classes

Identify what belongs in MVP vs later versions.

---

# Phase 5 — Package Structure

Propose:

```text
serializable_schemix_generator/
├── lib/
├── src/
├── builder/
├── generator/
├── emitter/
├── ...
```

Only create folders if they provide real value.

Avoid overengineering.

---

# Phase 6 — Generator Contract Review

Review the current Schemix generator API.

Determine:

- Is it sufficient?
- What is missing?
- What should change before building generators?
- What extension points are required?

If generator contract changes are needed, identify them before implementation.

---

# Phase 7 — Serializable Generator Roadmap

Create milestones:

## MVP

Minimum viable generator.

## Beta

Production-capable.

## Stable

Reference-quality implementation.

For each milestone provide:

- Deliverables
- Dependencies
- Risks
- Success criteria

---

# Phase 8 — Reference Generator Evaluation

This package will become the blueprint for:

- schemix_interface_generator
- schemix_zod_generator
- schemix_drift_generator
- schemix_drizzle_generator

Critically evaluate whether the architecture is reusable.

Identify anything that would cause future generators to duplicate logic.

Move shared concerns into:

- schemix
- schemix_builder

when appropriate.

---

# Rules

- Analyze before coding.
- Use the existing generator code as a source of knowledge, not as a source of truth.
- Favor simplicity.
- Avoid large files.
- Avoid unnecessary abstractions.
- Challenge existing decisions.
- Optimize for long-term ecosystem growth.
- Keep generators independent.
- Preserve clear boundaries between schemix, schemix_builder, and generator packages.

Final output should be:

1. Existing generator analysis
2. Architecture proposal
3. Package structure
4. Metadata integration design
5. Contract review
6. Roadmap
7. Recommended implementation order

Do not start implementation until the architecture has been reviewed.
