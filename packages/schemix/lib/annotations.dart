// ════════════════════════════════════════════════════════════════════════════
// 1. SCHEMA-LEVEL
// ════════════════════════════════════════════════════════════════════════════

/// Marks a Dart class as a schemix schema model and controls which generators
/// are active for it.
///
/// Example:
/// ```dart
/// @Schemix(
///   tableName: 'users',
///   schemaVersion: 1,
///   enableTimestamps: true,
///   generateZod: true,
///   generateDrift: true,
///   generateDrizzle: true,
/// )
/// class User { ... }
/// ```
class Schemix {
  /// SQL / Drift / Drizzle table name. Defaults to snake_case of class name.
  final String? tableName;

  /// Firestore collection name.
  final String? collectionName;

  /// Monotonically increasing schema version used for migration tracking.
  final int schemaVersion;

  /// Logical module or domain grouping (e.g. 'auth', 'billing').
  final String? namespace;

  /// When true, auto-injects `createdAt` and `updatedAt` columns if not
  /// explicitly declared on the class.
  final bool enableTimestamps;

  /// When true, auto-injects a `deletedAt` column for soft-delete support.
  final bool enableSoftDelete;

  /// When true, this schema is never persisted directly — it is only extended
  /// by other schemas. No table is generated for abstract schemas.
  final bool abstractSchema;

  /// Whether the model may be cached at runtime.
  final bool cacheable;

  /// Whether the model participates in the sync engine.
  final bool syncable;

  /// When true, the model is embedded inside a parent (no own table).
  final bool embeddable;

  /// Emit a Zod schema + TypeScript interface (`gen/{path}.g.ts`).
  final bool generateZod;

  /// Emit a Drift Table class (`lib/{path}.table.dart`).
  final bool generateDrift;

  /// Emit a Drizzle ORM table schema (`gen/{path}.drizzle.ts`).
  final bool generateDrizzle;

  const Schemix({
    this.tableName,
    this.collectionName,
    this.schemaVersion = 1,
    this.namespace,
    this.enableTimestamps = true,
    this.enableSoftDelete = true,
    this.abstractSchema = false,
    this.cacheable = true,
    this.syncable = true,
    this.embeddable = false,
    this.generateZod = true,
    this.generateDrift = true,
    this.generateDrizzle = true,
  });
}

/// Groups a schema into a logical domain.
///
/// Example: `@SchemaGroup('billing')`
class SchemaGroup {
  /// The domain or module name (e.g. 'auth', 'billing').
  final String group;
  const SchemaGroup(this.group);
}

/// Attaches human-readable documentation to a schema class.
/// The description propagates into generated code comments.
///
/// Example: `@SchemaDescription('Represents a registered business entity.')`
class SchemaDescription {
  /// Documentation text that appears in generated output.
  final String description;
  const SchemaDescription(this.description);
}

/// Marks an entire schema class as deprecated.
///
/// Example:
/// ```dart
/// @DeprecatedSchema(reason: 'Replaced by BusinessV2', replacement: 'BusinessV2')
/// class Business { ... }
/// ```
class DeprecatedSchema {
  /// Human-readable reason for the deprecation.
  final String reason;

  /// Name of the replacement schema, if any.
  final String? replacement;

  /// Semver string of the version in which this schema will be removed.
  final String? removalVersion;

