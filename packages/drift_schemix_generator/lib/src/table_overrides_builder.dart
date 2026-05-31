import 'package:schemix/models.dart';
import 'package:schemix_builder/schemix_builder.dart';

import 'column_builder.dart';
import 'utils.dart';

/// Builds the `@override` methods and static enum converter getters that sit
/// below the column declarations inside a Drift `Table` subclass.
///
/// Responsibilities:
/// - `tableName` override
/// - `primaryKey` override (composite PKs only; single-column PKs use
///   `autoIncrement()` or the column's own PK flag)
/// - `uniqueKeys` override (composite unique indexes from `@CompositeIndex`)
/// - Static `TypeConverter` getters for every enum field
final class DriftTableOverridesBuilder {
  const DriftTableOverridesBuilder(this._columnBuilder);
  final DriftColumnBuilder _columnBuilder;

  // ── Enum converters ────────────────────────────────────────────────────

  /// Returns zero or more `static TypeConverter<E, int>` getter declarations,
  /// one per distinct enum type used by the table's fields.
  ///
  /// A `Set<String>` is used to deduplicate: if two fields share the same enum
  /// type (e.g. two `UserStatus` columns) only one converter is emitted.
  List<String> buildEnumConverters(ClassInfo cls) {
    final seen = <String>{};
    return [
      for (final field in cls.allFields)
        if (!_columnBuilder.skipField(field) &&
            field.isEnum &&
            seen.add(field.dartType))
          '  static TypeConverter<${field.dartType}, int>'
              ' get ${field.dartType.converterName} =>\n'
              '      EnumIndexConverter<${field.dartType}>'
              '(${field.dartType}.values);',
    ];
  }

  // ── @override methods ──────────────────────────────────────────────────

  /// Returns the `@override` getter lines to append after all columns.
  ///
  /// Always emits `tableName`. Conditionally emits `primaryKey` (composite
  /// PKs only) and `uniqueKeys` (when composite unique indexes are declared).
  List<String> buildOverrides(
    ClassInfo cls,
    String tableName,
    SchemixLogger log,
  ) {
    final pkFields = cls.allFields
        .where((f) => f.db.isPrimaryKey)
        .toList(growable: false);

    final uniqueIndexes = cls.compositeIndexes
        .where((i) => i.unique)
        .toList(growable: false);

    if (pkFields.length > 1) {
      log.verbose(
        '   pk composite  | ${cls.name}'
        '  [${pkFields.map((f) => f.name).join(', ')}]',
      );
    }
    if (uniqueIndexes.isNotEmpty) {
      log.verbose(
        '   unique idx    | ${cls.name}  count=${uniqueIndexes.length}',
      );
    }

    return [
      '',
      '  @override',
      "  String get tableName => '$tableName';",
      // Composite PK override — only when there are multiple PK fields.
      if (pkFields.length > 1) ...[
        '',
        '  @override',
        '  Set<Column> get primaryKey =>'
            ' {${pkFields.map((f) => f.name).join(', ')}};',
      ],
      // Unique keys from @CompositeIndex(unique: true).
      if (uniqueIndexes.isNotEmpty) ...[
        '',
        '  @override',
        '  List<Set<Column>> get uniqueKeys => [',
        for (final idx in uniqueIndexes) '    {${idx.fields.join(', ')}},',
        '  ];',
      ],
    ];
  }
}
