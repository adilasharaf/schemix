import 'package:schemix/schemix.dart';

import 'column_builder.dart';
import 'utils.dart';

/// Emits the `export const {tableVar} = pgTable('{tableName}', { … });` block
/// for a single [ClassInfo].
final class DrizzleTableBuilder {
  const DrizzleTableBuilder(this._columnBuilder);

  final DrizzleColumnBuilder _columnBuilder;

  List<String> generateTable(ClassInfo cls) {
    final tableVar = tableVarName(cls.name);
    final tableName = cls.tableName ?? cls.name.snakeCase;

    final hasCreatedAt = cls.allFields.any((f) => f.isCreatedAt);
    final hasUpdatedAt = cls.allFields.any((f) => f.isUpdatedAt);
    final hasDeletedAt = cls.allFields.any((f) => f.isDeletedAt);

    // Fields that produce a column: exclude virtual relation sides and skipped
    // fields. HasMany / HasOne / ManyToMany never have a physical column.
    final visibleFields = cls.allFields.where(
      (f) =>
          !skipField(f) &&
          f.relation.kind != RelationKind.hasMany &&
          f.relation.kind != RelationKind.hasOne &&
          f.relation.kind != RelationKind.manyToMany,
    );

    return [
      "export const $tableVar = pgTable('$tableName', {",
      for (final field in visibleFields)
        if (_columnBuilder.buildColumn(field) case final col?) '  $col',
      // Auto-injected timestamps (only when not explicitly declared).
      if (cls.enableTimestamps) ...[
        if (!hasCreatedAt)
          "  createdAt: timestamp('created_at').defaultNow().notNull(),",
        if (!hasUpdatedAt)
          "  updatedAt: timestamp('updated_at').defaultNow().notNull(),",
      ],
      if (cls.enableSoftDelete && !hasDeletedAt)
        "  deletedAt: timestamp('deleted_at'),",
      '});',
    ];
  }
}
