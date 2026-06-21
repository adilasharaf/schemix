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
  GormProjectBuilder(BuilderOptions options)
    : _outputDir = options.config['go_dir'] as String? ?? 'go',
      _outputFile =
          options.config['output_file'] as String? ?? '.schemix_gorm_done',
      _goModule = options.config['go_module'] as String? ?? 'schemix_project';

  final String _outputDir;
  final String _outputFile;
  final String _goModule;

  @override
  Map<String, List<String>> get buildExtensions => {
    r'$package$': ['$_outputDir/$_outputFile'],
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

    final modelsToGenerate = allClasses
        .where(
          (c) => c.hasSchemix && c.extensions['gorm'] != false && !c.isEnum,
        )
        .toList();

    final enumsToGenerate = allClasses
        .where((c) => c.hasSchemix && c.extensions['gorm'] != false && c.isEnum)
        .toList();

    if (modelsToGenerate.isEmpty && enumsToGenerate.isEmpty) return;

    String resolvedGoModule = _goModule;
    if (resolvedGoModule == 'schemix_project') {
      final goModPaths = ['go.mod', p.join(_outputDir, 'go.mod')];
      for (final path in goModPaths) {
        final goModFile = File(path);
        if (goModFile.existsSync()) {
          final lines = goModFile.readAsLinesSync();
          for (final line in lines) {
            if (line.startsWith('module ')) {
              resolvedGoModule = line.substring('module '.length).trim();
              break;
            }
          }
          if (resolvedGoModule != 'schemix_project') break;
        }
      }
    }

    final structBuilder = const GormStructBuilder();
    final enumBuilder = const GormEnumBuilder();

    // Use dart:io to output files to the target directories.
    final modelsDir = Directory(p.join(_outputDir, 'models'));
    if (!modelsDir.existsSync()) {
      modelsDir.createSync(recursive: true);
    }

    for (final cls in modelsToGenerate) {
      final buffer = StringBuffer();
      buffer.writeln('package models\n');

      final hasTime = cls.allFields.any((f) => !skipField(f) && f.dartType == 'DateTime');
      final hasEnum = cls.allFields.any((f) => !skipField(f) && f.isEnum);
      
      if (hasTime || hasEnum) {
        buffer.writeln('import (');
        if (hasTime) buffer.writeln('\t"time"');
        if (hasEnum) {
          final enumsPath = '$resolvedGoModule/$_outputDir/enums'.replaceAll(r'\', '/');
          buffer.writeln('\t"$enumsPath"');
        }
        buffer.writeln(')\n');
      }

      buffer.writeln(structBuilder.build(cls));

      final outFile = File(p.join(modelsDir.path, '${cls.name.snakeCase}.go'));
      outFile.writeAsStringSync(buffer.toString());
    }

    if (enumsToGenerate.isNotEmpty) {
      final enumsDir = Directory(p.join(_outputDir, 'enums'));
      if (!enumsDir.existsSync()) {
        enumsDir.createSync(recursive: true);
      }

      for (final enumCls in enumsToGenerate) {
        final content = enumBuilder.build(enumCls);
        final outFile = File(
          p.join(enumsDir.path, '${enumCls.name.snakeCase}.go'),
        );
        outFile.writeAsStringSync(content);
      }
    }

    // Write a dummy file to satisfy build_runner
    await buildStep.writeAsString(outputId, '// schemix gorm completed');
  }
}
