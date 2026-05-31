import 'package:schemix/schemix.dart';
import 'package:schemix_builder/src/registry.dart';
import 'package:test/test.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

TypeInfo _model(
  String name, {
  String assetPath = 'lib/models.dart',
  bool embeddable = false,
  Set<String> fieldDeps = const {},
  Set<String> relationDeps = const {},
}) => TypeInfo(
  name: name,
  isEnum: false,
  sourceAssetPath: assetPath,
  embeddable: embeddable,
  fieldDeps: fieldDeps,
  relationDeps: relationDeps,
);

TypeInfo _enum(String name, List<String> values) => TypeInfo(
  name: name,
  isEnum: true,
  enumValues: values,
  sourceAssetPath: 'lib/models.dart',
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late CrossFileRegistry registry;

  setUp(() => registry = CrossFileRegistry());

  group('CrossFileRegistry.register / isModel / isEnum', () {
    test('registered model is recognised as model', () {
      registry.register(_model('User'));
      expect(registry.isModel('User'), isTrue);
      expect(registry.isEnum('User'), isFalse);
    });

    test('registered enum is recognised as enum', () {
      registry.register(_enum('Status', ['active', 'inactive']));
      expect(registry.isEnum('Status'), isTrue);
      expect(registry.isModel('Status'), isFalse);
    });

    test('unknown name returns false for both isModel and isEnum', () {
      expect(registry.isModel('Ghost'), isFalse);
      expect(registry.isEnum('Ghost'), isFalse);
    });

    test('re-registering same name overwrites entry', () {
      registry.register(_model('User'));
      registry.register(_enum('User', ['a', 'b']));
      expect(registry.isEnum('User'), isTrue);
    });
  });

  group('CrossFileRegistry.isEmbeddable', () {
    test('returns true for embeddable model', () {
      registry.register(_model('Address', embeddable: true));
      expect(registry.isEmbeddable('Address'), isTrue);
    });

    test('returns false for non-embeddable model', () {
      registry.register(_model('User'));
      expect(registry.isEmbeddable('User'), isFalse);
    });

    test('returns false for unknown name', () {
      expect(registry.isEmbeddable('Unknown'), isFalse);
    });
  });

  group('CrossFileRegistry.resolve', () {
    test('returns TypeInfo for registered name', () {
      final info = _model('Post');
      registry.register(info);
      expect(registry.resolve('Post'), info);
    });

    test('returns null for unknown name', () {
      expect(registry.resolve('Unknown'), isNull);
    });
  });

  group('CrossFileRegistry.cyclicTypes', () {
    test('returns empty set with no cyclic dependencies', () {
      registry.register(_model('User', fieldDeps: {'Post'}));
      registry.register(_model('Post', fieldDeps: {'Tag'}));
      registry.register(_model('Tag'));
      registry.seal();
      expect(registry.cyclicTypes, isEmpty);
    });

    test('detects direct cycle between two types', () {
      registry.register(_model('A', fieldDeps: {'B'}));
      registry.register(_model('B', fieldDeps: {'A'}));
      registry.seal();
      expect(registry.cyclicTypes, containsAll(['A', 'B']));
    });

    test('detects indirect cycle through three types', () {
      registry.register(_model('X', fieldDeps: {'Y'}));
      registry.register(_model('Y', fieldDeps: {'Z'}));
      registry.register(_model('Z', fieldDeps: {'X'}));
      registry.seal();
      expect(registry.cyclicTypes, containsAll(['X', 'Y', 'Z']));
    });
  });

  group('CrossFileRegistry.relativeImportFor', () {
    test('returns null when both types share the same file', () {
      registry.register(_model('User', assetPath: 'lib/models.dart'));
      registry.register(_model('Post', assetPath: 'lib/models.dart'));
      final result = registry.relativeImportFor(
        typeName: 'Post',
        fromSourceAssetPath: 'lib/models.dart',
      );
      expect(result, isNull);
    });

    test('returns null for unknown type', () {
      final result = registry.relativeImportFor(
        typeName: 'Ghost',
        fromSourceAssetPath: 'lib/models.dart',
      );
      expect(result, isNull);
    });

    test('returns relative path for types in different files', () {
      registry.register(_model('User', assetPath: 'lib/user.dart'));
      registry.register(_model('Post', assetPath: 'lib/post.dart'));
      final result = registry.relativeImportFor(
        typeName: 'User',
        fromSourceAssetPath: 'lib/post.dart',
      );
      expect(result, isNotNull);
      expect(result, isNot(contains('.ts')));
    });
  });

  group('CrossFileRegistry toJson / fromJson round-trip', () {
    test('serialises and deserialises registered types', () {
      registry.register(_model('User', assetPath: 'lib/user.dart'));
      registry.register(_enum('Status', ['active', 'inactive']));
      registry.registerRelation(
        const RelationInfo(
          ownerName: 'Post',
          targetName: 'User',
          fieldName: 'userId',
          kind: RelationKind.belongsTo,
        ),
      );

      final json = registry.toJson();
      final restored = CrossFileRegistry.fromJson(json);

      expect(restored.isModel('User'), isTrue);
      expect(restored.isEnum('Status'), isTrue);
      expect(restored.resolve('Status')?.enumValues, ['active', 'inactive']);
    });

    test('empty registry round-trips cleanly', () {
      final json = registry.toJson();
      final restored = CrossFileRegistry.fromJson(json);
      expect(restored.isModel('Anything'), isFalse);
    });
  });
}
