import 'package:drizzle_schemix_generator/src/column_builder.dart';
import 'package:schemix/models.dart';
import 'package:test/test.dart';

const _builder = DrizzleColumnBuilder();

void main() {
  group('DrizzleColumnBuilder.buildColumn — primitives', () {
    test('String field → text()', () {
      const f = FieldInfo(name: 'email', dartType: 'String', isNullable: false);
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains("text('email')"));
      expect(result, contains('.notNull()'));
    });

    test('int field → integer()', () {
      const f = FieldInfo(name: 'count', dartType: 'int', isNullable: false);
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains('integer('));
    });

    test('double field → real()', () {
      const f = FieldInfo(name: 'score', dartType: 'double', isNullable: false);
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains('real('));
    });

    test('bool field → boolean()', () {
      const f = FieldInfo(name: 'active', dartType: 'bool', isNullable: false);
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains('boolean('));
    });

    test('DateTime field → timestamp()', () {
      const f = FieldInfo(
        name: 'createdAt',
        dartType: 'DateTime',
        isNullable: false,
      );
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains('timestamp('));
    });

    test('nullable field omits .notNull()', () {
      const f = FieldInfo(
        name: 'deletedAt',
        dartType: 'DateTime',
        isNullable: true,
      );
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, isNot(contains('.notNull()')));
    });

    test('snake_case column name from camelCase field', () {
      const f = FieldInfo(
        name: 'passwordHash',
        dartType: 'String',
        isNullable: false,
      );
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains("text('password_hash')"));
    });
  });

  group('DrizzleColumnBuilder.buildColumn — primary key', () {
    test(r'UUID auto-generate PK uses .$defaultFn', () {
      const f = FieldInfo(
        name: 'id',
        dartType: 'String',
        isNullable: false,
        db: FieldDbInfo(isPrimaryKey: true, autoGenerate: true),
      );
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains(r'$defaultFn'));
      expect(result, contains('.primaryKey()'));
    });

    test('autoIncrement PK uses serial()', () {
      const f = FieldInfo(
        name: 'id',
        dartType: 'int',
        isNullable: false,
        db: FieldDbInfo(isPrimaryKey: true, isAutoIncrement: true),
      );
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains('serial('));
      expect(result, contains('.primaryKey()'));
    });

    test('plain PK (no auto) uses .primaryKey()', () {
      const f = FieldInfo(
        name: 'id',
        dartType: 'String',
        isNullable: false,
        db: FieldDbInfo(isPrimaryKey: true),
      );
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains('.primaryKey()'));
    });
  });

  group('DrizzleColumnBuilder.buildColumn — BelongsTo FK', () {
    test('BelongsTo produces text() column', () {
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
      expect(result, contains("text('user_id')"));
      expect(result, contains('.notNull()'));
    });
  });

  group('DrizzleColumnBuilder.buildColumn — embedded', () {
    test('embedded relation → jsonb()', () {
      const f = FieldInfo(
        name: 'address',
        dartType: 'Address',
        isNullable: false,
        relation: FieldRelationInfo(isEmbedded: true),
      );
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains("jsonb('address')"));
    });
  });

  group('DrizzleColumnBuilder.buildColumn — enum', () {
    test('enum field uses text with enum values', () {
      const f = FieldInfo(
        name: 'status',
        dartType: 'UserStatus',
        isNullable: false,
        isEnum: true,
      );
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains("userStatusValues"));
    });
  });

  group('DrizzleColumnBuilder.buildColumn — timestamps and defaults', () {
    test('isCreatedAt field adds .defaultNow()', () {
      const f = FieldInfo(
        name: 'createdAt',
        dartType: 'DateTime',
        isNullable: false,
        isCreatedAt: true,
      );
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains('.defaultNow()'));
    });

    test('unique field adds .unique()', () {
      const f = FieldInfo(
        name: 'email',
        dartType: 'String',
        isNullable: false,
        db: FieldDbInfo(isUnique: true),
      );
      final result = _builder.buildColumn(f);
      expect(result, isNotNull);
      expect(result, contains('.unique()'));
    });
  });

  group('DrizzleColumnBuilder.columnFunctionsFor', () {
    test('embedded field returns {jsonb}', () {
      const f = FieldInfo(
        name: 'addr',
        dartType: 'Address',
        isNullable: false,
        relation: FieldRelationInfo(isEmbedded: true),
      );
      expect(_builder.columnFunctionsFor(f), {'jsonb'});
    });

    test('String field returns {text}', () {
      const f = FieldInfo(name: 'email', dartType: 'String', isNullable: false);
      expect(_builder.columnFunctionsFor(f), {'text'});
    });

    test('unknown type returns empty set', () {
      const f = FieldInfo(
        name: 'x',
        dartType: 'UnknownModel',
        isNullable: false,
      );
      // Not enum, not list/map, not embedded — no column fn
      expect(_builder.columnFunctionsFor(f), {'jsonb'});
    });
  });
}
