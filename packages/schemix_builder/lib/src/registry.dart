import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:schemix/schemix.dart';

import 'logger.dart';

/// Mutable registry populated by [SchemixScanBuilder] during Phase 1.
/// Implements [TypeGraph] so it can be passed directly to [GeneratorContext]
/// in Phase 2 without an adapter.
class CrossFileRegistry implements TypeGraph {
  static final _log = SchemixLogger('registry');

  final Map<String, TypeInfo> _types = {};
  final List<RelationInfo> _relations = [];
  Set<String>? _cyclicCache;

  // ── Population (Phase 1 only) ──────────────────────────────────────────────

  void register(TypeInfo info) {
    final overwrite = _types.containsKey(info.name);
    _types[info.name] = info;
    _cyclicCache = null;

    if (overwrite) {
      _log.verbose(
        '   register ~   | ${info.name}  (overwrite)  <- ${info.sourceAssetPath}',
      );
    } else if (info.isEnum) {
      _log.verbose(
        '   register e   | ${info.name}  [${info.enumValues.join(', ')}]  <- ${info.sourceAssetPath}',
      );
    } else {
      final meta = [
        if (info.superclassName != null) 'extends ${info.superclassName}',
        if (info.fieldDeps.isNotEmpty) 'deps=[${info.fieldDeps.join(', ')}]',
        if (info.relationDeps.isNotEmpty)
          'rels=[${info.relationDeps.join(', ')}]',
        if (info.abstractSchema) 'abstract',
        if (info.embeddable) 'embeddable',
        if (info.manualImplementation) 'manual',
      ].join('  ');
      _log.verbose(
        '   register m   | ${info.name}  $meta  <- ${info.sourceAssetPath}',
      );
    }
  }

  void registerRelation(RelationInfo relation) {
    _relations.add(relation);
    _cyclicCache = null;
    _log.verbose(
      '   relation +   | ${relation.ownerName}.${relation.fieldName} --[${relation.kind.name}]--> ${relation.targetName}',
    );
  }

  void seal() {
    final cyclic = cyclicTypes;
    if (cyclic.isNotEmpty) {
      _log.warning('!! cyclic types | ${cyclic.join(', ')}');
    } else {
      _log.verbose('   cyclic check | none');
    }
    _log.verbose(
      '   sealed       | ${_types.length} types, ${_relations.length} relations',
    );
  }

  // ── TypeGraph (read-only, Phase 2) ─────────────────────────────────────────

  @override
  bool isEnum(String name) => _types[name]?.isEnum ?? false;

  @override
  bool isModel(String name) {
    final t = _types[name];
    return t != null && !t.isEnum;
  }

  @override
  bool isEmbeddable(String name) => _types[name]?.embeddable ?? false;

  @override
  TypeInfo? resolve(String name) {
    final result = _types[name];
    if (result == null) _log.verbose('   resolve !!   | $name not found');
    return result;
  }

  @override
  Set<String> get cyclicTypes =>
      _cyclicCache ??= _findCyclicNodes(_buildGraph());

  @override
  String? relativeImportFor({
    required String typeName,
    required String fromSourceAssetPath,
  }) {
    final target = _types[typeName];
    if (target == null) {
      _log.verbose('   import !!    | $typeName not in registry');
      return null;
    }
    final from = _toGenPath(fromSourceAssetPath);
    final to = _toGenPath(target.sourceAssetPath);
    if (from == to) return null;
    return _relativePath(from: from, to: to);
  }

  @override
  String? relativeDrizzleImportFor({
    required String typeName,
    required String fromSourceAssetPath,
  }) {
    final target = _types[typeName];
    if (target == null) {
      _log.verbose('   drizzle !!   | $typeName not in registry');
      return null;
    }
    final from = _toDrizzlePath(fromSourceAssetPath);
    final to = _toDrizzlePath(target.sourceAssetPath);
    if (from == to) return null;
    return _relativePath(from: from, to: to);
  }

  // ── Convenience accessors used by builders ─────────────────────────────────

  Iterable<TypeInfo> get allModels => _types.values.where((t) => !t.isEnum);
  Iterable<TypeInfo> get allEnums => _types.values.where((t) => t.isEnum);

  // ── JSON serialization ─────────────────────────────────────────────────────

  /// Serializes the full registry to a JSON string for the build artifact.
  String toJson() {
    return jsonEncode({
      'types': _types.values.map(_typeInfoToJson).toList(),
      'relations': _relations.map(_relationInfoToJson).toList(),
    });
  }

  /// Deserializes a registry from the JSON build artifact produced by Phase 1.
  static CrossFileRegistry fromJson(String source) {
    final registry = CrossFileRegistry();
    final map = jsonDecode(source) as Map<String, dynamic>;

    for (final raw in (map['types'] as List)) {
      registry._types[raw['name'] as String] = _typeInfoFromJson(
        raw as Map<String, dynamic>,
      );
    }
    for (final raw in (map['relations'] as List)) {
      registry._relations.add(
        _relationInfoFromJson(raw as Map<String, dynamic>),
      );
    }

    _log.verbose(
      '   loaded       | ${registry._types.length} types, ${registry._relations.length} relations',
    );
    return registry;
  }

  // ── Graph algorithms ───────────────────────────────────────────────────────

  Map<String, Set<String>> _buildGraph() => {
    for (final info in _types.values)
      if (!info.isEnum)
        info.name: {
          ...info.fieldDeps,
          ...info.relationDeps,
        }.where(isModel).toSet(),
  };

