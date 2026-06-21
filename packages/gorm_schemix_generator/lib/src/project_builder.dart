import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:gorm_schemix_generator/src/enum_builder.dart';
import 'package:schemix/schemix.dart';
import 'package:schemix_builder/schemix_builder.dart';

import 'struct_builder.dart';
import 'utils.dart';

class GormProjectBuilder implements Builder {
  GormProjectBuilder(BuilderOptions options) : _options = options;

  final BuilderOptions _options;

  @override
  Map<String, List<String>> get buildExtensions => const {
    r'$package$': ['.schemix_gorm_done'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final outputs = buildStep.allowedOutputs.toList();
    if (outputs.isEmpty) return;

    final outputId = outputs.first;

    final registryId = AssetId(
      buildStep.inputId.package,
      'lib/schemix_registry.json',
    );
    if (!await buildStep.canRead(registryId)) {
      return;
    }

    final registryContent = await buildStep.readAsString(registryId);
    final registry = CrossFileRegistry.fromJson(registryContent);

    var goDir =
        registry.options['go_dir'] as String? ??
        _options.config['go_dir'] as String? ??
        'go';

    final modelPaths = <String>{};
    for (final typeInfo in registry.allModels) {
      if (!typeInfo.manualImplementation &&
          typeInfo.extensions['gorm'] != false) {
        modelPaths.add(typeInfo.sourceAssetPath);
      }
    }

    if (modelPaths.isEmpty) {
      return;
    }

    final allClasses = <ClassInfo>[];

    for (final path in modelPaths) {
      final assetId = AssetId(buildStep.inputId.package, path);
      if (!await buildStep.canRead(assetId)) continue;

      LibraryElement? library;
      try {
        library = await buildStep.resolver.libraryFor(assetId);
      } catch (e) {
        continue;
      }

      final classes = ModelAnalyzer(registry).analyzeLibrary(library, path);
      allClasses.addAll(classes);
    }

    final structBuilder = const GormStructBuilder();
    final enumBuilder = const GormEnumBuilder();

    final modelsDir = Directory(p.join(goDir, 'models'));
    if (!modelsDir.existsSync()) {
      modelsDir.createSync(recursive: true);
    }

    final groupedClasses = <String, List<ClassInfo>>{};
    for (final cls in allClasses) {
      if (cls.hasSchemix &&
          cls.extensions['gorm'] != false &&
          !cls.abstractSchema &&
          !cls.embeddable) {
        groupedClasses.putIfAbsent(cls.assetPath, () => []).add(cls);
      }
    }

    for (final entry in groupedClasses.entries) {
      final path = entry.key;
      final classes = entry.value;
      if (classes.isEmpty) continue;

      final buffer = StringBuffer();
      buffer.writeln('package models\n');

      final hasTime = classes.any(
        (c) =>
            !c.isEnum &&
            c.allFields.any((f) => !skipField(f) && f.dartType == 'DateTime'),
      );

      final hasJson = classes.any(
        (c) =>
            !c.isEnum &&
            c.allFields.any((f) => !skipField(f) && (f.db.sqlType?.toUpperCase() == 'JSONB' || f.isMap)),
      );

      if (hasTime || hasJson) {
        buffer.writeln('import (');
        if (hasTime) buffer.writeln('\t"time"');
        if (hasJson) buffer.writeln('\t"gorm.io/datatypes"');
        buffer.writeln(')\n');
      }

      for (final cls in classes) {
        if (cls.isEnum) {
          buffer.writeln(enumBuilder.build(cls));
        } else {
          buffer.writeln(structBuilder.build(cls));
        }
      }

      final baseName = p.basenameWithoutExtension(path);
      final outFile = File(p.join(modelsDir.path, '${baseName.snakeCase}.go'));
      outFile.writeAsStringSync(buffer.toString());
    }

    // Write a dummy file to satisfy build_runner
    await buildStep.writeAsString(outputId, '// schemix gorm completed');
  }
}
