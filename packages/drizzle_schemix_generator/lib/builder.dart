import 'package:build/build.dart';
import 'package:schemix/schemix.dart';

import 'src/generator.dart';

/// Builder factory registered in `build.yaml`.
///
/// Registers [DrizzleSchemixGenerator] with the [GeneratorRegistry] so the
/// Schemix file builder can dispatch Drizzle generation to this package,
/// then returns a no-op builder (generation is driven by `schemix_builder`'s
/// file builder — this package only needs to register itself).
Builder drizzleSchemixBuilder(BuilderOptions options) {
  GeneratorRegistry.register(DrizzleSchemixGenerator());
  return _NoOpBuilder();
}

/// A builder that declares no extensions and writes no files.
///
/// Its sole purpose is to be a hook so `build_runner` loads this package's
/// code, which causes [DrizzleSchemixGenerator] to be registered before
/// `SchemixFileBuilder` runs.
final class _NoOpBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {};

  @override
  Future<void> build(BuildStep buildStep) async {}
}
