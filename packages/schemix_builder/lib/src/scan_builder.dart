import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:schemix/schemix.dart';

import 'logger.dart';
import 'registry.dart';

Builder schemixScanBuilder(BuilderOptions options) => _SchemixScanBuilder();

final class _SchemixScanBuilder implements Builder {
  const _SchemixScanBuilder();

  static final _log = SchemixLogger('scan');

  @override
  Map<String, List<String>> get buildExtensions => const {
    r'$package$': ['lib/schemix_registry.json'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final outputs = buildStep.allowedOutputs.toList();
    if (outputs.isEmpty) {
      _log.buildSkip('schemix_registry.json', 'no allowed outputs');
      return;
    }

    final outputId = outputs.first;
    final registry = CrossFileRegistry();

    final assets = await buildStep.findAssets(Glob('lib/**.dart')).toList();
    _log.scanStart(assets.length);

    // Sequential processing avoids analyzer contention.
    for (final asset in assets) {
      if (SchemixConstants.generatedSuffixes.any(asset.path.endsWith)) {
        _log.scanSkip(asset.path, 'generated suffix');
        continue;
      }

      _log.scanAsset(asset.path);

      final LibraryElement lib;
      try {
        lib = await buildStep.resolver.libraryFor(asset);
      } catch (e) {
        _log.verbose('   scan error   | ${asset.path}  $e');
        continue;
      }

      _scanEnums(lib, asset.path, registry);
      _scanClasses(lib, asset.path, registry);
    }

    registry.seal();

    final json = registry.toJson();
    _log.outputWrite(outputId.path, 'SchemixScanBuilder');
    await buildStep.writeAsString(outputId, json);
  }

  // ── Enum scanning ─────────────────────────────────────────────────────────

  void _scanEnums(
    LibraryElement lib,
    String assetPath,
    CrossFileRegistry registry,
  ) {
    for (final e in lib.enums) {
      final values = e.fields
          .where((f) => f.isEnumConstant)
          .map((f) => f.name)
          .whereType<String>()
          .toList(growable: false);

      _log.registeredEnum(e.name!, assetPath, values);

      registry.register(
        TypeInfo(
          name: e.name!,
          isEnum: true,
          enumValues: values,
          sourceAssetPath: assetPath,
        ),
      );
    }
  }

  // ── Class scanning ────────────────────────────────────────────────────────

  void _scanClasses(
    LibraryElement lib,
    String assetPath,
    CrossFileRegistry registry,
  ) {
    for (final c in lib.classes) {
      if (c.name!.startsWith('_')) continue;

      final superName = switch (c.supertype) {
        final s? when s.element.name != 'Object' => s.element.name,
        _ => null,
      };

      final schemixAnn = _annotationNamed(c, 'Schemix');
      final conflictAnn = _annotationNamed(c, 'ConflictResolver');
      final hasSchemix = schemixAnn != null;

      final fieldDeps = <String>{};
      final relationDeps = <String>{};

      for (final field in c.fields) {
        if (field.isStatic || field.isSynthetic) continue;
        _collectTypeDeps(field.type, fieldDeps);
        for (final annName in const [
          'BelongsTo',
          'HasOne',
          'HasMany',
          'ManyToMany',
        ]) {
          _collectRelationDep(field, annName, 'target', relationDeps);
        }
      }

      _log.registeredClass(
        c.name!,
        assetPath,
        superclass: superName,
        hasSchemix: hasSchemix,
        fieldDeps: fieldDeps,
        relationDeps: relationDeps,
      );

      registry.register(
        TypeInfo(
          name: c.name!,
          isEnum: false,
          sourceAssetPath: assetPath,
          superclassName: superName,
          fieldDeps: fieldDeps,
          relationDeps: relationDeps,
          tableName: _stringField(schemixAnn, 'tableName'),
          collectionName: _stringField(schemixAnn, 'collectionName'),
          schemaVersion: _intField(schemixAnn, 'schemaVersion') ?? 1,
          namespace: _stringField(schemixAnn, 'namespace'),
          enableTimestamps: _boolField(schemixAnn, 'enableTimestamps'),
          enableSoftDelete: _boolField(schemixAnn, 'enableSoftDelete'),
          abstractSchema: _boolField(schemixAnn, 'abstractSchema'),
          cacheable: _boolField(schemixAnn, 'cacheable'),
          embeddable: _boolField(schemixAnn, 'embeddable'),
          generators: GeneratorFlags(
            zod: _boolField(schemixAnn, 'generateZod'),
            drift: _boolField(schemixAnn, 'generateDrift'),
            drizzle: _boolField(schemixAnn, 'generateDrizzle'),
          ),
          sync: SyncMeta(
            syncable: _boolField(schemixAnn, 'syncable'),
            conflictStrategy:
                _stringField(conflictAnn, 'strategy') ?? 'latestWins',
          ),
          manualImplementation: _hasAnnotationNamed(c, 'ManualImplementation'),
        ),
      );

      for (final field in c.fields) {
        if (field.isStatic || field.isSynthetic) continue;
        _registerRelations(registry, c.name!, field);
      }
    }
  }

  // ── Relation registration ─────────────────────────────────────────────────

  static void _registerRelations(
    CrossFileRegistry registry,
    String ownerName,
    FieldElement field,
  ) {
    for (final meta in field.metadata.annotations) {
      final kind = switch (_annotationName(meta)) {
        'BelongsTo' => RelationKind.belongsTo,
        'HasOne' => RelationKind.hasOne,
        'HasMany' => RelationKind.hasMany,
        'ManyToMany' => RelationKind.manyToMany,
        _ => null,
      };
      if (kind == null) continue;

      try {
        if (meta
                .computeConstantValue()
                ?.getField('target')
                ?.toTypeValue()
                ?.element
                ?.name
            case final targetName?) {
          registry.registerRelation(
            RelationInfo(
              ownerName: ownerName,
              targetName: targetName,
              fieldName: field.name!,
              kind: kind,
            ),
          );
        }
      } catch (_) {}
    }
  }

  // ── Type dependency collection ────────────────────────────────────────────

  static void _collectTypeDeps(DartType type, Set<String> deps) {
    if (type is! InterfaceType) return;
    if (type.element.name case final name?
        when !SchemixConstants.dartPrimitives.contains(name)) {
      deps.add(name);
    }
    for (final arg in type.typeArguments) {
      _collectTypeDeps(arg, deps);
    }
  }

  static void _collectRelationDep(
    FieldElement field,
    String annotationName,
    String fieldName,
    Set<String> deps,
  ) {
    for (final meta in field.metadata.annotations) {
      if (_annotationName(meta) != annotationName) continue;
      try {
        if (meta
                .computeConstantValue()
                ?.getField(fieldName)
                ?.toTypeValue()
                ?.element
                ?.name
            case final name?) {
          deps.add(name);
        }
      } catch (_) {}
    }
  }

  // ── Annotation helpers ────────────────────────────────────────────────────

  static String? _annotationName(ElementAnnotation ann) =>
      switch (ann.element) {
        ConstructorElement e => e.enclosingElement.name,
        PropertyAccessorElement e => e.name,
        _ => null,
      };

  static ElementAnnotation? _annotationNamed(ClassElement c, String name) {
    for (final meta in c.metadata.annotations) {
      if (_annotationName(meta) == name) return meta;
    }
    return null;
  }

  static bool _hasAnnotationNamed(ClassElement c, String name) =>
      _annotationNamed(c, name) != null;

  static bool _boolField(
    ElementAnnotation? ann,
    String field, {
    bool defaultValue = true,
  }) {
    try {
      return ann?.computeConstantValue()?.getField(field)?.toBoolValue() ??
          defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  static String? _stringField(ElementAnnotation? ann, String field) {
    try {
      return ann?.computeConstantValue()?.getField(field)?.toStringValue();
    } catch (_) {
      return null;
    }
  }

  static int? _intField(ElementAnnotation? ann, String field) {
    try {
      return ann?.computeConstantValue()?.getField(field)?.toIntValue();
    } catch (_) {
      return null;
    }
  }
}
