import 'dart:async';

import 'package:build/build.dart';
import 'package:schemix/schemix.dart';

import 'logger.dart';
import 'model_analyzer.dart';
import 'registry.dart';

Builder schemixFileBuilder(BuilderOptions options) =>
    _SchemixFileBuilder(options);

final class _SchemixFileBuilder implements Builder {
  final BuilderOptions _options;

  const _SchemixFileBuilder(this._options);

  static final _log = SchemixLogger('builder');

  static const _registryAsset = 'lib/schemix_registry.json';

  @override
  Map<String, List<String>> get buildExtensions => const {
    r'^lib/{{}}.dart': [
      'lib/{{}}.schemix.dart',
      'lib/{{}}.table.dart',
      'gen/{{}}.g.ts',
      'gen/{{}}.drizzle.ts',
    ],
  };

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

    final outputs = buildStep.allowedOutputs.toList(growable: false);

    if (outputs.isNotEmpty) {
      await _writeOutput(
        buildStep,
        outputs[0],
        _runGenerator('serializable', relevant, context),
        'SerializableGenerator',
      );
    }

    if (outputs.length > 1) {
      final driftSource = _runGenerator('drift', relevant, context);
      if (driftSource != null) {
        _log.outputWrite(outputs[1].path, 'DriftGenerator');
        await buildStep.writeAsString(outputs[1], driftSource);

        final tableFile = inputId.path
            .split('/')
            .last
            .replaceAll('.dart', '.table.dart');
        final rawSource = await buildStep.readAsString(inputId);
        if (!rawSource.contains("part '$tableFile'")) {
          _log.outputWarning(
            inputId.path,
            "generates Drift table but missing: part '$tableFile';",
          );
        }
      } else {
        _log.outputSkip(outputs[1].path, 'DriftGenerator empty');
      }
    }

    if (outputs.length > 2) {
      await _writeOutput(
        buildStep,
        outputs[2],
        _runGenerator('zod', relevant, context),
        'ZodGenerator',
      );
    }

    if (outputs.length > 3) {
      await _writeOutput(
        buildStep,
        outputs[3],
        _runGenerator('drizzle', relevant, context),
        'DrizzleGenerator',
      );
    }
  }

  // ── Generator dispatch ────────────────────────────────────────────────────

  /// Locates the registered generator for [id], runs it over [classes],
  /// and returns the concatenated output for the primary extension, or null
  /// if no generator is registered or all output was empty.
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

    final buf = StringBuffer();
    try {
      for (final classInfo in classes) {
        if (!generator.shouldRun(classInfo)) continue;
        final output = generator.generate(classInfo, context);
        for (final entry in output.outputs.entries) {
          if (entry.value != null && entry.value!.trim().isNotEmpty) {
            buf.writeln(entry.value);
          }
        }
      }
    } catch (e, st) {
      _log.error(context.sourceAssetPath, '$id threw: $e', st);
      return null;
    }

    final result = buf.toString().trim();
    return result.isEmpty ? null : result;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _writeOutput(
    BuildStep buildStep,
    AssetId output,
    String? source,
    String generatorName,
  ) async {
    if (source != null && source.trim().isNotEmpty) {
      _log.outputWrite(output.path, generatorName);
      await buildStep.writeAsString(output, source);
    } else {
      _log.outputSkip(output.path, '$generatorName produced empty output');
    }
  }

  Future<dynamic> _resolveLibrary(BuildStep buildStep, AssetId inputId) async {
    try {
      return await buildStep.inputLibrary;
    } catch (e, st) {
      _log.error(inputId.path, e, st);
      return null;
    }
  }
}

// ── Generator registry ────────────────────────────────────────────────────────

/// Lightweight in-process registry for [SchemixGenerator] instances.
///
/// Generator packages call [GeneratorRegistry.register] from their builder
/// factory before returning the builder. The file builder looks generators up
/// by [SchemixGenerator.id] at generation time.
///
/// This is an interim design for Milestone 1. The long-term approach (declared
/// via `build.yaml` required_inputs and builder options) is tracked as an open
/// question in the architecture document.
abstract final class GeneratorRegistry {
  static final Map<String, SchemixGenerator> _generators = {};

  /// Registers [generator] so the file builder can dispatch to it.
  /// Re-registering with the same [SchemixGenerator.id] overwrites the previous entry.
  static void register(SchemixGenerator generator) {
    _generators[generator.id] = generator;
  }

  static SchemixGenerator? find(String id) => _generators[id];
}
