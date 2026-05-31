import 'package:schemix/models.dart';
import 'package:test/test.dart';
import 'package:ts_schemix_generator/ts_schemix_generator.dart';

// ── Helper ─────────────────────────────────────────────────────────────────────

String _resolve(FieldInfo field) => TsTypeResolver.resolve(
  field: field,
  modelTsType: (name) => name == 'User' ? 'User' : null,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('TsTypeResolver — primitive mappings', () {
    test('String → string', () {
      const f = FieldInfo(name: 'x', dartType: 'String', isNullable: false);
      expect(_resolve(f), 'string');
    });

    test('int → number', () {
      const f = FieldInfo(name: 'x', dartType: 'int', isNullable: false);
      expect(_resolve(f), 'number');
    });

    test('double → number', () {
      const f = FieldInfo(name: 'x', dartType: 'double', isNullable: false);
      expect(_resolve(f), 'number');
    });

    test('bool → boolean', () {
      const f = FieldInfo(name: 'x', dartType: 'bool', isNullable: false);
      expect(_resolve(f), 'boolean');
    });

    test('dynamic → unknown', () {
      const f = FieldInfo(name: 'x', dartType: 'dynamic', isNullable: false);
      expect(_resolve(f), 'unknown');
    });

    test('void → undefined', () {
      const f = FieldInfo(name: 'x', dartType: 'void', isNullable: false);
      expect(_resolve(f), 'undefined');
    });

    test('DateTime → string (ISO-8601)', () {
      const f = FieldInfo(name: 'x', dartType: 'DateTime', isNullable: false);
      expect(_resolve(f), 'string');
    });

    test('Uint8List → string (base64)', () {
      const f = FieldInfo(name: 'x', dartType: 'Uint8List', isNullable: false);
      expect(_resolve(f), 'string');
    });
  });

  group('TsTypeResolver — collection types', () {
    test('List<String> → Array<string>', () {
      const f = FieldInfo(
        name: 'tags',
        dartType: 'String',
        isNullable: false,
        isList: true,
        listItemType: 'String',
      );
      expect(_resolve(f), 'Array<string>');
    });

    test('Map<String, dynamic> → Record<string, unknown>', () {
      const f = FieldInfo(
        name: 'meta',
        dartType: 'String',
        isNullable: false,
        isMap: true,
        mapValueType: 'dynamic',
      );
      expect(_resolve(f), 'Record<string, unknown>');
    });

    test('List of model type → Array<User>', () {
      const f = FieldInfo(
        name: 'users',
        dartType: 'User',
        isNullable: false,
        isList: true,
        listItemType: 'User',
      );
      expect(_resolve(f), 'Array<User>');
    });
  });

  group('TsTypeResolver — model and enum types', () {
    test('known model type returns type name', () {
      const f = FieldInfo(name: 'owner', dartType: 'User', isNullable: false);
      expect(_resolve(f), 'User');
    });

    test('unknown model type falls back to unknown', () {
      const f = FieldInfo(
        name: 'profile',
        dartType: 'Profile',
        isNullable: false,
      );
      expect(_resolve(f), 'unknown');
    });
  });

  group('TsTypeResolver — tsTypeOverride', () {
    test('converter.tsTypeOverride takes precedence', () {
      const f = FieldInfo(
        name: 'custom',
        dartType: 'dynamic',
        isNullable: false,
        converter: FieldConverterInfo(tsTypeOverride: 'MyCustomType'),
      );
      expect(_resolve(f), 'MyCustomType');
    });
  });
}
