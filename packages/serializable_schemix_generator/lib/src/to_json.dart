import 'package:schemix/models.dart';
import 'package:schemix_builder/schemix_builder.dart';

import 'expr_builder.dart';

final class ToJsonGenerator {
  const ToJsonGenerator(this._expr, this._log);
  final JsonExprBuilder _expr;
  final SchemixLogger _log;

  String generate(
    ClassInfo cls, {
    required String Function(FieldInfo) jsonKey,
  }) {
    final name = cls.name;

    final fields = cls.allFields
        .where((f) => !f.isIgnored && !f.serialization.isReadOnly)
        .toList(growable: false);

    _log.verbose('   toJson       | $name  fields=${fields.length}');

    final buf = StringBuffer()
      ..writeln('Map<String, dynamic> _\$${name}ToJson($name instance) =>')
      ..writeln('    <String, dynamic>{');

    for (final f in fields) {
      buf.writeln(
        "      '${jsonKey(f)}': ${_expr.toJson(f, 'instance.${f.name}')},",
      );
    }

    buf.write('    };');
    return buf.toString();
  }
}