  Set<String> _findCyclicNodes(Map<String, Set<String>> graph) {
    final visited = <String>{};
    final stackSet = <String>{};
    final stack = <String>[];
    final cyclic = <String>{};

    void dfs(String node) {
      if (stackSet.contains(node)) {
        final cycleStart = stack.indexOf(node);
        cyclic.addAll(stack.sublist(cycleStart));
        cyclic.add(node);
        return;
      }
      if (visited.contains(node)) return;

      visited.add(node);
      stack.add(node);
      stackSet.add(node);

      for (final neighbour in graph[node] ?? const <String>{}) {
        dfs(neighbour);
      }

      stack.removeLast();
      stackSet.remove(node);
    }

    for (final node in graph.keys) {
      if (!visited.contains(node)) dfs(node);
    }
    return cyclic;
  }

  // ── Path helpers ───────────────────────────────────────────────────────────

  static String _relativePath({required String from, required String to}) {
    final fromDir = p.posix.dirname(from);
    var rel = p.posix.relative(to, from: fromDir);
    if (rel.endsWith('.ts')) rel = rel.substring(0, rel.length - 3);
    if (!rel.startsWith('.')) rel = './$rel';
    return rel;
  }

  static String _toGenPath(String assetPath) {
    final stripped = assetPath.startsWith('lib/')
        ? assetPath.substring(4)
        : assetPath;
    final noExt = stripped.endsWith('.dart')
        ? stripped.substring(0, stripped.length - 5)
        : stripped;
    return 'gen/$noExt.g.ts';
  }

  static String _toDrizzlePath(String assetPath) {
    final stripped = assetPath.startsWith('lib/')
        ? assetPath.substring(4)
        : assetPath;
    final noExt = stripped.endsWith('.dart')
        ? stripped.substring(0, stripped.length - 5)
        : stripped;
    return 'gen/$noExt.drizzle.ts';
  }

  // ── JSON helpers ───────────────────────────────────────────────────────────

  static Map<String, dynamic> _typeInfoToJson(TypeInfo t) => {
    'name': t.name,
    'isEnum': t.isEnum,
    'enumValues': t.enumValues,
    'sourceAssetPath': t.sourceAssetPath,
    if (t.superclassName != null) 'superclassName': t.superclassName,
    'fieldDeps': t.fieldDeps.toList(),
    'relationDeps': t.relationDeps.toList(),
    if (t.tableName != null) 'tableName': t.tableName,
    if (t.collectionName != null) 'collectionName': t.collectionName,
    'schemaVersion': t.schemaVersion,
    if (t.namespace != null) 'namespace': t.namespace,
    'enableTimestamps': t.enableTimestamps,
    'enableSoftDelete': t.enableSoftDelete,
    'abstractSchema': t.abstractSchema,
    'cacheable': t.cacheable,
    'embeddable': t.embeddable,
    'generators': {
      'zod': t.generators.zod,
      'drift': t.generators.drift,
      'drizzle': t.generators.drizzle,
    },
    'sync': {
      'syncable': t.sync.syncable,
      'conflictStrategy': t.sync.conflictStrategy,
    },
    'manualImplementation': t.manualImplementation,
  };

  static TypeInfo _typeInfoFromJson(Map<String, dynamic> j) => TypeInfo(
    name: j['name'] as String,
    isEnum: j['isEnum'] as bool,
    enumValues: List<String>.from(j['enumValues'] as List),
    sourceAssetPath: j['sourceAssetPath'] as String,
    superclassName: j['superclassName'] as String?,
    fieldDeps: Set<String>.from(j['fieldDeps'] as List),
    relationDeps: Set<String>.from(j['relationDeps'] as List),
    tableName: j['tableName'] as String?,
    collectionName: j['collectionName'] as String?,
    schemaVersion: j['schemaVersion'] as int? ?? 1,
    namespace: j['namespace'] as String?,
    enableTimestamps: j['enableTimestamps'] as bool? ?? false,
    enableSoftDelete: j['enableSoftDelete'] as bool? ?? false,
    abstractSchema: j['abstractSchema'] as bool? ?? false,
    cacheable: j['cacheable'] as bool? ?? false,
    embeddable: j['embeddable'] as bool? ?? false,
    generators: GeneratorFlags(
      zod: (j['generators'] as Map)['zod'] as bool? ?? true,
      drift: (j['generators'] as Map)['drift'] as bool? ?? false,
      drizzle: (j['generators'] as Map)['drizzle'] as bool? ?? false,
    ),
    sync: SyncMeta(
      syncable: (j['sync'] as Map)['syncable'] as bool? ?? false,
      conflictStrategy:
          (j['sync'] as Map)['conflictStrategy'] as String? ?? 'latestWins',
    ),
    manualImplementation: j['manualImplementation'] as bool? ?? false,
  );

  static Map<String, dynamic> _relationInfoToJson(RelationInfo r) => {
    'ownerName': r.ownerName,
    'targetName': r.targetName,
    'fieldName': r.fieldName,
    'kind': r.kind.name,
    if (r.junctionTable != null) 'junctionTable': r.junctionTable,
    if (r.relationName != null) 'relationName': r.relationName,
  };

  static RelationInfo _relationInfoFromJson(Map<String, dynamic> j) =>
      RelationInfo(
        ownerName: j['ownerName'] as String,
        targetName: j['targetName'] as String,
        fieldName: j['fieldName'] as String,
        kind: RelationKind.values.byName(j['kind'] as String),
        junctionTable: j['junctionTable'] as String?,
        relationName: j['relationName'] as String?,
      );
}
