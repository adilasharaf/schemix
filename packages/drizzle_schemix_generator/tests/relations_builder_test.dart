import 'package:drizzle_schemix_generator/src/relations_builder.dart';
import 'package:schemix/models.dart';
import 'package:test/test.dart';

const _builder = DrizzleRelationsBuilder();

ClassInfo _cls(String name, List<FieldInfo> fields) => ClassInfo(
  name: name,
  assetPath: 'lib/models.dart',
  hasSchemix: true,
  ownFields: fields,
);

void main() {
  group('DrizzleRelationsBuilder — no relations', () {
    test('returns empty list when class has no relation fields', () {
      final cls = _cls('User', const [
        FieldInfo(name: 'id', dartType: 'String', isNullable: false),
        FieldInfo(name: 'email', dartType: 'String', isNullable: false),
      ]);
      expect(_builder.generateRelations(cls), isEmpty);
    });
  });

  group('DrizzleRelationsBuilder — BelongsTo', () {
    test('BelongsTo emits one() relation line', () {
      final cls = _cls('Post', const [
        FieldInfo(name: 'id', dartType: 'String', isNullable: false),
        FieldInfo(
          name: 'userId',
          dartType: 'User',
          isNullable: false,
          relation: FieldRelationInfo(
            kind: RelationKind.belongsTo,
            targetTypeName: 'User',
          ),
        ),
      ]);
      final lines = _builder.generateRelations(cls);
      final joined = lines.join('\n');
      expect(joined, contains('one('));
      expect(joined, contains('users'));
      expect(joined, contains('userId'));
    });
  });

  group('DrizzleRelationsBuilder — HasMany', () {
    test('HasMany emits many() relation line', () {
      final cls = _cls('User', const [
        FieldInfo(name: 'id', dartType: 'String', isNullable: false),
        FieldInfo(
          name: 'posts',
          dartType: 'Post',
          isNullable: false,
          relation: FieldRelationInfo(
            kind: RelationKind.hasMany,
            targetTypeName: 'Post',
          ),
        ),
      ]);
      final lines = _builder.generateRelations(cls);
      final joined = lines.join('\n');
      expect(joined, contains('many('));
      expect(joined, contains('posts'));
    });
  });

  group('DrizzleRelationsBuilder — HasOne', () {
    test('HasOne with foreignKey emits one() with references', () {
      final cls = _cls('User', const [
        FieldInfo(name: 'id', dartType: 'String', isNullable: false),
        FieldInfo(
          name: 'profile',
          dartType: 'Profile',
          isNullable: true,
          relation: FieldRelationInfo(
            kind: RelationKind.hasOne,
            targetTypeName: 'Profile',
            relationFieldName: 'userId',
          ),
        ),
      ]);
      final lines = _builder.generateRelations(cls);
      final joined = lines.join('\n');
      expect(joined, contains('one('));
      expect(joined, contains('userId'));
    });

    test('HasOne without foreignKey emits TODO comment', () {
      final cls = _cls('User', const [
        FieldInfo(
          name: 'profile',
          dartType: 'Profile',
          isNullable: true,
          relation: FieldRelationInfo(
            kind: RelationKind.hasOne,
            targetTypeName: 'Profile',
          ),
        ),
      ]);
      final lines = _builder.generateRelations(cls);
      final joined = lines.join('\n');
      expect(joined, contains('TODO'));
    });
  });

  group('DrizzleRelationsBuilder — ManyToMany', () {
    test('ManyToMany emits many() relation line', () {
      final cls = _cls('Post', const [
        FieldInfo(name: 'id', dartType: 'String', isNullable: false),
        FieldInfo(
          name: 'tags',
          dartType: 'Tag',
          isNullable: false,
          relation: FieldRelationInfo(
            kind: RelationKind.manyToMany,
            targetTypeName: 'Tag',
          ),
        ),
      ]);
      final lines = _builder.generateRelations(cls);
      final joined = lines.join('\n');
      expect(joined, contains('many('));
      expect(joined, contains('tags'));
    });
  });

  group('DrizzleRelationsBuilder — output structure', () {
    test('wraps relation lines in relations() function call', () {
      final cls = _cls('Post', const [
        FieldInfo(
          name: 'userId',
          dartType: 'User',
          isNullable: false,
          relation: FieldRelationInfo(
            kind: RelationKind.belongsTo,
            targetTypeName: 'User',
          ),
        ),
      ]);
      final lines = _builder.generateRelations(cls);
      expect(lines.first, contains('relations('));
      expect(lines.last, equals('}));'));
    });
  });

  group('DrizzleRelationsBuilder — destructuring guard', () {
    test('only-many relations omit one from destructure', () {
      final cls = _cls('User', const [
        FieldInfo(name: 'id', dartType: 'String', isNullable: false),
        FieldInfo(
          name: 'posts',
          dartType: 'Post',
          isNullable: false,
          relation: FieldRelationInfo(
            kind: RelationKind.hasMany,
            targetTypeName: 'Post',
          ),
        ),
      ]);
      final header = _builder.generateRelations(cls).first;
      expect(header, contains('{ many }'));
      expect(header, isNot(contains('one')));
    });

    test('only-one relations omit many from destructure', () {
      final cls = _cls('Post', const [
        FieldInfo(name: 'id', dartType: 'String', isNullable: false),
        FieldInfo(
          name: 'userId',
          dartType: 'User',
          isNullable: false,
          relation: FieldRelationInfo(
            kind: RelationKind.belongsTo,
            targetTypeName: 'User',
          ),
        ),
      ]);
      final header = _builder.generateRelations(cls).first;
      expect(header, contains('{ one }'));
      expect(header, isNot(contains('many')));
    });

    test('mixed relations include both one and many in destructure', () {
      final cls = _cls('User', const [
        FieldInfo(name: 'id', dartType: 'String', isNullable: false),
        FieldInfo(
          name: 'profileId',
          dartType: 'Profile',
          isNullable: true,
          relation: FieldRelationInfo(
            kind: RelationKind.belongsTo,
            targetTypeName: 'Profile',
          ),
        ),
        FieldInfo(
          name: 'posts',
          dartType: 'Post',
          isNullable: false,
          relation: FieldRelationInfo(
            kind: RelationKind.hasMany,
            targetTypeName: 'Post',
          ),
        ),
      ]);
      final header = _builder.generateRelations(cls).first;
      expect(header, contains('one'));
      expect(header, contains('many'));
    });
  });
}
