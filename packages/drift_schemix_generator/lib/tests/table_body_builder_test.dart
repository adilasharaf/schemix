import 'package:drift_schemix_generator/src/column_builder.dart';
import 'package:drift_schemix_generator/src/table_body_builder.dart';
import 'package:schemix/models.dart';
import 'package:schemix_builder/schemix_builder.dart' show SchemixLogger;
import 'package:test/test.dart';

const _log = SchemixLogger('test');
const _columnBuilder = DriftColumnBuilder();
const _bodyBuilder = DriftTableBodyBuilder(_columnBuilder);

ClassInfo _cls({
  required String name,
  List<FieldInfo> fields = const [],
  bool enableTimestamps = false,
  bool enableSoftDelete = false,
}) => ClassInfo(
  name: name,
  assetPath: 'lib/models.dart',
  hasSchemix: true,
  ownFields: fields,
  enableTimestamps: enableTimestamps,
  enableSoftDelete: enableSoftDelete,
);

void main() {
  group('DriftTableBodyBuilder — normal fields', () {
    test('produces one column entry per eligible field', () {
      final cls = _cls(
        name: 'User',
        fields: const [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
          FieldInfo(name: 'email', dartType: 'String', isNullable: false),
        ],
      );
      final body = _bodyBuilder.buildTableBody(cls, _log);
      expect(body.length, 2);
    });

    test('skipped fields are omitted from body', () {
      final cls = _cls(
        name: 'User',
        fields: const [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
          FieldInfo(
            name: 'posts',
            dartType: 'Post',
            isNullable: false,
            relation: FieldRelationInfo(kind: RelationKind.hasMany),
          ),
        ],
      );
      final body = _bodyBuilder.buildTableBody(cls, _log);
      // Only 'id' should be in the body; 'posts' (hasMany) is skipped
      expect(body.length, 1);
      expect(body.first, contains('get id'));
    });

    test('fields with no drift type mapping are omitted', () {
      final cls = _cls(
        name: 'Config',
        fields: const [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
          FieldInfo(name: 'meta', dartType: 'Map', isNullable: false),
        ],
      );
      final body = _bodyBuilder.buildTableBody(cls, _log);
      expect(body.length, 1);
      expect(body.first, contains('get id'));
    });
  });

  group('DriftTableBodyBuilder — timestamp injection', () {
    test('enableTimestamps injects createdAt and updatedAt', () {
      final cls = _cls(
        name: 'Post',
        fields: const [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
        ],
        enableTimestamps: true,
      );
      final body = _bodyBuilder.buildTableBody(cls, _log);
      final joined = body.join('\n');
      expect(joined, contains('createdAt'));
      expect(joined, contains('updatedAt'));
      expect(joined, contains('withDefault(currentDateAndTime)'));
    });

    test('enableTimestamps does not re-inject when field already declared', () {
      final cls = _cls(
        name: 'Post',
        fields: const [
          FieldInfo(
            name: 'createdAt',
            dartType: 'DateTime',
            isNullable: false,
            isCreatedAt: true,
          ),
        ],
        enableTimestamps: true,
      );
      final body = _bodyBuilder.buildTableBody(cls, _log);
      // createdAt should appear exactly once
      final createdAtCount = body
          .where((line) => line.contains('createdAt'))
          .length;
      expect(createdAtCount, 1);
    });

    test('enableSoftDelete injects deletedAt as nullable', () {
      final cls = _cls(
        name: 'User',
        fields: const [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
        ],
        enableSoftDelete: true,
      );
      final body = _bodyBuilder.buildTableBody(cls, _log);
      final joined = body.join('\n');
      expect(joined, contains('deletedAt'));
      expect(joined, contains('.nullable()'));
    });

    test('no timestamps or soft-delete when both disabled', () {
      final cls = _cls(
        name: 'Simple',
        fields: const [
          FieldInfo(name: 'id', dartType: 'String', isNullable: false),
        ],
      );
      final body = _bodyBuilder.buildTableBody(cls, _log);
      final joined = body.join('\n');
      expect(joined, isNot(contains('createdAt')));
      expect(joined, isNot(contains('deletedAt')));
    });
  });
}
