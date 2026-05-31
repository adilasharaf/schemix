import 'package:schemix/models.dart';
import 'package:schemix_builder/schemix_builder.dart' show SchemixLogger;
import 'package:serializable_schemix_generator/src/copy.dart';
import 'package:test/test.dart';

const _log = SchemixLogger('test');

void main() {
  late CopyGenerator gen;

  setUp(() => gen = const CopyGenerator(_log));

  // ── No fields ─────────────────────────────────────────────────────────────

  group('CopyGenerator — no fields', () {
    test('empty class produces no-arg copy call', () {
      const cls = ClassInfo(
        name: 'Empty',
        assetPath: 'lib/empty.dart',
        hasSchemix: true,
      );
      final result = gen.generate(cls, ctorParams: const {});
      expect(result, 'Empty _\$EmptyCopy(Empty src) => Empty();');
    });
  });

  // ── Cascade-only (no ctor params) ─────────────────────────────────────────

  group('CopyGenerator — cascade-only strategy', () {
    test('all fields use cascade when ctorParams is empty', () {
      const cls = ClassInfo(
        name: 'Config',
        assetPath: 'lib/config.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'debug', dartType: 'bool', isNullable: false),
          FieldInfo(name: 'timeout', dartType: 'int', isNullable: false),
        ],
      );
      final result = gen.generate(cls, ctorParams: const {});
      expect(result, contains('Config _\$ConfigCopy(Config src)'));
      expect(result, contains('..debug = src.debug'));
      expect(result, contains('..timeout = src.timeout'));
      // Must NOT use named ctor args
      expect(result, isNot(contains('debug: src.debug')));
    });

    test('last cascade field ends with semicolon', () {
      const cls = ClassInfo(
        name: 'Config',
        assetPath: 'lib/config.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'a', dartType: 'String', isNullable: false),
          FieldInfo(name: 'b', dartType: 'String', isNullable: false),
        ],
      );
      final result = gen.generate(cls, ctorParams: const {});
      expect(result.trimRight(), endsWith(';'));
    });
  });

  // ── Constructor + cascade ──────────────────────────────────────────────────

  group('CopyGenerator — ctor + cascade strategy', () {
    test('ctor fields use named args, extra fields use cascade', () {
      const cls = ClassInfo(
        name: 'Event',
        assetPath: 'lib/event.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
          FieldInfo(name: 'cachedLabel', dartType: 'String', isNullable: true),
        ],
      );
      final result = gen.generate(cls, ctorParams: {'id'});
      expect(result, contains('Event _\$EventCopy(Event src)'));
      expect(result, contains('id: src.id'));
      expect(result, contains('..cachedLabel = src.cachedLabel'));
    });

    test('all fields are ctor params — no cascade', () {
      const cls = ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
          FieldInfo(name: 'email', dartType: 'String', isNullable: false),
        ],
      );
      final result = gen.generate(cls, ctorParams: {'id', 'email'});
      expect(result, contains('id: src.id'));
      expect(result, contains('email: src.email'));
      // No cascade when all fields are in ctor
      expect(result, isNot(contains('..')));
    });

    test('result ends with semicolon', () {
      const cls = ClassInfo(
        name: 'User',
        assetPath: 'lib/user.dart',
        hasSchemix: true,
        ownFields: [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
          FieldInfo(name: 'nickname', dartType: 'String', isNullable: true),
        ],
      );
      final result = gen.generate(cls, ctorParams: {'id'});
      expect(result.trimRight(), endsWith(';'));
    });
  });

  // ── Ignored fields ─────────────────────────────────────────────────────────

  group('CopyGenerator — ignored fields', () {
    test('ignored field is excluded from copy output', () {
      const cls = ClassInfo(
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
      final result = gen.generate(cls, ctorParams: {'id'});
      expect(result, isNot(contains('internal')));
    });
  });

  // ── Inherited fields ───────────────────────────────────────────────────────

  group('CopyGenerator — inherited fields', () {
    test('inherited fields are included in copy', () {
      const cls = ClassInfo(
        name: 'Admin',
        assetPath: 'lib/admin.dart',
        hasSchemix: true,
        inheritedFields: [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
        ],
        ownFields: [
          FieldInfo(name: 'role', dartType: 'String', isNullable: false),
        ],
      );
      final result = gen.generate(cls, ctorParams: {'id', 'role'});
      expect(result, contains('id: src.id'));
      expect(result, contains('role: src.role'));
    });
  });
}
