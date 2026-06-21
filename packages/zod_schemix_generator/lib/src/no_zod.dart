/// Opt out of Zod schema + TypeScript interface generation for this class.
///
/// ```dart
/// @Schemix()
/// @NoZod()
/// class ServerOnlyModel { ... }
/// ```
class NoZod {
  const NoZod();
}
