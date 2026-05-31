// ── Field sub-structs ────────────────────────────────────────────────────────

import 'package:schemix/src/utils.dart';

class FieldPlatformFlags {
  final bool driftIgnore;
  final bool drizzleIgnore;
  final bool zodIgnore;

  const FieldPlatformFlags({
    this.driftIgnore = false,
    this.drizzleIgnore = false,
    this.zodIgnore = false,
  });
}

class FieldSecurityInfo {
  final bool encrypted;
  final bool hashed;
  final bool sensitive;
  final bool maskInLogs;
  final String? permissionRequired;
  final List<String> readScopes;
  final List<String> writeScopes;

  const FieldSecurityInfo({
    this.encrypted = false,
    this.hashed = false,
    this.sensitive = false,
    this.maskInLogs = false,
    this.permissionRequired,
    this.readScopes = const [],
    this.writeScopes = const [],
  });
}

class FieldSyncInfo {
  final bool offlineOnly;
  final bool cloudOnly;
  final bool operationTracked;
  final int? syncPriority;

  const FieldSyncInfo({
    this.offlineOnly = false,
    this.cloudOnly = false,
    this.operationTracked = false,
    this.syncPriority,
  });
}

/// Visibility of the field in API DTOs.
class FieldApiInfo {
  final bool expose;
  final bool readonly;
  final bool deprecated;

  const FieldApiInfo({
    this.expose = true,
    this.readonly = false,
    this.deprecated = false,
  });
}

class FieldDbInfo {
  final bool isPrimaryKey;
  final bool autoGenerate;
  final int? compositeOrder;
  final bool clustered;
  final bool isSecondaryKey;
  final bool isUnique;
  final bool isAutoIncrement;
  final bool isDatabaseGenerated;
  final String? dbGeneratedStrategy;
  final String? sqlType;
  final String? drizzleType;
  final String? driftType;
  final dynamic databaseDefault;
  final String? checkConstraint;
  final bool isIndexed;
  final String? indexName;
  final bool indexUnique;
  final bool indexDescending;
  final bool indexFullText;
  final bool indexSpatial;
  final bool isPartitionKey;
  final bool isSortKey;
  final bool sortKeyDescending;
  final bool isFullTextSearch;
  final bool isCachedField;

  const FieldDbInfo({
    this.isPrimaryKey = false,
    this.autoGenerate = false,
    this.compositeOrder,
    this.clustered = false,
    this.isSecondaryKey = false,
    this.isUnique = false,
    this.isAutoIncrement = false,
    this.isDatabaseGenerated = false,
    this.dbGeneratedStrategy,
    this.sqlType,
    this.drizzleType,
    this.driftType,
    this.databaseDefault,
    this.checkConstraint,
    this.isIndexed = false,
    this.indexName,
    this.indexUnique = false,
    this.indexDescending = false,
    this.indexFullText = false,
    this.indexSpatial = false,
    this.isPartitionKey = false,
    this.isSortKey = false,
    this.sortKeyDescending = false,
    this.isFullTextSearch = false,
    this.isCachedField = false,
  });
}

class FieldRelationInfo {
  final RelationKind? kind;
  final String? targetTypeName;
  final String? junctionTable;
  final String? relationName;
  final bool isEmbedded;
  final bool isCascadeDelete;
  final bool isLazy;
  final String? relationFieldName;

  const FieldRelationInfo({
    this.kind,
    this.targetTypeName,
    this.junctionTable,
    this.relationName,
    this.isEmbedded = false,
    this.isCascadeDelete = false,
    this.isLazy = false,
    this.relationFieldName,
  });

  bool get hasRelation => kind != null || isEmbedded;
}

class FieldSerializationInfo {
  final String? jsonKeyName;
  final bool isIgnored;
  final bool isReadOnly;
  final bool isWriteOnly;
  final String? serializeAs;
  final bool flatten;
  final String? dateFormat;
  final int? precisionDigits;
  final int? precisionScale;
  final bool useSnakeCaseFallback;

  const FieldSerializationInfo({
    this.jsonKeyName,
    this.isIgnored = false,
    this.isReadOnly = false,
    this.isWriteOnly = false,
    this.serializeAs,
    this.flatten = false,
    this.dateFormat,
    this.precisionDigits,
    this.precisionScale,
    this.useSnakeCaseFallback = false,
  });

