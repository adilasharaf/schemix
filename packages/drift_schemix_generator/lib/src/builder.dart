import 'package:build/build.dart';
import 'package:schemix_builder/schemix_builder.dart'
    show schemixFileBuilder, GeneratorRegistry;

import 'generator.dart';

export 'generator.dart' show DriftGenerator;

/// Builder factory entry point declared in `build.yaml`.
///
/// Registers [DriftGenerator] with [GeneratorRegistry] so the shared
/// `schemix_builder` file builder can dispatch to it, then returns the standard
/// [schemixFileBuilder] which owns the build step and writes all outputs.
///
/// Registration happens exactly once per build process because `build_runner`
/// calls the factory function once when constructing the builder graph.
Builder driftBuilder(BuilderOptions options) {
  GeneratorRegistry.register(DriftGenerator());
  return schemixFileBuilder(options);
}
