import 'dart:async';

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:schemix/schemix.dart';

import 'logger.dart';
import 'model_analyzer.dart';
import 'registry.dart';

Builder schemixFileBuilder(BuilderOptions options) =>
    _SchemixFileBuilder(options);

// ── Options helpers ───────────────────────────────────────────────────────────

/// Reads output path configuration from [BuilderOptions].
///
/// All values have defaults that reproduce the original hardcoded behaviour.
/// Override any of these in the consuming package's `build.yaml`:
///
/// ```yaml
/// targets:
///   $default:
///     builders:
///       schemix_builder|schemix_file:
///         options:
///           serializable_dir: "lib"
///           serializable_suffix: ".schemix"
///           drift_dir: "lib"
///           drift_suffix: ".table"
///           ts_dir: "gen"
///           zod_suffix: ".g"
///           drizzle_suffix: ".drizzle"
/// ```
class _OutputPaths {
  _OutputPaths.fromOptions(BuilderOptions options)
    : serializableDir = options.config['serializable_dir'] as String? ?? 'lib',
      serializableSuffix =
          options.config['serializable_suffix'] as String? ?? '.schemix',
      driftDir = options.config['drift_dir'] as String? ?? 'lib',
      driftSuffix = options.config['drift_suffix'] as String? ?? '.table';

  final String serializableDir;
  final String serializableSuffix;
  final String driftDir;
  final String driftSuffix;

  /// Returns the output paths for a given input stem.
  ///
  /// [stem] is the part of the input path captured by `{{}}` in the
  /// build_extensions pattern — e.g. `models/user` for `lib/models/user.dart`.
  List<String> outputsFor(String stem) => [
    '$serializableDir/$stem$serializableSuffix.dart',
    '$driftDir/$stem$driftSuffix.dart',
  ];

  /// The `buildExtensions` map declared to `build_runner`.
  Map<String, List<String>> get buildExtensions => {
    r'^lib/{{}}.dart': [
      '$serializableDir/{{}}'
          '$serializableSuffix.dart',
      '$driftDir/{{}}'
          '$driftSuffix.dart',
    ],
  };
}

// ── GeneratorRegistry ─────────────────────────────────────────────────────────

/// Lightweight in-process registry for [SchemixGenerator] instances.
///
/// Generator packages call [GeneratorRegistry.register] from their builder
/// factory before returning the builder. The file builder looks generators up
/// by [SchemixGenerator.id] at generation time.
// abstract final class GeneratorRegistry {
//   static final Map<String, SchemixGenerator> _generators = {};

//   /// Registers [generator] so the file builder can dispatch to it.
//   /// Re-registering with the same [SchemixGenerator.id] overwrites the previous entry.
//   static void register(SchemixGenerator generator) {
//     _generators[generator.id] = generator;
//   }

//   static SchemixGenerator? find(String id) => _generators[id];
// }

// ── Builder ───────────────────────────────────────────────────────────────────

final class _SchemixFileBuilder implements Builder {
  _SchemixFileBuilder(BuilderOptions options)
    : _options = options,
      _paths = _OutputPaths.fromOptions(options);

  final BuilderOptions _options;
  final _OutputPaths _paths;

  static final _log = const SchemixLogger('builder');

  static const _registryAsset = 'lib/schemix_registry.json';

  @override
  Map<String, List<String>> get buildExtensions => _paths.buildExtensions;

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;

    _log.buildStart(inputId.path);

    if (SchemixConstants.generatedSuffixes.any(inputId.path.endsWith)) {
      _log.buildSkip(inputId.path, 'generated suffix');
      return;
    }
    if (!await buildStep.canRead(inputId)) {
      _log.buildSkip(inputId.path, 'cannot read');
      return;
    }

    // ── Load registry ──────────────────────────────────────────────────────

    final registryId = AssetId(inputId.package, _registryAsset);
    if (!await buildStep.canRead(registryId)) {
      _log.buildSkip(
        inputId.path,
        'registry not found — scan phase may not have run',
      );
      return;
    }

    final CrossFileRegistry registry;
    try {
      final json = await buildStep.readAsString(registryId);
      registry = CrossFileRegistry.fromJson(json);
    } catch (e, st) {
      _log.error(inputId.path, 'failed to deserialize registry: $e', st);
      return;
    }

    // ── Resolve library ────────────────────────────────────────────────────

    final library = await _resolveLibrary(buildStep, inputId);
    if (library == null) return;

    final fragmentUri = library.firstFragment.source.uri.toString();
    final inputUri = inputId.uri.toString();
    if (!fragmentUri.endsWith(inputId.path) && fragmentUri != inputUri) {
      _log.fragmentMismatch(fragmentUri, inputUri);
      return;
    }

    // ── Analyze ────────────────────────────────────────────────────────────

