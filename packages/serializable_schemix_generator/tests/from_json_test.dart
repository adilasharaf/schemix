import 'package:schemix/models.dart';
import 'package:schemix/src/generator_api.dart';
import 'package:schemix_builder/schemix_builder.dart' show SchemixLogger;
import 'package:serializable_schemix_generator/src/expr_builder.dart';
import 'package:serializable_schemix_generator/src/from_json.dart';
import 'package:test/test.dart';

// ── Stub TypeGraph ─────────────────────────────────────────────────────────────

final class _StubGraph implements TypeGraph {
  const _StubGraph({required this.enums, required this.models});
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

  @override
  bool canImport(String typeName, String generatorId) => true;
}

String _jsonKey(FieldInfo f) => f.effectiveJsonName;

void main() {
  final expr = const JsonExprBuilder(_StubGraph(enums: {}, models: {}));
  final log = const SchemixLogger('test');
  late FromJsonGenerator gen;

  setUp(() => gen = FromJsonGenerator(expr, log));

  group('FromJsonGenerator — ctor params only', () {
    test('generates named-ctor call for all ctor fields', () {
      final cls = const ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
          FieldInfo(name: 'email', dartType: 'String', isNullable: false),
        ],
        ctorParamNames: {'id', 'email'},
      );

      final result = gen.generate(
        cls,
        ctorParams: {'id', 'email'},
        jsonKey: _jsonKey,
      );

      expect(
        result,
        contains("User _\$UserFromJson(Map<String, dynamic> json)"),
      );
      expect(result, contains("id: json['id'] as String"));
      expect(result, contains("email: json['email'] as String"));
      expect(result, isNot(contains('..')));
    });
  });

  group('FromJsonGenerator — cascade-only', () {
    test('generates cascade assignments when ctorParams is empty', () {
      final cls = const ClassInfo(
        name: 'Config',
        assetPath: 'lib/config.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'debug', dartType: 'bool', isNullable: false),
          FieldInfo(name: 'timeout', dartType: 'int', isNullable: false),
        ],
      );

      final result = gen.generate(cls, ctorParams: {}, jsonKey: _jsonKey);

      expect(result, contains('Config()'));
      expect(result, contains('..debug ='));
      expect(result, contains('..timeout ='));
    });

    test('empty class body produces minimal form', () {
      final cls = const ClassInfo(
        name: 'Empty',
        assetPath: 'lib/empty.dart',
        hasSchemix: true,
        ownFields: [],
      );

      final result = gen.generate(cls, ctorParams: {}, jsonKey: _jsonKey);

      expect(
        result.trim(),
        "Empty _\$EmptyFromJson(Map<String, dynamic> json) => Empty();",
      );
    });
  });

  group('FromJsonGenerator — ctor + cascade mix', () {
    test('ctor fields named; non-ctor fields cascade', () {
      final cls = const ClassInfo(
        name: 'Event',
        assetPath: 'lib/event.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
          FieldInfo(name: 'cachedLabel', dartType: 'String', isNullable: true),
        ],
        ctorParamNames: {'id'},
      );

      final result = gen.generate(cls, ctorParams: {'id'}, jsonKey: _jsonKey);

      expect(result, contains("id: json['id'] as String"));
      expect(result, contains('..cachedLabel ='));
    });
  });

  group('FromJsonGenerator — field exclusion', () {
    test('ignored field is excluded', () {
      final cls = const ClassInfo(
        name: 'Post',
        assetPath: 'lib/post.dart',
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
        ctorParamNames: {'id'},
      );

      final result = gen.generate(cls, ctorParams: {'id'}, jsonKey: _jsonKey);
      expect(result, isNot(contains('internal')));
    });

    test('write-only field is excluded from fromJson', () {
      final cls = const ClassInfo(
        name: 'Token',
        assetPath: 'lib/token.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
          FieldInfo(
            name: 'raw',
            dartType: 'String',
            isNullable: false,
            serialization: FieldSerializationInfo(isWriteOnly: true),
          ),
        ],
        ctorParamNames: {'id'},
      );

      final result = gen.generate(cls, ctorParams: {'id'}, jsonKey: _jsonKey);
      expect(result, isNot(contains("json['raw']")));
    });
  });

  group('FromJsonGenerator — nullable fields in fromJson', () {
    test('nullable DateTime uses null-guard form', () {
      final cls = const ClassInfo(
        name: 'Audit',
        assetPath: 'lib/audit.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'deletedAt', dartType: 'DateTime', isNullable: true),
        ],
      );

      final result = gen.generate(cls, ctorParams: {}, jsonKey: _jsonKey);
      expect(result, contains('== null ? null : DateTime.parse'));
    });
  });
}
