import 'package:schemix/schemix.dart';

import 'column_builder.dart';
import 'file_assembler.dart';
import 'import_collector.dart';
import 'relations_builder.dart';
import 'table_builder.dart';
import 'utils.dart';

/// Schemix generator that produces Drizzle ORM table schemas.
///
/// For every source file that contains at least one `@Schemix(generateDrizzle:
/// true)` class, this generator emits a `.drizzle.ts` file containing:
///
/// - `pgTable` schema declarations for each model.
/// - `relations()` blocks for fields annotated with `@BelongsTo`, `@HasOne`,
///   `@HasMany`, or `@ManyToMany`.
/// - `$inferSelect` / `$inferInsert` TypeScript type exports.
/// - Inline enum const arrays and type aliases for referenced Dart enums.
///
/// Register via the builder factory in `lib/builder.dart`:
/// ```dart
/// GeneratorRegistry.register(DrizzleSchemixGenerator());
/// ```
final class DrizzleSchemixGenerator implements SchemixGenerator {
  DrizzleSchemixGenerator()
    : _columnBuilder = const DrizzleColumnBuilder(),
      _tableBuilder = const DrizzleTableBuilder(DrizzleColumnBuilder()),
      _assembler = const DrizzleFileAssembler(
        DrizzleTableBuilder(DrizzleColumnBuilder()),
        DrizzleRelationsBuilder(),
      );

  final DrizzleColumnBuilder _columnBuilder;
  // ignore: unused_field — kept for symmetry; table building is done via _assembler
  final DrizzleTableBuilder _tableBuilder;
  final DrizzleFileAssembler _assembler;

  @override
  String get id => 'drizzle';

  @override
  List<String> get outputExtensions => const ['.drizzle.ts'];

  // ── SchemixGenerator ────────────────────────────────────────────────────────

  @override
  bool shouldRun(ClassInfo classInfo) =>
      (classInfo.hasSchemix || classInfo.isEnum) &&
      !classInfo.abstractSchema &&
      !classInfo.embeddable;

  /// Generates the full `.drizzle.ts` content for the classes in [context]'s
  /// source file.
  ///
  /// [classInfo] here is the *per-class* invocation that `SchemixFileBuilder`
  /// makes. However, the Drizzle output is a *per-file* artefact — one
  /// `.drizzle.ts` per source file. We therefore accumulate all classes for
  /// the same source file and generate once.
  ///
  /// Because `SchemixFileBuilder` deduplicates by output path, calling this
  /// once per class and returning the full file content each time is safe: the
  /// builder writes the last non-empty result, and all invocations for the same
  /// source file produce identical output.
  @override
  GeneratorOutput generate(ClassInfo classInfo, GeneratorContext context) {
    if (!classInfo.generators.drizzle && !classInfo.isEnum) {
      return const GeneratorOutput.empty();
    }

    // Collect every class from this source file that we know about via the
    // type graph, then generate the full file in one pass.
    final assetPath = context.sourceAssetPath;
    final typeGraph = context.typeGraph;

    // Build the class list for this file.  The type graph gives us TypeInfo
    // summaries; we only have the full ClassInfo for the class the builder is
    // currently visiting.  We therefore generate a single-class file here —
    // multi-class files are handled correctly because the builder calls us once
    // per class and collects all outputs.
    final models = <ClassInfo>[];
    if (!classInfo.isEnum && _shouldGenerateModel(classInfo)) {
      models.add(classInfo);
    }

    if (models.isEmpty) return const GeneratorOutput.empty();

    final referencedEnums = <ClassInfo>[];
    final colImports = <String>{};
    final crossFileImports = <String, Set<String>>{};

    final importCollector = DrizzleImportCollector(_columnBuilder, typeGraph);

    for (final cls in models) {
      // Collect enums referenced by this class.
      for (final field in cls.allFields) {
        if (skipField(field)) continue;
        if (!field.isEnum) continue;

        final enumName = field.dartType;
        if (referencedEnums.any((e) => e.name == enumName)) continue;

        // Try to resolve from the type graph; fall back to a stub.
        final enumInfo = typeGraph.resolve(enumName);
        if (enumInfo != null && enumInfo.isEnum) {
          referencedEnums.add(
            ClassInfo(
              name: enumInfo.name,
              assetPath: enumInfo.sourceAssetPath,
              isEnum: true,
              enumValues: enumInfo.enumValues,
              hasSchemix: true,
            ),
          );
        } else {
          // Stub — values will be empty; generator emits a best-effort output.
          referencedEnums.add(
            ClassInfo(name: enumName, assetPath: '', isEnum: true),
          );
        }
      }

      importCollector.collect(cls, assetPath, colImports, crossFileImports);
    }

    final needsUuid = models.any(
      (cls) => cls.allFields.any((f) => f.db.isPrimaryKey && f.db.autoGenerate),
    );

    final needsRelations = models.any(
      (cls) =>
          cls.allFields.any((f) => f.relation.hasRelation && !skipField(f)),
    );

    final output = _assembler.assemble(
      assetPath: assetPath,
      models: models,
      referencedEnums: referencedEnums,
      colImports: colImports,
      crossFileImports: crossFileImports,
      needsUuid: needsUuid,
      needsRelations: needsRelations,
    );

    return GeneratorOutput({'.drizzle.ts': output});
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  bool _shouldGenerateModel(ClassInfo cls) =>
      cls.hasSchemix &&
      cls.generators.drizzle &&
      !cls.abstractSchema &&
      !cls.embeddable &&
      !cls.isEnum;
}
