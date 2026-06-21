import 'package:build/build.dart';
import 'src/project_builder.dart';

Builder gormProjectBuilder(BuilderOptions options) {
  return GormProjectBuilder(options);
}
