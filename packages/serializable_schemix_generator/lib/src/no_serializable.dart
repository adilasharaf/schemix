/// Opt out of Dart JSON serialization generation for this class.
///
/// Add to any `@Schemix`-annotated class to suppress `.schemix.dart` output:
/// ```dart
/// @Schemix()
/// @NoSerializable()
/// class InternalEvent { ... }
/// ```
class NoSerializable {
  const NoSerializable();
}
