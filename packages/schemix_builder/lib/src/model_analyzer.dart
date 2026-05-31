import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:schemix/models.dart';

import 'annotation_validator.dart';
import 'logger.dart';
import 'registry.dart';

class ModelAnalyzer {
  final CrossFileRegistry _registry;
  static final _log = SchemixLogger('analyzer');

  ModelAnalyzer(this._registry);

  List<ClassInfo> analyzeLibrary(LibraryElement library, String assetPath) {
    _log.verbose(
      '>> analyze      | $assetPath  enums=${library.enums.length}  classes=${library.classes.length}',
    );

    final results = <ClassInfo>[];

    for (final element in library.enums) {
      final info = _analyzeEnum(element, assetPath);
      _log.registeredEnum(info.name, assetPath, info.enumValues);
      results.add(info);
    }

    for (final element in library.classes) {
      if (element.name!.startsWith('_')) {
        _log.scanSkip('${element.name}  <- $assetPath', 'private class');
        continue;
      }
      final info = _analyzeClass(element, assetPath);
      if (info == null) {
        _log.scanSkip(
          '${element.name}  <- $assetPath',
          'no relevant annotations',
        );
        continue;
      }
      _log.registeredClass(
        info.name,
        assetPath,
        superclass: info.superclassName,
        hasSchemix: info.hasSchemix,
      );
      results.add(info);
    }

    _log.analysisResult(
      assetPath,
      library.enums.length + library.classes.length,
      results.length,
    );
    return results;
  }

  // ── Enum ─────────────────────────────────────────────────────────────────

  ClassInfo _analyzeEnum(EnumElement element, String assetPath) {
    final values = element.fields
        .where((f) => f.isEnumConstant)
        .map((f) => f.name)
        .whereType<String>()
        .toList();

    _log.verbose(
      '   enum         | ${element.name}  values=[${values.join(', ')}]',
    );

    return ClassInfo(
      name: element.name!,
      assetPath: assetPath,
      isEnum: true,
      enumValues: values,
      hasSchemix: true,
    );
  }

  // ── Class ─────────────────────────────────────────────────────────────────

