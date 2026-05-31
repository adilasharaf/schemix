import 'package:drift_schemix_generator/src/column_builder.dart';
import 'package:schemix/models.dart';
import 'package:test/test.dart';

const _builder = DriftColumnBuilder();

void main() {
  group('DriftColumnBuilder.skipField', () {
    test('isIgnored → skip', () {
      const f = FieldInfo(
        name: 'secret',
        dartType: 'String',
        isNullable: false,
        serialization: FieldSerializationInfo(isIgnored: true),
      );
      expect(_builder.skipField(f), isTrue);
    });

    test('driftIgnore → skip', () {
      const f = FieldInfo(
        name: 'local',
        dartType: 'String',
        isNullable: false,
        platform: FieldPlatformFlags(driftIgnore: true),
      );
      expect(_builder.skipField(f), isTrue);
    });

    test('cloudOnly → skip', () {
      const f = FieldInfo(
        name: 'cloud',
        dartType: 'String',
        isNullable: false,
        sync: FieldSyncInfo(cloudOnly: true),
      );
      expect(_builder.skipField(f), isTrue);
    });

    test('hasMany → skip', () {
      const f = FieldInfo(
        name: 'posts',
        dartType: 'Post',
        isNullable: false,
        relation: FieldRelationInfo(kind: RelationKind.hasMany),
      );
      expect(_builder.skipField(f), isTrue);
    });

    test('hasOne → skip', () {
      const f = FieldInfo(
        name: 'profile',
        dartType: 'Profile',
        isNullable: false,
        relation: FieldRelationInfo(kind: RelationKind.hasOne),
      );
      expect(_builder.skipField(f), isTrue);
    });

    test('manyToMany → skip', () {
      const f = FieldInfo(
        name: 'tags',
        dartType: 'Tag',
        isNullable: false,
        relation: FieldRelationInfo(kind: RelationKind.manyToMany),
      );
      expect(_builder.skipField(f), isTrue);
    });

    test('normal field → not skipped', () {
      const f = FieldInfo(name: 'email', dartType: 'String', isNullable: false);
      expect(_builder.skipField(f), isFalse);
    });
  });

  group('DriftColumnBuilder.buildColumn — regular fields', () {
    test('String field returns TextColumn getter', () {
      const f = FieldInfo(name: 'email', dartType: 'String', isNullable: false);
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains('TextColumn'));
      expect(result, contains('get email'));
      expect(result, contains("named('email')"));
    });

    test('nullable bool field includes .nullable()', () {
      const f = FieldInfo(name: 'active', dartType: 'bool', isNullable: true);
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains('.nullable()'));
    });

    test('unsupported type (Map) returns null', () {
      const f = FieldInfo(name: 'meta', dartType: 'Map', isNullable: false);
      final result = _builder.buildColumn(f);
      expect(result, isNull);
    });
  });

  group('DriftColumnBuilder.buildColumn — BelongsTo FK', () {
    test('BelongsTo field always produces TextColumn', () {
      const f = FieldInfo(
        name: 'userId',
        dartType: 'User',
        isNullable: false,
        relation: FieldRelationInfo(
          kind: RelationKind.belongsTo,
          targetTypeName: 'User',
        ),
      );
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains('TextColumn'));
      expect(result, contains("named('user_id')"));
    });
  });

  group('DriftColumnBuilder.buildColumn — enum fields', () {
    test('enum field produces IntColumn with .map(converter)', () {
      const f = FieldInfo(
        name: 'status',
        dartType: 'UserStatus',
        isNullable: false,
        isEnum: true,
      );
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains('IntColumn'));
      expect(result, contains('.map(_userStatusConverter)'));
    });

    test('nullable enum field includes .nullable()', () {
      const f = FieldInfo(
        name: 'status',
        dartType: 'UserStatus',
        isNullable: true,
        isEnum: true,
      );
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains('.nullable()'));
    });
  });

  group('DriftColumnBuilder.buildColumn — primary key', () {
    test(
      'UUID auto-generate PK uses .clientDefault(() => const Uuid().v4())',
      () {
        const f = FieldInfo(
          name: 'id',
          dartType: 'String',
          isNullable: false,
          db: FieldDbInfo(isPrimaryKey: true, autoGenerate: true),
        );
        final result = _builder.buildColumn(f);
        expect(result, isNotNull);
        expect(result, contains('clientDefault'));
        expect(result, contains('Uuid'));
      },
    );

    test('autoIncrement PK uses .autoIncrement()', () {
      const f = FieldInfo(
        name: 'id',
        dartType: 'int',
        isNullable: false,
        db: FieldDbInfo(isPrimaryKey: true, isAutoIncrement: true),
      );
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains('autoIncrement()'));
    });

    test('plain PK (no auto) produces text column', () {
      const f = FieldInfo(
        name: 'id',
        dartType: 'String',
        isNullable: false,
        db: FieldDbInfo(isPrimaryKey: true),
      );
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains("named('id')"));
    });
  });
}
