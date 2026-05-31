import 'package:schemix/schemix.dart';
import 'package:schemix_builder/schemix_builder.dart';

/// Resolves the set of field names that are constructor parameters for [cls].
///
/// Returns an empty set when the class uses a no-arg constructor — generators
/// should use cascade assignments for all fields in that case.
final class CtorParamResolver {
  const CtorParamResolver(this._log);
  final SchemixLogger _log;

  Set<String> resolve(ClassInfo cls) {
    if (cls.ctorParamNames.isNotEmpty) {
      _log.verbose(
        '   ctor params  | ${cls.name}  '
        'source=metadata  count=${cls.ctorParamNames.length}  '
        '${cls.ctorParamNames}',
      );
      return cls.ctorParamNames;
    }

    _log.verbose('   ctor params  | ${cls.name}  source=heuristic');
    return _heuristic(cls);
  }

  /// Infers constructor parameters from field shape when [ClassInfo.ctorParamNames]
  /// is unavailable. Non-nullable fields and `late required` fields are treated
  /// as constructor parameters; everything else is cascade-assigned.
  Set<String> _heuristic(ClassInfo cls) {
    final params = <String>{
      for (final f in cls.allFields)
        if (!f.isIgnored && (!f.isNullable || (f.isLate && f.isRequired)))
          f.name,
    };

    _log.verbose(
      '   ctor params  | ${cls.name}  '
      'heuristic count=${params.length}  $params',
    );

    return params;
  }
}
