// Golden test: verifies end-to-end output for a typical User model.
// Uses hand-constructed ClassInfo / FieldInfo — no analyzer or build_runner needed.

import 'package:build/build.dart';
import 'package:schemix/models.dart';
import 'package:schemix/src/generator_api.dart';
import 'package:serializable_schemix_generator/src/generator.dart';
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
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _userClass = const ClassInfo(
  name: 'User',
  assetPath: 'lib/models/user.dart',
  hasSchemix: true,
  ownFields: [
    FieldInfo(
      name: 'id',
      dartType: 'String',
      isNullable: false,
      db: FieldDbInfo(isPrimaryKey: true, autoGenerate: true),
    ),
    FieldInfo(name: 'email', dartType: 'String', isNullable: false),
    FieldInfo(
      name: 'passwordHash',
      dartType: 'String',
      isNullable: false,
      serialization: FieldSerializationInfo(useSnakeCaseFallback: true),
    ),
    FieldInfo(
      name: 'deletedAt',
      dartType: 'DateTime',
      isNullable: true,
      serialization: FieldSerializationInfo(useSnakeCaseFallback: true),
    ),
  ],
  ctorParamNames: {'id', 'email', 'passwordHash'},
);

GeneratorContext _makeContext() => const GeneratorContext(
  typeGraph: _StubGraph(enums: {}, models: {}),
  options: _NoOpOptions(),
  sourceAssetPath: 'lib/models/user.dart',
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final generator = SerializableGenerator();

  group('SerializableGenerator.shouldRun', () {
    test('returns true for @Schemix class', () {
      expect(generator.shouldRun(_userClass), isTrue);
    });

    test('returns false for enum', () {
      final enumClass = const ClassInfo(
        name: 'Status',
        assetPath: 'lib/status.dart',
        hasSchemix: true,
        isEnum: true,
        enumValues: ['active', 'inactive'],
      );
      expect(generator.shouldRun(enumClass), isFalse);
    });

    test('returns false for abstractSchema', () {
      final abstract = const ClassInfo(
        name: 'BaseModel',
        assetPath: 'lib/base.dart',
        hasSchemix: true,
        abstractSchema: true,
      );
      expect(generator.shouldRun(abstract), isFalse);
    });

    test('returns false when hasSchemix is false', () {
      final plain = const ClassInfo(
        name: 'Plain',
        assetPath: 'lib/plain.dart',
        hasSchemix: false,
      );
      expect(generator.shouldRun(plain), isFalse);
    });
  });

  group('SerializableGenerator.generate — User golden', () {
    late GeneratorOutput output;

    setUpAll(() {
      output = generator.generate(_userClass, _makeContext());
    });

    test('produces .schemix.dart extension key', () {
      expect(output.outputs.keys, contains('.schemix.dart'));
    });

    test('output is non-empty', () {
      expect(output.outputs['.schemix.dart'], isNotEmpty);
    });

    test('fromJson function is present', () {
      final src = output.outputs['.schemix.dart']!;
      expect(src, contains('_\$UserFromJson(Map<String, dynamic> json)'));
    });

    test('toJson function is present', () {
      final src = output.outputs['.schemix.dart']!;
      expect(src, contains('_\$UserToJson(User instance)'));
    });

    test('copy function is present', () {
      final src = output.outputs['.schemix.dart']!;
      expect(src, contains('_\$UserCopy(User src)'));
    });

    test('snake_case fallback applied to passwordHash key', () {
      final src = output.outputs['.schemix.dart']!;
      expect(src, contains("'password_hash'"));
    });

    test('nullable DateTime deletedAt uses null-guard in fromJson', () {
      final src = output.outputs['.schemix.dart']!;
      expect(src, contains("json['deleted_at'] == null"));
    });

    test('id field uses named ctor arg', () {
      final src = output.outputs['.schemix.dart']!;
      expect(src, contains("id: json['id']"));
    });
  });
}

// ── NoOp BuilderOptions ───────────────────────────────────────────────────────

final class _NoOpOptions implements BuilderOptions {
  const _NoOpOptions();

  @override
  Map<String, dynamic> get config => const {};

  @override
  bool get isRoot => true;

  String? get packageName => null;

  @override
  BuilderOptions overrideWith(BuilderOptions? other) => BuilderOptions(config);
}
