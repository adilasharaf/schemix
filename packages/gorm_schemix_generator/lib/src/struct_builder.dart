import 'package:schemix/schemix.dart';
import 'utils.dart';

class GormStructBuilder {
  const GormStructBuilder();

  String build(ClassInfo cls) {
    final buffer = StringBuffer();
    buffer.writeln('type ${cls.name} struct {');

    for (final field in cls.allFields) {
      if (skipField(field)) continue;

      final goType = _mapDartTypeToGo(field);
      final gormTag = _buildGormTag(field);
      final jsonTag = 'json:"${field.effectiveJsonName}"'; 
      
      final tags = '`gorm:"$gormTag" $jsonTag`';
      final fieldName = _capitalize(field.name);

      buffer.writeln('\t$fieldName $goType $tags');
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  String _mapDartTypeToGo(FieldInfo field) {
    if (field.isEnum) {
      final typeName = 'enums.${field.dartType}';
      if (field.isNullable) return '*$typeName';
      return typeName;
    }
    
    // Determine if it's a core primitive
    final baseType = switch (field.dartType) {
      'String' => 'string',
      'int' => 'int64',
      'double' => 'float64',
      'bool' => 'bool',
      'DateTime' => 'time.Time',
      _ => null, 
    };

    if (field.relation.hasRelation) {
      if (field.relation.kind == RelationKind.hasMany || field.relation.kind == RelationKind.manyToMany) {
        final target = field.relation.targetTypeName ?? field.dartType;
        return '[]$target';
      }
      
      // If it's a primitive (foreign key field like `String userId`)

      if (baseType != null) {
        if (field.isNullable) return '*$baseType';
        return baseType;
      }
      
      final target = field.relation.targetTypeName ?? field.dartType;
      
      // Otherwise it's the target object struct (like `User user`)
      if (field.isNullable) {
        return '*$target';
      }
      return target;
    }

    final type = baseType ?? 'string';
    if (field.isNullable) {
      return '*$type';
    }
    return type;
  }

  String _buildGormTag(FieldInfo field) {
    final parts = <String>[];

    if (field.db.isPrimaryKey) {
      parts.add('primaryKey');
    }
    
    // Gorm column name is usually the field name in snake case or defined in db generated strategy
    final colName = field.db.dbGeneratedStrategy ?? field.name.snakeCase;
    parts.add('column:$colName');

    if (field.relation.hasRelation) {
       if (field.relation.relationFieldName != null) {
         parts.add('foreignKey:${_capitalize(field.relation.relationFieldName!)}');
       }
    } else {
       if (!field.isNullable && !field.db.isPrimaryKey) {
          parts.add('not null');
       }
       if (field.db.isUnique) {
          parts.add('unique');
       }
       if (field.db.databaseDefault != null) {
          parts.add('default:${field.db.databaseDefault}');
       }
    }

    return parts.join(';');
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