  String effectiveJsonName(String dartFieldName) {
    if (jsonKeyName != null) return jsonKeyName!;
    if (useSnakeCaseFallback) return dartFieldName.snakeCase;
    return dartFieldName;
  }
}

class FieldConverterInfo {
  final bool hasDateTimeConverter;
  final bool hasDateTimeListConverter;
  final bool hasDateTimeNullableConverter;
  final String? customConverterClass;
  final String? tsConverter;
  final String? converterSqlType;
  final String? converterDrizzleType;
  final String? tsTypeOverride;
  final String? zodSchemaOverride;
  final String? zodTypeOverride;

  const FieldConverterInfo({
    this.hasDateTimeConverter = false,
    this.hasDateTimeListConverter = false,
    this.hasDateTimeNullableConverter = false,
    this.customConverterClass,
    this.tsConverter,
    this.converterSqlType,
    this.converterDrizzleType,
    this.tsTypeOverride,
    this.zodSchemaOverride,
    this.zodTypeOverride,
  });
}

class FieldValidation {
  final bool required;
  final num? min;
  final num? max;
  final int? minLength;
  final int? maxLength;
  final String? regex;
  final bool isEmail;
  final bool isUrl;
  final bool isPhone;
  final bool isIpAddress;
  final bool isUuid;
  final List<dynamic> allowedValues;
  final List<dynamic> disallowedValues;

  const FieldValidation({
    this.required = false,
    this.min,
    this.max,
    this.minLength,
    this.maxLength,
    this.regex,
    this.isEmail = false,
    this.isUrl = false,
    this.isPhone = false,
    this.isIpAddress = false,
    this.isUuid = false,
    this.allowedValues = const [],
    this.disallowedValues = const [],
  });

  bool get hasConstraints =>
      required ||
      min != null ||
      max != null ||
      minLength != null ||
      maxLength != null ||
      regex != null ||
      isEmail ||
      isUrl ||
      isPhone ||
      isIpAddress ||
      isUuid ||
      allowedValues.isNotEmpty ||
      disallowedValues.isNotEmpty;
}

// ── Field ────────────────────────────────────────────────────────────────────

class FieldInfo {
  final String name;
  final String dartType;
  final bool isNullable;
  final bool isList;
  final bool isMap;
  final String? listItemType;
  final String? mapValueType;
  final bool isEnum;
  final bool isLate;
  final bool isRequired;
  final bool immutable;
  final bool readonly;
  final bool hidden;
  final bool internal;
  final bool unique;
  final bool isCreatedAt;
  final bool isUpdatedAt;
  final bool isDeletedAt;
  final bool isVersionField;
  final bool isAuditField;
  final FieldDbInfo db;
  final FieldRelationInfo relation;
  final FieldSerializationInfo serialization;
  final FieldConverterInfo converter;
  final FieldValidation validation;
  final FieldSecurityInfo security;
  final FieldSyncInfo sync;
  final FieldApiInfo api;
  final FieldPlatformFlags platform;

  /// Open slot for generator-specific metadata. Keyed by the generator id.
  final Map<String, Object?> extensions;

  const FieldInfo({
    required this.name,
    required this.dartType,
    required this.isNullable,
    this.isList = false,
    this.isMap = false,
    this.listItemType,
    this.mapValueType,
    this.isEnum = false,
    this.isLate = false,
    this.isRequired = false,
    this.immutable = false,
    this.readonly = false,
    this.hidden = false,
    this.internal = false,
    this.unique = false,
    this.isCreatedAt = false,
    this.isUpdatedAt = false,
    this.isDeletedAt = false,
    this.isVersionField = false,
    this.isAuditField = false,
    this.db = const FieldDbInfo(),
    this.relation = const FieldRelationInfo(),
    this.serialization = const FieldSerializationInfo(),
    this.converter = const FieldConverterInfo(),
    this.validation = const FieldValidation(),
    this.security = const FieldSecurityInfo(),
    this.sync = const FieldSyncInfo(),
    this.api = const FieldApiInfo(),
    this.platform = const FieldPlatformFlags(),
    this.extensions = const {},
  });

  String get effectiveJsonName => serialization.effectiveJsonName(name);
  bool get isIgnored => serialization.isIgnored;
  bool get isLifecycleField =>
      isCreatedAt || isUpdatedAt || isDeletedAt || isVersionField;
}

// ── Class ────────────────────────────────────────────────────────────────────

