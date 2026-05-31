// Note: AnnotationValidator.validate requires a ClassElement (analyzer AST).
// These tests exercise the logic via hand-constructed ClassInfo objects and a
// null ClassElement — the validator only uses ClassElement to build error
// source-location pointers; null is accepted and produces correct error text.
//
// All five conflict scenarios documented in §3.2 of Plan2.md are covered here.

import 'package:schemix/models.dart';
import 'package:schemix_builder/src/annotation_validator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Builds a minimal [ClassInfo] containing [fields] and runs
/// [AnnotationValidator.validate] against a null [ClassElement].
/// Throws [InvalidGenerationSourceError] on any conflict.
void _validate(List<FieldInfo> fields) {
  final cls = ClassInfo(
    name: 'TestClass',
    assetPath: 'lib/test.dart',
    hasSchemix: true,
    ownFields: fields,
  );
  // null ClassElement is accepted — pointers will be missing but error text
  // is correct.
  AnnotationValidator.validate(cls, null);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AnnotationValidator — valid class does not throw', () {
    test('normal class with required fields passes', () {
      expect(
        () => _validate([
          const FieldInfo(
            name: 'id',
            dartType: 'String',
            isNullable: false,
            db: FieldDbInfo(isPrimaryKey: true),
          ),
          const FieldInfo(name: 'email', dartType: 'String', isNullable: false),
        ]),
        returnsNormally,
      );
    });

    test('ignored field without conflicting annotations passes', () {
      expect(
        () => _validate([
          const FieldInfo(
            name: 'internal',
            dartType: 'String',
            isNullable: true,
            serialization: FieldSerializationInfo(isIgnored: true),
          ),
        ]),
        returnsNormally,
      );
    });
  });

  group('Conflict 1 — @OfflineOnly + @CloudOnly', () {
    test('throws InvalidGenerationSourceError', () {
      expect(
        () => _validate([
          const FieldInfo(
            name: 'data',
            dartType: 'String',
            isNullable: false,
            sync: FieldSyncInfo(offlineOnly: true, cloudOnly: true),
          ),
        ]),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('error message mentions field name', () {
      try {
        _validate([
          const FieldInfo(
            name: 'data',
            dartType: 'String',
            isNullable: false,
            sync: FieldSyncInfo(offlineOnly: true, cloudOnly: true),
          ),
        ]);
        fail('expected throw');
      } on InvalidGenerationSourceError catch (e) {
        expect(e.message, contains('data'));
        expect(e.message, contains('@OfflineOnly'));
        expect(e.message, contains('@CloudOnly'));
      }
    });
  });

  group('Conflict 2 — @PrimaryKey on nullable field', () {
    test('throws InvalidGenerationSourceError', () {
      expect(
        () => _validate([
          const FieldInfo(
            name: 'id',
            dartType: 'String',
            isNullable: true,
            db: FieldDbInfo(isPrimaryKey: true),
          ),
        ]),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('non-nullable PK does not throw', () {
      expect(
        () => _validate([
          const FieldInfo(
            name: 'id',
            dartType: 'String',
            isNullable: false,
            db: FieldDbInfo(isPrimaryKey: true),
          ),
        ]),
        returnsNormally,
      );
    });
  });

  group('Conflict 3 — @CreatedAt + @UpdatedAt on same field', () {
    test('throws InvalidGenerationSourceError', () {
      expect(
        () => _validate([
          const FieldInfo(
            name: 'ts',
            dartType: 'DateTime',
            isNullable: false,
            isCreatedAt: true,
            isUpdatedAt: true,
          ),
        ]),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('only @CreatedAt does not throw', () {
      expect(
        () => _validate([
          const FieldInfo(
            name: 'createdAt',
            dartType: 'DateTime',
            isNullable: false,
            isCreatedAt: true,
          ),
        ]),
        returnsNormally,
      );
    });
  });

  group('Conflict 4 — @Encrypted + @ZodIgnore', () {
    test('throws InvalidGenerationSourceError', () {
      expect(
        () => _validate([
          const FieldInfo(
            name: 'secret',
            dartType: 'String',
            isNullable: false,
            security: FieldSecurityInfo(encrypted: true),
            platform: FieldPlatformFlags(zodIgnore: true),
          ),
        ]),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });
  });

  group('Conflict 5 — @IgnoreField + @PrimaryKey / validation / relation', () {
    test('IgnoreField + PrimaryKey throws', () {
      expect(
        () => _validate([
          const FieldInfo(
            name: 'id',
            dartType: 'String',
            isNullable: false,
            serialization: FieldSerializationInfo(isIgnored: true),
            db: FieldDbInfo(isPrimaryKey: true),
          ),
        ]),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('IgnoreField + validation constraint throws', () {
      expect(
        () => _validate([
          const FieldInfo(
            name: 'email',
            dartType: 'String',
            isNullable: false,
            serialization: FieldSerializationInfo(isIgnored: true),
            validation: FieldValidation(isEmail: true),
          ),
        ]),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('IgnoreField + BelongsTo relation throws', () {
      expect(
        () => _validate([
          const FieldInfo(
            name: 'userId',
            dartType: 'String',
            isNullable: false,
            serialization: FieldSerializationInfo(isIgnored: true),
            relation: FieldRelationInfo(
              kind: RelationKind.belongsTo,
              targetTypeName: 'User',
            ),
          ),
        ]),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('IgnoreField alone does not throw', () {
      expect(
        () => _validate([
          const FieldInfo(
            name: 'internal',
            dartType: 'String',
            isNullable: true,
            serialization: FieldSerializationInfo(isIgnored: true),
          ),
        ]),
        returnsNormally,
      );
    });
  });
}
