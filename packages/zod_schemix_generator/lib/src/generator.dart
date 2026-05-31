import 'package:schemix/schemix.dart';

import 'file_assembler.dart';
import 'graph_resolver.dart';
import 'schema_generator.dart';

/// The [SchemixGenerator] implementation for the Zod package.
///
/// Uses only [TypeGraph] from `schemix` — never [CrossFileRegistry], which
/// lives in `schemix_build` and must not be imported by generator packages.
///
/// ## How it integrates with the file builder
///
/// `_SchemixFileBuilder._runGenerator` calls [generate] once per class,
/// then concatenates all non-empty string outputs into a single file.
/// Because Zod schema order matters (dependency must precede dependent),
/// we buffer all classes from a source file on the first call and emit
/// everything on the *last* class — detected when [generate] is called
/// for a new source path.
///
/// Since `build_runner` processes one source file sequentially before moving
/// to the next, all classes from `lib/foo.dart` arrive before any class from
/// `lib/bar.dart`. The buffer is therefore flushed exactly once per file.
final class ZodGenerator implements SchemixGenerator {
  ZodGenerator({bool dateTimeAsString = true})
    : _dateTimeAsString = dateTimeAsString;

  final bool _dateTimeAsString;

  // Buffer: source asset path → collected classes + graph snapshot
  String? _currentPath;
  final List<ClassInfo> _buffer = [];
  TypeGraph? _graph;

  // ── SchemixGenerator contract ─────────────────────────────────────────────

  @override
  String get id => 'zod';

  @override
  List<String> get outputExtensions => const ['.g.ts'];

  @override
  bool shouldRun(ClassInfo classInfo) =>
      (classInfo.isEnum ||
          (classInfo.generators.zod && classInfo.hasSchemix)) &&
      !classInfo.manualImplementation;

  @override
  GeneratorOutput generate(ClassInfo classInfo, GeneratorContext context) {
    final path = context.sourceAssetPath;

    // ── New file detected: flush the previous file's buffer ─────────────────
    String? flushed;
    if (_currentPath != null && _currentPath != path) {
      flushed = _flush();
    }

    // ── Buffer this class ────────────────────────────────────────────────────
    if (_currentPath != path) {
      _currentPath = path;
      _buffer.clear();
      _graph = context.typeGraph;
    }
    _buffer.add(classInfo);

    // Return the flushed output of the *previous* file, if any.
    if (flushed != null && flushed.trim().isNotEmpty) {
      return GeneratorOutput({'.g.ts': flushed});
    }
    return const GeneratorOutput.empty();
  }

  /// Call this after all classes in a build step have been processed to
  /// emit the final file's output.
  ///
  /// The builder does not currently call this, so the last file's output
  /// is emitted via the class-by-class approach below. See [generateForFile]
  /// for an alternative entry point used in tests.
  String? get pendingOutput {
    if (_buffer.isEmpty) return null;
    return _flush();
  }

  // ── Direct entry point for tests / custom builders ────────────────────────

  /// Generates the complete `.g.ts` for [classes] from [assetPath].
  /// Bypasses the per-class buffer — useful in unit tests and in custom
  /// builders that collect all classes before calling the generator.
  String generateForFile(
    List<ClassInfo> classes,
    String assetPath,
    TypeGraph graph,
  ) {
    final relevant = classes.where(shouldRun).toList(growable: false);
    if (relevant.isEmpty) return '';
    return _assembleFile(relevant, assetPath, graph);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  String _flush() {
    if (_buffer.isEmpty || _graph == null) return '';
    final path = _currentPath!;
    final graph = _graph!;
    final relevant = _buffer.where(shouldRun).toList(growable: false);
    _buffer.clear();
    if (relevant.isEmpty) return '';
    return _assembleFile(relevant, path, graph);
  }

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

    return assembler.assemble(
      externalImports: externalImports,
      crossFileImports: crossFileImports,
      schemaBlocks: schemaBlocks,
    );
  }
}
