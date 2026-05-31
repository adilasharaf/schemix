/// Assembles the final `.g.ts` content that the Zod generator writes to disk.
///
/// Responsibilities:
///   1. `import { z } from 'zod'`
///   2. Any external npm imports (Firebase helpers, etc.)
///   3. Cross-file schema imports (other generated `.g.ts` files)
///   4. The schema `const` blocks in dependency order
///
/// The caller is expected to sort / order [schemaBlocks] before passing them
/// in. This class performs no ordering — it is a pure string-assembly step.
final class ZodFileAssembler {
  const ZodFileAssembler();

  String assemble({
    required Set<String> externalImports,
    required Map<String, Set<String>> crossFileImports,
    required List<String> schemaBlocks,
  }) {
    final buf = StringBuffer("import { z } from 'zod';\n");

    // External npm / utility imports, sorted for determinism.
    if (externalImports.isNotEmpty) {
      buf.writeln((externalImports.toList()..sort()).join('\n'));
    }

    // Cross-file schema imports, sorted by path for determinism.
    if (crossFileImports.isNotEmpty) {
      final sorted = crossFileImports.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in sorted) {
        final ids = (entry.value.toList()..sort()).join(', ');
        buf.writeln("import { $ids } from '${entry.key}';");
      }
    }

    buf.writeln();
    buf.write(schemaBlocks.join('\n'));
    return buf.toString();
  }
}
