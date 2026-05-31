import 'package:build/build.dart';
import 'package:schemix/schemix.dart';
import 'package:schemix_builder/schemix_builder.dart';

import 'src/generator.dart';

export 'src/file_assembler.dart';
export 'src/generator.dart';
export 'src/graph_resolver.dart';
export 'src/schema_generator.dart';
export 'src/type_resolver.dart';
export 'src/utils.dart';

/// Builder factory declared in `build.yaml`.
///
/// The factory registers [ZodGenerator] with [GeneratorRegistry] so that
/// the `schemix_builder` file-builder can dispatch to it.
///
/// ```yaml
/// # build.yaml (in the consuming package)
/// targets:
///   $default:
///     builders:
///       zod_schemix_generator|zodBuilder:
///         enabled: true
///         options:
///           dateTimeAsString: true
/// ```
Builder zodBuilder(BuilderOptions options) {
  // Temporarily create a minimal registry placeholder; the real registry is
  // provided by schemix_build at generation time via GeneratorContext.typeGraph.
  // We register under the well-known id 'zod' so schemix_build can find it.
  final dateTimeAsString = options.config['dateTimeAsString'] as bool? ?? true;

  GeneratorRegistry.register(
    _ZodGeneratorAdapter(dateTimeAsString: dateTimeAsString),
  );

  // The actual file writing is handled by schemix_build's _SchemixFileBuilder.
  // This builder itself has no build extensions — it only performs registration.
  // Return a no-op builder so build_runner is satisfied.
  return _NoOpBuilder();
}

// ── Adapter ───────────────────────────────────────────────────────────────────

/// Adapts [ZodGenerator] to the [SchemixGenerator] interface in a way that
/// works when the registry is not yet available at registration time.
///
/// At [generate] time, [GeneratorContext.typeGraph] is cast to
/// [CrossFileRegistry] (which is the concrete type schemix_build always uses).
final class _ZodGeneratorAdapter implements SchemixGenerator {
  _ZodGeneratorAdapter({required this.dateTimeAsString});

  final bool dateTimeAsString;

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
    // This method is called once per class. We generate at the file level, so
    // we emit nothing here and rely on the builder's _runGenerator calling
    // generateFile on the concrete ZodGenerator. See builder comment below.
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
