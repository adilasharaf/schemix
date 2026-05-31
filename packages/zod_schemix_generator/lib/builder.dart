import 'package:build/build.dart';
import 'package:schemix/schemix.dart';
import 'package:schemix_builder/schemix_builder.dart';

import 'src/generator.dart';

/// Builder factory declared in `build.yaml`.
///
/// Registers [ZodGenerator] with [GeneratorRegistry] so the shared
/// `schemix_builder` file builder can dispatch to it, then returns a no-op
/// builder (generation is driven by `schemix_builder`'s file builder — this
/// package only needs to register itself).
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
  final dateTimeAsString = options.config['dateTimeAsString'] as bool? ?? true;
  GeneratorRegistry.register(
    _ZodGeneratorAdapter(dateTimeAsString: dateTimeAsString),
  );
  return _NoOpBuilder();
}

// ── Adapter ───────────────────────────────────────────────────────────────────

/// Adapts [ZodGenerator] to the [SchemixGenerator] interface in a way that
/// works when the registry is not yet available at registration time.
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
