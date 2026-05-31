import 'package:schemix/models.dart';
import 'package:schemix_builder/schemix_builder.dart';

import 'expr_builder.dart';

final class FromJsonGenerator {
  const FromJsonGenerator(this._expr, this._log);
  final JsonExprBuilder _expr;
  final SchemixLogger _log;

  String generate(
    ClassInfo cls, {
    required Set<String> ctorParams,
    required String Function(FieldInfo) jsonKey,
  }) {
    final name = cls.name;

    final fields = cls.allFields
        .where((f) => !f.isIgnored && !f.serialization.isWriteOnly)
        .toList(growable: false);

    _log.verbose(
      '   fromJson     | $name  '
      'fields=${fields.length}  ctorParams=${ctorParams.length}',
    );

    if (ctorParams.isEmpty) return _cascadeOnly(name, fields, jsonKey);

    final ctorFields = fields
        .where((f) => ctorParams.contains(f.name))
        .toList(growable: false);
    final cascadeFields = fields
        .where((f) => !ctorParams.contains(f.name))
        .toList(growable: false);

    return _ctorPlusCascade(name, ctorFields, cascadeFields, jsonKey);
  }

  String _cascadeOnly(
    String name,
    List<FieldInfo> fields,
    String Function(FieldInfo) jsonKey,
  ) {
    if (fields.isEmpty) {
      return '$name _\$${name}FromJson(Map<String, dynamic> json) => $name();';
    }

    final buf = StringBuffer()
      ..writeln('$name _\$${name}FromJson(Map<String, dynamic> json) =>')
      ..writeln('    $name()');

    for (var i = 0; i < fields.length; i++) {
      final f = fields[i];
      final src = "json['${jsonKey(f)}']";
      buf.write("      ..${f.name} = ${_expr.fromJson(f, src)}");
      buf.writeln(i == fields.length - 1 ? ';' : '');
    }

    return buf.toString();
  }

  String _ctorPlusCascade(
    String name,
    List<FieldInfo> ctorFields,
    List<FieldInfo> cascadeFields,
    String Function(FieldInfo) jsonKey,
  ) {
    final buf = StringBuffer()
      ..writeln('$name _\$${name}FromJson(Map<String, dynamic> json) =>')
      ..writeln('    $name(');

    for (final f in ctorFields) {
      final src = "json['${jsonKey(f)}']";
      buf.writeln("      ${f.name}: ${_expr.fromJson(f, src)},");
    }

    if (cascadeFields.isEmpty) {
      buf.write('    );');
      return buf.toString();
    }

    buf.writeln('    )');
    for (var i = 0; i < cascadeFields.length; i++) {
      final f = cascadeFields[i];
      final src = "json['${jsonKey(f)}']";
      buf.write("      ..${f.name} = ${_expr.fromJson(f, src)}");
      buf.writeln(i == cascadeFields.length - 1 ? ';' : '');
    }

    return buf.toString();
  }
}
