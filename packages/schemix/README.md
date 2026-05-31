# Schemix

Define a Dart model once. Generate Zod schemas, TypeScript interfaces, Drift tables, Drizzle schemas, and JSON serialization from a single annotated class — with zero runtime footprint.

---

## Table of Contents

- [How It Works](#how-it-works)
- [Quick Start](#quick-start)
- [Annotation Reference](#annotation-reference)
  - [1. Schema-Level](#1-schema-level)
  - [2. Field Metadata](#2-field-metadata)
  - [3. Primary Key & Database](#3-primary-key--database)
  - [4. Relations](#4-relations)
  - [5. Validation](#5-validation)
  - [6. Serialization](#6-serialization)
  - [7. Type Overrides](#7-type-overrides)
  - [8. Platform-Specific Exclusions](#8-platform-specific-exclusions)
  - [9. Security](#9-security)
  - [10. UI Metadata](#10-ui-metadata)
  - [11. Lifecycle](#11-lifecycle)
  - [12. Sync & Offline](#12-sync--offline)
  - [13. API](#13-api)
  - [14. Audit & Tracking](#14-audit--tracking)
  - [15. Migration](#15-migration)
  - [16. Feature & Release Control](#16-feature--release-control)
  - [17. Slug](#17-slug)
  - [18. Generator Control](#18-generator-control)
- [Writing a Custom Generator](#writing-a-custom-generator)
- [Build Pipeline](#build-pipeline)
- [Package Map](#package-map)

---

## How It Works

Schemix is a `build_runner` plugin. It runs in three phases:

1. **Scan** — reads every `lib/**.dart` file and builds a type graph (`schemix_registry.json`).
2. **Generate** — reads the registry + one source file per invocation, analyzes annotations, and calls each active generator.
3. **Index** — emits a barrel `gen/schemix.g.ts` that re-exports every generated Zod schema.

There is no runtime dependency. Add `schemix` to your regular `dependencies` (for the annotations) and `schemix_builder` to `dev_dependencies` (for the build tooling).

---

## Quick Start

**pubspec.yaml**

```yaml
dependencies:
  schemix: any

dev_dependencies:
  schemix_builder: any
  build_runner: ^2.4.0
```

**Define a model**

```dart
import 'package:schemix/schemix.dart';

@Schemix(
  tableName: 'users',
  schemaVersion: 1,
  enableTimestamps: true,
  generateZod: true,
  generateDrift: true,
)
class User {
  @PrimaryKey(autoGenerate: true)
  final String id;

  @Email()
  @Length(max: 255)
  final String email;

  @Hashed()
  final String passwordHash;

  @Indexed()
  final String tenantId;

  const User({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.tenantId,
  });
}
```

**Run the build**

```bash
dart run build_runner build
```

**Outputs**

```
lib/user.schemix.dart     ← Dart JSON serialization
lib/user.table.dart       ← Drift table class
gen/user.g.ts             ← Zod schema + TypeScript interface
gen/user.drizzle.ts       ← Drizzle ORM table schema
gen/schemix.g.ts          ← Barrel re-export
```

---

## Annotation Reference

---

### 1. Schema-Level

#### `@Schemix`

The root annotation. Every class that should produce generated output must carry this. Controls the table name, schema version, timestamp injection, soft-delete, and which generators are active.

```dart
@Schemix(
  tableName: 'business_entities',
  schemaVersion: 2,
  namespace: 'billing',
  enableTimestamps: true,
  enableSoftDelete: true,
  generateZod: true,
  generateDrift: true,
  generateDrizzle: false,
)
class Business { ... }
```

| Parameter          | Type      | Default                  | Description                                             |
| ------------------ | --------- | ------------------------ | ------------------------------------------------------- |
| `tableName`        | `String?` | snake_case of class name | SQL / Drift / Drizzle table name                        |
| `collectionName`   | `String?` | —                        | Firestore collection name                               |
| `schemaVersion`    | `int`     | `1`                      | Monotonically increasing version for migration tracking |
| `namespace`        | `String?` | —                        | Logical domain grouping, e.g. `'auth'`, `'billing'`     |
| `enableTimestamps` | `bool`    | `true`                   | Auto-injects `createdAt` / `updatedAt` if not declared  |
| `enableSoftDelete` | `bool`    | `true`                   | Auto-injects `deletedAt` nullable column                |
| `abstractSchema`   | `bool`    | `false`                  | No table generated; class is only extended by others    |
| `cacheable`        | `bool`    | `true`                   | Model may be cached at runtime                          |
| `syncable`         | `bool`    | `true`                   | Model participates in the sync engine                   |
| `embeddable`       | `bool`    | `false`                  | Fields are inlined into a parent table; no own table    |
| `generateZod`      | `bool`    | `true`                   | Emit `gen/{path}.g.ts`                                  |
| `generateDrift`    | `bool`    | `true`                   | Emit `lib/{path}.table.dart`                            |
| `generateDrizzle`  | `bool`    | `true`                   | Emit `gen/{path}.drizzle.ts`                            |

---

#### `@SchemaGroup`

Groups a schema into a named domain. Informational — used by tooling for documentation and organization reports.

```dart
@SchemaGroup('billing')
@Schemix()
class Invoice { ... }
```

---

#### `@SchemaDescription`

Attaches a human-readable description to a schema. The text propagates into generated code comments and API documentation.

```dart
@SchemaDescription('Represents a registered business entity with billing info.')
@Schemix()
class Business { ... }
```

---

#### `@DeprecatedSchema`

Marks an entire schema class as deprecated. Generators emit a deprecation comment in all outputs. Provide `replacement` so consumers know where to migrate.

```dart
@DeprecatedSchema(
  reason: 'Replaced by BusinessV2 with normalized address fields.',
  replacement: 'BusinessV2',
  removalVersion: '4.0.0',
)
class Business { ... }
```

---

### 2. Field Metadata

#### `@SchemixField` / `@AppField`

Rich per-field metadata controlling visibility, searchability, and display hints. `@AppField` is a typedef alias — use whichever reads better in context.

```dart
@SchemixField(
  searchable: true,
  sortable: true,
  filterable: true,
  displayName: 'Business Name',
  description: 'Legal registered name of the business.',
  example: 'Acme Corp',
)
final String businessName;
```

| Parameter    | Default | Effect                                       |
| ------------ | ------- | -------------------------------------------- |
| `immutable`  | `false` | Field cannot change after creation           |
| `readonly`   | `false` | Exposed for reads; clients cannot set it     |
| `hidden`     | `false` | Hidden from UI but present in all outputs    |
| `internal`   | `false` | Excluded from all external (public) outputs  |
| `searchable` | `false` | Included in full-text search indexes         |
| `sortable`   | `false` | May be used as a sort key in queries         |
| `filterable` | `false` | May be used as a query filter                |
| `computed`   | `false` | Derived value; never written to the database |
| `transient`  | `false` | In-memory only; never persisted              |
| `virtual`    | `false` | Exists in the type system only; no DB column |
| `generated`  | `false` | Value is produced by the database engine     |
| `unique`     | `false` | Value must be unique across all rows         |
| `sensitive`  | `false` | Contains PII or confidential data            |

---

### 3. Primary Key & Database

#### `@PrimaryKey`

Marks the primary key field. For `String` PKs, `autoGenerate: true` emits a UUID v4 client-side default. For `int` PKs, it maps to `SERIAL` / `AUTOINCREMENT`.

```dart
@PrimaryKey(autoGenerate: true)
final String id;

// Composite PK — declare compositeOrder on each participating field
@PrimaryKey(compositeOrder: 1)
final String tenantId;

@PrimaryKey(compositeOrder: 2)
final String userId;
```

---

#### `@Indexed`

Creates a database index on this field. Supports unique, descending, full-text, and spatial variants.

```dart
@Indexed(unique: true)
final String email;

@Indexed(fullText: true)
final String description;
```

---

#### `@CompositeIndex`

Class-level annotation. Creates a multi-column index. Apply multiple times for multiple composite indexes.

```dart
@CompositeIndex(fields: ['email', 'tenantId'], unique: true)
@CompositeIndex(fields: ['createdAt', 'status'])
@Schemix()
class User { ... }
```

---

#### `@Unique`

Shorthand for `@Indexed(unique: true)`. Use when you only need the uniqueness constraint with no other index options.

```dart
@Unique()
final String slug;
```

---

#### `@AutoIncrement`

Marks an `int` PK as auto-increment (`SERIAL` in PostgreSQL, `AUTOINCREMENT` in SQLite). Use alongside `@PrimaryKey`.

```dart
@PrimaryKey(autoGenerate: false)
@AutoIncrement()
final int id;
```

---

#### `@DatabaseGenerated`

Indicates the column value is entirely produced by the database engine (sequences, expressions, `DEFAULT gen_random_uuid()`).

```dart
@DatabaseGenerated(strategy: 'uuid')
final String id;
```

---

#### `@SqlType`

Overrides the raw SQL column type emitted for this field. Use when the default mapping is not precise enough.

```dart
@SqlType('JSONB')
final Map<String, dynamic> metadata;

@SqlType('TIMESTAMPTZ')
final DateTime scheduledAt;
```

---

#### `@DrizzleType`

Overrides the Drizzle ORM column builder function for this field.

```dart
@DrizzleType('jsonb')
final Map<String, dynamic> settings;
```

---

#### `@DriftType`

Overrides the Drift column builder type for this field.

```dart
@DriftType('text')
final MyCustomEnum status;
```

---

#### `@DatabaseDefault`

Sets a database-level default value. Accepts Dart primitives and enum constants.

```dart
@DatabaseDefault(UserStatus.active)
final UserStatus status;

@DatabaseDefault(0)
final int loginCount;
```

---

#### `@CheckConstraint`

Adds a SQL `CHECK` constraint to the column. The expression is written in SQL and must evaluate to true for every row.

```dart
@CheckConstraint('price >= 0')
final double price;

@CheckConstraint("status IN ('active', 'inactive', 'pending')")
final String status;
```

---

#### `@SecondaryKey`

Marks a field as an alternate lookup key (not the primary key). Informational for generators that produce repository or query helpers.

```dart
@SecondaryKey()
final String externalReferenceId;
```

---

#### `@PartitionKey`

Marks the partition key for distributed or sharded databases (e.g. DynamoDB, Cassandra).

```dart
@PartitionKey()
final String tenantId;
```

---

#### `@SortKey`

Marks a sort key for distributed or time-series databases. Used alongside `@PartitionKey`.

```dart
@SortKey(descending: true)
final DateTime createdAt;
```

---

#### `@FullTextSearch`

Marks a field for inclusion in a full-text search index. Equivalent to `@Indexed(fullText: true)` but reads more clearly on string fields.

```dart
@FullTextSearch()
final String bio;
```

---

#### `@CachedField`

Marks a field whose value may be cached independently at the application layer.

```dart
@CachedField()
final String avatarUrl;
```

---

### 4. Relations

#### `@BelongsTo`

Many-to-one. The annotated field stores the foreign-key ID. Generators emit an FK column.

```dart
@BelongsTo(User)
final String userId;

// With explicit FK name
@BelongsTo(Organization, foreignKey: 'org_id')
final String organizationId;
```

---

#### `@HasOne`

One-to-one. No column is emitted on this side; the FK lives on the target model. The field type is typically the target class or its ID type.

```dart
@HasOne(Profile)
final Profile? profile;
```

---

#### `@HasMany`

One-to-many. No column is emitted. Generators produce a virtual relation reference that is resolved via a FK on the target model.

```dart
@HasMany(Invoice)
final List<Invoice> invoices;
```

---

#### `@ManyToMany`

Many-to-many via a junction table. No column is emitted. Provide `junctionTable` explicitly to control the junction table name.

```dart
@ManyToMany(Tag, junctionTable: 'product_tags')
final List<Tag> tags;
```

---

#### `@Embedded`

Inlines the target class's fields into this model's table. No join is needed. The target class must be annotated with `@Schemix(embeddable: true)`.

```dart
@Embedded()
final Address? address;
```

---

#### `@RelationField`

Marks a field as the raw FK column that backs a named relation field on the same class. Connects the FK integer/string to its relation counterpart.

```dart
@BelongsTo(User)
final User? user;

@RelationField(fieldName: 'user')
final String userId;
```

---

#### `@CascadeDelete`

Marks a relation so that deleting the owner row also deletes all related rows (ON DELETE CASCADE).

```dart
@CascadeDelete()
@HasMany(OrderItem)
final List<OrderItem> items;
```

---

#### `@LazyRelation`

Marks a relation as lazy-loaded. Generators that produce query helpers will not eagerly fetch this relation with the parent.

```dart
@LazyRelation()
@HasMany(AuditLog)
final List<AuditLog> auditLogs;
```

---

### 5. Validation

All validation annotations emit corresponding Zod schema constraints in the generated TypeScript output.

#### `@Required`

Field must be present and non-empty. Emits `.min(1)` for strings, `.nonEmpty()` for arrays.

```dart
@Required()
final String businessName;
```

---

#### `@Min` / `@Max`

Numeric range constraints (inclusive). Emit `.gte(value)` and `.lte(value)` in Zod.

```dart
@Min(0)
@Max(1000000)
final double price;
```

---

#### `@Length`

String length constraint. Emit `.min(n).max(n)` in Zod.

```dart
@Length(min: 3, max: 150)
final String username;
```

---

#### `@Regex`

Validates the field value against a regular expression. Emits `.regex(/pattern/)` in Zod.

```dart
@Regex(r'^[A-Z]{2}\d{6}$')
final String passportNumber;
```

---

#### `@Email` / `@Url` / `@Phone` / `@IpAddress` / `@Uuid`

Format validators. Each emits the corresponding Zod format method (`.email()`, `.url()`, `.ip()`, `.uuid()`).

```dart
@Email()
final String email;

@Url()
final String? websiteUrl;

@Uuid()
final String externalId;
```

---

#### `@EnumFallback`

Specifies a fallback enum value when deserialization receives an unknown variant. Emits `.catch(value)` in Zod, preventing parse failures on unknown server values.

```dart
@EnumFallback(BusinessType.other)
final BusinessType type;
```

---

#### `@AllowedValues` / `@DisallowValues`

Restricts or rejects a fixed set of values. Emit `.refine(...)` predicates in Zod.

```dart
@AllowedValues(['retail', 'wholesale', 'online'])
final String channel;

@DisallowValues(['admin', 'root', 'superuser'])
final String username;
```

---

### 6. Serialization

#### `@JsonField`

Sets a custom JSON key name for this field. Takes priority over `@JsonKey(name:)` and the default snake_case fallback.

```dart
@JsonField('business_name')
final String businessName;
```

---

#### `@IgnoreField`

Excludes this field from all serialization and code generation outputs entirely. Cannot be combined with `@PrimaryKey`, validation, or relation annotations.

```dart
@IgnoreField()
final String _internalCache;
```

---

#### `@ReadOnlyField` / `@WriteOnlyField`

`@ReadOnlyField` — serialized in responses, never accepted from clients.
`@WriteOnlyField` — accepted on writes, never included in responses.

```dart
@WriteOnlyField()
final String passwordHash;

@ReadOnlyField()
final String generatedSlug;
```

---

#### `@Flatten`

Flattens a nested object's fields into the parent JSON object, removing the nesting level.

```dart
@Flatten()
final Address address;
// Serializes as { street: '...', city: '...' } instead of { address: { street: '...' } }
```

---

#### `@DateFormat`

Specifies a custom date format string for DateTime serialization.

```dart
@DateFormat('yyyy-MM-dd')
final DateTime birthDate;
```

---

#### `@Precision`

Specifies decimal precision and scale for numeric fields. Maps to `DECIMAL(precision, scale)` in SQL.

```dart
@Precision(precision: 18, scale: 2)
final double amount;
```

---

#### `@SerializeAs`

Instructs serialization to write the value as a different type.

```dart
@SerializeAs('string')
final int legacyId;
```

---

### 7. Type Overrides

#### `@TsType`

Overrides the TypeScript type and optionally the Zod schema for this field. Use for branded types, union types, or any type the default resolver cannot infer.

```dart
@TsType('string | number')
final dynamic id;

@TsType("UserId", zodSchema: "z.string().brand('UserId')")
final String userId;
```

---

#### `@ZodType`

Overrides the full Zod schema expression for this field. Use when `@TsType(zodSchema:)` is too verbose.

```dart
@ZodType("z.string().brand('TenantId')")
final String tenantId;
```

---

#### `@CustomConverter`

Unified type override spanning all generation targets. Use when a field needs custom handling in Dart, TypeScript, SQL, and Drizzle simultaneously.

```dart
@CustomConverter(
  dartConverter: 'MetadataConverter',
  tsConverter: "z.record(z.string(), z.unknown())",
  sqlType: 'JSONB',
  drizzleType: 'jsonb',
)
final Map<String, dynamic>? metadata;
```

---

### 8. Platform-Specific Exclusions

Use these to exclude a field from a single generator target while keeping it in all others.

#### `@DriftIgnore`

Excludes this field from the Drift table generator only.

```dart
@DriftIgnore()
final String computedDisplayName;
```

---

#### `@DrizzleIgnore`

Excludes this field from the Drizzle schema generator only.

```dart
@DrizzleIgnore()
final String localOnlyFlag;
```

---

#### `@ZodIgnore`

Excludes this field from the Zod schema and TypeScript interface only.

```dart
@ZodIgnore()
final String internalServerId;
```

---

### 9. Security

#### `@Encrypted`

Marks a field as encrypted at rest. Excluded from API response DTOs unless `@ApiField(expose: true)` is set.

```dart
@Encrypted()
final String taxIdentificationNumber;
```

---

#### `@Hashed`

Marks a field as hashed (passwords, API keys). Excluded from API response DTOs. Never included in read outputs by default.

```dart
@Hashed()
final String passwordHash;
```

---

#### `@Sensitive`

Marks a field as sensitive PII. Excluded from API response DTOs. Generators emit appropriate warnings in comments.

```dart
@Sensitive()
final String socialSecurityNumber;
```

---

#### `@MaskInLogs`

Redacts this field's value in application and server logs.

```dart
@MaskInLogs()
final String creditCardNumber;
```

---

#### `@PermissionRequired`

Restricts read access to this field to callers who hold the given permission string.

```dart
@PermissionRequired('admin')
final double internalCostPrice;
```

---

#### `@ReadScope` / `@WriteScope`

Restricts read or write access to callers who hold one of the listed OAuth / RBAC scope strings.

```dart
@ReadScope(['admin', 'owner'])
@WriteScope(['owner'])
final String privateNotes;
```

---

### 10. UI Metadata

#### `@UiField`

Display metadata for generated form and table UIs. Consumed by generators that produce UI scaffolding.

```dart
@UiField(
  label: 'Business Name',
  icon: 'business',
  section: 'general',
  order: 1,
  helpText: 'Enter the legal registered name.',
  tooltip: 'This must match your business registration certificate.',
)
final String businessName;
```

---

#### `@FormField`

Controls the input widget type and behaviour for generated forms.

```dart
@FormField(widgetType: 'textarea', multiline: true, autofocus: false)
final String description;
```

---

#### `@TableColumn`

Column display hints for generated data-table UIs.

```dart
@TableColumn(width: 200, align: 'left', sortable: true)
final String businessName;
```

---

#### `@ColorField` / `@ImageField` / `@FileField`

Mark string fields as holding a colour hex value, an image URL, or a file URL. Form generators render the appropriate picker widget.

```dart
@ColorField()
final String brandColor;

@ImageField()
final String? logoUrl;

@FileField()
final String? attachmentUrl;
```

---

#### `@FilterField` / `@SearchField`

Mark fields that should appear in query filter UIs or search bars.

```dart
@FilterField()
@SearchField()
final String status;
```

---

### 11. Lifecycle

#### `@CreatedAt`

Marks a `DateTime` field as the record creation timestamp. Auto-excluded from create/update API DTOs.

```dart
@CreatedAt()
final DateTime createdAt;
```

---

#### `@UpdatedAt`

Marks a `DateTime` field as the last-updated timestamp. Auto-excluded from create/update DTOs.

```dart
@UpdatedAt()
final DateTime updatedAt;
```

---

#### `@DeletedAt`

Marks a nullable `DateTime` field as the soft-delete timestamp. Non-null means the record is deleted. Used with `@Schemix(enableSoftDelete: true)`.

```dart
@DeletedAt()
final DateTime? deletedAt;
```

---

#### `@VersionField`

Marks an `int` field as an optimistic-concurrency version counter. Incremented on every update. Auto-excluded from create/update DTOs.

```dart
@VersionField()
final int version;
```

---

#### `@AuditField`

Marks a field as an audit-trail marker. Generators that produce change-history tables include this field in the audit schema.

```dart
@AuditField()
final String lastModifiedBy;
```

---

### 12. Sync & Offline

#### `@ConflictResolver`

Class-level. Specifies how write conflicts should be resolved during sync. Strategies: `'latestWins'`, `'firstWins'`, `'merge'`.

```dart
@ConflictResolver(strategy: 'latestWins')
@Schemix(syncable: true)
class Document { ... }
```

---

#### `@OfflineOnly`

Field exists only in the local database — never synced to the server. Excluded from Zod / TypeScript outputs.

```dart
@OfflineOnly()
final bool isDirty;
```

---

#### `@CloudOnly`

Field exists only in the remote/cloud database — not stored locally. Excluded from Drift / Drizzle table generation.

```dart
@CloudOnly()
final String cloudProcessingJobId;
```

---

#### `@SyncPriority`

Sets the sync priority for this field during conflict resolution. Higher values are synced first.

```dart
@SyncPriority(priority: 10)
final String criticalFlag;
```

---

#### `@OperationTracked`

Every mutation to this field is recorded as an operation log entry, enabling CRDT-style merge strategies.

```dart
@OperationTracked()
final int counter;
```

---

### 13. API

#### `@ApiField`

Controls how this field appears in generated API DTO interfaces. Set `expose: false` to remove it from all DTOs entirely.

```dart
@ApiField(expose: true, readonly: true, deprecated: false)
final String publicId;

@ApiField(expose: false)
final String internalAuditKey;
```

---

#### `@ApiVersion`

Tracks the API version lifecycle of a field. Generators emit appropriate deprecation warnings and changelog comments.

```dart
@ApiVersion(introducedIn: '1.2.0', deprecatedIn: '2.0.0', removedIn: '3.0.0')
final String legacyCode;
```

---

#### `@DtoOnly`

Field is included in DTO interfaces only — not persisted to the database. Useful for computed or joined values returned by APIs.

```dart
@DtoOnly()
final String displayLabel;
```

---

#### `@InternalApi`

Field is for internal server use only. Excluded from all public API DTOs regardless of other settings.

```dart
@InternalApi()
final String serviceRoutingKey;
```

---

### 14. Audit & Tracking

#### `@TrackChanges`

Records every mutation to this field in the audit log table.

```dart
@TrackChanges()
final String status;
```

---

#### `@TrackAnalytics`

Emits an analytics event whenever this field changes. `eventName` defaults to a generated name based on class and field.

```dart
@TrackAnalytics(eventName: 'subscription_plan_changed')
final String subscriptionPlan;
```

---

#### `@LogChanges`

Logs every write to this field using the application's structured logging system.

```dart
@LogChanges()
final String adminOverrideReason;
```

---

### 15. Migration

#### `@RenamedFrom`

Records that this field was previously named `oldName`. Generators use this to produce `ALTER TABLE RENAME COLUMN` migration scripts.

```dart
@RenamedFrom('company_name')
final String businessName;
```

---

#### `@RemovedIn`

Marks a field as scheduled for removal in the given semver version. Generators emit a deprecation warning in all outputs.

```dart
@RemovedIn('3.0.0')
final String legacyExternalId;
```

---

#### `@MigrationNote`

Attaches a free-form migration note to a field. Appears in generated migration scripts as a comment.

```dart
@MigrationNote('Backfill from the legacy profile table using the data pipeline in scripts/migrate_profile.ts')
final String normalizedAddress;
```

---

#### `@LegacyField`

Marks a field as a legacy carry-over that exists only for backwards compatibility. Excluded from new code generation paths.

```dart
@LegacyField()
final String oldFormatPhone;
```

---

### 16. Feature & Release Control

#### `@FeatureFlag`

Gates this field behind a named feature flag. Generators emit conditional logic or comments referencing the flag identifier.

```dart
@FeatureFlag('new_billing_flow')
final String stripePaymentMethodId;
```

---

#### `@Experimental`

Marks a field as experimental. Generated code includes a warning comment so consumers know the API may change.

```dart
@Experimental()
final Map<String, dynamic> aiGeneratedTags;
```

---

#### `@EnterpriseOnly`

Marks a field as available to enterprise-tier users only. Generators can emit tier-gating comments or exclude the field from public SDK output.

```dart
@EnterpriseOnly()
final String ssoConfigurationId;
```

---

### 17. Slug

#### `@SlugField`

Marks a field as a URL-safe slug derived from another field's value. Combine with `@Indexed(unique: true)` to enforce uniqueness.

```dart
@SlugField(sourceField: 'businessName', separator: '-')
@Indexed(unique: true)
final String slug;
// 'Acme Corp' → 'acme-corp'
```

---

### 18. Generator Control

#### `@ManualImplementation`

Opts this class out of automatic code generation entirely. All output files must be written by hand. Use when the generated output is structurally incompatible with your requirements.

```dart
@ManualImplementation()
@Schemix()
class ComplexCustomModel { ... }
```

---

## Writing a Custom Generator

Any package can publish a Schemix generator. Add `schemix` as a dependency, implement the `SchemixGenerator` interface, and declare a `build.yaml` builder.

### 1. Implement `SchemixGenerator`

```dart
import 'package:schemix/schemix.dart';

class MyCustomGenerator implements SchemixGenerator {
  @override
  String get id => 'my_custom_generator';

  @override
  List<String> get outputExtensions => ['.my.output'];

  @override
  bool shouldRun(ClassInfo classInfo) {
    // Return false cheaply if this class is not relevant.
    return classInfo.hasSchemix && !classInfo.abstractSchema;
  }

  @override
  GeneratorOutput generate(ClassInfo classInfo, GeneratorContext context) {
    final buf = StringBuffer();

    // Use context.typeGraph to resolve cross-file types.
    for (final field in classInfo.allFields) {
      if (field.isIgnored) continue;

      // Store generator-specific metadata in extensions rather than
      // adding fields to FieldInfo.
      final meta = field.extensions[id];

      buf.writeln('// field: ${field.name}  type: ${field.dartType}');
    }

    return GeneratorOutput({'.my.output': buf.toString()});
  }
}
```

### 2. Register the generator

```dart
// In your builder factory:
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
      - "lib/schemix_registry.json"
```

`required_inputs: [lib/schemix_registry.json]` is mandatory — it ensures the scan phase completes before your generator runs and that `build_runner` correctly invalidates your outputs when the type graph changes.

### Key interfaces

**`TypeGraph`** — read-only view of the cross-file type graph. Available via `context.typeGraph`.

```dart
context.typeGraph.isEnum('MyEnum');           // true/false
context.typeGraph.isModel('User');            // true/false
context.typeGraph.resolve('User');            // TypeInfo?
context.typeGraph.cyclicTypes;               // Set<String> — types in reference cycles
context.typeGraph.relativeImportFor(
  typeName: 'User',
  fromSourceAssetPath: context.sourceAssetPath,
);  // relative import path for cross-file references, or null if same file
```

**`ClassInfo`** — fully analyzed schema class.

```dart
classInfo.name                // 'User'
classInfo.tableName           // 'users' (explicit) or null (use snake_case of name)
classInfo.allFields           // inherited + own fields
classInfo.ownFields           // fields declared on this class only
classInfo.generators.zod      // true/false
classInfo.generators.drift    // true/false
classInfo.compositeIndexes    // List<CompositeIndexInfo>
classInfo.enableTimestamps    // bool
classInfo.abstractSchema      // bool
```

**`FieldInfo`** — analyzed field with all annotation data.

```dart
field.name                    // 'emailAddress'
field.dartType                // 'String'
field.isNullable              // true/false
field.isList                  // true/false
field.listItemType            // 'Tag' (for List<Tag>)
field.isEnum                  // true/false
field.isIgnored               // true — skip this field entirely
field.effectiveJsonName       // 'email_address' (respects @JsonField / snake_case)
field.db.isPrimaryKey         // true/false
field.db.isIndexed            // true/false
field.db.sqlType              // 'JSONB' (from @SqlType) or null
field.relation.kind           // RelationKind.belongsTo / hasMany / etc.
field.relation.targetTypeName // 'User'
field.validation.isEmail      // true/false
field.validation.minLength    // 3 (from @Length(min: 3))
field.security.encrypted      // true/false
field.security.sensitive      // true/false
field.sync.offlineOnly        // true/false
field.sync.cloudOnly          // true/false
field.platform.zodIgnore      // true/false
field.platform.driftIgnore    // true/false
field.converter.zodTypeOverride // 'z.string().brand(...)' or null
field.isCreatedAt             // true/false
field.isUpdatedAt             // true/false
field.extensions[myGeneratorId] // generator-specific metadata
```

---

## Build Pipeline

```
Phase 1 — SchemixScanBuilder
  Input:   all lib/**.dart
  Output:  lib/schemix_registry.json  (build_to: cache)
  Purpose: builds the cross-file type graph once per package

Phase 2 — SchemixFileBuilder  (+ any custom generators)
  Input:   one lib/{name}.dart + lib/schemix_registry.json
  Output:  lib/{name}.schemix.dart
           lib/{name}.table.dart
           gen/{name}.g.ts
           gen/{name}.drizzle.ts
  Purpose: full per-file code generation using the type graph

Phase 3 — SchemixIndexBuilder
  Input:   all gen/**.g.ts
  Output:  gen/schemix.g.ts  (barrel re-export)
  Purpose: single import point for all Zod schemas
```

Custom generators run in Phase 2. They must list `lib/schemix_registry.json` in `required_inputs` so `build_runner` tracks the dependency correctly and invalidates outputs when the type graph changes.

---

## Package Map

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

No generator package depends on another generator package. No generator package depends on `schemix_builder`. These two rules must never be broken.# Schemix

Define a Dart model once. Generate Zod schemas, TypeScript interfaces, Drift tables, Drizzle schemas, and JSON serialization from a single annotated class — with zero runtime footprint.

---

## Table of Contents

- [How It Works](#how-it-works)
- [Quick Start](#quick-start)
- [Annotation Reference](#annotation-reference)
  - [1. Schema-Level](#1-schema-level)
  - [2. Field Metadata](#2-field-metadata)
  - [3. Primary Key & Database](#3-primary-key--database)
  - [4. Relations](#4-relations)
  - [5. Validation](#5-validation)
  - [6. Serialization](#6-serialization)
  - [7. Type Overrides](#7-type-overrides)
  - [8. Platform-Specific Exclusions](#8-platform-specific-exclusions)
  - [9. Security](#9-security)
  - [10. UI Metadata](#10-ui-metadata)
  - [11. Lifecycle](#11-lifecycle)
  - [12. Sync & Offline](#12-sync--offline)
  - [13. API](#13-api)
  - [14. Audit & Tracking](#14-audit--tracking)
  - [15. Migration](#15-migration)
  - [16. Feature & Release Control](#16-feature--release-control)
  - [17. Slug](#17-slug)
  - [18. Generator Control](#18-generator-control)
- [Writing a Custom Generator](#writing-a-custom-generator)
- [Build Pipeline](#build-pipeline)
- [Package Map](#package-map)

---

## How It Works

Schemix is a `build_runner` plugin. It runs in three phases:

1. **Scan** — reads every `lib/**.dart` file and builds a type graph (`schemix_registry.json`).
2. **Generate** — reads the registry + one source file per invocation, analyzes annotations, and calls each active generator.
3. **Index** — emits a barrel `gen/schemix.g.ts` that re-exports every generated Zod schema.

There is no runtime dependency. Add `schemix` to your regular `dependencies` (for the annotations) and `schemix_builder` to `dev_dependencies` (for the build tooling).

---

## Quick Start

**pubspec.yaml**

```yaml
dependencies:
  schemix: any

dev_dependencies:
  schemix_builder: any
  build_runner: ^2.4.0
```

**Define a model**

```dart
import 'package:schemix/schemix.dart';

@Schemix(
  tableName: 'users',
  schemaVersion: 1,
  enableTimestamps: true,
  generateZod: true,
  generateDrift: true,
)
class User {
  @PrimaryKey(autoGenerate: true)
  final String id;

  @Email()
  @Length(max: 255)
  final String email;

  @Hashed()
  final String passwordHash;

  @Indexed()
  final String tenantId;

  const User({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.tenantId,
  });
}
```

**Run the build**

```bash
dart run build_runner build
```

**Outputs**

```
lib/user.schemix.dart     ← Dart JSON serialization
lib/user.table.dart       ← Drift table class
gen/user.g.ts             ← Zod schema + TypeScript interface
gen/user.drizzle.ts       ← Drizzle ORM table schema
gen/schemix.g.ts          ← Barrel re-export
```

---

## Annotation Reference

---

### 1. Schema-Level

#### `@Schemix`

The root annotation. Every class that should produce generated output must carry this. Controls the table name, schema version, timestamp injection, soft-delete, and which generators are active.

```dart
@Schemix(
  tableName: 'business_entities',
  schemaVersion: 2,
  namespace: 'billing',
  enableTimestamps: true,
  enableSoftDelete: true,
  generateZod: true,
  generateDrift: true,
  generateDrizzle: false,
)
class Business { ... }
```

| Parameter          | Type      | Default                  | Description                                             |
| ------------------ | --------- | ------------------------ | ------------------------------------------------------- |
| `tableName`        | `String?` | snake_case of class name | SQL / Drift / Drizzle table name                        |
| `collectionName`   | `String?` | —                        | Firestore collection name                               |
| `schemaVersion`    | `int`     | `1`                      | Monotonically increasing version for migration tracking |
| `namespace`        | `String?` | —                        | Logical domain grouping, e.g. `'auth'`, `'billing'`     |
| `enableTimestamps` | `bool`    | `true`                   | Auto-injects `createdAt` / `updatedAt` if not declared  |
| `enableSoftDelete` | `bool`    | `true`                   | Auto-injects `deletedAt` nullable column                |
| `abstractSchema`   | `bool`    | `false`                  | No table generated; class is only extended by others    |
| `cacheable`        | `bool`    | `true`                   | Model may be cached at runtime                          |
| `syncable`         | `bool`    | `true`                   | Model participates in the sync engine                   |
| `embeddable`       | `bool`    | `false`                  | Fields are inlined into a parent table; no own table    |
| `generateZod`      | `bool`    | `true`                   | Emit `gen/{path}.g.ts`                                  |
| `generateDrift`    | `bool`    | `true`                   | Emit `lib/{path}.table.dart`                            |
| `generateDrizzle`  | `bool`    | `true`                   | Emit `gen/{path}.drizzle.ts`                            |

---

#### `@SchemaGroup`

Groups a schema into a named domain. Informational — used by tooling for documentation and organization reports.

```dart
@SchemaGroup('billing')
@Schemix()
class Invoice { ... }
```

---

#### `@SchemaDescription`

Attaches a human-readable description to a schema. The text propagates into generated code comments and API documentation.

```dart
@SchemaDescription('Represents a registered business entity with billing info.')
@Schemix()
class Business { ... }
```

---

#### `@DeprecatedSchema`

Marks an entire schema class as deprecated. Generators emit a deprecation comment in all outputs. Provide `replacement` so consumers know where to migrate.

```dart
@DeprecatedSchema(
  reason: 'Replaced by BusinessV2 with normalized address fields.',
  replacement: 'BusinessV2',
  removalVersion: '4.0.0',
)
class Business { ... }
```

---

### 2. Field Metadata

#### `@SchemixField` / `@AppField`

Rich per-field metadata controlling visibility, searchability, and display hints. `@AppField` is a typedef alias — use whichever reads better in context.

```dart
@SchemixField(
  searchable: true,
  sortable: true,
  filterable: true,
  displayName: 'Business Name',
  description: 'Legal registered name of the business.',
  example: 'Acme Corp',
)
final String businessName;
```

| Parameter    | Default | Effect                                       |
| ------------ | ------- | -------------------------------------------- |
| `immutable`  | `false` | Field cannot change after creation           |
| `readonly`   | `false` | Exposed for reads; clients cannot set it     |
| `hidden`     | `false` | Hidden from UI but present in all outputs    |
| `internal`   | `false` | Excluded from all external (public) outputs  |
| `searchable` | `false` | Included in full-text search indexes         |
| `sortable`   | `false` | May be used as a sort key in queries         |
| `filterable` | `false` | May be used as a query filter                |
| `computed`   | `false` | Derived value; never written to the database |
| `transient`  | `false` | In-memory only; never persisted              |
| `virtual`    | `false` | Exists in the type system only; no DB column |
| `generated`  | `false` | Value is produced by the database engine     |
| `unique`     | `false` | Value must be unique across all rows         |
| `sensitive`  | `false` | Contains PII or confidential data            |

---

### 3. Primary Key & Database

#### `@PrimaryKey`

Marks the primary key field. For `String` PKs, `autoGenerate: true` emits a UUID v4 client-side default. For `int` PKs, it maps to `SERIAL` / `AUTOINCREMENT`.

```dart
@PrimaryKey(autoGenerate: true)
final String id;

// Composite PK — declare compositeOrder on each participating field
@PrimaryKey(compositeOrder: 1)
final String tenantId;

@PrimaryKey(compositeOrder: 2)
final String userId;
```

---

#### `@Indexed`

Creates a database index on this field. Supports unique, descending, full-text, and spatial variants.

```dart
@Indexed(unique: true)
final String email;

@Indexed(fullText: true)
final String description;
```

---

#### `@CompositeIndex`

Class-level annotation. Creates a multi-column index. Apply multiple times for multiple composite indexes.

```dart
@CompositeIndex(fields: ['email', 'tenantId'], unique: true)
@CompositeIndex(fields: ['createdAt', 'status'])
@Schemix()
class User { ... }
```

---

#### `@Unique`

Shorthand for `@Indexed(unique: true)`. Use when you only need the uniqueness constraint with no other index options.

```dart
@Unique()
final String slug;
```

---

#### `@AutoIncrement`

Marks an `int` PK as auto-increment (`SERIAL` in PostgreSQL, `AUTOINCREMENT` in SQLite). Use alongside `@PrimaryKey`.

```dart
@PrimaryKey(autoGenerate: false)
@AutoIncrement()
final int id;
```

---

#### `@DatabaseGenerated`

Indicates the column value is entirely produced by the database engine (sequences, expressions, `DEFAULT gen_random_uuid()`).

```dart
@DatabaseGenerated(strategy: 'uuid')
final String id;
```

---

#### `@SqlType`

Overrides the raw SQL column type emitted for this field. Use when the default mapping is not precise enough.

```dart
@SqlType('JSONB')
final Map<String, dynamic> metadata;

@SqlType('TIMESTAMPTZ')
final DateTime scheduledAt;
```

---

#### `@DrizzleType`

Overrides the Drizzle ORM column builder function for this field.

```dart
@DrizzleType('jsonb')
final Map<String, dynamic> settings;
```

---

#### `@DriftType`

Overrides the Drift column builder type for this field.

```dart
@DriftType('text')
final MyCustomEnum status;
```

---

#### `@DatabaseDefault`

Sets a database-level default value. Accepts Dart primitives and enum constants.

```dart
@DatabaseDefault(UserStatus.active)
final UserStatus status;

@DatabaseDefault(0)
final int loginCount;
```

---

#### `@CheckConstraint`

Adds a SQL `CHECK` constraint to the column. The expression is written in SQL and must evaluate to true for every row.

```dart
@CheckConstraint('price >= 0')
final double price;

@CheckConstraint("status IN ('active', 'inactive', 'pending')")
final String status;
```

---

#### `@SecondaryKey`

Marks a field as an alternate lookup key (not the primary key). Informational for generators that produce repository or query helpers.

```dart
@SecondaryKey()
final String externalReferenceId;
```

---

#### `@PartitionKey`

Marks the partition key for distributed or sharded databases (e.g. DynamoDB, Cassandra).

```dart
@PartitionKey()
final String tenantId;
```

---

#### `@SortKey`

Marks a sort key for distributed or time-series databases. Used alongside `@PartitionKey`.

```dart
@SortKey(descending: true)
final DateTime createdAt;
```

---

#### `@FullTextSearch`

Marks a field for inclusion in a full-text search index. Equivalent to `@Indexed(fullText: true)` but reads more clearly on string fields.

```dart
@FullTextSearch()
final String bio;
```

---

#### `@CachedField`

Marks a field whose value may be cached independently at the application layer.

```dart
@CachedField()
final String avatarUrl;
```

---

### 4. Relations

#### `@BelongsTo`

Many-to-one. The annotated field stores the foreign-key ID. Generators emit an FK column.

```dart
@BelongsTo(User)
final String userId;

// With explicit FK name
@BelongsTo(Organization, foreignKey: 'org_id')
final String organizationId;
```

---

#### `@HasOne`

One-to-one. No column is emitted on this side; the FK lives on the target model. The field type is typically the target class or its ID type.

```dart
@HasOne(Profile)
final Profile? profile;
```

---

#### `@HasMany`

One-to-many. No column is emitted. Generators produce a virtual relation reference that is resolved via a FK on the target model.

```dart
@HasMany(Invoice)
final List<Invoice> invoices;
```

---

#### `@ManyToMany`

Many-to-many via a junction table. No column is emitted. Provide `junctionTable` explicitly to control the junction table name.

```dart
@ManyToMany(Tag, junctionTable: 'product_tags')
final List<Tag> tags;
```

---

#### `@Embedded`

Inlines the target class's fields into this model's table. No join is needed. The target class must be annotated with `@Schemix(embeddable: true)`.

```dart
@Embedded()
final Address? address;
```

---

#### `@RelationField`

Marks a field as the raw FK column that backs a named relation field on the same class. Connects the FK integer/string to its relation counterpart.

```dart
@BelongsTo(User)
final User? user;

@RelationField(fieldName: 'user')
final String userId;
```

---

#### `@CascadeDelete`

Marks a relation so that deleting the owner row also deletes all related rows (ON DELETE CASCADE).

```dart
@CascadeDelete()
@HasMany(OrderItem)
final List<OrderItem> items;
```

---

#### `@LazyRelation`

Marks a relation as lazy-loaded. Generators that produce query helpers will not eagerly fetch this relation with the parent.

```dart
@LazyRelation()
@HasMany(AuditLog)
final List<AuditLog> auditLogs;
```

---

### 5. Validation

All validation annotations emit corresponding Zod schema constraints in the generated TypeScript output.

#### `@Required`

Field must be present and non-empty. Emits `.min(1)` for strings, `.nonEmpty()` for arrays.

```dart
@Required()
final String businessName;
```

---

#### `@Min` / `@Max`

Numeric range constraints (inclusive). Emit `.gte(value)` and `.lte(value)` in Zod.

```dart
@Min(0)
@Max(1000000)
final double price;
```

---

#### `@Length`

String length constraint. Emit `.min(n).max(n)` in Zod.

```dart
@Length(min: 3, max: 150)
final String username;
```

---

#### `@Regex`

Validates the field value against a regular expression. Emits `.regex(/pattern/)` in Zod.

```dart
@Regex(r'^[A-Z]{2}\d{6}$')
final String passportNumber;
```

---

#### `@Email` / `@Url` / `@Phone` / `@IpAddress` / `@Uuid`

Format validators. Each emits the corresponding Zod format method (`.email()`, `.url()`, `.ip()`, `.uuid()`).

```dart
@Email()
final String email;

@Url()
final String? websiteUrl;

@Uuid()
final String externalId;
```

---

#### `@EnumFallback`

Specifies a fallback enum value when deserialization receives an unknown variant. Emits `.catch(value)` in Zod, preventing parse failures on unknown server values.

```dart
@EnumFallback(BusinessType.other)
final BusinessType type;
```

---

#### `@AllowedValues` / `@DisallowValues`

Restricts or rejects a fixed set of values. Emit `.refine(...)` predicates in Zod.

```dart
@AllowedValues(['retail', 'wholesale', 'online'])
final String channel;

@DisallowValues(['admin', 'root', 'superuser'])
final String username;
```

---

### 6. Serialization

#### `@JsonField`

Sets a custom JSON key name for this field. Takes priority over `@JsonKey(name:)` and the default snake_case fallback.

```dart
@JsonField('business_name')
final String businessName;
```

---

#### `@IgnoreField`

Excludes this field from all serialization and code generation outputs entirely. Cannot be combined with `@PrimaryKey`, validation, or relation annotations.

```dart
@IgnoreField()
final String _internalCache;
```

---

#### `@ReadOnlyField` / `@WriteOnlyField`

`@ReadOnlyField` — serialized in responses, never accepted from clients.
`@WriteOnlyField` — accepted on writes, never included in responses.

```dart
@WriteOnlyField()
final String passwordHash;

@ReadOnlyField()
final String generatedSlug;
```

---

#### `@Flatten`

Flattens a nested object's fields into the parent JSON object, removing the nesting level.

```dart
@Flatten()
final Address address;
// Serializes as { street: '...', city: '...' } instead of { address: { street: '...' } }
```

---

#### `@DateFormat`

Specifies a custom date format string for DateTime serialization.

```dart
@DateFormat('yyyy-MM-dd')
final DateTime birthDate;
```

---

#### `@Precision`

Specifies decimal precision and scale for numeric fields. Maps to `DECIMAL(precision, scale)` in SQL.

```dart
@Precision(precision: 18, scale: 2)
final double amount;
```

---

#### `@SerializeAs`

Instructs serialization to write the value as a different type.

```dart
@SerializeAs('string')
final int legacyId;
```

---

### 7. Type Overrides

#### `@TsType`

Overrides the TypeScript type and optionally the Zod schema for this field. Use for branded types, union types, or any type the default resolver cannot infer.

```dart
@TsType('string | number')
final dynamic id;

@TsType("UserId", zodSchema: "z.string().brand('UserId')")
final String userId;
```

---

#### `@ZodType`

Overrides the full Zod schema expression for this field. Use when `@TsType(zodSchema:)` is too verbose.

```dart
@ZodType("z.string().brand('TenantId')")
final String tenantId;
```

---

#### `@CustomConverter`

Unified type override spanning all generation targets. Use when a field needs custom handling in Dart, TypeScript, SQL, and Drizzle simultaneously.

```dart
@CustomConverter(
  dartConverter: 'MetadataConverter',
  tsConverter: "z.record(z.string(), z.unknown())",
  sqlType: 'JSONB',
  drizzleType: 'jsonb',
)
final Map<String, dynamic>? metadata;
```

---

### 8. Platform-Specific Exclusions

Use these to exclude a field from a single generator target while keeping it in all others.

#### `@DriftIgnore`

Excludes this field from the Drift table generator only.

```dart
@DriftIgnore()
final String computedDisplayName;
```

---

#### `@DrizzleIgnore`

Excludes this field from the Drizzle schema generator only.

```dart
@DrizzleIgnore()
final String localOnlyFlag;
```

---

#### `@ZodIgnore`

Excludes this field from the Zod schema and TypeScript interface only.

```dart
@ZodIgnore()
final String internalServerId;
```

---

### 9. Security

#### `@Encrypted`

Marks a field as encrypted at rest. Excluded from API response DTOs unless `@ApiField(expose: true)` is set.

```dart
@Encrypted()
final String taxIdentificationNumber;
```

---

#### `@Hashed`

Marks a field as hashed (passwords, API keys). Excluded from API response DTOs. Never included in read outputs by default.

```dart
@Hashed()
final String passwordHash;
```

---

#### `@Sensitive`

Marks a field as sensitive PII. Excluded from API response DTOs. Generators emit appropriate warnings in comments.

```dart
@Sensitive()
final String socialSecurityNumber;
```

---

#### `@MaskInLogs`

Redacts this field's value in application and server logs.

```dart
@MaskInLogs()
final String creditCardNumber;
```

---

#### `@PermissionRequired`

Restricts read access to this field to callers who hold the given permission string.

```dart
@PermissionRequired('admin')
final double internalCostPrice;
```

---

#### `@ReadScope` / `@WriteScope`

Restricts read or write access to callers who hold one of the listed OAuth / RBAC scope strings.

```dart
@ReadScope(['admin', 'owner'])
@WriteScope(['owner'])
final String privateNotes;
```

---

### 10. UI Metadata

#### `@UiField`

Display metadata for generated form and table UIs. Consumed by generators that produce UI scaffolding.

```dart
@UiField(
  label: 'Business Name',
  icon: 'business',
  section: 'general',
  order: 1,
  helpText: 'Enter the legal registered name.',
  tooltip: 'This must match your business registration certificate.',
)
final String businessName;
```

---

#### `@FormField`

Controls the input widget type and behaviour for generated forms.

```dart
@FormField(widgetType: 'textarea', multiline: true, autofocus: false)
final String description;
```

---

#### `@TableColumn`

Column display hints for generated data-table UIs.

```dart
@TableColumn(width: 200, align: 'left', sortable: true)
final String businessName;
```

---

#### `@ColorField` / `@ImageField` / `@FileField`

Mark string fields as holding a colour hex value, an image URL, or a file URL. Form generators render the appropriate picker widget.

```dart
@ColorField()
final String brandColor;

@ImageField()
final String? logoUrl;

@FileField()
final String? attachmentUrl;
```

---

#### `@FilterField` / `@SearchField`

Mark fields that should appear in query filter UIs or search bars.

```dart
@FilterField()
@SearchField()
final String status;
```

---

### 11. Lifecycle

#### `@CreatedAt`

Marks a `DateTime` field as the record creation timestamp. Auto-excluded from create/update API DTOs.

```dart
@CreatedAt()
final DateTime createdAt;
```

---

#### `@UpdatedAt`

Marks a `DateTime` field as the last-updated timestamp. Auto-excluded from create/update DTOs.

```dart
@UpdatedAt()
final DateTime updatedAt;
```

---

#### `@DeletedAt`

Marks a nullable `DateTime` field as the soft-delete timestamp. Non-null means the record is deleted. Used with `@Schemix(enableSoftDelete: true)`.

```dart
@DeletedAt()
final DateTime? deletedAt;
```

---

#### `@VersionField`

Marks an `int` field as an optimistic-concurrency version counter. Incremented on every update. Auto-excluded from create/update DTOs.

```dart
@VersionField()
final int version;
```

---

#### `@AuditField`

Marks a field as an audit-trail marker. Generators that produce change-history tables include this field in the audit schema.

```dart
@AuditField()
final String lastModifiedBy;
```

---

### 12. Sync & Offline

#### `@ConflictResolver`

Class-level. Specifies how write conflicts should be resolved during sync. Strategies: `'latestWins'`, `'firstWins'`, `'merge'`.

```dart
@ConflictResolver(strategy: 'latestWins')
@Schemix(syncable: true)
class Document { ... }
```

---

#### `@OfflineOnly`

Field exists only in the local database — never synced to the server. Excluded from Zod / TypeScript outputs.

```dart
@OfflineOnly()
final bool isDirty;
```

---

#### `@CloudOnly`

Field exists only in the remote/cloud database — not stored locally. Excluded from Drift / Drizzle table generation.

```dart
@CloudOnly()
final String cloudProcessingJobId;
```

---

#### `@SyncPriority`

Sets the sync priority for this field during conflict resolution. Higher values are synced first.

```dart
@SyncPriority(priority: 10)
final String criticalFlag;
```

---

#### `@OperationTracked`

Every mutation to this field is recorded as an operation log entry, enabling CRDT-style merge strategies.

```dart
@OperationTracked()
final int counter;
```

---

### 13. API

#### `@ApiField`

Controls how this field appears in generated API DTO interfaces. Set `expose: false` to remove it from all DTOs entirely.

```dart
@ApiField(expose: true, readonly: true, deprecated: false)
final String publicId;

@ApiField(expose: false)
final String internalAuditKey;
```

---

#### `@ApiVersion`

Tracks the API version lifecycle of a field. Generators emit appropriate deprecation warnings and changelog comments.

```dart
@ApiVersion(introducedIn: '1.2.0', deprecatedIn: '2.0.0', removedIn: '3.0.0')
final String legacyCode;
```

---

#### `@DtoOnly`

Field is included in DTO interfaces only — not persisted to the database. Useful for computed or joined values returned by APIs.

```dart
@DtoOnly()
final String displayLabel;
```

---

#### `@InternalApi`

Field is for internal server use only. Excluded from all public API DTOs regardless of other settings.

```dart
@InternalApi()
final String serviceRoutingKey;
```

---

### 14. Audit & Tracking

#### `@TrackChanges`

Records every mutation to this field in the audit log table.

```dart
@TrackChanges()
final String status;
```

---

#### `@TrackAnalytics`

Emits an analytics event whenever this field changes. `eventName` defaults to a generated name based on class and field.

```dart
@TrackAnalytics(eventName: 'subscription_plan_changed')
final String subscriptionPlan;
```

---

#### `@LogChanges`

Logs every write to this field using the application's structured logging system.

```dart
@LogChanges()
final String adminOverrideReason;
```

---

### 15. Migration

#### `@RenamedFrom`

Records that this field was previously named `oldName`. Generators use this to produce `ALTER TABLE RENAME COLUMN` migration scripts.

```dart
@RenamedFrom('company_name')
final String businessName;
```

---

#### `@RemovedIn`

Marks a field as scheduled for removal in the given semver version. Generators emit a deprecation warning in all outputs.

```dart
@RemovedIn('3.0.0')
final String legacyExternalId;
```

---

#### `@MigrationNote`

Attaches a free-form migration note to a field. Appears in generated migration scripts as a comment.

```dart
@MigrationNote('Backfill from the legacy profile table using the data pipeline in scripts/migrate_profile.ts')
final String normalizedAddress;
```

---

#### `@LegacyField`

Marks a field as a legacy carry-over that exists only for backwards compatibility. Excluded from new code generation paths.

```dart
@LegacyField()
final String oldFormatPhone;
```

---

### 16. Feature & Release Control

#### `@FeatureFlag`

Gates this field behind a named feature flag. Generators emit conditional logic or comments referencing the flag identifier.

```dart
@FeatureFlag('new_billing_flow')
final String stripePaymentMethodId;
```

---

#### `@Experimental`

Marks a field as experimental. Generated code includes a warning comment so consumers know the API may change.

```dart
@Experimental()
final Map<String, dynamic> aiGeneratedTags;
```

---

#### `@EnterpriseOnly`

Marks a field as available to enterprise-tier users only. Generators can emit tier-gating comments or exclude the field from public SDK output.

```dart
@EnterpriseOnly()
final String ssoConfigurationId;
```

---

### 17. Slug

#### `@SlugField`

Marks a field as a URL-safe slug derived from another field's value. Combine with `@Indexed(unique: true)` to enforce uniqueness.

```dart
@SlugField(sourceField: 'businessName', separator: '-')
@Indexed(unique: true)
final String slug;
// 'Acme Corp' → 'acme-corp'
```

---

### 18. Generator Control

#### `@ManualImplementation`

Opts this class out of automatic code generation entirely. All output files must be written by hand. Use when the generated output is structurally incompatible with your requirements.

```dart
@ManualImplementation()
@Schemix()
class ComplexCustomModel { ... }
```

---

## Writing a Custom Generator

Any package can publish a Schemix generator. Add `schemix` as a dependency, implement the `SchemixGenerator` interface, and declare a `build.yaml` builder.

### 1. Implement `SchemixGenerator`

```dart
import 'package:schemix/schemix.dart';

class MyCustomGenerator implements SchemixGenerator {
  @override
  String get id => 'my_custom_generator';

  @override
  List<String> get outputExtensions => ['.my.output'];

  @override
  bool shouldRun(ClassInfo classInfo) {
    // Return false cheaply if this class is not relevant.
    return classInfo.hasSchemix && !classInfo.abstractSchema;
  }

  @override
  GeneratorOutput generate(ClassInfo classInfo, GeneratorContext context) {
    final buf = StringBuffer();

    // Use context.typeGraph to resolve cross-file types.
    for (final field in classInfo.allFields) {
      if (field.isIgnored) continue;

      // Store generator-specific metadata in extensions rather than
      // adding fields to FieldInfo.
      final meta = field.extensions[id];

      buf.writeln('// field: ${field.name}  type: ${field.dartType}');
    }

    return GeneratorOutput({'.my.output': buf.toString()});
  }
}
```

### 2. Register the generator

```dart
// In your builder factory:
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
      - "lib/schemix_registry.json"
```

`required_inputs: [lib/schemix_registry.json]` is mandatory — it ensures the scan phase completes before your generator runs and that `build_runner` correctly invalidates your outputs when the type graph changes.

### Key interfaces

**`TypeGraph`** — read-only view of the cross-file type graph. Available via `context.typeGraph`.

```dart
context.typeGraph.isEnum('MyEnum');           // true/false
context.typeGraph.isModel('User');            // true/false
context.typeGraph.resolve('User');            // TypeInfo?
context.typeGraph.cyclicTypes;               // Set<String> — types in reference cycles
context.typeGraph.relativeImportFor(
  typeName: 'User',
  fromSourceAssetPath: context.sourceAssetPath,
);  // relative import path for cross-file references, or null if same file
```

**`ClassInfo`** — fully analyzed schema class.

```dart
classInfo.name                // 'User'
classInfo.tableName           // 'users' (explicit) or null (use snake_case of name)
classInfo.allFields           // inherited + own fields
classInfo.ownFields           // fields declared on this class only
classInfo.generators.zod      // true/false
classInfo.generators.drift    // true/false
classInfo.compositeIndexes    // List<CompositeIndexInfo>
classInfo.enableTimestamps    // bool
classInfo.abstractSchema      // bool
```

**`FieldInfo`** — analyzed field with all annotation data.

```dart
field.name                    // 'emailAddress'
field.dartType                // 'String'
field.isNullable              // true/false
field.isList                  // true/false
field.listItemType            // 'Tag' (for List<Tag>)
field.isEnum                  // true/false
field.isIgnored               // true — skip this field entirely
field.effectiveJsonName       // 'email_address' (respects @JsonField / snake_case)
field.db.isPrimaryKey         // true/false
field.db.isIndexed            // true/false
field.db.sqlType              // 'JSONB' (from @SqlType) or null
field.relation.kind           // RelationKind.belongsTo / hasMany / etc.
field.relation.targetTypeName // 'User'
field.validation.isEmail      // true/false
field.validation.minLength    // 3 (from @Length(min: 3))
field.security.encrypted      // true/false
field.security.sensitive      // true/false
field.sync.offlineOnly        // true/false
field.sync.cloudOnly          // true/false
field.platform.zodIgnore      // true/false
field.platform.driftIgnore    // true/false
field.converter.zodTypeOverride // 'z.string().brand(...)' or null
field.isCreatedAt             // true/false
field.isUpdatedAt             // true/false
field.extensions[myGeneratorId] // generator-specific metadata
```

---

## Build Pipeline

```
Phase 1 — SchemixScanBuilder
  Input:   all lib/**.dart
  Output:  lib/schemix_registry.json  (build_to: cache)
  Purpose: builds the cross-file type graph once per package

Phase 2 — SchemixFileBuilder  (+ any custom generators)
  Input:   one lib/{name}.dart + lib/schemix_registry.json
  Output:  lib/{name}.schemix.dart
           lib/{name}.table.dart
           gen/{name}.g.ts
           gen/{name}.drizzle.ts
  Purpose: full per-file code generation using the type graph

Phase 3 — SchemixIndexBuilder
  Input:   all gen/**.g.ts
  Output:  gen/schemix.g.ts  (barrel re-export)
  Purpose: single import point for all Zod schemas
```

Custom generators run in Phase 2. They must list `lib/schemix_registry.json` in `required_inputs` so `build_runner` tracks the dependency correctly and invalidates outputs when the type graph changes.

---

## Package Map

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

No generator package depends on another generator package. No generator package depends on `schemix_builder`. These two rules must never be broken.
