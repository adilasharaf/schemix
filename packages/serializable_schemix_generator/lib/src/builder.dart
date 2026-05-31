import 'package:build/build.dart';
import 'package:schemix_builder/schemix_builder.dart';

import 'generator.dart';

Builder serializableBuilder(BuilderOptions options) {
  GeneratorRegistry.register(SerializableGenerator());
  return schemixFileBuilder(options);
}