class ClassInfo {
  final String name;
  final String assetPath;
  final bool isEnum;
  final List<String> enumValues;
  final List<FieldInfo> ownFields;
  final List<FieldInfo> inheritedFields;
  final String? superclassName;
  final bool hasSchemix;
  final bool hasJsonSerializable;
  final bool hasManualSerialization;
  final String? tableName;
  final String? collectionName;
  final int schemaVersion;
  final String? namespace;
  final bool enableTimestamps;
  final bool enableSoftDelete;
  final bool abstractSchema;
  final bool cacheable;
  final bool syncable;
  final bool embeddable;
  final GeneratorFlags generators;
  final SyncMeta sync;
  final bool manualImplementation;
  final List<CompositeIndexInfo> compositeIndexes;
  final Set<String> ctorParamNames;

  const ClassInfo({
    required this.name,
    required this.assetPath,
    this.isEnum = false,
    this.enumValues = const [],
    this.ownFields = const [],
    this.inheritedFields = const [],
    this.superclassName,
    this.hasSchemix = false,
    this.hasJsonSerializable = false,
    this.hasManualSerialization = false,
    this.tableName,
    this.collectionName,
    this.schemaVersion = 1,
    this.namespace,
    this.enableTimestamps = false,
    this.enableSoftDelete = false,
    this.abstractSchema = false,
    this.cacheable = false,
    this.syncable = false,
    this.embeddable = false,
    this.generators = const GeneratorFlags(),
    this.sync = const SyncMeta(),
    this.manualImplementation = false,
    this.compositeIndexes = const [],
    this.ctorParamNames = const {},
  });

  List<FieldInfo> get allFields => [...inheritedFields, ...ownFields];
}

// ── Supporting types ─────────────────────────────────────────────────────────

class CompositeIndexInfo {
  final List<String> fields;
  final bool unique;
  final List<String> order;

  const CompositeIndexInfo({
    required this.fields,
    this.unique = false,
    this.order = const [],
  });
}

enum RelationKind { belongsTo, hasOne, hasMany, manyToMany, embedded }

class RelationInfo {
  final String ownerName;
  final String targetName;
  final String fieldName;
  final RelationKind kind;
  final String? junctionTable;
  final String? relationName;

  const RelationInfo({
    required this.ownerName,
    required this.targetName,
    required this.fieldName,
    required this.kind,
    this.junctionTable,
    this.relationName,
  });
}

class GeneratorFlags {
  final bool zod;
  final bool drift;
  final bool drizzle;

  const GeneratorFlags({
    this.zod = true,
    this.drift = false,
    this.drizzle = false,
  });

  GeneratorFlags copyWith({bool? zod, bool? drift, bool? drizzle}) =>
      GeneratorFlags(
        zod: zod ?? this.zod,
        drift: drift ?? this.drift,
        drizzle: drizzle ?? this.drizzle,
      );
}

class SyncMeta {
  final bool syncable;
  final String conflictStrategy;

  const SyncMeta({this.syncable = false, this.conflictStrategy = 'latestWins'});
}

/// Lightweight type summary stored in the registry.
/// Contains only what the cross-file graph and generators need —
/// no field-level detail.
class TypeInfo {
  final String name;
  final bool isEnum;
  final List<String> enumValues;
  final String sourceAssetPath;
  final String? superclassName;
  final Set<String> fieldDeps;
  final Set<String> relationDeps;
  final String? tableName;
  final String? collectionName;
  final int schemaVersion;
  final String? namespace;
  final bool enableTimestamps;
  final bool enableSoftDelete;
  final bool abstractSchema;
  final bool cacheable;
  final bool embeddable;
  final GeneratorFlags generators;
  final SyncMeta sync;
  final bool manualImplementation;

  const TypeInfo({
    required this.name,
    required this.isEnum,
    this.enumValues = const [],
    required this.sourceAssetPath,
    this.superclassName,
    this.fieldDeps = const {},
    this.relationDeps = const {},
    this.tableName,
    this.collectionName,
    this.schemaVersion = 1,
    this.namespace,
    this.enableTimestamps = false,
    this.enableSoftDelete = false,
    this.abstractSchema = false,
    this.cacheable = false,
    this.embeddable = false,
    this.generators = const GeneratorFlags(),
    this.sync = const SyncMeta(),
    this.manualImplementation = false,
  });
}
