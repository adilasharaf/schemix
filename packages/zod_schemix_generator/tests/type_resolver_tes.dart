import 'package:schemix/models.dart';
import 'package:test/test.dart';
import 'package:zod_schemix_generator/zod_schemix_generator.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _resolve(FieldInfo field, {Set<String> cyclicTypes = const {}}) {
  final imports = <String>{};
  return ZodTypeResolver.resolve(
    field: field,
    modelSchemaName: (name) => '${name}Schema',
    cyclicTypes: cyclicTypes,
    requiredImports: imports,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ZodTypeResolver — primitives', () {
    test('String → z.string()', () {
      const f = FieldInfo(name: 'x', dartType: 'String', isNullable: false);
      expect(_resolve(f), 'z.string()');
    });

    test('int → z.number().int()', () {
      const f = FieldInfo(name: 'x', dartType: 'int', isNullable: false);
      expect(_resolve(f), 'z.number().int()');
    });

    test('double → z.number()', () {
      const f = FieldInfo(name: 'x', dartType: 'double', isNullable: false);
      expect(_resolve(f), 'z.number()');
    });

    test('num → z.number()', () {
      const f = FieldInfo(name: 'x', dartType: 'num', isNullable: false);
      expect(_resolve(f), 'z.number()');
    });

    test('bool → z.boolean()', () {
      const f = FieldInfo(name: 'x', dartType: 'bool', isNullable: false);
      expect(_resolve(f), 'z.boolean()');
    });

    test('dynamic → z.unknown()', () {
      const f = FieldInfo(name: 'x', dartType: 'dynamic', isNullable: false);
      expect(_resolve(f), 'z.unknown()');
    });

    test('DateTime → z.string().datetime()', () {
      const f = FieldInfo(name: 'x', dartType: 'DateTime', isNullable: false);
      expect(_resolve(f), contains('z.string().datetime'));
    });

    test('Uint8List → z.string().base64()', () {
      const f = FieldInfo(name: 'x', dartType: 'Uint8List', isNullable: false);
      expect(_resolve(f), 'z.string().base64()');
    });
  });

  group('ZodTypeResolver — string validation chains', () {
    test('Email adds .email()', () {
      const f = FieldInfo(
        name: 'email',
        dartType: 'String',
        isNullable: false,
        validation: FieldValidation(isEmail: true),
      );
      expect(_resolve(f), contains('.email()'));
    });

    test('Url adds .url()', () {
      const f = FieldInfo(
        name: 'url',
        dartType: 'String',
        isNullable: false,
        validation: FieldValidation(isUrl: true),
      );
      expect(_resolve(f), contains('.url()'));
    });

    test('Uuid adds .uuid()', () {
      const f = FieldInfo(
        name: 'id',
        dartType: 'String',
        isNullable: false,
        validation: FieldValidation(isUuid: true),
      );
      expect(_resolve(f), contains('.uuid()'));
    });

    test('Length(max: 255) adds .max(255)', () {
      const f = FieldInfo(
        name: 'name',
        dartType: 'String',
        isNullable: false,
        validation: FieldValidation(maxLength: 255),
      );
      expect(_resolve(f), contains('.max(255)'));
    });

    test('Length(min: 3, max: 150) adds .min(3).max(150)', () {
      const f = FieldInfo(
        name: 'name',
        dartType: 'String',
        isNullable: false,
        validation: FieldValidation(minLength: 3, maxLength: 150),
      );
      final result = _resolve(f);
      expect(result, contains('.min(3)'));
      expect(result, contains('.max(150)'));
    });

    test('Regex adds .regex()', () {
      const f = FieldInfo(
        name: 'code',
        dartType: 'String',
        isNullable: false,
        validation: FieldValidation(regex: r'^[A-Z]{3}$'),
      );
      expect(_resolve(f), contains('.regex('));
    });

    test('Required String adds .min(1)', () {
      const f = FieldInfo(
        name: 'value',
        dartType: 'String',
        isNullable: false,
        validation: FieldValidation(required: true),
      );
      expect(_resolve(f), contains('.min(1)'));
    });
  });

  group('ZodTypeResolver — number validation', () {
    test('Min(0) on int adds .gte(0)', () {
      const f = FieldInfo(
        name: 'count',
        dartType: 'int',
        isNullable: false,
        validation: FieldValidation(min: 0),
      );
      expect(_resolve(f), contains('.gte(0)'));
    });

    test('Max(100) adds .lte(100)', () {
      const f = FieldInfo(
        name: 'percent',
        dartType: 'double',
        isNullable: false,
        validation: FieldValidation(max: 100),
      );
      expect(_resolve(f), contains('.lte(100)'));
    });
  });

  group('ZodTypeResolver — list and map', () {
    test('List<String> → z.array(z.string())', () {
      const f = FieldInfo(
        name: 'tags',
        dartType: 'String',
        isNullable: false,
        isList: true,
        listItemType: 'String',
      );
      expect(_resolve(f), 'z.array(z.string())');
    });

    test('Map<String, dynamic> → z.record(z.string(), z.unknown())', () {
      const f = FieldInfo(
        name: 'meta',
        dartType: 'String',
        isNullable: false,
        isMap: true,
        mapValueType: 'dynamic',
      );
      expect(_resolve(f), 'z.record(z.string(), z.unknown())');
    });

    test('required List adds .nonempty()', () {
      const f = FieldInfo(
        name: 'tags',
        dartType: 'String',
        isNullable: false,
        isList: true,
        listItemType: 'String',
        validation: FieldValidation(required: true),
      );
      expect(_resolve(f), contains('.nonempty()'));
    });
  });

  group('ZodTypeResolver — cyclic types', () {
    test('cyclic model is wrapped in z.lazy()', () {
      const f = FieldInfo(name: 'parent', dartType: 'Node', isNullable: false);
      final result = _resolve(f, cyclicTypes: {'Node'});
      expect(result, contains('z.lazy('));
      expect(result, contains('NodeSchema'));
    });

    test('non-cyclic model returns bare schema name', () {
      const f = FieldInfo(name: 'user', dartType: 'User', isNullable: false);
      final result = _resolve(f);
      expect(result, 'UserSchema');
      expect(result, isNot(contains('z.lazy')));
    });
  });

  group('DefaultResolver.toZodCatch', () {
    test('bool true → "true"', () {
      expect(DefaultResolver.toZodCatch('true'), 'true');
    });

    test('bool false → "false"', () {
      expect(DefaultResolver.toZodCatch('false'), 'false');
    });

    test('integer string → same', () {
      expect(DefaultResolver.toZodCatch('42'), '42');
    });

    test('enum constant → quoted variant', () {
      expect(DefaultResolver.toZodCatch('UserStatus.active'), "'active'");
    });

    test('plain string without dot → quoted', () {
      expect(DefaultResolver.toZodCatch('hello'), "'hello'");
    });
  });
}
