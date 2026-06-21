import 'package:build/build.dart';
import 'package:schemix/schemix.dart';

import 'src/generator.dart';

export 'src/drift_barrel_builder.dart' show driftBarrelBuilder;

/// Registers [DriftGenerator] with [GeneratorRegistry] so the shared
/// `schemix_builder:schemix_file` builder can dispatch to it.
///
/// Returns a [_NoOpBuilder] — this package does NOT write files directly.
/// All file output is handled by `schemix_builder:schemix_file`.
///
/// Enable this alongside `schemix_builder|schemix_file` in your build.yaml:
///
/// ```yaml
/// targets:
///   $default:
///     builders:
///       schemix_builder|schemix_file:
///         enabled: true
///         options:
///           models_package: "my_models"
///       drift_schemix_generator|drift_schemix_generator:
///         enabled: true
/// ```
Builder driftBuilder(BuilderOptions options) {
  GeneratorRegistry.register(DriftGenerator(), skipAnnotation: 'NoDrift');
  return _NoOpBuilder();
}

/// A builder that declares no extensions and writes no files.
/// Its sole purpose is to trigger registration of [DriftGenerator].
final class _NoOpBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {};

  @override
  Future<void> build(BuildStep buildStep) async {}
}
