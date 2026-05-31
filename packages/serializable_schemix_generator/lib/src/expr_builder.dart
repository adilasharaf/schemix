import 'package:schemix/models.dart';
import 'package:schemix/src/generator_api.dart';

final class JsonExprBuilder {
  final TypeGraph _graph;

  const JsonExprBuilder(this._graph);

  String fromJson(FieldInfo field, String src) {
    final nullable = field.isNullable;
    final type = field.dartType;

    if (field.isEnum) return _enumFromJson(field, src, nullable);
    if (field.isList) return _listFromJson(field, src, nullable);
    if (field.isMap) return _mapFromJson(field, src, nullable);

    if (field.relation.isEmbedded || _graph.isModel(type)) {
      return nullable
          ? '$src == null ? null : $type.fromJson($src as Map<String, dynamic>)'
          : '$type.fromJson($src as Map<String, dynamic>)';
    }

    if (type == 'DateTime') {
      return nullable
          ? '$src == null ? null : DateTime.parse($src as String)'
          : 'DateTime.parse($src as String)';
    }

    return '$src ${dartCast(type, nullable)}';
  }

  String fromJsonItem(String dartType, String src) => switch (dartType) {
    'DateTime' => 'DateTime.parse($src as String)',
    _ when _graph.isEnum(dartType) => '$dartType.values.byName($src as String)',
    _ when _graph.isModel(dartType) =>
      '$dartType.fromJson($src as Map<String, dynamic>)',
    _ => '$src ${dartCast(dartType, false)}',
  };

  String toJson(FieldInfo field, String src) {
    final op = field.isNullable ? '?.' : '.';
    final type = field.dartType;

    if (field.isEnum) return field.isNullable ? '$src?.name' : '$src.name';

    if (field.isList) {
      final item = field.listItemType ?? 'dynamic';
      final itemExpr = toJsonItem(item, 'e');
      if (itemExpr == 'e') return src;
      return field.isNullable
          ? '$src?.map((e) => $itemExpr).toList()'
          : '$src.map((e) => $itemExpr).toList()';
    }

    if (field.isMap) return src;

    if (field.relation.isEmbedded || _graph.isModel(type)) {
      return '$src${op}toJson()';
    }

    if (type == 'DateTime') return '$src${op}toIso8601String()';

    return src;
  }

  String toJsonItem(String dartType, String src) => switch (dartType) {
    'DateTime' => '$src.toIso8601String()',
    _ when _graph.isEnum(dartType) => '$src.name',
    _ when _graph.isModel(dartType) => '$src.toJson()',
    _ => src,
  };

  String dartCast(String dartType, bool nullable) {
    final q = nullable ? '?' : '';
    return switch (dartType) {
      'String' => 'as String$q',
      'int' => 'as int$q',
      'double' => 'as double$q',
      'num' => 'as num$q',
      'bool' => 'as bool$q',
      _ => 'as dynamic',
    };
  }

  String _enumFromJson(FieldInfo field, String src, bool nullable) {
    final type = field.dartType;
    if (nullable) {
      return '$src == null ? null : $type.values.byName($src as String)';
    }
    final def = _enumDefault(field);
    return def != null
        ? '$src == null ? $def : _\$safeByName($type.values, $src as String, $def)'
        : '$type.values.byName($src as String)';
  }

  String _listFromJson(FieldInfo field, String src, bool nullable) {
    final item = field.listItemType ?? 'dynamic';
    return nullable
        ? '($src as List<dynamic>?)?.map((e) => ${fromJsonItem(item, 'e')}).toList()'
        : '($src as List<dynamic>).map((e) => ${fromJsonItem(item, 'e')}).toList()';
  }

  String _mapFromJson(FieldInfo field, String src, bool nullable) {
    final val = field.mapValueType ?? 'dynamic';
    return nullable
        ? '($src as Map<String, dynamic>?)?.cast<String, $val>()'
        : '($src as Map<String, dynamic>).cast<String, $val>()';
  }

  String? _enumDefault(FieldInfo field) {
    final def = field.db.databaseDefault;
    if (def == null) return null;
    final raw = def.toString();
    return raw.contains('.')
        ? raw
        : '${field.dartType}.values.byName(\'$raw\')';
  }
}
