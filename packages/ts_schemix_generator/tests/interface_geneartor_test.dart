import 'package:schemix/models.dart';
import 'package:schemix/src/generator_api.dart';
import 'package:test/test.dart';
import 'package:ts_schemix_generator/ts_schemix_generator.dart';

// ── Stub TypeGraph ─────────────────────────────────────────────────────────────

final class _StubGraph implements TypeGraph {
  const _StubGraph({this.models = const {}});
  final Set<String> models;

  @override
  bool isEnum(String name) => false;
  @override
  bool isModel(String name) => models.contains(name);
  @override
  bool isEmbeddable(String name) => false;
  @override
  TypeInfo? resolve(String name) => models.contains(name)
      ? TypeInfo(name: name, isEnum: false, sourceAssetPath: 'lib/models.dart')
      : null;
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

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('TsInterfaceGenerator.generateEnum', () {
    final gen = const TsInterfaceGenerator(_StubGraph());

    test('produces z.enum block with values', () {
      final cls = const ClassInfo(
        name: 'Status',
        assetPath: 'lib/status.dart',
        isEnum: true,
        hasSchemix: true,
        enumValues: ['active', 'inactive', 'pending'],
      );

      final result = gen.generateEnum(cls);

      expect(result, contains("StatusSchema = z.enum(["));
      expect(result, contains("'active'"));
      expect(result, contains("'inactive'"));
      expect(result, contains("'pending'"));
      expect(result, contains('export type Status ='));
    });

    test('single value enum', () {
      final cls = const ClassInfo(
        name: 'Flag',
        assetPath: 'lib/flag.dart',
        isEnum: true,
        hasSchemix: true,
        enumValues: ['only'],
      );

      final result = gen.generateEnum(cls);
      expect(result, contains("z.enum(['only'])"));
    });
  });

  group('TsInterfaceGenerator.generateInterface', () {
    final gen = const TsInterfaceGenerator(_StubGraph(models: {'User'}));

    test('produces export interface declaration', () {
      final cls = const ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
          FieldInfo(name: 'email', dartType: 'String', isNullable: false),
        ],
      );

      final result = gen.generateInterface(cls);

      expect(result, contains('export interface User'));
      expect(result, contains('id: string'));
      expect(result, contains('email: string'));
    });

    test('nullable field gets optional marker and | null', () {
      final cls = const ClassInfo(
        name: 'Post',
        assetPath: 'lib/post.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'deletedAt', dartType: 'DateTime', isNullable: true),
        ],
      );

      final result = gen.generateInterface(cls);

      // Optional field: `deletedAt?: string | null;`
      expect(result, contains('deletedAt?:'));
      expect(result, contains('| null'));
    });

    test('ignored field is excluded from interface', () {
      final cls = const ClassInfo(
        name: 'Secure',
        assetPath: 'lib/secure.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
          FieldInfo(
            name: 'secret',
            dartType: 'String',
            isNullable: false,
            serialization: FieldSerializationInfo(isIgnored: true),
          ),
        ],
      );

      final result = gen.generateInterface(cls);
      expect(result, contains('id: string'));
      expect(result, isNot(contains('secret')));
    });

    test('ZodIgnore field is excluded', () {
      final cls = const ClassInfo(
        name: 'Config',
        assetPath: 'lib/config.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
          FieldInfo(
            name: 'internalFlag',
            dartType: 'bool',
            isNullable: false,
            platform: FieldPlatformFlags(zodIgnore: true),
          ),
        ],
      );

      final result = gen.generateInterface(cls);
      expect(result, isNot(contains('internalFlag')));
    });

    test('List field produces Array<T> type', () {
      final cls = const ClassInfo(
        name: 'Post',
        assetPath: 'lib/post.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(
            name: 'tags',
            dartType: 'String',
            isNullable: false,
            isList: true,
            listItemType: 'String',
          ),
        ],
      );

      final result = gen.generateInterface(cls);
      expect(result, contains('Array<string>'));
    });
  });

  group('TsGenerator.shouldRun', () {
    final gen = TsGenerator();

    test('returns true for @Schemix class with generateZod', () {
      final cls = const ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        hasSchemix: true,
        generators: GeneratorFlags(zod: true),
      );
      expect(gen.shouldRun(cls), isTrue);
    });

    test('returns true for enum regardless of generators flags', () {
      final cls = const ClassInfo(
        name: 'Status',
        assetPath: 'lib/status.dart',
        hasSchemix: true,
        isEnum: true,
        enumValues: ['active'],
      );
      expect(gen.shouldRun(cls), isTrue);
    });

    test('returns false when manualImplementation is true', () {
      final cls = const ClassInfo(
        name: 'Manual',
        assetPath: 'lib/manual.dart',
        hasSchemix: true,
        generators: GeneratorFlags(zod: true),
        manualImplementation: true,
      );
      expect(gen.shouldRun(cls), isFalse);
    });

    test('returns false when generateZod is false for non-enum', () {
      final cls = const ClassInfo(
        name: 'Internal',
        assetPath: 'lib/internal.dart',
        hasSchemix: true,
        generators: GeneratorFlags(zod: false),
      );
      expect(gen.shouldRun(cls), isFalse);
    });
  });

  group('TsGenerator.generateFile — golden', () {
    test('produces interface and enum in single file', () {
      final gen = TsGenerator();
      final graph = const _StubGraph();

      final classes = [
        const ClassInfo(
          name: 'Status',
          assetPath: 'lib/models.dart',
          hasSchemix: true,
          isEnum: true,
          enumValues: ['active', 'inactive'],
        ),
        const ClassInfo(
          name: 'User',
          assetPath: 'lib/models.dart',
          hasSchemix: true,
          generators: GeneratorFlags(zod: true),
          ownFields: [
            FieldInfo(name: 'id', dartType: 'String', isNullable: false),
            FieldInfo(name: 'name', dartType: 'String', isNullable: false),
          ],
        ),
      ];

      final result = gen.generateFile(classes, 'lib/models.dart', graph);

      expect(result, contains("import { z } from 'zod'"));
      expect(result, contains('StatusSchema'));
      expect(result, contains('export interface User'));
      expect(result, contains('id: string'));
    });

    test('returns empty string when no eligible classes', () {
      final gen = TsGenerator();
      final classes = [
        const ClassInfo(
          name: 'Manual',
          assetPath: 'lib/manual.dart',
          hasSchemix: true,
          manualImplementation: true,
        ),
      ];

      final result = gen.generateFile(
        classes,
        'lib/manual.dart',
        const _StubGraph(),
      );
      expect(result, isEmpty);
    });
  });
}
