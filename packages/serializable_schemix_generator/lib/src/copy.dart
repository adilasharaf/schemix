import 'package:schemix/models.dart';
import 'package:schemix_builder/src/logger.dart';

final class CopyGenerator {
  final SchemixLogger _log;

  const CopyGenerator(this._log);

  String generate(ClassInfo cls, {required Set<String> ctorParams}) {
    final name = cls.name;
    final fields = cls.allFields
        .where((f) => !f.isIgnored)
        .toList(growable: false);

    if (fields.isEmpty) {
      _log.verbose('   copy         | $name  (no fields, empty ctor)');
      return '$name _\$${name}Copy($name src) => $name();';
    }

    _log.verbose(
      '   copy         | $name  '
      'fields=${fields.length}  ctorParams=${ctorParams.length}',
    );

    if (ctorParams.isEmpty) return _cascadeOnly(name, fields);

    final ctorFields = fields
        .where((f) => ctorParams.contains(f.name))
        .toList(growable: false);
    final cascadeFields = fields
        .where((f) => !ctorParams.contains(f.name))
        .toList(growable: false);

    return _ctorPlusCascade(name, ctorFields, cascadeFields);
  }

  String _cascadeOnly(String name, List<FieldInfo> fields) {
    final buf = StringBuffer()
      ..writeln('$name _\$${name}Copy($name src) =>')
      ..writeln('    $name()');

    for (var i = 0; i < fields.length; i++) {
      final f = fields[i];
      buf.write('      ..${f.name} = src.${f.name}');
      buf.writeln(i == fields.length - 1 ? ';' : '');
    }

    return buf.toString();
  }

  String _ctorPlusCascade(
    String name,
    List<FieldInfo> ctorFields,
    List<FieldInfo> cascadeFields,
  ) {
    final buf = StringBuffer()
      ..writeln('$name _\$${name}Copy($name src) =>')
      ..writeln('    $name(');

    for (final f in ctorFields) {
      buf.writeln('      ${f.name}: src.${f.name},');
    }

    if (cascadeFields.isEmpty) {
      buf.write('    );');
      return buf.toString();
    }

    buf.writeln('    )');
    for (var i = 0; i < cascadeFields.length; i++) {
      final f = cascadeFields[i];
      buf.write('      ..${f.name} = src.${f.name}');
      buf.writeln(i == cascadeFields.length - 1 ? ';' : '');
    }

    return buf.toString();
  }
}