  const DeprecatedSchema({
    required this.reason,
    this.replacement,
    this.removalVersion,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// 2. FIELD-LEVEL
// ════════════════════════════════════════════════════════════════════════════

/// Rich field metadata. Controls visibility, searchability, and display hints
/// across all generators.
///
/// Also available as the typedef `@AppField`.
class SchemixField {
  /// Field cannot be changed after creation.
  final bool immutable;

  /// Field is exposed for reads but cannot be set by the client.
  final bool readonly;

  /// Field is hidden from UI display but still present in outputs.
  final bool hidden;

  /// Field is excluded from all external (public) outputs.
  final bool internal;

  /// Field is included in full-text search indexes.
  final bool searchable;

  /// Field may be used to sort query results.
  final bool sortable;

  /// Field may be used as a filter in queries.
  final bool filterable;

  /// Field value is derived — never written directly to the database.
  final bool computed;

  /// Field is never persisted; exists only in memory during a session.
  final bool transient;

  /// Field exists in the type system only, not as a database column.
  final bool virtual;

  /// Value is produced by the database engine (e.g. sequences, expressions).
  final bool generated;

  /// Field value must be unique across all rows.
  final bool unique;

  /// Field contains personally-identifiable or confidential data.
  final bool sensitive;

  /// Human-readable label for UI display (overrides auto-generated label).
  final String? displayName;

  /// Description of the field's purpose for documentation and tooltips.
  final String? description;

  /// Example value shown in documentation and API specs.
  final String? example;

  /// Placeholder text for form inputs.
  final String? placeholder;

  const SchemixField({
    this.immutable = false,
    this.readonly = false,
    this.hidden = false,
    this.internal = false,
    this.searchable = false,
    this.sortable = false,
    this.filterable = false,
    this.computed = false,
    this.transient = false,
    this.virtual = false,
    this.generated = false,
    this.unique = false,
    this.sensitive = false,
    this.displayName,
    this.description,
    this.example,
    this.placeholder,
  });
}

/// Alias for [@SchemixField].
typedef AppField = SchemixField;

/// Marks a field as the primary key of the model.
///
/// Example: `@PrimaryKey(autoGenerate: true)`
class PrimaryKey {
  /// When true, the database or ORM generates the value automatically
  /// (UUID for String PKs, SERIAL for int PKs).
  final bool autoGenerate;

  /// Position of this field within a composite primary key (1-based).
  final int? compositeOrder;

  /// Whether this PK column is the clustered index (SQL Server / MySQL).
  final bool clustered;

  const PrimaryKey({
    this.autoGenerate = true,
    this.compositeOrder,
    this.clustered = false,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// 3. DATABASE
// ════════════════════════════════════════════════════════════════════════════

/// Creates a database index on the annotated field.
///
/// Example: `@Indexed(unique: true)`
class Indexed {
  /// Optional explicit index name. Defaults to a generated name.
  final String? name;

  /// Index enforces uniqueness across all rows.
  final bool unique;

  /// Index is sorted in descending order.
  final bool descending;

  /// Index supports full-text search queries.
  final bool fullText;

  /// Index supports spatial / GIS queries.
  final bool spatial;

  const Indexed({
    this.name,
    this.unique = false,
    this.descending = false,
    this.fullText = false,
    this.spatial = false,
  });
}

/// Creates a multi-field composite index. Applied at class level.
///
/// Example: `@CompositeIndex(fields: ['email', 'tenantId'], unique: true)`
class CompositeIndex {
  /// Ordered list of field names that form the composite index.
  final List<String> fields;

  /// Index enforces uniqueness across all rows for the combined columns.
  final bool unique;

  /// Per-field sort directions; must match [fields] length if provided.
  final List<String> order;

  const CompositeIndex({
    required this.fields,
    this.unique = false,
    this.order = const [],
  });
}

/// Shorthand uniqueness constraint. Equivalent to `@Indexed(unique: true)`.
class Unique {
  const Unique();
}

/// Marks an integer PK field as auto-increment (SERIAL / AUTOINCREMENT).
class AutoIncrement {
  const AutoIncrement();
}

/// Indicates the column value is generated by the database engine.
///
/// Example: `@DatabaseGenerated(strategy: 'uuid')`
class DatabaseGenerated {
  /// Generation strategy, e.g. `'uuid'`, `'sequence'`, `'expression'`.
  final String? strategy;
  const DatabaseGenerated({this.strategy});
}

/// Overrides the raw SQL column type for this field.
///
/// Example: `@SqlType('JSONB')`
class SqlType {
  /// Raw SQL type string, e.g. `'JSONB'`, `'TEXT[]'`, `'TIMESTAMPTZ'`.
  final String type;
  const SqlType(this.type);
}

/// Overrides the Drizzle ORM column type for this field.
///
/// Example: `@DrizzleType('jsonb')`
class DrizzleType {
  /// Drizzle column function name, e.g. `'jsonb'`, `'text'`, `'timestamp'`.
  final String type;
  const DrizzleType(this.type);
}

/// Overrides the Drift column type for this field.
///
/// Example: `@DriftType('text')`
class DriftType {
  /// Drift column builder type string, e.g. `'text'`, `'integer'`.
  final String type;
  const DriftType(this.type);
}

/// Sets a database-level default value for this field.
///
/// Example: `@DatabaseDefault(UserStatus.active)`
class DatabaseDefault {
  /// The default value; may be a Dart enum constant, primitive, or string.
  final dynamic value;
  const DatabaseDefault(this.value);
}

/// Adds a SQL CHECK constraint to this field's column.
///
/// Example: `@CheckConstraint('count >= 0')`
class CheckConstraint {
  /// SQL expression that must evaluate to true for every row.
  final String expression;
  const CheckConstraint(this.expression);
}

/// Marks a field as a secondary (alternate) key for lookups.
class SecondaryKey {
  const SecondaryKey();
}

/// Marks a field as the partition key for distributed databases.
class PartitionKey {
  const PartitionKey();
}

/// Marks a field as a sort key for distributed / time-series databases.
///
/// Example: `@SortKey(descending: true)`
class SortKey {
  /// When true, results are sorted in descending order by default.
  final bool descending;
  const SortKey({this.descending = false});
}

/// Marks a field for inclusion in a full-text search index.
class FullTextSearch {
  const FullTextSearch();
}

/// Marks a field whose value may be cached by the runtime.
class CachedField {
  const CachedField();
}

// ════════════════════════════════════════════════════════════════════════════
// 4. RELATIONS
// ════════════════════════════════════════════════════════════════════════════

/// Many-to-one relation. The annotated field stores the foreign-key ID.
///
/// Example: `@BelongsTo(User)`
class BelongsTo {
  /// The target model type.
  final Type target;

  /// Explicit foreign-key column name. Defaults to `{targetName}Id`.
  final String? foreignKey;

  const BelongsTo(this.target, {this.foreignKey});
}

/// One-to-one relation. No column is emitted; resolved via a foreign key on
/// the target model.
///
/// Example: `@HasOne(Profile)`
class HasOne {
  /// The target model type.
  final Type target;

  /// Explicit foreign-key column name on the target model.
  final String? foreignKey;

  const HasOne(this.target, {this.foreignKey});
}

/// One-to-many relation. No column is emitted; resolved via a foreign key on
/// the target model.
///
/// Example: `@HasMany(Invoice)`
class HasMany {
  /// The target model type.
  final Type target;

  /// Explicit foreign-key column name on the target model.
  final String? foreignKey;

  const HasMany(this.target, {this.foreignKey});
}

/// Many-to-many relation via a junction table. No column is emitted.
///
/// Example: `@ManyToMany(Tag, junctionTable: 'business_tags')`
class ManyToMany {
  /// The target model type.
  final Type target;

  /// Name of the junction table. Defaults to a generated name.
  final String? junctionTable;

  /// Optional explicit relation name used in generated code.
  final String? relationName;

  const ManyToMany(this.target, {this.junctionTable, this.relationName});
}

/// Embeds the target class fields inline into this model's table (no join).
///
/// Example: `@Embedded() Address? address;`
class Embedded {
  const Embedded();
}

/// Marks a field as the FK column backing a relation field on this class.
///
/// [fieldName] is the name of the owning relation field on this class.
class RelationField {
  /// Name of the owning relation field (e.g. `'user'` for `userId`).
  final String? fieldName;
  const RelationField({this.fieldName});
}

/// Marks a relation so that deleting the owner also deletes related rows.
class CascadeDelete {
  const CascadeDelete();
}

/// Marks a relation as lazy-loaded (not eagerly fetched with the parent).
class LazyRelation {
  const LazyRelation();
}

// ════════════════════════════════════════════════════════════════════════════
// 5. VALIDATION
// ════════════════════════════════════════════════════════════════════════════

/// Field must be present and non-null. Emits `.nonEmpty()` or `.min(1)` in Zod
/// depending on the field type.
class Required {
  const Required();
}

/// Numeric minimum value (inclusive). Emits `.gte(value)` in Zod.
///
/// Example: `@Min(0)`
class Min {
  /// The minimum allowed value.
  final num value;
  const Min(this.value);
}

/// Numeric maximum value (inclusive). Emits `.lte(value)` in Zod.
///
/// Example: `@Max(1000000)`
class Max {
  /// The maximum allowed value.
  final num value;
  const Max(this.value);
}

/// String length constraint. Emits `.min(min).max(max)` in Zod.
///
/// Example: `@Length(min: 3, max: 150)`
class Length {
  /// Minimum character count (inclusive).
  final int? min;

  /// Maximum character count (inclusive).
  final int? max;

  const Length({this.min, this.max});
}

/// Validates the field value against a regular expression.
/// Emits `.regex(/pattern/)` in Zod.
///
/// Example: `@Regex(r'^[A-Z]{2}\d{6}$')`
class Regex {
  /// The Dart regex pattern string.
  final String pattern;
  const Regex(this.pattern);
}

/// Validates the field as an email address. Emits `.email()` in Zod.
class Email {
  const Email();
}

/// Validates the field as a URL. Emits `.url()` in Zod.
class Url {
  const Url();
}

/// Validates the field as a phone number. Emits `.phone()` in Zod.
class Phone {
  const Phone();
}

/// Validates the field as an IP address. Emits `.ip()` in Zod.
class IpAddress {
  const IpAddress();
}

/// Validates the field as a UUID v4 string. Emits `.uuid()` in Zod.
class Uuid {
  const Uuid();
}

/// Specifies a fallback enum value when deserialization receives an unknown
/// variant. Emits `.catch(value)` in Zod.
///
/// Example: `@EnumFallback(BusinessType.other)`
class EnumFallback {
  /// The fallback enum value.
  final dynamic value;
  const EnumFallback(this.value);
}

/// Restricts the field to a fixed set of allowed values.
/// Emits a `.refine(v => [...].includes(v))` in Zod.
///
/// Example: `@AllowedValues(['retail', 'wholesale'])`
class AllowedValues {
  /// The list of permitted values.
  final List<dynamic> values;
  const AllowedValues(this.values);
}

/// Rejects a fixed set of disallowed values.
/// Emits a `.refine(v => ![...].includes(v))` in Zod.
///
/// Example: `@DisallowValues(['admin', 'root'])`
class DisallowValues {
  /// The list of forbidden values.
  final List<dynamic> values;
  const DisallowValues(this.values);
}

// ════════════════════════════════════════════════════════════════════════════
// 6. SERIALIZATION
// ════════════════════════════════════════════════════════════════════════════

/// Sets a custom JSON key name for this field.
/// Takes priority over `@JsonKey(name:)` and snake_case fallback.
///
/// Example: `@JsonField('business_name')`
class JsonField {
  /// The JSON key to use in serialized output.
  final String name;
  const JsonField(this.name);
}

/// Excludes this field from all serialization and code generation outputs.
/// Equivalent to `@JsonKey(ignore: true)`.
class IgnoreField {
  const IgnoreField();
}

/// Field is serialized in responses but cannot be set by the client.
class ReadOnlyField {
  const ReadOnlyField();
}

/// Field is accepted on writes (create/update) but excluded from responses.
class WriteOnlyField {
  const WriteOnlyField();
}

/// Flattens a nested object's fields into the parent JSON object.
class Flatten {
  const Flatten();
}

/// Specifies a custom date format string for DateTime serialization.
///
/// Example: `@DateFormat('yyyy-MM-dd')`
class DateFormat {
  /// The date format pattern (e.g. `'yyyy-MM-dd'`, `'ISO8601'`).
  final String format;
  const DateFormat(this.format);
}

/// Specifies decimal precision and scale for numeric fields.
///
/// Example: `@Precision(precision: 18, scale: 2)`
class Precision {
  /// Total number of significant digits.
  final int precision;

  /// Number of digits after the decimal point.
  final int? scale;

  const Precision({required this.precision, this.scale});
}

/// Instructs serialization to write the value as a different type.
///
/// Example: `@SerializeAs('string')`
class SerializeAs {
  /// The target serialization type name.
  final String type;
  const SerializeAs(this.type);
}

// ════════════════════════════════════════════════════════════════════════════
// 7. TYPE OVERRIDES
// ════════════════════════════════════════════════════════════════════════════

/// Overrides the TypeScript type and/or Zod schema for this field.
///
/// Example:
/// ```dart
/// @TsType('string | number')
/// dynamic id;
///
/// @TsType('UserId', zodSchema: "z.string().brand('UserId')")
/// String userId;
/// ```
class TsType {
  /// The TypeScript type expression, e.g. `'string | number'`.
  final String typeName;

  /// Optional Zod schema expression to use instead of the default resolver.
  final String? zodSchema;

  const TsType(this.typeName, {this.zodSchema});
}

/// Overrides the Zod schema expression for this field directly.
///
/// Example: `@ZodType("z.string().brand('UserId')")`
class ZodType {
  /// The full Zod schema expression string.
  final String schema;
  const ZodType(this.schema);
}

/// Unified type override that spans multiple generation targets.
///
/// Example:
/// ```dart
/// @CustomConverter(
///   dartConverter: MetadataConverter,
///   tsConverter: "z.record(z.string(), z.unknown())",
///   sqlType: 'JSONB',
///   drizzleType: 'jsonb',
/// )
/// Map<String, dynamic>? metadata;
/// ```
class CustomConverter {
  /// Dart converter class name (read by ModelAnalyzer via reflection).
  final String? dartConverter;

  /// TypeScript / Zod expression to use in generated TS output.
  final String? tsConverter;

  /// Raw SQL column type override (e.g. `'JSONB'`).
  final String? sqlType;

  /// Drizzle column function name override (e.g. `'jsonb'`).
  final String? drizzleType;

  const CustomConverter({
    this.dartConverter,
    this.tsConverter,
    this.sqlType,
    this.drizzleType,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// 8. PLATFORM-SPECIFIC
// ════════════════════════════════════════════════════════════════════════════

/// Excludes this field from the Drift table generator only.
class DriftIgnore {
  const DriftIgnore();
}

/// Excludes this field from the Drizzle schema generator only.
class DrizzleIgnore {
  const DrizzleIgnore();
}

/// Excludes this field from the Zod schema / TypeScript interface only.
class ZodIgnore {
  const ZodIgnore();
}

// ════════════════════════════════════════════════════════════════════════════
// 9. SECURITY
// ════════════════════════════════════════════════════════════════════════════

/// Marks a field as encrypted at rest. The field is excluded from API
/// response DTOs unless `@ApiField(expose: true)` is set explicitly.
class Encrypted {
  const Encrypted();
}

/// Marks a field as hashed (e.g. passwords, API keys). Excluded from API
/// response DTOs unless `@ApiField(expose: true)` is set explicitly.
class Hashed {
  const Hashed();
}

/// Marks a field as sensitive PII. Excluded from API response DTOs unless
/// `@ApiField(expose: true)` is set explicitly.
class Sensitive {
  const Sensitive();
}

/// Redacts this field's value in application and server logs.
class MaskInLogs {
  const MaskInLogs();
}

/// Restricts access to this field to callers who have the given permission.
///
/// Example: `@PermissionRequired('admin')`
class PermissionRequired {
  /// The permission string required to read this field.
  final String permission;
  const PermissionRequired(this.permission);
}

/// Restricts read access to callers with one of the listed scopes.
///
/// Example: `@ReadScope(['admin', 'owner'])`
class ReadScope {
  /// List of scope strings that are permitted to read this field.
  final List<String> scopes;
  const ReadScope(this.scopes);
}

/// Restricts write access to callers with one of the listed scopes.
///
/// Example: `@WriteScope(['owner'])`
class WriteScope {
  /// List of scope strings that are permitted to write this field.
  final List<String> scopes;
  const WriteScope(this.scopes);
}

// ════════════════════════════════════════════════════════════════════════════
// 10. UI METADATA
// ════════════════════════════════════════════════════════════════════════════

/// Display metadata for form and table UIs. Used by `generateForms: true`.
///
/// Example:
/// ```dart
/// @UiField(label: 'Business Name', icon: 'business', section: 'general', order: 1)
/// String businessName;
/// ```
class UiField {
  /// Human-readable field label shown in forms and tables.
  final String? label;

  /// Icon identifier (e.g. Material icon name).
  final String? icon;

  /// Section or group this field belongs to in a multi-section form.
  final String? section;

  /// Display order within its section (lower = earlier).
  final int? order;

  /// Helper text shown below the input widget.
  final String? helpText;

  /// Tooltip text shown on hover.
  final String? tooltip;

  const UiField({
    this.label,
    this.icon,
    this.section,
    this.order,
    this.helpText,
    this.tooltip,
  });
}

/// Form widget metadata. Controls input type and behaviour.
///
/// Widget type resolution priority (when [widgetType] is null):
///   `@ColorField` → 'color' · `@ImageField` → 'image' · `@FileField` → 'file'
///   `@Encrypted`/`@Hashed` → 'password' · `@Email` → 'email' · `@Url` → 'url'
///   bool → 'boolean' · int/double → 'number' · DateTime → 'date' · else → 'text'
class FormField {
  /// Explicit widget type override (e.g. `'text'`, `'select'`, `'textarea'`).
  final String? widgetType;

  /// Whether this input should receive focus when the form first renders.
  final bool autofocus;

  /// When true, renders as a multi-line textarea instead of a single-line input.
  final bool multiline;

  /// Hides this field from the generated form (still present in the type).
  final bool hidden;

  const FormField({
    this.widgetType,
    this.autofocus = false,
    this.multiline = false,
    this.hidden = false,
  });
}

/// Column metadata for generated data-table UIs.
class TableColumn {
  /// Column width in pixels.
  final int? width;

  /// Text alignment: `'left'`, `'center'`, or `'right'`.
  final String? align;

  /// Whether the column header is clickable to sort rows.
  final bool sortable;

  const TableColumn({this.width, this.align, this.sortable = true});
}

/// Marks a string field as a colour value (e.g. hex `#RRGGBB`).
/// Widget type resolves to `'color'`.
class ColorField {
  const ColorField();
}

/// Marks a string field as an image URL or path.
/// Widget type resolves to `'image'`.
class ImageField {
  const ImageField();
}

/// Marks a string field as a file URL or path.
/// Widget type resolves to `'file'`.
class FileField {
  const FileField();
}

/// Marks this field as available for use in query filter UIs.
class FilterField {
  const FilterField();
}

/// Marks this field as searchable in search-bar UIs.
/// Equivalent to setting `searchable: true` on `@SchemixField`.
class SearchField {
  const SearchField();
}

// ════════════════════════════════════════════════════════════════════════════
// 11. LIFECYCLE
// ════════════════════════════════════════════════════════════════════════════

/// Marks a `DateTime` field as the record creation timestamp.
/// Auto-excluded from create/update API DTOs.
class CreatedAt {
  const CreatedAt();
}

/// Marks a `DateTime` field as the last-updated timestamp.
/// Auto-excluded from create/update API DTOs.
class UpdatedAt {
  const UpdatedAt();
}

/// Marks a nullable `DateTime` field as the soft-delete timestamp.
/// Used with `@Schemix(enableSoftDelete: true)`.
/// Auto-excluded from create/update API DTOs.
class DeletedAt {
  const DeletedAt();
}

/// Marks an `int` field as an optimistic-concurrency version counter.
/// Auto-excluded from create/update API DTOs.
class VersionField {
  const VersionField();
}

/// Marks a field as an audit-trail marker that tracks change history.
class AuditField {
  const AuditField();
}

// ════════════════════════════════════════════════════════════════════════════
// 12. SYNC & OFFLINE
// ════════════════════════════════════════════════════════════════════════════

/// Specifies how write conflicts should be resolved during sync.
///
/// Example: `@ConflictResolver(strategy: 'latestWins')`
class ConflictResolver {
  /// Conflict resolution strategy: `'latestWins'`, `'firstWins'`, `'merge'`.
  final String strategy;
  const ConflictResolver({required this.strategy});
}

/// Field exists only in the local database — never synced to the server.
/// Excluded from Zod / TypeScript outputs.
class OfflineOnly {
  const OfflineOnly();
}

/// Field exists only in the remote/cloud database — not stored locally.
/// Excluded from Drift / Drizzle table generation.
class CloudOnly {
  const CloudOnly();
}

/// Sets the sync priority for this field during conflict resolution.
///
/// Example: `@SyncPriority(priority: 10)`
class SyncPriority {
  /// Higher values are synced first.
  final int priority;
  const SyncPriority({required this.priority});
}

/// Marks a field so that every mutation is recorded as an operation log entry.
class OperationTracked {
  const OperationTracked();
}

// ════════════════════════════════════════════════════════════════════════════
// 13. API
// ════════════════════════════════════════════════════════════════════════════

/// Controls how this field appears in generated API DTO interfaces.
///
/// Example: `@ApiField(expose: true, readonly: true)`
class ApiField {
  /// When false, the field is excluded from all DTO interfaces.
  final bool expose;

  /// When true, the field appears in response DTOs but not in create/update DTOs.
  final bool readonly;

  /// Marks this field as deprecated in generated API documentation.
  final bool deprecated;

  const ApiField({
    this.expose = true,
    this.readonly = false,
    this.deprecated = false,
  });
}

/// Tracks the API version lifecycle of a field.
///
/// Example: `@ApiVersion(introducedIn: '1.2.0', deprecatedIn: '2.0.0')`
class ApiVersion {
  /// Semver string of the API version that introduced this field.
  final String? introducedIn;

  /// Semver string of the API version that deprecated this field.
  final String? deprecatedIn;

  /// Semver string of the API version that removed this field.
  final String? removedIn;

  const ApiVersion({this.introducedIn, this.deprecatedIn, this.removedIn});
}

/// Field is included in DTO interfaces only — not persisted to the database.
class DtoOnly {
  const DtoOnly();
}

/// Field is for internal server use only. Excluded from all public API DTOs.
class InternalApi {
  const InternalApi();
}

// ════════════════════════════════════════════════════════════════════════════
// 14. AUDIT & TRACKING
// ════════════════════════════════════════════════════════════════════════════

/// Records every mutation to this field in the audit log.
class TrackChanges {
  const TrackChanges();
}

/// Emits an analytics event whenever this field changes.
///
/// Example: `@TrackAnalytics(eventName: 'plan_changed')`
class TrackAnalytics {
  /// Optional override for the analytics event name.
  /// Defaults to a generated name based on the class and field name.
  final String? eventName;
  const TrackAnalytics({this.eventName});
}

/// Logs every write to this field using the application's logging system.
class LogChanges {
  const LogChanges();
}

// ════════════════════════════════════════════════════════════════════════════
// 15. MIGRATION
// ════════════════════════════════════════════════════════════════════════════

/// Records that this field was renamed from [oldName] in a previous version.
/// Used to generate compatible ALTER TABLE / migration scripts.
///
/// Example: `@RenamedFrom('company_name')`
class RenamedFrom {
  /// The previous field / column name.
  final String oldName;
  const RenamedFrom(this.oldName);
}

/// Marks a field as scheduled for removal in [version].
/// Generators emit a deprecation warning.
///
/// Example: `@RemovedIn('3.0.0')`
class RemovedIn {
  /// Semver string of the version in which this field will be removed.
  final String version;
  const RemovedIn(this.version);
}

/// Attaches a free-form migration note to a field for documentation purposes.
///
/// Example: `@MigrationNote('Backfill from the legacy profile table.')`
class MigrationNote {
  /// The migration note text.
  final String note;
  const MigrationNote(this.note);
}

/// Marks a field as a legacy carry-over that exists only for backwards
/// compatibility. Excluded from new code generation paths.
class LegacyField {
  const LegacyField();
}

// ════════════════════════════════════════════════════════════════════════════
// 16. FEATURE & RELEASE CONTROL
// ════════════════════════════════════════════════════════════════════════════

/// Gates this field behind a named feature flag.
///
/// Example: `@FeatureFlag('new_billing_flow')`
class FeatureFlag {
  /// The feature-flag identifier checked at runtime.
  final String flag;
  const FeatureFlag(this.flag);
}

/// Marks a field as experimental. Generated code includes a warning comment.
class Experimental {
  const Experimental();
}

/// Marks a field as available to enterprise-tier users only.
class EnterpriseOnly {
  const EnterpriseOnly();
}

// ════════════════════════════════════════════════════════════════════════════
// 17. SLUG
// ════════════════════════════════════════════════════════════════════════════

/// Marks a field as a URL-safe slug derived from another field's value.
///
/// Example:
/// ```dart
/// @SlugField(sourceField: 'businessName', separator: '-')
/// @Indexed(unique: true)
/// String slug;
/// ```
class SlugField {
  /// The field name whose value is used to generate the slug.
  final String? sourceField;

  /// Character used to join slug words (default: `'-'`).
  final String separator;

  const SlugField({this.sourceField, this.separator = '-'});
}

// ════════════════════════════════════════════════════════════════════════════
// 18. GENERATOR CONTROL
// ════════════════════════════════════════════════════════════════════════════

/// Opts this class out of automatic code generation. The developer is
/// responsible for providing the generated output by hand.
class ManualImplementation {
  const ManualImplementation();
}
