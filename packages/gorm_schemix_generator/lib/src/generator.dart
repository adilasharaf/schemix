import 'package:schemix/schemix.dart';
import 'struct_builder.dart';
import 'utils.dart';

final class GormSchemixGenerator extends SchemixGenerator {
  GormSchemixGenerator() : _structBuilder = const GormStructBuilder();

  final GormStructBuilder _structBuilder;

  @override
  String get id => 'gorm';

  @override
  List<String> get outputExtensions => const ['.gorm.go'];

  @override
  bool shouldRun(ClassInfo classInfo) =>
      (classInfo.hasSchemix || classInfo.isEnum) &&
      !classInfo.abstractSchema &&
      !classInfo.embeddable;

  @override
  GeneratorOutput generate(ClassInfo classInfo, GeneratorContext context) {
    if (classInfo.extensions['gorm'] == false && !classInfo.isEnum) {
      return const GeneratorOutput.empty();
    }

    final models = <ClassInfo>[];
    if (!classInfo.isEnum && _shouldGenerateModel(classInfo)) {
      models.add(classInfo);
    }

    if (models.isEmpty) return const GeneratorOutput.empty();

    final buffer = StringBuffer();
    // Default package name
    buffer.writeln('package models');
    buffer.writeln();

    final imports = <String>{};
    for (final cls in models) {
       for (final field in cls.allFields) {
          if (skipField(field)) continue;
          if (field.dartType == 'DateTime') {
            imports.add('"time"');
          }
          if (field.db.sqlType?.toUpperCase() == 'JSONB' || field.isMap) {
            imports.add('"gorm.io/datatypes"');
          }
       }
    }

    if (imports.isNotEmpty) {
      buffer.writeln('import (');
      for (final imp in imports) {
        buffer.writeln('\t$imp');
      }
      buffer.writeln(')');
      buffer.writeln();
    }

    for (final cls in models) {
      buffer.writeln(_structBuilder.build(cls));
      buffer.writeln();
    }

    return GeneratorOutput({'.gorm.go': buffer.toString()});
  }

  bool _shouldGenerateModel(ClassInfo cls) =>
      cls.hasSchemix &&
      cls.extensions['gorm'] != false &&
      !cls.abstractSchema &&
      !cls.embeddable &&
      !cls.isEnum;
}