  ClassInfo? _analyzeClass(ClassElement element, String assetPath) {
    final hasSchemixAnnotation = _hasAnnotation(element, 'Schemix');
    final hasJsonSerializable = _hasAnnotation(element, 'JsonSerializable');
    final hasTsGenerate = _hasAnnotation(element, 'TsGenerate');

    final hasFromJson = element.methods.any(
      (m) => m.isStatic && (m.name == 'fromJson' || m.name == 'fromMap'),
    );
    final hasToMap = element.methods.any(
      (m) => !m.isStatic && (m.name == 'toMap' || m.name == 'toJson'),
    );
    final hasManualSerialization = hasFromJson && hasToMap;

    final isRelevant =
        hasSchemixAnnotation ||
        hasJsonSerializable ||
        hasTsGenerate ||
        hasManualSerialization;

    if (!isRelevant) return null;

    _log.verbose(
      '   class scan   | ${element.name}'
      '  schemix=$hasSchemixAnnotation'
      '  jsonSerializable=$hasJsonSerializable'
      '  tsGenerate=$hasTsGenerate'
      '  manualSerialization=$hasManualSerialization',
    );

    final useSnakeCase = hasManualSerialization && !hasJsonSerializable;
    final schemixAnn = _getAnnotation(element, 'Schemix');

    final tableName = _stringField(schemixAnn, 'tableName');
    final collectionName = _stringField(schemixAnn, 'collectionName');
    final schemaVersion = _intField(schemixAnn, 'schemaVersion') ?? 1;
    final namespace = _stringField(schemixAnn, 'namespace');
    final enableTimestamps =
        _boolField(schemixAnn, 'enableTimestamps') ?? false;
    final enableSoftDelete =
        _boolField(schemixAnn, 'enableSoftDelete') ?? false;
    final abstractSchema = _boolField(schemixAnn, 'abstractSchema') ?? false;
    final cacheable = _boolField(schemixAnn, 'cacheable') ?? false;
    final syncable = _boolField(schemixAnn, 'syncable') ?? false;
    final embeddable = _boolField(schemixAnn, 'embeddable') ?? false;

    _log.verbose(
      '   class cfg    | ${element.name}'
      '  table=${tableName ?? element.name}'
      '  v$schemaVersion'
      '  timestamps=$enableTimestamps'
      '  softDelete=$enableSoftDelete'
      '  abstract=$abstractSchema'
      '  embeddable=$embeddable',
    );

    final generators = GeneratorFlags(
      zod: _boolField(schemixAnn, 'generateZod') ?? true,
      drift: _boolField(schemixAnn, 'generateDrift') ?? false,
      drizzle: _boolField(schemixAnn, 'generateDrizzle') ?? false,
    );

    _log.verbose(
      '   generators   | ${element.name}'
      '  zod=${generators.zod}'
      '  drift=${generators.drift}'
      '  drizzle=${generators.drizzle}',
    );

    final conflictAnn = _getAnnotation(element, 'ConflictResolver');
    final syncMeta = SyncMeta(
      syncable: syncable,
      conflictStrategy: _stringField(conflictAnn, 'strategy') ?? 'latestWins',
    );

    if (syncable) {
      _log.verbose(
        '   sync         | ${element.name}  strategy=${syncMeta.conflictStrategy}',
      );
    }

    final manualImpl = _hasAnnotation(element, 'ManualImplementation');
    if (manualImpl) {
      _log.verbose('   manual impl  | ${element.name}');
    }

    final compositeIndexes = element.metadata.annotations
        .where((a) => _annotationName(a) == 'CompositeIndex')
        .map((a) {
          final fieldsObj = a.computeConstantValue()?.getField('fields');
          final fields =
              fieldsObj
                  ?.toListValue()
                  ?.map((v) => v.toStringValue() ?? '')
                  .where((s) => s.isNotEmpty)
                  .toList() ??
              [];
          final unique = _boolField(a, 'unique') ?? false;
          final orderObj = a.computeConstantValue()?.getField('order');
          final order =
              orderObj
                  ?.toListValue()
                  ?.map((v) => v.toStringValue() ?? '')
                  .where((s) => s.isNotEmpty)
                  .toList() ??
              [];
          _log.verbose(
            '   composite idx| ${element.name}'
            '  fields=[${fields.join(', ')}]'
            '  unique=$unique',
          );
          return CompositeIndexInfo(
            fields: fields,
            unique: unique,
            order: order,
          );
        })
        .toList();

    final ownFields = element.fields
        .where((f) => !f.isStatic && !f.isSynthetic)
        .map((f) => _analyzeField(element, f, useSnakeCase: useSnakeCase))
        .whereType<FieldInfo>()
        .toList();

    final inheritedFields = _collectInheritedFields(
      element,
      useSnakeCase: useSnakeCase,
    );

    _log.verbose(
      '   fields       | ${element.name}'
      '  own=${ownFields.length}'
      '  inherited=${inheritedFields.length}',
    );

    // Extract primary constructor parameter names for serialization generators.
    final ctorParamNames = element.constructors
        .where((ctor) => !ctor.isFactory && (ctor.name?.isEmpty ?? true))
        .expand((ctor) => ctor.formalParameters)
        .map((p) => p.name)
        .toSet();

    _log.verbose(
      '   ctor params  | ${element.name}  count=${ctorParamNames.length}  $ctorParamNames',
    );

    final classInfo = ClassInfo(
      name: element.name!,
      assetPath: assetPath,
      ownFields: ownFields,
      inheritedFields: inheritedFields,
      superclassName: _superclassName(element),
      hasSchemix: isRelevant,
      hasJsonSerializable: hasJsonSerializable,
      hasManualSerialization: hasManualSerialization,
      tableName: tableName,
      collectionName: collectionName,
      schemaVersion: schemaVersion,
      namespace: namespace,
      enableTimestamps: enableTimestamps,
      enableSoftDelete: enableSoftDelete,
      abstractSchema: abstractSchema,
      cacheable: cacheable,
      syncable: syncable,
      embeddable: embeddable,
      generators: generators,
      sync: syncMeta,
      manualImplementation: manualImpl,
      compositeIndexes: compositeIndexes,
      ctorParamNames: ctorParamNames.whereType<String>().toSet(),
    );

    AnnotationValidator.validate(classInfo, element);

    return classInfo;
  }

  // ── Inherited field collection ────────────────────────────────────────────

