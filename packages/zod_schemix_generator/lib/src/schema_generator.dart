import 'package:schemix/schemix.dart';

import 'type_resolver.dart';
import 'utils.dart';

/// Generates the `export const FooSchema: z.ZodType<Foo> = ...` block
/// for a single [ClassInfo].
///
/// Cyclic types are wrapped in `z.lazy()` and typed via `z.ZodType<T>`.
/// Non-cyclic types use plain `z.object({...})`.
final class ZodSchemaGenerator {
  const ZodSchemaGenerator(this._graph, {this.dateTimeAsString = false});

  final TypeGraph _graph;

  /// When true, DateTime fields are emitted as `z.string().datetime(...)`.
  /// (Currently always true — kept as an explicit option for future
  /// dateTimeAsNumber or native Date modes.)
  final bool dateTimeAsString;

  /// Appends a schema block to [schemaBlocks] for [cls].
  ///
  /// Any cross-file imports discovered during resolution are written into
  /// [crossFileImports] (keyed by relative import path).
  /// Any external npm/utility imports are written into [externalImports].
  void generateSchema({
    required ClassInfo cls,
    required String assetPath,
    required Set<String> cyclicTypes,
    required Set<String> externalImports,
    required Map<String, Set<String>> crossFileImports,
    required List<String> schemaBlocks,
  }) {
    final localImports = <String>{};

    final fieldLines = [
      for (final field in cls.allFields)
        if (!skipField(field))
          '  ${tsKey(field.effectiveJsonName)}: ${_resolveFieldZod(field: field, assetPath: assetPath, cyclicTypes: cyclicTypes, externalImports: localImports, crossFileImports: crossFileImports)},',
    ];

    externalImports.addAll(localImports);

    final name = cls.name;
    final schema = '${name}Schema';
    final isCyclic = cyclicTypes.contains(name);

    final block = isCyclic
        ? '// ── $name (Schema) ──\n'
              'export const $schema: z.ZodType<$name> = z.lazy(() =>\n'
              '  z.object({\n'
              '${fieldLines.map((l) => '  $l').join('\n')}\n'
              '  })\n'
              ') as unknown as z.ZodType<$name>;'
        : '// ── $name (Schema) ──\n'
              'export const $schema: z.ZodType<$name> = z.object({\n'
              '${fieldLines.join('\n')}\n'
              '});';

    schemaBlocks.add(block);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  String _resolveFieldZod({
    required FieldInfo field,
    required String assetPath,
    required Set<String> cyclicTypes,
    required Set<String> externalImports,
    required Map<String, Set<String>> crossFileImports,
  }) {
    String? modelSchemaName(String typeName) {
      if (_graph.resolve(typeName) == null) return null;
      if (_graph.relativeImportFor(
            typeName: typeName,
            fromSourceAssetPath: assetPath,
          )
          case final rel?) {
        crossFileImports.putIfAbsent(rel, () => {})
          ..add(typeName)
          ..add('${typeName}Schema');
      }
      return '${typeName}Schema';
    }

    var expr = ZodTypeResolver.resolve(
      field: field,
      modelSchemaName: modelSchemaName,
      cyclicTypes: cyclicTypes,
      requiredImports: externalImports,
    );

    if (field.isNullable) expr = '$expr.nullish()';

    if (field.db.databaseDefault case final def?) {
      if (DefaultResolver.toZodCatch(def.toString()) case final catch_?) {
        expr = '$expr.catch($catch_)';
      }
    }

    return expr;
  }
}
