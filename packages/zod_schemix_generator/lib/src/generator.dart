import 'package:schemix/schemix.dart';
import 'package:ts_schemix_generator/ts_schemix_generator.dart'
    show assembleFile;

import 'file_assembler.dart';
import 'graph_resolver.dart';
import 'schema_generator.dart';

/// The [SchemixGenerator] implementation for the Zod package.
///
/// Uses only [TypeGraph] from `schemix` — never [CrossFileRegistry], which
/// lives in `schemix_builder` and must not be imported by generator packages.
///
/// ## Output format
///
/// Each `.g.ts` file contains both TypeScript interface / enum-type-alias
/// declarations (produced by `ts_schemix_generator`) and Zod schema constants
/// (produced by this package), merged into a single file:
///
/// ```
/// import { z } from 'zod';
/// <cross-file imports>
///
/// // ── Status (Enum) ──
/// export const StatusSchema = z.enum([...]);
/// export type Status = z.infer<typeof StatusSchema>;
///
/// // ── User (Type) ──
/// export interface User { ... }
///
/// // ── UserSchema ──
/// export const UserSchema = z.object({ ... });
/// ```
///
/// ## How it integrates with the file builder
///
/// `_SchemixFileBuilder._runGenerator` calls [generate] once per class, then
/// calls [flushPendingOutput] after all classes in a source file have been
/// dispatched (via the [FlushableGenerator] contract). This flush returns the
/// complete topo-sorted `.g.ts` content for that file.
///
/// Because Zod schema order matters (a dependency must be declared before any
/// schema that references it), this generator accumulates all classes from a
/// source file and only runs the topological sort + assembly at flush time.
final class ZodGenerator extends SchemixGenerator {
  ZodGenerator({bool dateTimeAsString = true})
    : _dateTimeAsString = dateTimeAsString;

  final bool _dateTimeAsString;

  // ── SchemixGenerator contract ─────────────────────────────────────────────

  @override
  String get id => 'zod';

  @override
  List<String> get outputExtensions => const ['.g.ts'];

  @override
  bool shouldRun(ClassInfo classInfo) =>
      (classInfo.isEnum || classInfo.hasSchemix) &&
      !classInfo.manualImplementation &&
      classInfo.extensions['zod'] != false;

  @override
  String? generateForFile(
    List<ClassInfo> classes,
    GeneratorContext context,
  ) {
    final relevant = classes.where(shouldRun).toList(growable: false);
    if (relevant.isEmpty) return null;
    return _assembleFile(relevant, context.sourceAssetPath, context.typeGraph);
  }

  @override
  GeneratorOutput generate(ClassInfo classInfo, GeneratorContext context) {
    return const GeneratorOutput.empty();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  String _assembleFile(
    List<ClassInfo> relevant,
    String assetPath,
    TypeGraph graph,
  ) {
    final graphResolver = const ZodGraphResolver();
    final schemaGen = ZodSchemaGenerator(
      graph,
      dateTimeAsString: _dateTimeAsString,
    );
    const assembler = ZodFileAssembler();

    final intraGraph = graphResolver.buildIntraFileGraph(relevant);
    final cyclicTypes = {
      ...graphResolver.findCyclicNodes(intraGraph),
      ...graph.cyclicTypes,
    };

    final externalImports = <String>{};
    final crossFileImports = <String, Set<String>>{};
    final schemaBlocks = <String>[];
    final classMap = {for (final c in relevant) c.name: c};
    final emitted = <String>{};

    for (final name in graphResolver.topoSort(intraGraph)) {
      final cls = classMap[name];
      if (cls == null || cls.isEnum) continue;
      schemaGen.generateSchema(
        cls: cls,
        assetPath: assetPath,
        cyclicTypes: cyclicTypes,
        externalImports: externalImports,
        crossFileImports: crossFileImports,
        schemaBlocks: schemaBlocks,
      );
      emitted.add(name);
    }

    for (final cls in relevant) {
      if (cls.isEnum || emitted.contains(cls.name)) continue;
      schemaGen.generateSchema(
        cls: cls,
        assetPath: assetPath,
        cyclicTypes: cyclicTypes,
        externalImports: externalImports,
        crossFileImports: crossFileImports,
        schemaBlocks: schemaBlocks,
      );
    }

    // Obtain the TS interface / enum-type-alias blocks from ts_schemix_generator
    // and merge them above the Zod schema constants in the same .g.ts file.
    final tsContent = assembleFile(relevant, assetPath, graph);

    return assembler.assembleWithTs(
      tsContent: tsContent.isEmpty ? null : tsContent,
      externalImports: externalImports,
      crossFileImports: crossFileImports,
      schemaBlocks: schemaBlocks,
    );
  }
}