  List<FieldInfo> _collectInheritedFields(
    ClassElement element, {
    bool useSnakeCase = false,
    int depth = 0,
  }) {
    if (depth > 8) {
      _log.warning(
        'inheritance depth > 8 for ${element.name} — stopping traversal',
      );
      return const [];
    }

    final superType = element.supertype;
    if (superType == null) return const [];

    final superEl = superType.element;
    if (superEl is! ClassElement || superEl.name == 'Object') return const [];

    _log.verbose(
      '   inherit      | ${element.name}  <- ${superEl.name}  depth=$depth',
    );

    final ancestorFields = _collectInheritedFields(
      superEl,
      useSnakeCase: useSnakeCase,
      depth: depth + 1,
    );

    final parentFields = superEl.fields
        .where((f) => !f.isStatic && !f.isSynthetic)
        .map((f) => _analyzeField(superEl, f, useSnakeCase: useSnakeCase))
        .whereType<FieldInfo>()
        .toList();

    return [...ancestorFields, ...parentFields];
  }

  // ── Field analysis ────────────────────────────────────────────────────────

  FieldInfo? _analyzeField(
    ClassElement element,
    FieldElement field, {
    bool useSnakeCase = false,
  }) {
    final type = field.type;
    final isNullable = type.nullabilitySuffix == NullabilitySuffix.question;
    final baseType = _baseTypeName(type);
    final isRequired = element.constructors.any(
      (ctor) => ctor.formalParameters.any(
        (param) =>
            param is FieldFormalParameterElement &&
            param.field == field &&
            (param.isRequiredNamed || param.isRequiredPositional),
      ),
    );

    bool isList = false, isMap = false;
    String? listItemType, mapValueType;

    if (type is InterfaceType) {
      final typeName = type.element.name;
      if ((typeName == 'List' || typeName == 'Iterable') &&
          type.typeArguments.isNotEmpty) {
        isList = true;
        listItemType = _baseTypeName(type.typeArguments.first);
        _log.verbose('   field list   | ${field.name}  itemType=$listItemType');
      } else if (typeName == 'Map' && type.typeArguments.length >= 2) {
        isMap = true;
        mapValueType = _baseTypeName(type.typeArguments[1]);
        _log.verbose(
          '   field map    | ${field.name}  valueType=$mapValueType',
        );
      }
    }

    final isEnumType = _isKnownEnum(type);

    // Early return for ignored fields — extractors must not run.
    final jsonKeyAnn = _getAnnotation(field, 'JsonKey');
    final isIgnored =
        _hasAnnotation(field, 'IgnoreField') ||
        _hasAnnotation(field, 'TsIgnore') ||
        _boolField(jsonKeyAnn, 'ignore') == true ||
        _boolField(jsonKeyAnn, 'includeFromJson') == false ||
        _boolField(jsonKeyAnn, 'includeToJson') == false;

    if (isIgnored) {
      _log.verbose('   field skip   | ${field.name}  (ignored)');
      return FieldInfo(
        name: field.name!,
        dartType: baseType,
        isNullable: isNullable,
        serialization: const FieldSerializationInfo(isIgnored: true),
        isLate: field.isLate,
        isRequired: isRequired,
      );
    }

    final schemixFieldAnn =
        _getAnnotation(field, 'SchemixField') ??
        _getAnnotation(field, 'AppField');

    final immutable = _boolField(schemixFieldAnn, 'immutable') ?? false;
    final readonly = _boolField(schemixFieldAnn, 'readonly') ?? false;
    final hidden = _boolField(schemixFieldAnn, 'hidden') ?? false;
    final internal = _boolField(schemixFieldAnn, 'internal') ?? false;
    final unique = _boolField(schemixFieldAnn, 'unique') ?? false;

    return FieldInfo(
      name: field.name!,
      dartType: baseType,
      isNullable: isNullable,
      isList: isList,
      isMap: isMap,
      listItemType: listItemType,
      mapValueType: mapValueType,
      isEnum: isEnumType,
      isLate: field.isLate,
      isRequired: isRequired,
      immutable: immutable,
      readonly: readonly,
      hidden: hidden,
      internal: internal,
      unique: unique,
      isCreatedAt: _hasAnnotation(field, 'CreatedAt'),
      isUpdatedAt: _hasAnnotation(field, 'UpdatedAt'),
      isDeletedAt: _hasAnnotation(field, 'DeletedAt'),
      isVersionField: _hasAnnotation(field, 'VersionField'),
      isAuditField: _hasAnnotation(field, 'AuditField'),
      db: _extractDb(field),
      relation: _extractRelation(field),
      serialization: _extractSerialization(field, useSnakeCase, jsonKeyAnn),
      converter: _extractConverter(field),
      validation: _extractValidation(field),
      security: _extractSecurity(field, schemixFieldAnn),
      sync: _extractSync(field),
      api: _extractApi(field, readonly),
      platform: _extractPlatform(field),
    );
  }

