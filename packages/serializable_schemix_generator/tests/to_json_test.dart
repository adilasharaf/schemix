import 'package:schemix/models.dart';
import 'package:schemix/src/generator_api.dart';
import 'package:schemix_builder/schemix_builder.dart' show SchemixLogger;
import 'package:serializable_schemix_generator/src/expr_builder.dart';
import 'package:serializable_schemix_generator/src/to_json.dart';
import 'package:test/test.dart';

final class _StubGraph implements TypeGraph {
  const _StubGraph({this.enums = const {}, this.models = const {}});
  final Set<String> enums;
  final Set<String> models;

  @override
  bool isEnum(String name) => enums.contains(name);
  @override
  bool isModel(String name) => models.contains(name);
  @override
  bool isEmbeddable(String name) => false;
  @override
  TypeInfo? resolve(String name) => null;
  @override
  Set<String> get cyclicTypes => const {};
  @override
  String? relativeImportFor({
    required String typeName,
    required String fromSourceAssetPath,
  }) => null;
  @override
  String? relativeDrizzleImportFor({
    required String typeName,
    required String fromSourceAssetPath,
  }) => null;
}

String _jsonKey(FieldInfo f) => f.effectiveJsonName;

void main() {
  final expr = const JsonExprBuilder(_StubGraph(models: {}));
  final log = const SchemixLogger('test');
  late ToJsonGenerator gen;

  setUp(() => gen = ToJsonGenerator(expr, log));

  group('ToJsonGenerator — signature', () {
    test('produces correct function signature', () {
      final cls = const ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
        ],
      );

      final result = gen.generate(cls, jsonKey: _jsonKey);

      expect(
        result,
        contains("Map<String, dynamic> _\$UserToJson(User instance)"),
      );
    });
  });

  group('ToJsonGenerator — primitive fields', () {
    test('String field emits passthrough', () {
      final cls = const ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'email', dartType: 'String', isNullable: false),
        ],
      );

      final result = gen.generate(cls, jsonKey: _jsonKey);
      expect(result, contains("'email': instance.email"));
    });

    test('DateTime field emits toIso8601String()', () {
      final cls = const ClassInfo(
        name: 'Audit',
        assetPath: 'lib/audit.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'createdAt', dartType: 'DateTime', isNullable: false),
        ],
      );

      final result = gen.generate(cls, jsonKey: _jsonKey);
      expect(result, contains('instance.createdAt.toIso8601String()'));
    });

    test('nullable DateTime emits null-aware call', () {
      final cls = const ClassInfo(
        name: 'Audit',
        assetPath: 'lib/audit.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'deletedAt', dartType: 'DateTime', isNullable: true),
        ],
      );

      final result = gen.generate(cls, jsonKey: _jsonKey);
      expect(result, contains('instance.deletedAt?.toIso8601String()'));
    });
  });

  group('ToJsonGenerator — enum fields', () {
    test('non-nullable enum emits .name', () {
      final expr2 = const JsonExprBuilder(_StubGraph(enums: {'Status'}));
      final gen2 = ToJsonGenerator(expr2, log);

      final cls = const ClassInfo(
        name: 'Post',
        assetPath: 'lib/post.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(
            name: 'status',
            dartType: 'Status',
            isNullable: false,
            isEnum: true,
          ),
        ],
      );

      final result = gen2.generate(cls, jsonKey: _jsonKey);
      expect(result, contains('instance.status.name'));
    });
  });

  group('ToJsonGenerator — field exclusion', () {
    test('ignored field is excluded', () {
      final cls = const ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
          FieldInfo(
            name: 'internal',
            dartType: 'String',
            isNullable: true,
            serialization: FieldSerializationInfo(isIgnored: true),
          ),
        ],
      );

      final result = gen.generate(cls, jsonKey: _jsonKey);
      expect(result, isNot(contains("'internal'")));
    });

    test('read-only field is excluded from toJson', () {
      final cls = const ClassInfo(
        name: 'Auth',
        assetPath: 'lib/auth.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
          FieldInfo(
            name: 'token',
            dartType: 'String',
            isNullable: false,
            serialization: FieldSerializationInfo(isReadOnly: true),
          ),
        ],
      );

      final result = gen.generate(cls, jsonKey: _jsonKey);
      expect(result, isNot(contains("'token'")));
    });
  });

  group('ToJsonGenerator — json key override', () {
    test('respects explicit jsonKeyName', () {
      final cls = const ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(
            name: 'email',
            dartType: 'String',
            isNullable: false,
            serialization: FieldSerializationInfo(jsonKeyName: 'email_address'),
          ),
        ],
      );

      final result = gen.generate(cls, jsonKey: _jsonKey);
      expect(result, contains("'email_address': instance.email"));
      expect(result, isNot(contains("'email': instance.email")));
    });
  });
}
