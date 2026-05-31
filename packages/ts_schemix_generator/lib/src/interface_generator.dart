import 'package:schemix/schemix.dart';

import 'type_resolver.dart';
import 'utils.dart';

/// Generates TypeScript `interface` and `enum` declarations for a single
/// [ClassInfo].
///
/// Enum handling uses `z.enum([...])` style string-union types so they are
/// compatible with the Zod schemas emitted by `zod_schemix_generator`:
///
/// ```ts
/// export const StatusSchema = z.enum(['active', 'inactive']);
/// export type Status = z.infer<typeof StatusSchema>;
/// ```
///
/// For models, a plain `export interface Foo { ... }` is emitted, referencing
/// other model names directly (no `Schema` suffix here).
final class TsInterfaceGenerator {
  const TsInterfaceGenerator(this._graph);

  final TypeGraph _graph;

  // ── Enum ──────────────────────────────────────────────────────────────────

  /// Emits:
  /// ```ts
  /// // ── Status (Enum) ──
  /// export const StatusSchema = z.enum(['active', 'inactive']);
  /// export type Status = z.infer<typeof StatusSchema>;
  /// ```
  String generateEnum(ClassInfo cls) {
    final values = cls.enumValues.map((v) => "'$v'").join(', ');
    return '// ── ${cls.name} (Enum) ──\n'
        'export const ${cls.name}Schema = z.enum([$values]);\n'
        'export type ${cls.name} = z.infer<typeof ${cls.name}Schema>;';
  }

  // ── Interface ─────────────────────────────────────────────────────────────

  /// Emits:
  /// ```ts
  /// // ── User (Type) ──
  /// export interface User {
  ///   id: string;
  ///   email?: string | null;
  /// }
  /// ```
  String generateInterface(ClassInfo cls) {
    final buf = StringBuffer()
      ..writeln('// ── ${cls.name} (Type) ──')
      ..writeln('export interface ${cls.name} {');

    for (final field in cls.allFields) {
      if (skipField(field)) continue;

      final tsType = TsTypeResolver.resolve(
        field: field,
        modelTsType: (name) => _graph.resolve(name) != null ? name : null,
      );

      final key = tsKey(field.effectiveJsonName);
      final opt = field.isNullable ? '?' : '';
      final nul = field.isNullable ? ' | null' : '';

      buf.writeln('  $key$opt: $tsType$nul;');
    }

    buf.write('}');
    return buf.toString();
  }
}