  // ── Extractor functions ───────────────────────────────────────────────────

  FieldDbInfo _extractDb(FieldElement field) {
    final pkAnn = _getAnnotation(field, 'PrimaryKey');
    final indexedAnn = _getAnnotation(field, 'Indexed');
    final dbGenAnn = _getAnnotation(field, 'DatabaseGenerated');
    final dbDefAnn = _getAnnotation(field, 'DatabaseDefault');
    final checkAnn = _getAnnotation(field, 'CheckConstraint');
    final sqlTypeAnn = _getAnnotation(field, 'SqlType');
    final drizzleTypeAnn = _getAnnotation(field, 'DrizzleType');
    final driftTypeAnn = _getAnnotation(field, 'DriftType');
    final sortKeyAnn = _getAnnotation(field, 'SortKey');
    final uniqueF =
        _boolField(_getAnnotation(field, 'SchemixField'), 'unique') ?? false;

    final db = FieldDbInfo(
      isPrimaryKey: pkAnn != null,
      autoGenerate: _boolField(pkAnn, 'autoGenerate') ?? false,
      compositeOrder: _intField(pkAnn, 'compositeOrder'),
      clustered: _boolField(pkAnn, 'clustered') ?? false,
      isSecondaryKey: _hasAnnotation(field, 'SecondaryKey'),
      isUnique: _hasAnnotation(field, 'Unique') || uniqueF,
      isAutoIncrement: _hasAnnotation(field, 'AutoIncrement'),
      isDatabaseGenerated: dbGenAnn != null,
      dbGeneratedStrategy: _stringField(dbGenAnn, 'strategy'),
      sqlType: _stringField(sqlTypeAnn, 'type'),
      drizzleType: _stringField(drizzleTypeAnn, 'type'),
      driftType: _stringField(driftTypeAnn, 'type'),
      databaseDefault: _readConstantValue(dbDefAnn, 'value'),
      checkConstraint: _stringField(checkAnn, 'expression'),
      isIndexed: indexedAnn != null,
      indexName: _stringField(indexedAnn, 'name'),
      indexUnique: _boolField(indexedAnn, 'unique') ?? false,
      indexDescending: _boolField(indexedAnn, 'descending') ?? false,
      indexFullText: _boolField(indexedAnn, 'fullText') ?? false,
      indexSpatial: _boolField(indexedAnn, 'spatial') ?? false,
      isPartitionKey: _hasAnnotation(field, 'PartitionKey'),
      isSortKey: sortKeyAnn != null,
      sortKeyDescending: _boolField(sortKeyAnn, 'descending') ?? false,
      isFullTextSearch: _hasAnnotation(field, 'FullTextSearch'),
      isCachedField: _hasAnnotation(field, 'CachedField'),
    );

    if (pkAnn != null) {
      _log.verbose(
        '   pk           | ${field.name}'
        '  autoGenerate=${db.autoGenerate}'
        '  autoIncrement=${db.isAutoIncrement}'
        '  composite=${db.compositeOrder}',
      );
    }
    if (db.isIndexed) {
      _log.verbose(
        '   index        | ${field.name}'
        '  name=${db.indexName}'
        '  unique=${db.indexUnique}'
        '  fullText=${db.indexFullText}',
      );
    }

    return db;
  }

