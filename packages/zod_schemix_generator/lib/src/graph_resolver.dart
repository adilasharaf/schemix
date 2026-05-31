import 'package:schemix/schemix.dart';

/// Builds the intra-file type dependency graph and provides topological sort
/// and cycle detection over it.
///
/// "Intra-file" means only dependencies between types declared in the *same*
/// source file. Cross-file dependencies are handled by [CrossFileRegistry].
final class ZodGraphResolver {
  const ZodGraphResolver();

  /// Returns a dependency graph for [classes] where each node is a class name
  /// and each edge `A → B` means "A uses B as a field type".
  ///
  /// Enum nodes always have an empty dependency set — they never reference
  /// other schema types.
  Map<String, Set<String>> buildIntraFileGraph(List<ClassInfo> classes) {
    final names = {for (final c in classes) c.name};
    return {
      for (final cls in classes)
        cls.name: cls.isEnum
            ? const {}
            : {
                for (final f in cls.allFields)
                  for (final candidate in [
                    f.dartType,
                    f.listItemType,
                    f.mapValueType,
                  ])
                    if (candidate != null &&
                        candidate != cls.name &&
                        names.contains(candidate))
                      candidate,
              },
    };
  }

  /// Returns a topological ordering of [graph] — dependencies before dependents.
  ///
  /// Nodes that participate in a cycle (detected by the caller via
  /// [findCyclicNodes]) are appended at the end in arbitrary order so they are
  /// still emitted, just wrapped in `z.lazy()` by the schema generator.
  List<String> topoSort(Map<String, Set<String>> graph) {
    final inDegree = {for (final n in graph.keys) n: 0};

    for (final deps in graph.values) {
      for (final d in deps) {
        if (inDegree.containsKey(d)) inDegree[d] = inDegree[d]! + 1;
      }
    }

    final queue = [
      for (final e in inDegree.entries)
        if (e.value == 0) e.key,
    ];
    final result = <String>[];

    while (queue.isNotEmpty) {
      final node = queue.removeLast();
      result.add(node);
      for (final dep in graph[node] ?? const <String>{}) {
        if (!inDegree.containsKey(dep)) continue;
        if ((inDegree[dep] = inDegree[dep]! - 1) == 0) queue.add(dep);
      }
    }

    // Append any nodes not yet emitted (cycle members or disconnected).
    result.addAll(graph.keys.toSet().difference(result.toSet()));
    return result.reversed.toList(growable: false);
  }

  /// Returns the set of node names that participate in at least one cycle
  /// within [graph].
  Set<String> findCyclicNodes(Map<String, Set<String>> graph) {
    final visited = <String>{};
    final stackSet = <String>{};
    final stack = <String>[];
    final cyclic = <String>{};

    void dfs(String node) {
      if (stackSet.contains(node)) {
        // Everything on the stack from `node` onward is part of this cycle.
        cyclic.addAll(stack.sublist(stack.indexOf(node)));
        cyclic.add(node);
        return;
      }
      if (!visited.add(node)) return;

      stack.add(node);
      stackSet.add(node);
      for (final n in graph[node] ?? const <String>{}) {
        dfs(n);
      }
      stack.removeLast();
      stackSet.remove(node);
    }

    for (final node in graph.keys) {
      if (!visited.contains(node)) dfs(node);
    }
    return cyclic;
  }
}
