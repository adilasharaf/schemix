import 'package:build/build.dart';
import 'package:schemix/schemix.dart';
import 'package:schemix_builder/schemix_builder.dart';

import 'src/generator.dart';

/// Builder factory declared in `build.yaml`.
///
/// Registers [TsGenerator] with [GeneratorRegistry] under the id `'ts'` so
/// that `schemix_builder`'s file-builder can dispatch to it, then returns a
/// no-op builder (generation is driven by `schemix_builder`'s file builder).
///
/// ```yaml
/// # build.yaml (in the consuming package)
/// targets:
///   $default:
///     builders:
///       ts_schemix_generator|tsBuilder:
///         enabled: true
/// ```
Builder tsBuilder(BuilderOptions options) {
  GeneratorRegistry.register(_TsGeneratorAdapter());
  return _NoOpBuilder();
}

// ── Adapter ───────────────────────────────────────────────────────────────────

/// Lightweight adapter that implements [SchemixGenerator] without needing
/// the [CrossFileRegistry] at registration time.
final class _TsGeneratorAdapter implements SchemixGenerator {
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
    return const GeneratorOutput.empty();
  }
}

// ── No-op builder ─────────────────────────────────────────────────────────────

final class _NoOpBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {};

  @override
  Future<void> build(BuildStep buildStep) async {}
}
