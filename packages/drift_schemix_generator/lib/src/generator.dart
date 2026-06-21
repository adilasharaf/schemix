import 'package:schemix/schemix.dart';
import 'package:schemix_builder/schemix_builder.dart' show SchemixLogger;

import 'column_builder.dart';
import 'header.dart';
import 'table_body_builder.dart';
import 'table_overrides_builder.dart';
import 'utils.dart';

/// Drift table generator.
///
/// Implements [SchemixGenerator] so it integrates with [GeneratorRegistry]
/// inside `schemix_builder`. One `.table.dart` file is produced per source
/// `.dart` file that contains at least one table-eligible class.
///
/// A class is eligible when:
/// - It is not an enum
/// - `ClassInfo.generators.drift` is `true`
/// - `ClassInfo.abstractSchema` is `false`
/// - `ClassInfo.embeddable` is `false`
final class DriftGenerator extends SchemixGenerator {
  /// Constructs the generator with a shared [DriftColumnBuilder] instance
  /// passed into both sub-builders so all column dispatch goes through one
  /// object (consistent skip logic, easy to swap in tests).
  DriftGenerator() : this._withColumnBuilder(const DriftColumnBuilder());

  DriftGenerator._withColumnBuilder(DriftColumnBuilder columnBuilder)
    : _bodyBuilder = DriftTableBodyBuilder(columnBuilder),
      _overridesBuilder = DriftTableOverridesBuilder(columnBuilder);
  static final _log = const SchemixLogger('drift');

  final DriftTableBodyBuilder _bodyBuilder;
  final DriftTableOverridesBuilder _overridesBuilder;

  // ── SchemixGenerator ────────────────────────────────────────────────────

  @override
  String get id => 'drift';

  @override
  List<String> get outputExtensions => const ['.table.dart'];

  @override
  bool shouldRun(ClassInfo classInfo) => _shouldGenerate(classInfo);

  /// Called once per class by the `schemix_builder` file builder dispatch loop.
  ///
  /// The [SchemixGenerator] contract expects per-class output; the file
  /// builder accumulates each class's output into a single file. The header
  /// is included in the output so the result is always a complete, valid Dart
  /// file. Callers that render multiple classes into one file should use
  /// [generateFile] directly instead.
  @override
  GeneratorOutput generate(ClassInfo classInfo, GeneratorContext context) {
    if (!_shouldGenerate(classInfo)) {
      _log.buildSkip(classInfo.name, _skipReason(classInfo));
      return const GeneratorOutput.empty();
    }

    final modelsPackage =
        context.options.config['models_package'] as String? ?? 'models';

    final tableClass = _generateTableClass(classInfo);
    if (tableClass.isEmpty) return const GeneratorOutput.empty();

    final header = DriftHeader(
      modelsPackage: modelsPackage,
    ).build(context.sourceAssetPath).join('\n');

    return GeneratorOutput({'.table.dart': '$header$tableClass'});
  }

  // ── File-level generation (used by tests and the builder directly) ───────

  /// Generates the complete `.table.dart` file content for [classes].
  ///
  /// Emits the file header exactly once, followed by one table class per
  /// eligible entry in [classes]. Returns an empty string when no class
  /// passes the eligibility gate.
  String generateFile(
    List<ClassInfo> classes,
    String assetPath,
    String modelsPackage,
  ) {
    _log.verbose('>> generate     | $assetPath  classes=${classes.length}');

    final tableClasses = <String>[];
    for (final cls in classes) {
      final table = _generateTableClass(cls);
      if (table.isNotEmpty) tableClasses.add(table);
    }

    _log.verbose('   done         | $assetPath  tables=${tableClasses.length}');

    if (tableClasses.isEmpty) return '';

    final header = DriftHeader(
      modelsPackage: modelsPackage,
    ).build(assetPath).join('\n');

    return '$header${tableClasses.join('\n')}';
  }

  // ── Private ──────────────────────────────────────────────────────────────

  String _generateTableClass(ClassInfo cls) {
    if (!_shouldGenerate(cls)) return '';

    final tableName = cls.tableName ?? cls.name.snakeCase;
    _log.verbose('   table        | ${cls.name} -> $tableName');

    final body = _bodyBuilder.buildTableBody(cls, _log);
    final converters = _overridesBuilder.buildEnumConverters(cls);

    _log.verbose(
      '   columns      | ${cls.name}  count=${body.length}'
      '${converters.isNotEmpty ? '  converters=${converters.length}' : ''}',
    );

    return [
      '// ─── ${cls.name} ───────────────────────────────────────────────',
      '',
      '@UseRowClass(${cls.name}, generateInsertable: true)',
      'class ${cls.name}Table extends Table {',
      ...body,
      if (converters.isNotEmpty) ...['', ...converters],
      ..._overridesBuilder.buildOverrides(cls, tableName, _log),
      '}',
      '',
    ].join('\n');
  }

  bool _shouldGenerate(ClassInfo cls) =>
      !cls.isEnum &&
      cls.extensions['drift'] != false &&
      !cls.abstractSchema &&
      !cls.embeddable;

  String _skipReason(ClassInfo cls) {
    if (cls.isEnum) return 'enum';
    if (cls.extensions['drift'] == false) return 'drift disabled';
    if (cls.abstractSchema) return 'abstract schema';
    if (cls.embeddable) return 'embeddable';
    return 'unknown';
  }
}
