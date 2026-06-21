import 'package:schemix/models.dart';
import 'package:test/test.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _idField = FieldInfo(
  name: 'id',
  dartType: 'String',
  isNullable: false,
  db: FieldDbInfo(isPrimaryKey: true, autoGenerate: true),
);

const _emailField = FieldInfo(
  name: 'email',
  dartType: 'String',
  isNullable: false,
  serialization: FieldSerializationInfo(jsonKeyName: 'email_address'),
);

const _statusField = FieldInfo(
  name: 'status',
  dartType: 'UserStatus',
  isNullable: true,
  isEnum: true,
);

const _tagsField = FieldInfo(
  name: 'tags',
  dartType: 'String',
  isNullable: false,
  isList: true,
  listItemType: 'String',
);

const _metaField = FieldInfo(
  name: 'meta',
  dartType: 'String',
  isNullable: true,
  isMap: true,
  mapValueType: 'dynamic',
);

const _ignoredField = FieldInfo(
  name: 'internal',
  dartType: 'String',
  isNullable: true,
  serialization: FieldSerializationInfo(isIgnored: true),
);

ClassInfo _makeUser({
  List<FieldInfo> ownFields = const [_idField, _emailField],
  List<FieldInfo> inheritedFields = const [],
}) => ClassInfo(
  name: 'User',
  assetPath: 'lib/models/user.dart',
  hasSchemix: true,
  ownFields: ownFields,
  inheritedFields: inheritedFields,
  ctorParamNames: {'id', 'email'},
);

// ── FieldInfo tests ───────────────────────────────────────────────────────────

void main() {
  group('FieldInfo.effectiveJsonName', () {
    test('returns explicit jsonKeyName when set', () {
      expect(_emailField.effectiveJsonName, 'email_address');
    });

    test('returns field name when no override and no snake_case fallback', () {
      expect(_idField.effectiveJsonName, 'id');
    });

    test('uses snakeCase fallback when useSnakeCaseFallback is true', () {
      const field = FieldInfo(
        name: 'passwordHash',
        dartType: 'String',
        isNullable: false,
        serialization: FieldSerializationInfo(useSnakeCaseFallback: true),
      );
      expect(field.effectiveJsonName, 'password_hash');
    });
  });

  group('FieldInfo.isIgnored', () {
    test('returns true for IgnoreField', () {
      expect(_ignoredField.isIgnored, isTrue);
    });

    test('returns false for normal field', () {
      expect(_idField.isIgnored, isFalse);
    });
  });

  group('FieldInfo.isLifecycleField', () {
    test('returns true for createdAt', () {
      const f = FieldInfo(
        name: 'createdAt',
        dartType: 'DateTime',
        isNullable: false,
        isCreatedAt: true,
      );
      expect(f.isLifecycleField, isTrue);
    });

    test('returns true for updatedAt', () {
      const f = FieldInfo(
        name: 'updatedAt',
        dartType: 'DateTime',
        isNullable: true,
        isUpdatedAt: true,
      );
      expect(f.isLifecycleField, isTrue);
    });

    test('returns false for regular field', () {
      expect(_idField.isLifecycleField, isFalse);
    });
  });

  group('FieldInfo type flags', () {
    test('isList is set on list field', () {
      expect(_tagsField.isList, isTrue);
      expect(_tagsField.listItemType, 'String');
    });

    test('isMap is set on map field', () {
      expect(_metaField.isMap, isTrue);
      expect(_metaField.mapValueType, 'dynamic');
    });

    test('isEnum is set on enum field', () {
      expect(_statusField.isEnum, isTrue);
      expect(_statusField.isNullable, isTrue);
    });
  });

  // ── ClassInfo tests ─────────────────────────────────────────────────────────

  group('ClassInfo.allFields', () {
    test('concatenates inheritedFields before ownFields', () {
      const parent = FieldInfo(
        name: 'baseId',
        dartType: 'int',
        isNullable: false,
      );
      final cls = _makeUser(
        inheritedFields: [parent],
        ownFields: [_idField, _emailField],
      );
      expect(cls.allFields, [parent, _idField, _emailField]);
    });

    test('returns ownFields only when no inherited fields', () {
      final cls = _makeUser();
      expect(cls.allFields, [_idField, _emailField]);
    });
  });

  group('ClassInfo defaults', () {
    test('schemaVersion defaults to 1', () {
      final cls = _makeUser();
      expect(cls.schemaVersion, 1);
    });

    test('enableTimestamps defaults to false', () {
      final cls = _makeUser();
      expect(cls.enableTimestamps, isFalse);
    });

    test('enableSoftDelete defaults to false', () {
      final cls = _makeUser();
      expect(cls.enableSoftDelete, isFalse);
    });

    test('abstractSchema defaults to false', () {
      final cls = _makeUser();
      expect(cls.abstractSchema, isFalse);
    });
  });

  group('ClassInfo.extensions', () {
    test('defaults to empty map', () {
      const cls = ClassInfo(name: 'User', assetPath: 'lib/user.dart');
      expect(cls.extensions, isEmpty);
    });

    test('extensions["drizzle"] != false means generate (absent key)', () {
      const cls = ClassInfo(name: 'User', assetPath: 'lib/user.dart');
      expect(cls.extensions['drizzle'] != false, isTrue);
    });

    test('extensions["drizzle"] == false means suppressed', () {
      final cls = const ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        extensions: {'drizzle': false},
      );
      expect(cls.extensions['drizzle'], false);
    });

    test('suppressing one generator does not affect others', () {
      final cls = const ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        extensions: {'drizzle': false},
      );
      expect(cls.extensions['zod'] != false, isTrue);
      expect(cls.extensions['drift'] != false, isTrue);
    });
  });

  group('TypeInfo.extensions', () {
    test('defaults to empty map', () {
      const info = TypeInfo(
        name: 'User',
        isEnum: false,
        sourceAssetPath: 'lib/user.dart',
      );
      expect(info.extensions, isEmpty);
    });

    test('extensions["zod"] == false suppresses zod cross-file import', () {
      final info = const TypeInfo(
        name: 'Tag',
        isEnum: false,
        sourceAssetPath: 'lib/tag.dart',
        extensions: {'zod': false},
      );
      expect(info.extensions['zod'], false);
    });
  });
}
