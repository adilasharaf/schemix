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

    if (externalImports.isNotEmpty) {
      buf.writeln((externalImports.toList()..sort()).join('\n'));
    }

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

  /// Assembles a single `.g.ts` file that contains both TypeScript interface /
  /// enum-type-alias blocks (from `ts_schemix_generator`) and Zod schema
  /// constants (from this generator).
  ///
  /// Layout of the output file:
  ///
  /// ```
  /// import { z } from 'zod';              ← exactly once
  /// <external npm imports>
  /// <merged cross-file imports>
  ///
  /// <TS enum + interface blocks>
  ///
  /// <Zod schema blocks>
  /// ```
  ///
  /// [tsContent] is the raw string returned by `ts_schemix_generator`'s
  /// `assembleFile`. Its own `import { z }` line and `import type` lines are
  /// stripped here so they can be merged with the Zod imports without
  /// duplication.
  ///
  /// When [tsContent] is null or empty the output is identical to [assemble].
  String assembleWithTs({
    required String? tsContent,
    required Set<String> externalImports,
    required Map<String, Set<String>> crossFileImports,
    required List<String> schemaBlocks,
  }) {
    if (tsContent == null || tsContent.trim().isEmpty) {
      return assemble(
        externalImports: externalImports,
        crossFileImports: crossFileImports,
        schemaBlocks: schemaBlocks,
      );
    }

    // Strip the `import { z } from 'zod'` line and any `import type` lines
    // from the TS content — they will be re-emitted below in merged form.
    final tsLines = tsContent.split('\n');
    final tsBodyLines = tsLines.where((line) {
      final t = line.trimLeft();
      return !t.startsWith("import { z } from 'zod'") &&
          !t.startsWith('import type ');
    }).toList();

    // Collect `import type` lines from TS content so they can be merged into
    // the cross-file import block.
    final tsTypeImports = tsLines
        .where((l) => l.trimLeft().startsWith('import type '))
        .toList();

    // Drop leading blank lines left over after stripping imports.
    while (tsBodyLines.isNotEmpty && tsBodyLines.first.trim().isEmpty) {
      tsBodyLines.removeAt(0);
    }

    final buf = StringBuffer("import { z } from 'zod';\n");

    if (externalImports.isNotEmpty) {
      buf.writeln((externalImports.toList()..sort()).join('\n'));
    }

    if (crossFileImports.isNotEmpty) {
      final sorted = crossFileImports.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in sorted) {
        final ids = (entry.value.toList()..sort()).join(', ');
        buf.writeln("import { $ids } from '${entry.key}';");
      }
    }

    // Re-emit `import type` lines from TS content, sorted for determinism.
    if (tsTypeImports.isNotEmpty) {
      for (final line in tsTypeImports..sort()) {
        buf.writeln(line);
      }
    }

    buf.writeln();

    // TS interface / enum-type-alias blocks come first.
    final tsBody = tsBodyLines.join('\n').trimRight();
    if (tsBody.isNotEmpty) {
      buf
        ..writeln(tsBody)
        ..writeln();
    }

    // Zod schema constants follow.
    buf.write(schemaBlocks.join('\n'));
    return buf.toString();
  }
}
