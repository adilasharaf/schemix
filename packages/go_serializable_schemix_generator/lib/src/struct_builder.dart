import 'package:schemix/schemix.dart';
import 'utils.dart';

class GoSerializableStructBuilder {
  const GoSerializableStructBuilder();

  String build(ClassInfo cls) {
    final buffer = StringBuffer();
    buffer.writeln('type ${cls.name} struct {');

    for (final field in cls.allFields) {
      if (skipField(field)) continue;

      final goType = _mapDartTypeToGo(field);
      final jsonTag = _buildJsonTag(field);
      
      final tags = '`json:"$jsonTag"`';
      final fieldName = _capitalize(field.name);

      buffer.writeln('\t$fieldName $goType $tags');
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  String _mapDartTypeToGo(FieldInfo field) {
    if (field.isEnum) return field.dartType;
    if (field.relation.hasRelation) {
      if (field.relation.kind == RelationKind.hasMany || field.relation.kind == RelationKind.manyToMany) {
        return '[]${field.dartType}';
      }
      if (field.isNullable) {
        return '*${field.dartType}';
      }
      return field.dartType;
    }

    final baseType = switch (field.dartType) {
      'String' => 'string',
      'int' => 'int64',
      'double' => 'float64',
      'bool' => 'bool',
      'DateTime' => 'time.Time',
      _ => 'string', 
    };

    if (field.isNullable) {
      return '*$baseType';
    }
    return baseType;
  }

  String _buildJsonTag(FieldInfo field) {
    final name = field.name;
    if (field.isNullable) {
      return '$name,omitempty';
    }
    return name;
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
