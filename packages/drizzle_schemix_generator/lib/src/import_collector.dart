import 'package:schemix/schemix.dart';

import 'column_builder.dart';
import 'utils.dart';

/// Collects all import symbols needed for a single source file's Drizzle output.
///
/// Populates two sets:
/// - [colImports] — identifiers imported from `drizzle-orm/pg-core`
///   (e.g. `pgTable`, `text`, `timestamp`).
/// - [crossFileImports] — map from relative TS import path to the set of
///   table variable names imported from that path.
final class DrizzleImportCollector {
  const DrizzleImportCollector(this._columnBuilder, this._typeGraph);

  final DrizzleColumnBuilder _columnBuilder;
  final TypeGraph _typeGraph;

  void collect(
    ClassInfo cls,
    String assetPath,
    Set<String> colImports,
    Map<String, Set<String>> crossFileImports,
  ) {
    colImports.add('pgTable');

    for (final field in cls.allFields) {
      if (skipField(field)) continue;

      // Cross-file relation imports.
      if (field.relation.hasRelation && field.relation.targetTypeName != null) {
        final isUnresolvableHasOne =
            field.relation.kind == RelationKind.hasOne &&
            field.relation.relationFieldName == null;

        if (!isUnresolvableHasOne) {
          final rel = _typeGraph.relativeDrizzleImportFor(
            typeName: field.relation.targetTypeName!,
            fromSourceAssetPath: assetPath,
          );
          if (rel != null) {
            crossFileImports
                .putIfAbsent(rel, () => {})
                .add(tableVarName(field.relation.targetTypeName!));
          }
          // If rel == null, the target is in the same file — no import needed.
        }
      }

      // pg-core column function imports (only for fields that produce columns).
      if (!field.relation.hasRelation ||
          field.relation.kind == RelationKind.belongsTo ||
          field.relation.isEmbedded) {
        colImports.addAll(_columnBuilder.columnFunctionsFor(field));
      }
    }

    // Auto-injected timestamp columns always need the timestamp import.
    if (cls.enableTimestamps || cls.enableSoftDelete) {
      colImports.add('timestamp');
    }
  }
}
