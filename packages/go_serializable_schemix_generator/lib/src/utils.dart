import 'package:schemix/schemix.dart';

extension GoStringExtension on String {
  String get snakeCase {
    if (isEmpty) return this;
    final buf = StringBuffer();
    for (var i = 0; i < length; i++) {
      final ch = this[i];
      if (ch == ch.toUpperCase() && ch != ch.toLowerCase()) {
        if (i > 0) buf.write('_');
        buf.write(ch.toLowerCase());
      } else {
        buf.write(ch);
      }
    }
    return buf.toString();
  }
}

bool skipField(FieldInfo field) =>
    field.isIgnored ||
    field.platform.driftIgnore ||
    field.platform.drizzleIgnore ||
    field.sync.cloudOnly;
