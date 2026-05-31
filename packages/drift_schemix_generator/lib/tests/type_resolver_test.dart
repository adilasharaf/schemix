import 'package:drift_schemix_generator/src/type_resolver.dart';
import 'package:schemix/models.dart';
import 'package:test/test.dart';

FieldInfo _field(
  String dartType, {
  bool isNullable = false,
  bool isList = false,
  String? driftType,
}) => FieldInfo(
  name: 'col',
  dartType: dartType,
  isNullable: isNullable,
  isList: isList,
  db: FieldDbInfo(driftType: driftType),
);

void main() {
  group('DriftTypeResolver.resolve — dart type mapping', () {
    test('String → TextColumn', () {
      expect(DriftTypeResolver.resolve(_field('String')), 'TextColumn');
    });

    test('int → IntColumn', () {
      expect(DriftTypeResolver.resolve(_field('int')), 'IntColumn');
    });

    test('double → RealColumn', () {
      expect(DriftTypeResolver.resolve(_field('double')), 'RealColumn');
    });

    test('num → RealColumn', () {
      expect(DriftTypeResolver.resolve(_field('num')), 'RealColumn');
    });

    test('bool → BoolColumn', () {
      expect(DriftTypeResolver.resolve(_field('bool')), 'BoolColumn');
    });

    test('DateTime → DateTimeColumn', () {
      expect(DriftTypeResolver.resolve(_field('DateTime')), 'DateTimeColumn');
    });

    test('Uint8List → BlobColumn', () {
      expect(DriftTypeResolver.resolve(_field('Uint8List')), 'BlobColumn');
    });

    test('List → null (no column for lists)', () {
      expect(DriftTypeResolver.resolve(_field('String', isList: true)), isNull);
    });

    test('unknown type → null', () {
      expect(DriftTypeResolver.resolve(_field('CustomType')), isNull);
    });
  });

  group('DriftTypeResolver.resolve — @DriftType override', () {
    test('driftType "text" → TextColumn', () {
      expect(
        DriftTypeResolver.resolve(_field('int', driftType: 'text')),
        'TextColumn',
      );
    });

    test('driftType "integer" → IntColumn', () {
      expect(
        DriftTypeResolver.resolve(_field('String', driftType: 'integer')),
        'IntColumn',
      );
    });

    test('driftType "boolean" → BoolColumn', () {
      expect(
        DriftTypeResolver.resolve(_field('String', driftType: 'boolean')),
        'BoolColumn',
      );
    });

    test('driftType "datetime" → DateTimeColumn', () {
      expect(
        DriftTypeResolver.resolve(_field('String', driftType: 'datetime')),
        'DateTimeColumn',
      );
    });

    test('driftType "blob" → BlobColumn', () {
      expect(
        DriftTypeResolver.resolve(_field('String', driftType: 'blob')),
        'BlobColumn',
      );
    });

    test('unknown driftType → null', () {
      expect(
        DriftTypeResolver.resolve(_field('String', driftType: 'jsonb')),
        isNull,
      );
    });
  });

  group('DriftTypeResolver.columnDefinition', () {
    test('String field produces text() builder', () {
      final result = DriftTypeResolver.columnDefinition(
        const FieldInfo(name: 'email', dartType: 'String', isNullable: false),
      );
      expect(result, isNotNull);
      expect(result, contains("text()"));
      expect(result, contains("named('email')"));
      expect(result, isNot(contains('.nullable()')));
    });

    test('nullable field includes .nullable()', () {
      final result = DriftTypeResolver.columnDefinition(
        const FieldInfo(
          name: 'deletedAt',
          dartType: 'DateTime',
          isNullable: true,
        ),
      );
      expect(result, isNotNull);
      expect(result, contains('.nullable()'));
    });

    test('DateTime with @DatabaseDefault adds withDefault clause', () {
      final result = DriftTypeResolver.columnDefinition(
        const FieldInfo(
          name: 'createdAt',
          dartType: 'DateTime',
          isNullable: false,
          db: FieldDbInfo(databaseDefault: 'now'),
        ),
      );
      expect(result, isNotNull);
      expect(result, contains('.withDefault(currentDateAndTime)'));
    });

    test('camelCase field name produces snake_case column name', () {
      final result = DriftTypeResolver.columnDefinition(
        const FieldInfo(
          name: 'createdAt',
          dartType: 'DateTime',
          isNullable: false,
        ),
      );
      expect(result, isNotNull);
      expect(result, contains("named('created_at')"));
    });

    test('unknown type returns null', () {
      final result = DriftTypeResolver.columnDefinition(
        const FieldInfo(name: 'meta', dartType: 'Map', isNullable: false),
      );
      expect(result, isNull);
    });
  });
}