  FieldRelationInfo _extractRelation(FieldElement field) {
    RelationKind? kind;
    String? targetTypeName;
    String? junctionTable;
    String? relationName;

    if (_hasAnnotation(field, 'BelongsTo')) {
      kind = RelationKind.belongsTo;
      targetTypeName = _typeField(field, 'BelongsTo', 'target');
    } else if (_hasAnnotation(field, 'HasOne')) {
      kind = RelationKind.hasOne;
      targetTypeName = _typeField(field, 'HasOne', 'target');
    } else if (_hasAnnotation(field, 'HasMany')) {
      kind = RelationKind.hasMany;
      targetTypeName = _typeField(field, 'HasMany', 'target');
    } else if (_hasAnnotation(field, 'ManyToMany')) {
      kind = RelationKind.manyToMany;
      final ann = _getAnnotation(field, 'ManyToMany')!;
      targetTypeName = _typeFieldFromAnnotation(ann, 'target');
      junctionTable = _stringField(ann, 'junctionTable');
      relationName = _stringField(ann, 'relationName');
    }

    if (kind != null) {
      if (targetTypeName == null) {
        _log.outputWarning(
          field.name!,
          'relation kind=$kind but target type could not be resolved — check annotation',
        );
      } else {
        _log.verbose(
          '   relation     | ${field.name}'
          '  kind=$kind'
          '  target=$targetTypeName'
          '  junction=$junctionTable',
        );
      }
    }

    final relationFieldAnn = _getAnnotation(field, 'RelationField');

    return FieldRelationInfo(
      kind: kind,
      targetTypeName: targetTypeName,
      junctionTable: junctionTable,
      relationName: relationName,
      isEmbedded: _hasAnnotation(field, 'Embedded'),
      isCascadeDelete: _hasAnnotation(field, 'CascadeDelete'),
      isLazy: _hasAnnotation(field, 'LazyRelation'),
      relationFieldName: _stringField(relationFieldAnn, 'fieldName'),
    );
  }

  FieldSerializationInfo _extractSerialization(
    FieldElement field,
    bool useSnakeCase,
    ElementAnnotation? jsonKeyAnn,
  ) {
    final jsonFieldAnn = _getAnnotation(field, 'JsonField');
    final dateFormatAnn = _getAnnotation(field, 'DateFormat');
    final precisionAnn = _getAnnotation(field, 'Precision');
    final serializeAsAnn = _getAnnotation(field, 'SerializeAs');

    final jsonKeyName =
        _stringField(jsonFieldAnn, 'name') ?? _stringField(jsonKeyAnn, 'name');

    return FieldSerializationInfo(
      jsonKeyName: jsonKeyName,
      isIgnored: false,
      isReadOnly: _hasAnnotation(field, 'ReadOnlyField'),
      isWriteOnly: _hasAnnotation(field, 'WriteOnlyField'),
      serializeAs: _stringField(serializeAsAnn, 'type'),
      flatten: _hasAnnotation(field, 'Flatten'),
      dateFormat: _stringField(dateFormatAnn, 'format'),
      precisionDigits: _intField(precisionAnn, 'precision'),
      precisionScale: _intField(precisionAnn, 'scale'),
      useSnakeCaseFallback: jsonKeyName == null && useSnakeCase,
    );
  }

  FieldConverterInfo _extractConverter(FieldElement field) {
    final customConvAnn = _getAnnotation(field, 'CustomConverter');
    final tsTypeAnn = _getAnnotation(field, 'TsType');
    final zodTypeAnn = _getAnnotation(field, 'ZodType');

    final converter = FieldConverterInfo(
      hasDateTimeConverter: _hasAnnotation(field, 'DateTimeConverter'),
      hasDateTimeListConverter: _hasAnnotation(field, 'DateTimeListConverter'),
      hasDateTimeNullableConverter: _hasAnnotation(
        field,
        'DateTimeNullableConverter',
      ),
      customConverterClass: _typeFieldFromAnnotation(
        customConvAnn,
        'dartConverter',
      ),
      tsConverter: _stringField(customConvAnn, 'tsConverter'),
      converterSqlType: _stringField(customConvAnn, 'sqlType'),
      converterDrizzleType: _stringField(customConvAnn, 'drizzleType'),
      tsTypeOverride: _stringField(tsTypeAnn, 'typeName'),
      zodSchemaOverride: _stringField(tsTypeAnn, 'zodSchema'),
      zodTypeOverride: _stringField(zodTypeAnn, 'schema'),
    );

    if (converter.customConverterClass != null) {
      _log.verbose(
        '   converter    | ${field.name}'
        '  dart=${converter.customConverterClass}'
        '  ts=${converter.tsConverter}'
        '  drizzleType=${converter.converterDrizzleType}',
      );
    }
    if (converter.zodSchemaOverride != null ||
        converter.zodTypeOverride != null) {
      _log.verbose(
        '   zod override | ${field.name}'
        '  schema=${converter.zodSchemaOverride}'
        '  type=${converter.zodTypeOverride}',
      );
    }

    return converter;
  }

