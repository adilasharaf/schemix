import 'package:schemix/schemix.dart';

class GormEnumBuilder {
  const GormEnumBuilder();

  String build(ClassInfo enumInfo) {
    final buffer = StringBuffer();
    final typeName = enumInfo.name;

    buffer.writeln('package enums\n');
    buffer.writeln('type $typeName string\n');
    buffer.writeln('const (');

    for (final valueName in enumInfo.enumValues) {
      // Convert Dart enum value name to Go standard: TypeNameValueName 
      // e.g. categoryType + standard => CategoryTypeStandard
      final goValueName = '$typeName${_capitalize(valueName)}';
      
      // Usually, enum values are string-based.
      final stringValue = valueName;
      buffer.writeln('\t$goValueName $typeName = "$stringValue"');
    }

    buffer.writeln(')');
    return buffer.toString();
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
