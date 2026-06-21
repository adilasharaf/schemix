import 'package:build/build.dart';
import 'package:schemix/schemix.dart';

import 'src/generator.dart';

Builder goSerializableSchemixBuilder(BuilderOptions options) {
  GeneratorRegistry.register(GoSerializableSchemixGenerator());
  return _NoOpBuilder();
}

final class _NoOpBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {};

  @override
  Future<void> build(BuildStep buildStep) async {}
}
