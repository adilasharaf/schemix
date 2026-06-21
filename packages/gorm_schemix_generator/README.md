# gorm_schemix_generator

A generator for Schemix that produces Go structs and Gorm ORM tags from Dart models.

## How it works

This package is part of the Schemix ecosystem. When added as a `dev_dependency` alongside `schemix_builder`, it registers itself to intercept models annotated with `@Schemix()`. 

For each class, it reads the properties, fields, validation rules, and outputs a `.go` file containing Go structs formatted with:
- Standard Go data types (e.g. `string`, `int`, `time.Time`, `bool`)
- Gorm ORM tags for database integrations (e.g. `gorm:"primaryKey"`, `gorm:"index"`)
- JSON tags for standard serialization (e.g. `json:"id"`)

## Usage

In your `pubspec.yaml`, add:

```yaml
dev_dependencies:
  gorm_schemix_generator: any
```

When you run `dart run build_runner build`, it will automatically generate `gen/{name}.go` alongside your Dart models.

## Annotations

The generator supports Schemix's universal annotations with specific Go/Gorm adaptations:

- `@GormIgnore()`: Excludes a field from being generated in Go.
- `@GormType('json.RawMessage')`: Overrides the Go type explicitly.
- `@PrimaryKey`, `@Indexed`, `@Unique`: Map to Gorm constraints.

## Requirements
- The generated Go files may import `time` and `encoding/json` depending on the types used in your models.
