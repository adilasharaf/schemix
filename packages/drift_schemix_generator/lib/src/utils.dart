/// Local string utilities for the Drift generator.
extension DriftStringExtension on String {
  /// Converts a camelCase / PascalCase identifier to snake_case.
  ///
  /// Examples:
  ///   'createdAt'   → 'created_at'
  ///   'UserId'      → 'user_id'
  ///   'XMLParser'   → 'x_m_l_parser'   (all-caps run is split per character)
  String get snakeCase {
    if (isEmpty) return this;
    final buf = StringBuffer();
    for (var i = 0; i < length; i++) {
      final ch = this[i];
      if (ch == ch.toUpperCase() && ch != ch.toLowerCase()) {
        // It is an uppercase letter.
        if (i > 0) buf.write('_');
        buf.write(ch.toLowerCase());
      } else {
        buf.write(ch);
      }
    }
    return buf.toString();
  }

  /// Produces the private Dart converter getter name for an enum type.
  ///
  /// Examples:
  ///   'UserStatus'   → '_userStatusConverter'
  ///   'OrderKind'    → '_orderKindConverter'
  String get converterName =>
      '\$${substring(0, 1).toLowerCase()}${substring(1)}Converter';
}
