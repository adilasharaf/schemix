import 'package:schemix/models.dart';
import 'package:test/test.dart';
import 'package:zod_schemix_generator/zod_schemix_generator.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

ClassInfo _cls(String name, {List<FieldInfo> fields = const []}) => ClassInfo(
  name: name,
  assetPath: 'lib/models.dart',
  hasSchemix: true,
  ownFields: fields,
);

FieldInfo _refField(String name, String dartType) =>
    FieldInfo(name: name, dartType: dartType, isNullable: false);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  const resolver = ZodGraphResolver();

  group('ZodGraphResolver.buildIntraFileGraph', () {
    test('single class with no deps produces empty dep set', () {
      final classes = [_cls('User')];
      final graph = resolver.buildIntraFileGraph(classes);
      expect(graph['User'], isEmpty);
    });

    test('class depending on sibling in same file is linked', () {
      final classes = [
        _cls('Post', fields: [_refField('author', 'User')]),
        _cls('User'),
      ];
      final graph = resolver.buildIntraFileGraph(classes);
      expect(graph['Post'], contains('User'));
      expect(graph['User'], isEmpty);
    });

    test('cross-file dependency not included (type not in classes list)', () {
      final classes = [
        _cls('Post', fields: [_refField('author', 'User')]),
      ];
      final graph = resolver.buildIntraFileGraph(classes);
      // User is not in classes → dep is ignored
      expect(graph['Post'], isEmpty);
    });

    test('enum has empty dependency set regardless of fields', () {
      final cls = const ClassInfo(
        name: 'Status',
        assetPath: 'lib/models.dart',
        hasSchemix: true,
        isEnum: true,
        enumValues: ['active'],
      );
      final graph = resolver.buildIntraFileGraph([cls]);
      expect(graph['Status'], isEmpty);
    });
  });

  group('ZodGraphResolver.topoSort', () {
    test('independent nodes all appear in result', () {
      final graph = {'A': <String>{}, 'B': <String>{}, 'C': <String>{}};
      final result = resolver.topoSort(graph);
      expect(result.toSet(), {'A', 'B', 'C'});
    });

    test('dependency appears before dependent', () {
      final graph = {
        'Post': {'User'},
        'User': <String>{},
      };
      final result = resolver.topoSort(graph);
      final postIdx = result.indexOf('Post');
      final userIdx = result.indexOf('User');
      expect(userIdx, lessThan(postIdx));
    });

    test('three-level chain in correct order', () {
      final graph = {
        'C': {'B'},
        'B': {'A'},
        'A': <String>{},
      };
      final result = resolver.topoSort(graph);
      expect(result.indexOf('A'), lessThan(result.indexOf('B')));
      expect(result.indexOf('B'), lessThan(result.indexOf('C')));
    });

    test('cyclic nodes all appear in result', () {
      final graph = {
        'X': {'Y'},
        'Y': {'X'},
      };
      final result = resolver.topoSort(graph);
      expect(result.toSet(), {'X', 'Y'});
    });
  });

  group('ZodGraphResolver.findCyclicNodes', () {
    test('returns empty set for acyclic graph', () {
      final graph = {
        'A': {'B'},
        'B': {'C'},
        'C': <String>{},
      };
      expect(resolver.findCyclicNodes(graph), isEmpty);
    });

    test('detects direct cycle A ↔ B', () {
      final graph = {
        'A': {'B'},
        'B': {'A'},
      };
      expect(resolver.findCyclicNodes(graph), containsAll(['A', 'B']));
    });

    test('detects indirect cycle X→Y→Z→X', () {
      final graph = {
        'X': {'Y'},
        'Y': {'Z'},
        'Z': {'X'},
      };
      expect(resolver.findCyclicNodes(graph), containsAll(['X', 'Y', 'Z']));
    });

    test('acyclic node not included even when adjacent to cyclic ones', () {
      final graph = {
        'Root': {'A'},
        'A': {'B'},
        'B': {'A'},
      };
      final cyclic = resolver.findCyclicNodes(graph);
      expect(cyclic, containsAll(['A', 'B']));
      expect(cyclic, isNot(contains('Root')));
    });
  });
}
