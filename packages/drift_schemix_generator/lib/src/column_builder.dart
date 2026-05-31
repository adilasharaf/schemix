import 'package:schemix/models.dart';

import 'type_resolver.dart';
import 'utils.dart';

/// Builds a single Drift column declaration string for a [FieldInfo].
///
/// The returned string is a complete Dart getter declaration, e.g.:
///
/// ```dart
/// TextColumn get email => text().named('email')();
/// IntColumn get status => integer().named('status').map(_statusConverter)();
/// TextColumn get userId => text().named('user_id')();
/// ```
///
/// Returns `null` when no Drift type mapping exists for the field.
final class DriftColumnBuilder {
  const DriftColumnBuilder();

  // ── Public API ─────────────────────────────────────────────────────────

  /// Returns the full getter declaration for [field], or `null` if the field
  /// has no Drift type mapping (e.g. `Map`, `List`, unsupported custom types).
  String? buildColumn(FieldInfo field) {
    // belongsTo FK columns are always stored as text (the FK ID string).
    if (field.relation.kind == RelationKind.belongsTo) {
      return _buildBelongsToColumn(field);
    }

    // Enum fields are stored as integers via EnumIndexConverter.
    if (field.isEnum) {
      return _buildEnumColumn(field);
    }

    // Primary key fields have their own dedicated builder.
    if (field.db.isPrimaryKey) {
      final colType = DriftTypeResolver.resolve(field);
      if (colType == null) return null;
      final colName = field.serialization
          .effectiveJsonName(field.name)
          .snakeCase;
      return _buildPrimaryKeyColumn(field, colName, colType);
    }

    // Regular column — delegate entirely to DriftTypeResolver.
    return DriftTypeResolver.columnDefinition(field);
  }

  // ── Skip predicates ─────────────────────────────────────────────────────

  /// Returns `true` when this field must not appear in the generated table.
  bool skipField(FieldInfo field) =>
      field.isIgnored ||
      field.platform.driftIgnore ||
      field.sync.cloudOnly ||
      field.relation.kind == RelationKind.hasMany ||
      field.relation.kind == RelationKind.hasOne ||
      field.relation.kind == RelationKind.manyToMany;

  /// Human-readable reason why [field] is being skipped (for verbose logging).
  String fieldSkipReason(FieldInfo field) {
    if (field.isIgnored) return 'ignored';
    if (field.platform.driftIgnore) return 'driftIgnore';
    if (field.sync.cloudOnly) return 'cloudOnly';
    if (field.relation.kind == RelationKind.hasMany) return 'hasMany';
    if (field.relation.kind == RelationKind.hasOne) return 'hasOne';
    if (field.relation.kind == RelationKind.manyToMany) return 'manyToMany';
    return 'unknown';
  }

  // ── Private builders ───────────────────────────────────────────────────

  String _buildBelongsToColumn(FieldInfo field) {
    final colName = field.serialization.effectiveJsonName(field.name).snakeCase;
    return "TextColumn get ${field.name} => text().named('$colName')();";
  }

  String _buildEnumColumn(FieldInfo field) {
    final colName = field.serialization.effectiveJsonName(field.name).snakeCase;
    final cn = field.dartType.converterName;
    final nullable = field.isNullable ? '.nullable()' : '';
    return "IntColumn get ${field.name} => integer().named('$colName')$nullable.map($cn)();";
  }

  String _buildPrimaryKeyColumn(
    FieldInfo field,
    String colName,
    String colType,
  ) {
    final db = field.db;
    if (db.isAutoIncrement) {
      return "$colType get ${field.name} => integer().named('$colName').autoIncrement()();";
    }
    if (db.autoGenerate) {
      // UUID v4 generated client-side via the `uuid` package.
      return "$colType get ${field.name} => text().named('$colName').clientDefault(() => const Uuid().v4())();";
    }
    // Plain PK with no auto-generation (caller sets the value).
    return "$colType get ${field.name} => text().named('$colName')();";
  }
}
