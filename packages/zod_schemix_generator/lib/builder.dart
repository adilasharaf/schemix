import 'package:build/build.dart';
import 'package:schemix/schemix.dart';

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
    ZodGenerator(dateTimeAsString: dateTimeAsString),
    skipAnnotation: 'NoZod',
  );
  return _NoOpBuilder();
}

// ── No-op builder ─────────────────────────────────────────────────────────────

final class _NoOpBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {};

  @override
  Future<void> build(BuildStep buildStep) async {}
}
