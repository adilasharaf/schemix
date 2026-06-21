import 'package:schemix/schemix.dart';
import 'package:schemix_builder/schemix_builder.dart';

/// Resolves the set of field names that are constructor parameters for [cls].
///
/// Returns [ClassInfo.ctorParamNames] when it is non-empty.
/// Returns an empty set when [ClassInfo.ctorParamNames] is empty — this means
/// the class uses a no-arg constructor and all fields should be cascade-assigned.
final class CtorParamResolver {
  const CtorParamResolver(this._log);
  final SchemixLogger _log;

  Set<String> resolve(ClassInfo cls) {
    if (cls.ctorParamNames.isNotEmpty) {
      _log.verbose(
        '   ctor params  | ${cls.name}  '
        'count=${cls.ctorParamNames.length}  '
        '${cls.ctorParamNames}',
      );
      return cls.ctorParamNames;
    }

    _log.verbose('   ctor params  | ${cls.name}  no-arg ctor — cascade only');
    return const {};
  }
}
