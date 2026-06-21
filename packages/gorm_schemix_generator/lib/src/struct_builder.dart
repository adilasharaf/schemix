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
      final gormTag = _buildGormTag(cls, field);
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
      final typeName = field.dartType;
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

    if (field.db.sqlType?.toUpperCase() == 'JSONB' || field.isMap) {
      return 'datatypes.JSON';
    }

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

  String _buildGormTag(ClassInfo cls, FieldInfo field) {
    final parts = <String>[];

    if (field.db.isPrimaryKey) {
      parts.add('primaryKey');
    }
    
    // Gorm column name is usually the field name in snake case
    final colName = field.name.snakeCase;
    
    if (field.relation.hasRelation) {
      if (field.relation.kind == RelationKind.belongsTo) {
        // BelongsTo is a primitive foreign key, so it gets a column tag
        parts.add('column:$colName');
      } else if (field.relation.kind == RelationKind.manyToMany) {
        // ManyToMany needs a join table tag, not a column tag
        final joinTable = field.relation.junctionTable ?? '${cls.name.snakeCase}_${field.name.snakeCase}';
        parts.add('many2many:$joinTable');
      } else {
        // hasOne / hasMany should not have a column tag
        if (field.relation.relationFieldName != null) {
          parts.add('foreignKey:${_capitalize(field.relation.relationFieldName!)}');
        } else {
          parts.add('foreignKey:${_capitalize(cls.name)}Id');
        }
      }
    } else {
       parts.add('column:$colName');
       if (!field.isNullable && !field.db.isPrimaryKey) {
          parts.add('not null');
       }
       if (field.db.isUnique || field.db.indexUnique) {
          parts.add('uniqueIndex');
       } else if (field.db.isIndexed) {
          parts.add('index');
       }
       if (field.db.databaseDefault != null) {
          parts.add('default:${field.db.databaseDefault}');
       }
    }

    return parts.join(';');
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
