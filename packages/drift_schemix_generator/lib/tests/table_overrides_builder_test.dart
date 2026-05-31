import 'package:drift_schemix_generator/src/column_builder.dart';
import 'package:drift_schemix_generator/src/table_overrides_builder.dart';
import 'package:schemix/models.dart';
import 'package:schemix_builder/schemix_builder.dart' show SchemixLogger;
import 'package:test/test.dart';

const _log = SchemixLogger('test');
const _columnBuilder = DriftColumnBuilder();
const _overridesBuilder = DriftTableOverridesBuilder(_columnBuilder);

void main() {
  group('DriftTableOverridesBuilder.buildOverrides — tableName', () {
    test('always emits tableName override', () {
      const cls = ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        hasSchemix: true,
      );
      final overrides = _overridesBuilder.buildOverrides(cls, 'users', _log);
      final joined = overrides.join('\n');
      expect(joined, contains("String get tableName => 'users'"));
    });

    test('custom tableName is used verbatim', () {
      const cls = ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        hasSchemix: true,
        tableName: 'app_users',
      );
      final overrides = _overridesBuilder.buildOverrides(
        cls,
        cls.tableName ?? cls.name,
        _log,
      );
      expect(overrides.join('\n'), contains("=> 'app_users'"));
    });
  });

  group('DriftTableOverridesBuilder.buildOverrides — composite PK', () {
    test('single PK does not emit primaryKey override', () {
      const cls = ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(
            name: 'id',
            dartType: 'String',
            isNullable: false,
            db: FieldDbInfo(isPrimaryKey: true),
          ),
        ],
      );
      final overrides = _overridesBuilder.buildOverrides(cls, 'users', _log);
      expect(overrides.join('\n'), isNot(contains('Set<Column>')));
    });

    test('multiple PK fields emit composite primaryKey override', () {
      const cls = ClassInfo(
        name: 'UserTag',
        assetPath: 'lib/user_tag.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(
            name: 'userId',
            dartType: 'String',
            isNullable: false,
            db: FieldDbInfo(isPrimaryKey: true),
          ),
          FieldInfo(
            name: 'tagId',
            dartType: 'String',
            isNullable: false,
            db: FieldDbInfo(isPrimaryKey: true),
          ),
        ],
      );
      final overrides = _overridesBuilder.buildOverrides(
        cls,
        'user_tags',
        _log,
      );
      final joined = overrides.join('\n');
      expect(joined, contains('Set<Column> get primaryKey'));
      expect(joined, contains('userId'));
      expect(joined, contains('tagId'));
    });
  });

  group('DriftTableOverridesBuilder.buildOverrides — uniqueKeys', () {
    test('no composite unique indexes → no uniqueKeys override', () {
      const cls = ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        hasSchemix: true,
      );
      final overrides = _overridesBuilder.buildOverrides(cls, 'users', _log);
      expect(overrides.join('\n'), isNot(contains('uniqueKeys')));
    });

    test('composite unique index emits uniqueKeys override', () {
      const cls = ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        hasSchemix: true,
        compositeIndexes: [
          CompositeIndexInfo(fields: ['email', 'tenantId'], unique: true),
        ],
      );
      final overrides = _overridesBuilder.buildOverrides(cls, 'users', _log);
      final joined = overrides.join('\n');
      expect(joined, contains('uniqueKeys'));
      expect(joined, contains('email'));
      expect(joined, contains('tenantId'));
    });

    test('non-unique composite index does not emit uniqueKeys', () {
      const cls = ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        hasSchemix: true,
        compositeIndexes: [
          CompositeIndexInfo(fields: ['email'], unique: false),
        ],
      );
      final overrides = _overridesBuilder.buildOverrides(cls, 'users', _log);
      expect(overrides.join('\n'), isNot(contains('uniqueKeys')));
    });
  });

  group('DriftTableOverridesBuilder.buildEnumConverters', () {
    test('no enum fields → empty list', () {
      const cls = ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
        ],
      );
      expect(_overridesBuilder.buildEnumConverters(cls), isEmpty);
    });

    test('one enum field emits one TypeConverter getter', () {
      const cls = ClassInfo(
        name: 'Post',
        assetPath: 'lib/post.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(
            name: 'status',
            dartType: 'PostStatus',
            isNullable: false,
            isEnum: true,
          ),
        ],
      );
      final converters = _overridesBuilder.buildEnumConverters(cls);
      expect(converters.length, 1);
      expect(converters.first, contains('TypeConverter<PostStatus, int>'));
      expect(converters.first, contains('EnumIndexConverter'));
    });

    test('two fields of same enum type emit only one converter', () {
      const cls = ClassInfo(
        name: 'Post',
        assetPath: 'lib/post.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(
            name: 'status',
            dartType: 'PostStatus',
            isNullable: false,
            isEnum: true,
          ),
          FieldInfo(
            name: 'previousStatus',
            dartType: 'PostStatus',
            isNullable: true,
            isEnum: true,
          ),
        ],
      );
      final converters = _overridesBuilder.buildEnumConverters(cls);
      expect(converters.length, 1);
    });

    test('two fields of different enum types emit two converters', () {
      const cls = ClassInfo(
        name: 'Job',
        assetPath: 'lib/job.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(
            name: 'status',
            dartType: 'JobStatus',
            isNullable: false,
            isEnum: true,
          ),
          FieldInfo(
            name: 'kind',
            dartType: 'JobKind',
            isNullable: false,
            isEnum: true,
          ),
        ],
      );
      final converters = _overridesBuilder.buildEnumConverters(cls);
      expect(converters.length, 2);
    });
  });
}
