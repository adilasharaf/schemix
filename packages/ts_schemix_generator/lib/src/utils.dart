import 'package:schemix/schemix.dart';

/// Matches valid JavaScript/TypeScript identifiers.
final _identPattern = RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$');

/// Returns [name] quoted as a TS object key if it is not a valid identifier
/// (e.g. `"some-key"` → `'some-key'`), or bare otherwise.
String tsKey(String name) => _identPattern.hasMatch(name) ? name : "'$name'";

/// Returns true when [field] should be omitted from TS output entirely.
///
/// A field is skipped when it is:
///   - marked `@IgnoreField` ([FieldInfo.isIgnored])
///   - marked `@ZodIgnore` ([FieldPlatformFlags.zodIgnore]) — also skips TS
///     because TS interfaces and Zod schemas must stay in sync
///   - marked `@OfflineOnly` ([FieldSyncInfo.offlineOnly])
bool skipField(FieldInfo field) =>
    field.isIgnored || field.platform.zodIgnore || field.sync.offlineOnly;
