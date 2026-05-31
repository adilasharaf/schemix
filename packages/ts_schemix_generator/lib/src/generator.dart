import 'package:schemix/schemix.dart';
import 'package:schemix_builder/schemix_builder.dart' show SchemixLogger;

import 'file_assembler.dart';
import 'interface_generator.dart';

/// The [SchemixGenerator] implementation for the TypeScript interfaces package.
///
/// Output: a single `.d.ts` file per source file containing:
///   - `import { z } from 'zod'` (when enums are present)
///   - `import type { Foo } from './...'` for cross-file references
///   - `export const FooSchema = z.enum([...])` + `export type Foo = ...`
///     for enum types
///   - `export interface Foo { ... }` for model types
///
/// This generator deliberately does **not** emit Zod schema `z.object({...})`
/// blocks — that is the responsibility of `zod_schemix_generator`.
final class TsGenerator implements SchemixGenerator {
  static final _log = SchemixLogger('ts');

  @override
  String get id => 'ts';

  @override
  List<String> get outputExtensions => const ['.d.ts'];

  @override
  bool shouldRun(ClassInfo classInfo) =>
      (classInfo.isEnum ||
          (classInfo.generators.zod && classInfo.hasSchemix)) &&
      !classInfo.manualImplementation;

  @override
  GeneratorOutput generate(ClassInfo classInfo, GeneratorContext context) {
    if (!shouldRun(classInfo)) {
      _log.buildSkip(classInfo.name, _skipReason(classInfo));
      return const GeneratorOutput.empty();
    }

    final interfaceGenerator = TsInterfaceGenerator(context.typeGraph);

    _log.verbose('   generate     | ${classInfo.name}');

    final block = classInfo.isEnum
        ? interfaceGenerator.generateEnum(classInfo)
        : interfaceGenerator.generateInterface(classInfo);

    return GeneratorOutput({'.d.ts': block});
  }

  // ── File-level generation (used by tests and the builder directly) ───────

  /// Generates the complete `.d.ts` content for [classes] from [assetPath].
  /// Returns an empty string if no class passes the eligibility gate.
  String generateFile(
    List<ClassInfo> classes,
    String assetPath,
    TypeGraph graph,
  ) {
    _log.verbose('>> generate     | $assetPath  classes=${classes.length}');

    final relevant = classes.where(shouldRun).toList(growable: false);
    if (relevant.isEmpty) return '';

    final result = assembleFile(relevant, assetPath, graph);

    _log.verbose('   done         | $assetPath  types=${relevant.length}');

    return result;
  }

  // ── Private ───────────────────────────────────────────────────────────────

  String _skipReason(ClassInfo cls) {
    if (cls.manualImplementation) return 'manual implementation';
    if (!cls.isEnum && !cls.generators.zod) return 'zod disabled';
    if (!cls.isEnum && !cls.hasSchemix) return 'no schemix annotation';
    return 'unknown';
  }
}

/// Assembles the full `.d.ts` file from [classes] for the source at [assetPath].
///
/// Called by the builder after all classes in a file have been collected.
/// Returns an empty string if no output was produced.
String assembleFile(
  List<ClassInfo> classes,
  String assetPath,
  TypeGraph graph,
) {
  final log = SchemixLogger('ts');
  log.buildStart(assetPath);

  final generator = TsGenerator();
  final interfaceGenerator = TsInterfaceGenerator(graph);
  const assembler = TsFileAssembler();

  final relevant = classes.where(generator.shouldRun).toList(growable: false);
  if (relevant.isEmpty) {
    log.buildNoOp(assetPath);
    return '';
  }

  final zodImports = <String>{};
  final crossFileImports = <String, Set<String>>{};
  final enumBlocks = <String>[];
  final interfaceBlocks = <String>[];

  for (final cls in relevant) {
    if (cls.isEnum) {
      enumBlocks.add(interfaceGenerator.generateEnum(cls));
      continue;
    }
    interfaceBlocks.add(interfaceGenerator.generateInterface(cls));
  }

  final content = assembler.assemble(
    zodImports: zodImports,
    crossFileImports: crossFileImports,
    enumBlocks: enumBlocks,
    interfaceBlocks: interfaceBlocks,
  );

  if (content.trim().isEmpty) {
    log.buildNoOp(assetPath);
    return '';
  }

  log.outputWrite(assetPath, 'ts');
  return content;
}
