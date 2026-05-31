import 'package:schemix/schemix.dart';

/// Matches valid JavaScript/TypeScript identifiers.
final _identPattern = RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$');

/// Returns [name] quoted as a TS object key if it is not a valid identifier
/// (e.g. `"some-key"` → `'some-key'`), or bare otherwise.
String tsKey(String name) => _identPattern.hasMatch(name) ? name : "'$name'";

/// Returns true when [field] should be omitted from Zod / TS output entirely.
///
/// A field is skipped when it is:
///   - marked `@IgnoreField` ([FieldInfo.isIgnored])
///   - marked `@ZodIgnore` ([FieldPlatformFlags.zodIgnore])
///   - marked `@OfflineOnly` ([FieldSyncInfo.offlineOnly]) — offline-only
///     fields never reach the server / TypeScript layer
bool skipField(FieldInfo field) =>
    field.isIgnored || field.platform.zodIgnore || field.sync.offlineOnly;
