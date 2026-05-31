import 'package:build/build.dart';
import 'package:schemix/schemix.dart';
import 'package:schemix_builder/schemix_builder.dart';

import 'src/generator.dart';

export 'src/file_assembler.dart';
export 'src/generator.dart';
export 'src/interface_generator.dart';
export 'src/type_resolver.dart';
export 'src/utils.dart';

/// Builder factory declared in `build.yaml`.
///
/// Registers [TsGenerator] with [GeneratorRegistry] under the id `'ts'` so
/// that `schemix_build`'s file-builder can dispatch to it.
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
///
/// File-level generation is driven by the builder, which provides the full
/// context via [GeneratorContext.typeGraph].
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
    // File-level generation is driven by the builder; this returns empty.
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
