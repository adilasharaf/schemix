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
        .where((f) => f.relation.hasRelation && f.relation.kind != RelationKind.manyToMany && !skipField(f))
        .toList();

    if (relationFields.isEmpty) return const [];

    final tableVar = tableVarName(cls.name);

    // Only destructure the identifiers that are actually used, to avoid
    // TypeScript's 'declared but never read' warning.
    final needsOne = relationFields.any(
      (f) =>
          f.relation.kind == RelationKind.belongsTo ||
          f.relation.kind == RelationKind.hasOne,
    );
    final needsMany = relationFields.any(
      (f) => f.relation.kind == RelationKind.hasMany,
    );

    final destructure = [if (needsOne) 'one', if (needsMany) 'many'].join(', ');

    return [
      'export const ${tableVar}Relations = relations($tableVar, ({ $destructure }) => ({',
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
    final relationName = field.name.endsWith('Id')
        ? field.name.substring(0, field.name.length - 2)
        : field.name;

    return switch (field.relation.kind) {
      RelationKind.belongsTo =>
        '  $relationName: one($targetVar, { fields: [$tableVar.${field.name}], references: [$targetVar.id] }),',
      RelationKind.hasOne when field.relation.relationFieldName != null =>
        '  $relationName: one($targetVar, { fields: [$tableVar.id], references: [$targetVar.${field.relation.relationFieldName}] }),',
      RelationKind.hasOne =>
        '  $relationName: one($targetVar, { fields: [$tableVar.id], references: [$targetVar.${ownerName.camelCase}Id] }),',
      RelationKind.hasMany => '  $relationName: many($targetVar),',
      // manyToMany relations are skipped in Drizzle because junction tables 
      // are not auto-generated. The user should use explicit models.
      RelationKind.manyToMany => '',
      _ => '',
    };
  }
}
