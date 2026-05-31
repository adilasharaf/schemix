extension StringExtension on String {
  /// `fooBar` → `foo_bar`
  String get snakeCase => replaceAllMapped(
    RegExp(r'(?<=[a-z])[A-Z]'),
    (m) => '_${m.group(0)!.toLowerCase()}',
  );

  /// `FooBar` → `fooBar`
  String get camelCase => substring(0, 1).toLowerCase() + substring(1);
}
