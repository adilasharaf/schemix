import 'package:schemix/schemix.dart';

import 'utils.dart';

/// Emits the `export const {tableVar}Relations = relations(…)` block for a
/// single [ClassInfo].
///
/// Returns an empty list when the class has no relation fields.
final class DrizzleRelationsBuilder {
  const DrizzleRelationsBuilder();

  List<String> generateRelations(ClassInfo cls) {
    final relationFields = cls.allFields
        .where((f) => f.relation.hasRelation && !skipField(f))
        .toList();

    if (relationFields.isEmpty) return const [];

    final tableVar = tableVarName(cls.name);

    return [
      'export const ${tableVar}Relations = relations($tableVar, ({ one, many }) => ({',
      for (final field in relationFields)
        if (field.relation.targetTypeName case final target?)
          _relationLine(cls.name, tableVar, field, target),
      '}));',
    ];
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  String _relationLine(
    String ownerName,
    String tableVar,
    FieldInfo field,
    String target,
  ) {
    final targetVar = tableVarName(target);
    return switch (field.relation.kind) {
      RelationKind.belongsTo =>
        '  ${field.name}: one($targetVar, { fields: [$tableVar.${field.name}], references: [$targetVar.id] }),',
      RelationKind.hasOne when field.relation.relationFieldName != null =>
        '  ${field.name}: one($targetVar, { fields: [$tableVar.id], references: [$targetVar.${field.relation.relationFieldName}] }),',
      RelationKind.hasOne =>
        '  // TODO: ${field.name} — hasOne requires explicit foreignKey. Add @HasOne($target, foreignKey: \'${ownerName.camelCase}Id\')',
      RelationKind.hasMany ||
      RelationKind.manyToMany => '  ${field.name}: many($targetVar),',
      _ => '',
    };
  }
}