  FieldValidation _extractValidation(FieldElement field) {
    final minAnn = _getAnnotation(field, 'Min');
    final maxAnn = _getAnnotation(field, 'Max');
    final lengthAnn = _getAnnotation(field, 'Length');
    final regexAnn = _getAnnotation(field, 'Regex');
    final allowedAnn = _getAnnotation(field, 'AllowedValues');
    final disallowedAnn = _getAnnotation(field, 'DisallowValues');

    return FieldValidation(
      required: _hasAnnotation(field, 'Required'),
      min: _numField(minAnn, 'value'),
      max: _numField(maxAnn, 'value'),
      minLength: _intField(lengthAnn, 'min'),
      maxLength: _intField(lengthAnn, 'max'),
      regex: _stringField(regexAnn, 'pattern'),
      isEmail: _hasAnnotation(field, 'Email'),
      isUrl: _hasAnnotation(field, 'Url'),
      isPhone: _hasAnnotation(field, 'Phone'),
      isIpAddress: _hasAnnotation(field, 'IpAddress'),
      isUuid: _hasAnnotation(field, 'Uuid'),
      allowedValues: _listField(allowedAnn, 'values'),
      disallowedValues: _listField(disallowedAnn, 'values'),
    );
  }

  FieldSecurityInfo _extractSecurity(
    FieldElement field,
    ElementAnnotation? schemixFieldAnn,
  ) {
    final sensitive = _boolField(schemixFieldAnn, 'sensitive') ?? false;
    final permAnn = _getAnnotation(field, 'PermissionRequired');
    final readScopeAnn = _getAnnotation(field, 'ReadScope');
    final writeScopeAnn = _getAnnotation(field, 'WriteScope');

    final security = FieldSecurityInfo(
      encrypted: _hasAnnotation(field, 'Encrypted'),
      hashed: _hasAnnotation(field, 'Hashed'),
      sensitive: _hasAnnotation(field, 'Sensitive') || sensitive,
      maskInLogs: _hasAnnotation(field, 'MaskInLogs'),
      permissionRequired: _stringField(permAnn, 'permission'),
      readScopes: _stringListField(readScopeAnn, 'scopes'),
      writeScopes: _stringListField(writeScopeAnn, 'scopes'),
    );

    if (security.encrypted || security.hashed || security.sensitive) {
      _log.verbose(
        '   security     | ${field.name}'
        '  encrypted=${security.encrypted}'
        '  hashed=${security.hashed}'
        '  sensitive=${security.sensitive}'
        '  maskInLogs=${security.maskInLogs}',
      );
    }

    return security;
  }

  FieldSyncInfo _extractSync(FieldElement field) {
    final syncPriorityAnn = _getAnnotation(field, 'SyncPriority');

    final sync = FieldSyncInfo(
      offlineOnly: _hasAnnotation(field, 'OfflineOnly'),
      cloudOnly: _hasAnnotation(field, 'CloudOnly'),
      operationTracked: _hasAnnotation(field, 'OperationTracked'),
      syncPriority: _intField(syncPriorityAnn, 'priority'),
    );

    if (sync.offlineOnly || sync.cloudOnly) {
      _log.verbose(
        '   sync flag    | ${field.name}'
        '  offlineOnly=${sync.offlineOnly}'
        '  cloudOnly=${sync.cloudOnly}',
      );
    }

    return sync;
  }

  FieldApiInfo _extractApi(FieldElement field, bool readonlyFromSchemixField) {
    final apiFieldAnn = _getAnnotation(field, 'ApiField');
    final apiVerAnn = _getAnnotation(field, 'ApiVersion');

    final api = FieldApiInfo(
      expose: _boolField(apiFieldAnn, 'expose') ?? true,
      readonly: _boolField(apiFieldAnn, 'readonly') ?? readonlyFromSchemixField,
      deprecated: _boolField(apiFieldAnn, 'deprecated') ?? false,
    );

    if (api.deprecated) {
      _log.outputWarning(
        field.name!,
        'field is deprecated'
        '  deprecatedIn=${_stringField(apiVerAnn, 'deprecatedIn')}'
        '  removedIn=${_stringField(apiVerAnn, 'removedIn')}',
      );
    }

    return api;
  }

