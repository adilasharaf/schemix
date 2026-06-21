import 'package:schemix/models.dart';

/// Maps a [FieldInfo] to its Drift column type name and column builder
/// expression.
///
/// Resolution priority for every non-enum, non-relation field:
///
///   1. `@DriftType` override on the field (`field.db.driftType`)
///   2. Dart type → Drift type table (see [_dartTypeToDriftType])
///   3. `null` → field is skipped with a verbose log entry
abstract final class DriftTypeResolver {
  DriftTypeResolver._();

  // ── Public API ──────────────────────────────────────────────────────────

  /// Returns the Drift column type string (e.g. `'TextColumn'`, `'IntColumn'`)
  /// for [field], or `null` if no mapping exists.
  static String? resolve(FieldInfo field) {
    if (field.db.driftType != null) {
      return _driftTypeToColumn(field.db.driftType!);
    }
    return _dartTypeToDriftType(field.dartType, field.isList);
  }

  /// Returns the full Drift column builder expression for [field]
  /// (everything after `get fieldName =>`), or `null` if no mapping exists.
  ///
  /// Handles:
  /// - Nullable modifier (`.nullable()`)
  /// - `withDefault` for `DateTime` columns when `@DatabaseDefault` is set
  /// - `named(...)` with the snake_case JSON name
  static String? columnDefinition(FieldInfo field) {
    final colType = resolve(field);
    if (colType == null) return null;

    final colName = field.serialization
        .effectiveJsonName(field.name)
        ._snakeCase;

    final builder = _builderFunction(field.dartType, field.isList);
    if (builder == null) return null;

    final nullable = field.isNullable ? '.nullable()' : '';
    final unique = field.db.isUnique || field.db.indexUnique ? '.unique()' : '';

    // withDefault for DatabaseDefault
    final defaultClause = _defaultClause(field);

    return "$colType get ${field.name} => $builder().named('$colName')$defaultClause$unique$nullable();";
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  static String? _dartTypeToDriftType(String dartType, bool isList) {
    if (isList) return null; // Lists are never direct DB columns
    return switch (dartType) {
      'String' => 'TextColumn',
      'int' => 'IntColumn',
      'double' => 'RealColumn',
      'num' => 'RealColumn',
      'bool' => 'BoolColumn',
      'DateTime' => 'DateTimeColumn',
      'Uint8List' => 'BlobColumn',
      _ => null,
    };
  }

  /// Converts a raw `@DriftType` string like `'text'` to its column type
  /// class name like `'TextColumn'`.
  static String? _driftTypeToColumn(String driftType) {
    return switch (driftType.toLowerCase()) {
      'text' => 'TextColumn',
      'integer' || 'int' => 'IntColumn',
      'real' || 'double' || 'num' => 'RealColumn',
      'boolean' || 'bool' => 'BoolColumn',
      'datetime' || 'date' => 'DateTimeColumn',
      'blob' || 'uint8list' => 'BlobColumn',
      _ => null,
    };
  }

  /// Returns the Drift column builder method name (without parentheses) for a
  /// given Dart type, e.g. `'text'`, `'integer'`, `'real'`.
  static String? _builderFunction(String dartType, bool isList) {
    if (isList) return null;
    return switch (dartType) {
      'String' => 'text',
      'int' => 'integer',
      'double' || 'num' => 'real',
      'bool' => 'boolean',
      'DateTime' => 'dateTime',
      'Uint8List' => 'blob',
      _ => null,
    };
  }

  static String _defaultClause(FieldInfo field) {
    if (field.db.databaseDefault == null) return '';
    // Only currentDateAndTime is a named constant in Drift; everything else
    // would need a custom expression which we can't safely infer here.
    if (field.dartType == 'DateTime') {
      return '.withDefault(currentDateAndTime)';
    }
    final def = field.db.databaseDefault;
    if (def is String) {
      return ".withDefault(const Constant('$def'))";
    }
    return '.withDefault(const Constant($def))';
  }
}

// Local snakeCase to avoid importing utils in this file directly
extension _SnakeCaseHelper on String {
  String get _snakeCase {
    if (isEmpty) return this;
    final buf = StringBuffer();
    for (var i = 0; i < length; i++) {
      final ch = this[i];
      if (ch == ch.toUpperCase() && ch != ch.toLowerCase()) {
        if (i > 0) buf.write('_');
        buf.write(ch.toLowerCase());
      } else {
        buf.write(ch);
      }
    }
    return buf.toString();
  }
}
