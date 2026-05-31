/// Assembles the final `.d.ts` content that the TS generator writes to disk.
///
/// Responsibilities:
///   1. `import { z } from 'zod'` (needed for enum `z.infer<typeof ...>` lines)
///   2. Cross-file type imports from other generated `.d.ts` files
///   3. Enum schema+type blocks
///   4. Interface declaration blocks
///
/// Unlike the Zod assembler, there is no dependency-ordering concern here:
/// TypeScript interfaces are structural and forward-references are fine in
/// `.d.ts` files. The caller may pass blocks in any order.
final class TsFileAssembler {
  const TsFileAssembler();

  String assemble({
    required Set<String> zodImports,
    required Map<String, Set<String>> crossFileImports,
    required List<String> enumBlocks,
    required List<String> interfaceBlocks,
  }) {
    final buf = StringBuffer();

    // Zod import is only needed when there are enum declarations.
    if (enumBlocks.isNotEmpty) {
      buf.writeln("import { z } from 'zod';");
    }

    // External imports (e.g. Firebase type helpers)
    if (zodImports.isNotEmpty) {
      buf.writeln((zodImports.toList()..sort()).join('\n'));
    }

    // Cross-file type imports, sorted for determinism.
    if (crossFileImports.isNotEmpty) {
      final sorted = crossFileImports.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in sorted) {
        final ids = (entry.value.toList()..sort()).join(', ');
        buf.writeln("import type { $ids } from '${entry.key}';");
      }
    }

    if (buf.isNotEmpty) buf.writeln();

    if (enumBlocks.isNotEmpty) {
      buf
        ..writeln(enumBlocks.join('\n\n'))
        ..writeln();
    }

    if (interfaceBlocks.isNotEmpty) {
      buf.write(interfaceBlocks.join('\n\n'));
    }

    return buf.toString();
  }
}