  FieldPlatformFlags _extractPlatform(FieldElement field) {
    final platform = FieldPlatformFlags(
      driftIgnore: _hasAnnotation(field, 'DriftIgnore'),
      drizzleIgnore: _hasAnnotation(field, 'DrizzleIgnore'),
      zodIgnore: _hasAnnotation(field, 'ZodIgnore'),
    );

    if (platform.driftIgnore || platform.drizzleIgnore || platform.zodIgnore) {
      _log.verbose(
        '   platform skip| ${field.name}'
        '  drift=${platform.driftIgnore}'
        '  drizzle=${platform.drizzleIgnore}'
        '  zod=${platform.zodIgnore}',
      );
    }

    return platform;
  }

  // ── Type helpers ──────────────────────────────────────────────────────────

  String _baseTypeName(DartType type) {
    if (type is InterfaceType) return type.element.name!;
    final raw = type.toString().replaceAll('?', '');
    return raw.split('<').first.trim();
  }

  bool _isKnownEnum(DartType type) {
    if (type is InterfaceType && type.element is EnumElement) return true;
    return _registry.isEnum(_baseTypeName(type));
  }

  String? _superclassName(ClassElement element) {
    final s = element.supertype;
    if (s == null || s.element.name == 'Object') return null;
    return s.element.name;
  }

  // ── Annotation helpers ────────────────────────────────────────────────────

  String? _annotationName(ElementAnnotation ann) {
    final el = ann.element;
    if (el is ConstructorElement) return el.enclosingElement.name;
    if (el is PropertyAccessorElement) return el.name;
    return null;
  }

  bool _hasAnnotation(Element element, String name) =>
      element.metadata.annotations.any((a) => _annotationName(a) == name);

  ElementAnnotation? _getAnnotation(Element element, String name) {
    for (final a in element.metadata.annotations) {
      if (_annotationName(a) == name) return a;
    }
    return null;
  }

  bool? _boolField(ElementAnnotation? ann, String field) {
    try {
      return ann?.computeConstantValue()?.getField(field)?.toBoolValue();
    } catch (_) {
      return null;
    }
  }

  String? _stringField(ElementAnnotation? ann, String field) {
    try {
      return ann?.computeConstantValue()?.getField(field)?.toStringValue();
    } catch (_) {
      return null;
    }
  }

  int? _intField(ElementAnnotation? ann, String field) {
    try {
      return ann?.computeConstantValue()?.getField(field)?.toIntValue();
    } catch (_) {
      return null;
    }
  }

  num? _numField(ElementAnnotation? ann, String field) {
    try {
      final obj = ann?.computeConstantValue()?.getField(field);
      if (obj == null) return null;
      return obj.toIntValue() ?? obj.toDoubleValue();
    } catch (_) {
      return null;
    }
  }

  List<dynamic> _listField(ElementAnnotation? ann, String field) {
    try {
      final list = ann?.computeConstantValue()?.getField(field)?.toListValue();
      if (list == null) return const [];
      return list.map((v) {
        return v.toBoolValue() ??
            v.toIntValue() ??
            v.toDoubleValue() ??
            v.toStringValue() ??
            v.toString();
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  List<String> _stringListField(ElementAnnotation? ann, String field) {
    try {
      final list = ann?.computeConstantValue()?.getField(field)?.toListValue();
      if (list == null) return const [];
      return list.map((v) => v.toStringValue() ?? '').toList();
    } catch (_) {
      return const [];
    }
  }

  dynamic _readConstantValue(ElementAnnotation? ann, String field) {
    try {
      final obj = ann?.computeConstantValue()?.getField(field);
      if (obj == null || obj.isNull) return null;
      final t = obj.type;
      if (t == null) return null;
      if (t.isDartCoreBool) return obj.toBoolValue();
      if (t.isDartCoreInt) return obj.toIntValue();
      if (t.isDartCoreDouble) return obj.toDoubleValue();
      if (t.isDartCoreString) return obj.toStringValue();
      final nameField = obj.getField('_name') ?? obj.getField('name');
      if (nameField != null) return nameField.toStringValue();
      if (obj.toListValue() != null) return <dynamic>[];
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _typeField(Element element, String annotationName, String fieldName) {
    final ann = _getAnnotation(element, annotationName);
    return _typeFieldFromAnnotation(ann, fieldName);
  }

  String? _typeFieldFromAnnotation(ElementAnnotation? ann, String fieldName) {
    try {
      final obj = ann?.computeConstantValue()?.getField(fieldName);
      if (obj == null) return null;
      return obj.toTypeValue()?.element?.name;
    } catch (_) {
      return null;
    }
  }
}