    final allClasses = ModelAnalyzer(
      registry,
    ).analyzeLibrary(library, inputId.path);
    final relevant = allClasses
        .where((c) => c.isEnum || c.hasSchemix)
        .toList(growable: false);

    _log.analysisResult(inputId.path, allClasses.length, relevant.length);

    if (relevant.isEmpty) {
      _log.buildNoOp(inputId.path);
      return;
    }

    _log.verbose('   classes      | ${relevant.map((c) => c.name).join(', ')}');

    // ── Build context ──────────────────────────────────────────────────────

    final context = GeneratorContext(
      typeGraph: registry,
      options: _options,
      sourceAssetPath: inputId.path,
    );

    // ── Dispatch to generators ─────────────────────────────────────────────
    // outputs[0] = serializable (.schemix.dart)
    // outputs[1] = drift        (.table.dart)
    // outputs[2] = zod/ts       (.g.ts)
    // outputs[3] = drizzle      (.drizzle.ts)

    final outputs = buildStep.allowedOutputs.toList(growable: false);

    if (outputs.isNotEmpty) {
      final serializableSource = _runGenerator(
        'serializable',
        relevant,
        context,
      );
      await _writeOutput(
        buildStep,
        outputs[0],
        serializableSource,
        'SerializableGenerator',
      );
      if (serializableSource != null) {
        final serializableFile = inputId.path
            .split('/')
            .last
            .replaceAll('.dart', '${_paths.serializableSuffix}.dart');
        final rawSource = await buildStep.readAsString(inputId);
        if (!rawSource.contains("part '$serializableFile'")) {
          _log.outputWarning(
            inputId.path,
            "generates Serializable but missing: part '$serializableFile';",
          );
        }
      }
    }

    if (outputs.length > 1) {
      final driftSource = _runGenerator('drift', relevant, context);
      if (driftSource != null) {
        _log.outputWrite(outputs[1].path, 'DriftGenerator');
        await buildStep.writeAsString(outputs[1], driftSource);

        // The .table.dart files are standalone libraries, so they don't
        // need to be declared as parts. Warning removed.
      } else {
        _log.outputSkip(outputs[1].path, 'DriftGenerator empty');
      }
    }

    // ── Dispatch to external generators via dart:io ───────────────────────
    // outputs are no longer tracked by build_runner to support external folders

    final tsDir = registry.options['ts_dir'] as String? ?? 'gen';
    final zodSuffix = registry.options['zod_suffix'] as String? ?? '.g';
    final drizzleSuffix =
        registry.options['drizzle_suffix'] as String? ?? '.drizzle';

    final stem = inputId.path.startsWith('lib/')
        ? inputId.path.substring(4).replaceAll('.dart', '')
        : inputId.path.replaceAll('.dart', '');

    final zodSource = _runGenerator('zod', relevant, context);
    if (zodSource != null) {
      final zodFile = File('$tsDir/$stem$zodSuffix.ts');
      if (!zodFile.parent.existsSync()) {
        zodFile.parent.createSync(recursive: true);
      }
      zodFile.writeAsStringSync(zodSource);
      _log.outputWrite(zodFile.path, 'ZodGenerator');
    }

    final drizzleSource = _runGenerator('drizzle', relevant, context);
    if (drizzleSource != null) {
      final drizzleFile = File('$tsDir/$stem$drizzleSuffix.ts');
      if (!drizzleFile.parent.existsSync()) {
        drizzleFile.parent.createSync(recursive: true);
      }
      drizzleFile.writeAsStringSync(drizzleSource);
      _log.outputWrite(drizzleFile.path, 'DrizzleGenerator');
    }
  }

  // ── Generator dispatch ─────────────────────────────────────────────────────

  /// Drives [id]-registered generator over [classes] and returns the
  /// concatenated output, or `null` when nothing was produced.
  String? _runGenerator(
    String id,
    List<ClassInfo> classes,
    GeneratorContext context,
  ) {
    final generator = GeneratorRegistry.find(id);
    if (generator == null) {
      _log.verbose('   no generator  | id=$id not registered');
      return null;
    }

    try {
      return generator.generateForFile(classes, context);
    } catch (e, st) {
      _log.error(context.sourceAssetPath, '$id threw: $e', st);
      return null;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _writeOutput(
    BuildStep buildStep,
    AssetId output,
    String? source,
    String generatorName,
  ) async {
    if (source == null) {
      _log.outputSkip(output.path, '$generatorName empty');
      return;
    }
    _log.outputWrite(output.path, generatorName);
    await buildStep.writeAsString(output, source);
  }

  Future<LibraryElement?> _resolveLibrary(
    BuildStep buildStep,
    AssetId inputId,
  ) async {
    try {
      return await buildStep.resolver.libraryFor(inputId);
    } catch (e) {
      _log.buildSkip(inputId.path, 'not a library: $e');
      return null;
    }
  }
}
