import 'package:schemix/schemix.dart';

import 'utils.dart';

/// Translates a single [FieldInfo] into a Drizzle ORM column expression.
///
/// Returns `null` when the field should be omitted (e.g. unresolvable type).
final class DrizzleColumnBuilder {
  const DrizzleColumnBuilder();

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Builds the Drizzle column definition string for [field].
  ///
  /// Returns `null` if no Drizzle column function can be resolved for the
  /// field's Dart type (a warning is expected from the caller).
  String? buildColumn(FieldInfo field) {
    final colName = field.effectiveJsonName.snakeCase;
    final getter = field.name;

    // Embedded objects → jsonb column on the owning table.
    if (field.relation.isEmbedded) {
      return "$getter: jsonb('$colName')${field.isNullable ? '' : '.notNull()'},";
    }

    // BelongsTo FK → plain text column (UUIDs are stored as text).
    if (field.relation.kind == RelationKind.belongsTo) {
      return "$getter: text('$colName')${field.isNullable ? '' : '.notNull()'},";
    }

    // Explicit Drizzle type override (@DrizzleType / @CustomConverter).
    final customType =
        field.db.drizzleType ??
        field.converter.converterDrizzleType ??
        (field.db.sqlType?.toLowerCase());
    if (customType != null) {
      return "$getter: $customType('$colName')${field.isNullable ? '' : '.notNull()'},";
    }

    final fn = _columnFn(field);
    if (fn == null) return null;

    final buf = StringBuffer();

    if (field.isEnum) {
      buf.write("$fn('$colName', { enum: ${field.dartType.camelCase}Values })");
    } else {
      buf.write("$fn('$colName')");
    }

    // Primary key modifiers.
    if (field.db.isPrimaryKey) {
      if (field.db.isAutoIncrement) {
        buf.write('.primaryKey()');
      } else if (field.db.autoGenerate) {
        buf.write(r".$defaultFn(() => uuidv4()).primaryKey()");
      } else {
        buf.write('.primaryKey()');
      }
    }

    // Default value.
    final def = _drizzleDefault(field);
    if (def != null) buf.write(def);

    // notNull — skip for PKs (already implied) and nullable fields.
    if (!field.isNullable && !field.db.isPrimaryKey) buf.write('.notNull()');

    // Uniqueness.
    if (field.db.isUnique || field.db.indexUnique) buf.write('.unique()');

    return '$getter: $buf,';
  }

  /// Returns the set of drizzle-orm/pg-core function names this field needs.
  ///
  /// Used by [DrizzleImportCollector] to build the pg-core import set.
  Set<String> columnFunctionsFor(FieldInfo field) {
    if (field.relation.isEmbedded) return const {'jsonb'};
    if (field.db.drizzleType != null ||
        field.converter.converterDrizzleType != null) {
      // Custom type — the caller supplies the function name; we can't know it
      // statically. Return empty so no spurious imports are added.
      return const {};
    }
    final fn = _columnFn(field);
    return fn != null ? {fn} : const {};
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  String? _columnFn(FieldInfo field) {
    if (field.isList || field.isMap) return 'jsonb';
    return switch (field.dartType) {
      'String' => 'text',
      'int' => field.db.isAutoIncrement ? 'serial' : 'integer',
      'double' || 'num' => 'real',
      'bool' => 'boolean',
      'DateTime' => 'timestamp',
      'Duration' => 'integer',
      'Uint8List' => 'text',
      'dynamic' || 'Object' || 'Map' => 'jsonb',
      _ => field.isEnum ? 'text' : 'jsonb',
    };
  }

  String? _drizzleDefault(FieldInfo field) {
    if (field.isCreatedAt || field.isUpdatedAt) return '.defaultNow()';
    return switch (field.db.databaseDefault) {
      null => null,
      final String s => ".default('$s')",
      final bool b => '.default($b)',
      final num n => '.default($n)',
      final dynamic v => ".default('$v')",
    };
  }
}
