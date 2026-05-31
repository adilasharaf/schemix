import 'package:schemix/src/constants.dart';
import 'package:test/test.dart';

void main() {
  group('SchemixConstants.dartPrimitives', () {
    test('contains core Dart primitives', () {
      final p = SchemixConstants.dartPrimitives;
      expect(p, containsAll(['String', 'int', 'double', 'num', 'bool']));
    });

    test('contains collection types', () {
      final p = SchemixConstants.dartPrimitives;
      expect(p, containsAll(['List', 'Map', 'Set', 'Iterable']));
    });

    test('contains DateTime and Duration', () {
      final p = SchemixConstants.dartPrimitives;
      expect(p, containsAll(['DateTime', 'Duration']));
    });

    test('contains Uint8List', () {
      expect(SchemixConstants.dartPrimitives, contains('Uint8List'));
    });

    test('contains special types', () {
      final p = SchemixConstants.dartPrimitives;
      expect(p, containsAll(['dynamic', 'Object', 'void', 'Null', 'Never']));
    });

    test('does not contain non-primitive types', () {
      expect(SchemixConstants.dartPrimitives, isNot(contains('User')));
      expect(SchemixConstants.dartPrimitives, isNot(contains('Post')));
    });
  });

  group('SchemixConstants.generatedSuffixes', () {
    test('contains .g.dart', () {
      expect(SchemixConstants.generatedSuffixes, contains('.g.dart'));
    });

    test('contains .schemix.dart', () {
      expect(SchemixConstants.generatedSuffixes, contains('.schemix.dart'));
    });

    test('contains .table.dart', () {
      expect(SchemixConstants.generatedSuffixes, contains('.table.dart'));
    });

    test('contains .freezed.dart', () {
      expect(SchemixConstants.generatedSuffixes, contains('.freezed.dart'));
    });

    test('does not contain plain .dart', () {
      expect(SchemixConstants.generatedSuffixes, isNot(contains('.dart')));
    });
  });
}
