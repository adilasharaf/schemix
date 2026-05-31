import 'package:schemix/schemix.dart';

// ── String extensions ─────────────────────────────────────────────────────────

extension DrizzleStringExtension on String {
  /// Converts a camelCase / PascalCase identifier to snake_case.
  ///
  /// Examples:
  ///   'createdAt'  → 'created_at'
  ///   'UserId'     → 'user_id'
  ///   'OrderItem'  → 'order_item'
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

  /// Converts a PascalCase / snake_case identifier to lowerCamelCase.
  ///
  /// Examples:
  ///   'UserStatus'  → 'userStatus'
  ///   'Order'       → 'order'
  ///   'order_item'  → 'orderItem'
  String get camelCase {
    if (isEmpty) return this;
    if (contains('_')) {
      final parts = split('_');
      return parts.first.lowercaseFirst +
          parts.skip(1).map((p) => p.uppercaseFirst).join();
    }
    return substring(0, 1).toLowerCase() + substring(1);
  }

  String get lowercaseFirst =>
      isEmpty ? this : substring(0, 1).toLowerCase() + substring(1);

  String get uppercaseFirst =>
      isEmpty ? this : substring(0, 1).toUpperCase() + substring(1);

  /// Returns the Drizzle table variable name for a Dart class name.
  ///
  /// Applies simple English pluralisation after converting to lowerCamelCase:
  ///   'User'       → 'users'
  ///   'Category'   → 'categories'
  ///   'Address'    → 'addresses'
  ///   'Business'   → 'businesses'
  String get tableVarName {
    final lower = camelCase;
    if (lower.endsWith('s') ||
        lower.endsWith('x') ||
        lower.endsWith('z') ||
        lower.endsWith('ch') ||
        lower.endsWith('sh')) {
      return '${lower}es';
    }
    if (lower.endsWith('y') &&
        lower.length > 1 &&
        !_isVowel(lower[lower.length - 2])) {
      return '${lower.substring(0, lower.length - 1)}ies';
    }
    return '${lower}s';
  }

  bool _isVowel(String ch) => 'aeiou'.contains(ch.toLowerCase());
}

// ── Top-level helpers ─────────────────────────────────────────────────────────

/// Returns the Drizzle table variable name for a Dart class name.
String tableVarName(String dartClassName) => dartClassName.tableVarName;

/// Returns `true` when [field] must be omitted from Drizzle output.
///
/// A field is skipped when:
/// - `@IgnoreField` is present — excluded from all outputs.
/// - `@DriftIgnore` is present — reused here: local-only exclusion applies to
///   Drizzle as well (both represent "not in the server schema").
/// - `@DrizzleIgnore` is present — explicit Drizzle exclusion.
/// - `@CloudOnly` is present — field lives on the server only; no local table
///   column is needed.
bool skipField(FieldInfo field) =>
    field.isIgnored ||
    field.platform.driftIgnore ||
    field.platform.drizzleIgnore ||
    field.sync.cloudOnly;
